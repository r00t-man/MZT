import logging
import os
from datetime import datetime
from html import escape

from dotenv import load_dotenv
load_dotenv()

from telegram import Update
from telegram.constants import ParseMode
from telegram.error import BadRequest
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

from .rbac import is_control_chat, is_user, is_admin, is_blocked
from .ui import (
    main_menu,
    nodes_menu,
    node_details_menu,
    traffic_menu,
    alerts_menu,
    persistent_menu_keyboard,
    users_menu,
    user_card_menu,
)
from .summary import make_summary, make_status_text
from .prometheus import (
    get_up,
    get_traffic,
    get_traffic_period,
    get_traffic_total,
    get_traffic_sum_now,
    get_traffic_sum_period,
    get_traffic_sum_total,
    get_node_snapshot,
)
from .reserve_logic import render_node_status
from .alerts_state import (
    set_mute_for_seconds,
    set_manual_off,
    clear_mute,
    get_status as get_alert_status,
)
from .user_registry import (
    register_guest_user,
    users_page,
    get_user,
    set_blocked,
)
from .worker import worker

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
log = logging.getLogger("grafana-bot")


async def safe_edit(query, text, reply_markup=None):
    """
    query: callback_query, сообщение которого нужно отредактировать.
    text: новый HTML-текст сообщения.
    reply_markup: инлайн-клавиатура (опционально).
    """
    try:
        return await query.edit_message_text(
            text,
            reply_markup=reply_markup,
            parse_mode=ParseMode.HTML,
            disable_web_page_preview=True,
        )
    except BadRequest as e:
        msg = str(e)
        if "Message is not modified" in msg:
            await query.answer("Уже актуально")
            return
        raise


def _format_gb(value_bytes: float) -> str:
    """value_bytes: объём в байтах."""
    return f"{value_bytes / 1024 / 1024 / 1024:.2f} GB"


def _admin_menu_markup(update: Update):
    """update: объект Telegram Update для определения прав администратора."""
    return main_menu(show_admin=is_admin(update))


async def _deny_if_blocked(update: Update):
    """update: объект Telegram Update пользователя, чей доступ проверяется."""
    if not is_blocked(update):
        return False

    text = (
        "<b>⛔ Доступ ограничен</b>\n\n"
        "<blockquote>Обратись к администратору бота, если доступ нужен снова.</blockquote>"
    )

    try:
        if update.message:
            await update.message.reply_text(
                text,
                parse_mode=ParseMode.HTML,
                disable_web_page_preview=True,
            )
        elif update.callback_query:
            await update.callback_query.answer("Доступ ограничен", show_alert=True)
    except Exception:
        pass

    return True


def _format_alert_status(chat_id: str) -> str:
    """chat_id: chat id, для которого показываем статус получения алертов."""
    status = get_alert_status(chat_id)

    if status["enabled"]:
        return (
            "<b>🔔 Мои алерты</b>\n\n"
            "Статус: <b>включены</b>\n\n"
            "<blockquote>Все уведомления мониторинга будут приходить как обычно.</blockquote>"
        )

    if status["mode"] == "manual_off":
        return (
            "<b>🔕 Мои алерты</b>\n\n"
            "Статус: <b>отключены до ручного включения</b>\n\n"
            "<blockquote>Уведомления не будут приходить, пока ты сам не включишь их обратно.</blockquote>"
        )

    if status["mode"] == "until" and status["until"]:
        dt = datetime.fromtimestamp(status["until"]).strftime("%d.%m.%Y %H:%M")
        return (
            "<b>🔕 Мои алерты</b>\n\n"
            f"Статус: <b>временно отключены до {escape(dt)}</b>\n\n"
            "<blockquote>После этого времени уведомления включатся автоматически.</blockquote>"
        )

    return "<b>🔔 Мои алерты</b>\n\nСтатус: <b>включены</b>"


def _format_user_card(user: dict) -> str:
    """user: словарь данных пользователя из users_registry."""
    username = f"@{user['username']}" if user.get("username") else "—"
    full_name = user.get("full_name") or "—"
    lang = user.get("language_code") or "—"
    first_seen = user.get("first_seen") or "—"
    last_seen = user.get("last_seen") or "—"
    blocked = "⛔ Да" if user.get("blocked") else "✅ Нет"

    return (
        "<b>👤 Карточка пользователя</b>\n\n"
        f"<b>ID:</b> <code>{user.get('user_id')}</code>\n"
        f"<b>Username:</b> {escape(username)}\n"
        f"<b>Имя:</b> {escape(full_name)}\n"
        f"<b>Язык:</b> {escape(lang)}\n"
        f"<b>Первый вход:</b> {escape(first_seen)}\n"
        f"<b>Последняя активность:</b> {escape(last_seen)}\n"
        f"<b>Заблокирован:</b> {blocked}"
    )


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """update/context: стандартные параметры обработчика команды /start."""
    register_guest_user(update, is_admin=is_admin(update))

    if await _deny_if_blocked(update):
        return

    if not is_control_chat(update) or not is_user(update):
        return

    text = make_status_text(force_refresh=True)
    await update.message.reply_text(
        text,
        reply_markup=persistent_menu_keyboard(),
        parse_mode=ParseMode.HTML,
        disable_web_page_preview=True,
    )
    await update.message.reply_text(
        "<b>🏠 Быстрое меню</b>",
        reply_markup=_admin_menu_markup(update),
        parse_mode=ParseMode.HTML,
        disable_web_page_preview=True,
    )


async def menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """update/context: стандартные параметры обработчика команды /menu."""
    register_guest_user(update, is_admin=is_admin(update))

    if await _deny_if_blocked(update):
        return

    if not is_control_chat(update) or not is_user(update):
        return

    text = "<b>🏠 Меню мониторинга</b>"

    if update.message:
        await update.message.reply_text(
            text,
            reply_markup=persistent_menu_keyboard(),
            parse_mode=ParseMode.HTML,
            disable_web_page_preview=True,
        )
        await update.message.reply_text(
            "<b>Выбери действие:</b>",
            reply_markup=_admin_menu_markup(update),
            parse_mode=ParseMode.HTML,
            disable_web_page_preview=True,
        )
    elif update.callback_query:
        await update.callback_query.answer()
        await safe_edit(update.callback_query, text, reply_markup=_admin_menu_markup(update))


async def quick_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """update/context: обработчик текста от reply-клавиатуры."""
    register_guest_user(update, is_admin=is_admin(update))

    if await _deny_if_blocked(update):
        return

    if not is_control_chat(update) or not is_user(update):
        return

    text = (update.message.text or "").strip()

    if text == "🏠 Меню":
        return await menu(update, context)

    if text == "📊 Статус":
        status_text = make_status_text(force_refresh=True)
        return await update.message.reply_text(
            status_text,
            reply_markup=_admin_menu_markup(update),
            parse_mode=ParseMode.HTML,
            disable_web_page_preview=True,
        )

    if text == "🔕 Алерты":
        txt = (
            "<b>🔕 Управление алертами</b>\n\n"
            "<blockquote>Здесь можно отключить уведомления только для себя. "
            "Это не повлияет на других пользователей бота.</blockquote>"
        )
        return await update.message.reply_text(
            txt,
            reply_markup=alerts_menu(),
            parse_mode=ParseMode.HTML,
            disable_web_page_preview=True,
        )

    return await menu(update, context)


async def buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """update/context: обработчик callback-кнопок инлайн-меню."""
    register_guest_user(update, is_admin=is_admin(update))

    if await _deny_if_blocked(update):
        return

    if not is_control_chat(update) or not is_user(update):
        return

    q = update.callback_query
    await q.answer()
    data = q.data or ""
    user_chat_id = str(update.effective_chat.id)

    if data == "menu":
        return await safe_edit(q, "<b>🏠 Меню мониторинга</b>", reply_markup=_admin_menu_markup(update))

    if data in ("refresh", "status"):
        txt = make_status_text(force_refresh=True)
        return await safe_edit(q, txt, reply_markup=_admin_menu_markup(update))

    if data == "alerts_menu":
        txt = (
            "<b>🔕 Управление алертами</b>\n\n"
            "<blockquote>Здесь можно отключить уведомления только для себя. "
            "Это не повлияет на других пользователей бота.</blockquote>"
        )
        return await safe_edit(q, txt, reply_markup=alerts_menu())

    if data == "alerts_status":
        return await safe_edit(q, _format_alert_status(user_chat_id), reply_markup=alerts_menu())

    if data == "alerts_unmute":
        clear_mute(user_chat_id)
        txt = (
            "<b>🔔 Алерты включены</b>\n\n"
            "<blockquote>Теперь уведомления мониторинга снова будут приходить тебе в личку.</blockquote>"
        )
        return await safe_edit(q, txt, reply_markup=alerts_menu())

    if data.startswith("alerts_mute:"):
        mode = data.split(":", 1)[1]

        if mode == "1d":
            set_mute_for_seconds(user_chat_id, 86400)
            txt = (
                "<b>🔕 Алерты отключены на 1 день</b>\n\n"
                "<blockquote>После истечения срока уведомления включатся автоматически.</blockquote>"
            )
            return await safe_edit(q, txt, reply_markup=alerts_menu())

        if mode == "7d":
            set_mute_for_seconds(user_chat_id, 7 * 86400)
            txt = (
                "<b>🔕 Алерты отключены на 7 дней</b>\n\n"
                "<blockquote>После истечения срока уведомления включатся автоматически.</blockquote>"
            )
            return await safe_edit(q, txt, reply_markup=alerts_menu())

        if mode == "30d":
            set_mute_for_seconds(user_chat_id, 30 * 86400)
            txt = (
                "<b>🔕 Алерты отключены на 30 дней</b>\n\n"
                "<blockquote>После истечения срока уведомления включатся автоматически.</blockquote>"
            )
            return await safe_edit(q, txt, reply_markup=alerts_menu())

        if mode == "manual":
            set_manual_off(user_chat_id)
            txt = (
                "<b>⛔ Алерты отключены до ручного включения</b>\n\n"
                "<blockquote>Уведомления не будут приходить, пока ты не нажмёшь кнопку включения обратно.</blockquote>"
            )
            return await safe_edit(q, txt, reply_markup=alerts_menu())

    if data == "traffic":
        t = get_traffic(force_refresh=True)
        total = get_traffic_sum_now(force_refresh=True)

        if not t:
            return await safe_edit(
                q,
                "<b>🌐 Трафик сейчас</b>\n\nНет данных по трафику",
                reply_markup=_admin_menu_markup(update),
            )

        top = sorted(t.items(), key=lambda x: x[1], reverse=True)[:10]
        txt = (
            "<b>🌐 Трафик сейчас</b>\n"
            "<blockquote>Текущая реальная скорость приёма и отдачи трафика на нодах.\n"
            "Показывает живую нагрузку в данный момент.</blockquote>\n\n"
            f"📊 <b>Суммарно по всем нодам:</b> {total:.2f} Mbps\n\n"
            + "\n".join(f"• {escape(k)}: {v:.2f} Mbps" for k, v in top)
        )
        return await safe_edit(q, txt, reply_markup=_admin_menu_markup(update))

    if data == "trafficmenu":
        txt = (
            "<b>📦 Трафик по периодам</b>\n"
            "<blockquote>Выбери интервал, за который показать суммарный объём трафика.\n"
            "Данные считаются как входящий + исходящий трафик.</blockquote>"
        )
        return await safe_edit(q, txt, reply_markup=traffic_menu())

    if data == "trafficsum":
        now = get_traffic_sum_now(force_refresh=True)
        d24 = get_traffic_sum_period("24h", force_refresh=True)
        d7 = get_traffic_sum_period("7d", force_refresh=True)
        d30 = get_traffic_sum_period("30d", force_refresh=True)
        all_time = get_traffic_sum_total(force_refresh=True)

        txt = (
            "<b>📊 Суммарный трафик по всем нодам</b>\n\n"
            f"🌐 <b>Сейчас:</b> {now:.2f} Mbps\n"
            f"📦 <b>За 24 часа:</b> {_format_gb(d24)}\n"
            f"🗓 <b>За 7 дней:</b> {_format_gb(d7)}\n"
            f"📅 <b>За 30 дней:</b> {_format_gb(d30)}\n"
            f"🧮 <b>За всё время:</b> {_format_gb(all_time)}"
        )
        return await safe_edit(q, txt, reply_markup=traffic_menu())

    if data.startswith("trafficp:"):
        period_key = data.split(":", 1)[1]

        mapping = {
            "24h": ("24h", "📦 Трафик за 24 часа"),
            "7d": ("7d", "🗓 Трафик за 7 дней"),
            "30d": ("30d", "📅 Трафик за 30 дней"),
            "all": ("all", "🧮 Трафик за всё время"),
        }

        if period_key not in mapping:
            return await safe_edit(q, "Неизвестный период", reply_markup=traffic_menu())

        prom_period, title = mapping[period_key]

        if prom_period == "all":
            t = get_traffic_total(force_refresh=True)
            total = get_traffic_sum_total(force_refresh=True)
        else:
            t = get_traffic_period(prom_period, force_refresh=True)
            total = get_traffic_sum_period(prom_period, force_refresh=True)

        if not t:
            return await safe_edit(q, f"<b>{escape(title)}</b>\n\nНет данных", reply_markup=traffic_menu())

        top = sorted(t.items(), key=lambda x: x[1], reverse=True)[:15]
        txt = (
            f"<b>{escape(title)}</b>\n"
            "<blockquote>Суммарный объём входящего и исходящего трафика.</blockquote>\n\n"
            f"📊 <b>Суммарно по всем нодам:</b> {_format_gb(total)}\n\n"
            + "\n".join(f"• {escape(k)}: {_format_gb(v)}" for k, v in top)
        )
        return await safe_edit(q, txt, reply_markup=traffic_menu())

    if data == "summary":
        return await safe_edit(q, make_summary(force_refresh=True), reply_markup=_admin_menu_markup(update))

    if data.startswith("nodes:"):
        page = int(data.split(":")[1])
        inst = sorted(get_up().keys())
        return await safe_edit(q, "<b>🖥 Список нод</b>", reply_markup=nodes_menu(inst, page))

    if data.startswith("nodeidx:"):
        parts = data.split(":")
        idx = int(parts[1])
        page = int(parts[3]) if len(parts) >= 4 else 0

        inst = sorted(get_up().keys())
        if idx < 0 or idx >= len(inst):
            return await safe_edit(q, "Нода не найдена", reply_markup=_admin_menu_markup(update))

        instance = inst[idx]
        s = get_node_snapshot(instance, force_refresh=True)
        up_map = get_up(force_refresh=True)
        node_status_text = render_node_status(instance, s["up"], up_map)

        txt = (
            f"<b>🖥 {escape(instance)}</b>\n\n"
            f"📶 <b>Статус:</b> {escape(node_status_text)}\n"
            f"🔥 <b>CPU:</b> {s['cpu']:.1f}% — текущая загрузка процессора\n"
            f"🧠 <b>RAM:</b> {s['mem']:.1f}% — занято оперативной памяти\n"
            f"💽 <b>Disk /:</b> {s['disk']:.1f}% — заполнение корневого раздела\n"
            f"⬇️ <b>RX:</b> {s['rx_mbps']:.2f} Mbps — входящая скорость сейчас\n"
            f"⬆️ <b>TX:</b> {s['tx_mbps']:.2f} Mbps — исходящая скорость сейчас\n"
            f"📦 <b>RX 24ч:</b> {_format_gb(s['rx_24h'])} — принято за сутки\n"
            f"📤 <b>TX 24ч:</b> {_format_gb(s['tx_24h'])} — отдано за сутки"
        )
        return await safe_edit(q, txt, reply_markup=node_details_menu(page))

    if data.startswith("users:"):
        if not is_admin(update):
            return await q.answer("Только для админа", show_alert=True)

        page = int(data.split(":")[1])
        items, total = users_page(page=page, per_page=8)

        txt = (
            "<b>👥 Пользователи</b>\n\n"
            "<blockquote>Здесь отображаются только новые гости, не входящие в группу админов.</blockquote>\n\n"
            f"Всего гостей: <b>{total}</b>"
        )
        return await safe_edit(q, txt, reply_markup=users_menu(items, page=page, total=total, per_page=8))

    if data.startswith("usercard:"):
        if not is_admin(update):
            return await q.answer("Только для админа", show_alert=True)

        _, user_id, page = data.split(":")
        user = get_user(user_id)

        if not user:
            return await safe_edit(q, "<b>Пользователь не найден</b>", reply_markup=_admin_menu_markup(update))

        return await safe_edit(
            q,
            _format_user_card(user),
            reply_markup=user_card_menu(user_id, page=int(page), blocked=bool(user.get("blocked"))),
        )

    if data.startswith("userblock:"):
        if not is_admin(update):
            return await q.answer("Только для админа", show_alert=True)

        _, user_id, page = data.split(":")
        set_blocked(user_id, True)
        user = get_user(user_id)

        return await safe_edit(
            q,
            _format_user_card(user),
            reply_markup=user_card_menu(user_id, page=int(page), blocked=True),
        )

    if data.startswith("userunblock:"):
        if not is_admin(update):
            return await q.answer("Только для админа", show_alert=True)

        _, user_id, page = data.split(":")
        set_blocked(user_id, False)
        user = get_user(user_id)

        return await safe_edit(
            q,
            _format_user_card(user),
            reply_markup=user_card_menu(user_id, page=int(page), blocked=False),
        )


async def on_error(update, context):
    """update/context: параметры глобального обработчика ошибок python-telegram-bot."""
    log.exception("Unhandled error", exc_info=context.error)
    try:
        if update and update.callback_query:
            await update.callback_query.answer("Ошибка", show_alert=False)
        elif update and update.message:
            await update.message.reply_text("⚠️ Ошибка обработки команды")
    except Exception:
        pass


async def post_init(app):
    """app: экземпляр Application, в который подключаем фонового worker."""
    async def _runner():
        await worker(app)
    app.create_task(_runner())


def main():
    # Токен Telegram-бота от BotFather.
    token = os.getenv("BOT_TOKEN")
    if not token:
        raise SystemExit("В .env не задан BOT_TOKEN")

    app = Application.builder().token(token).post_init(post_init).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("menu", menu))
    app.add_handler(CallbackQueryHandler(buttons))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, quick_buttons))
    app.add_error_handler(on_error)

    log.info("Starting polling...")
    app.run_polling(close_loop=False)


if __name__ == "__main__":
    main()
