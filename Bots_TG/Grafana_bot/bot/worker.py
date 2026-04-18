import asyncio
import os
import time
import logging

from telegram.error import BadRequest, Forbidden
from .prometheus import get_summary_snapshot
from .alerts_state import is_muted

log = logging.getLogger("grafana-bot.worker")


def parse_ids(val: str):
    # Разбирает строку chat_id через запятую в список id получателей алертов.
    return [x.strip() for x in val.split(",") if x.strip()]


# Chat ID получателей алертов (через запятую в .env).
ALERT_CHAT_IDS = parse_ids(os.getenv("ALERT_CHAT_IDS", ""))
# Интервал опроса Prometheus в секундах.
POLL_SECONDS = int(os.getenv("POLL_SECONDS", "30"))
# Время в секундах, через которое считать сервер офлайн.
DOWN_CONFIRM_SECONDS = int(os.getenv("DOWN_CONFIRM_SECONDS", "360"))
# Время в секундах, через которое подтверждаем восстановление сервера.
UP_CONFIRM_SECONDS = int(os.getenv("UP_CONFIRM_SECONDS", "15"))
# Порог заполнения диска в процентах для отправки предупреждения.
DISK_ALERT_PCT = float(os.getenv("DISK_ALERT_PCT", "90"))


async def safe_send(app, text: str):
    """
    app: экземпляр Telegram Application.
    text: текст алерта для отправки в ALERT_CHAT_IDS.
    """
    if not ALERT_CHAT_IDS:
        return 0

    sent_count = 0

    for chat_id in ALERT_CHAT_IDS:
        if is_muted(chat_id):
            log.info("Алерты для chat_id=%s временно отключены пользователем", chat_id)
            continue

        try:
            await app.bot.send_message(chat_id=chat_id, text=text)
            sent_count += 1
        except (BadRequest, Forbidden) as e:
            log.error("Не могу отправить алерт в chat_id=%s: %s", chat_id, e)
        except Exception:
            log.exception("Ошибка отправки алерта в chat_id=%s", chat_id)

    return sent_count


async def worker(app):
    """app: экземпляр Telegram Application, который используется для фоновой рассылки алертов."""
    if not ALERT_CHAT_IDS:
        log.warning("ALERT_CHAT_IDS не задан, алерты отключены")
        return

    prev_health = {}
    down_since = {}
    up_since = {}
    offline_sent = set()
    disk_alert_state = set()

    while True:
        try:
            snap = get_summary_snapshot(force_refresh=True)
            up = snap.get("up", {})
            disk = snap.get("disk", {})
            now = time.monotonic()

            for inst, state in up.items():
                old = prev_health.get(inst)

                if old is None:
                    prev_health[inst] = state
                    if state < 1:
                        down_since[inst] = now
                    continue

                if state < 1:
                    down_since.setdefault(inst, now)
                    up_since.pop(inst, None)

                    if inst not in offline_sent and now - down_since[inst] >= DOWN_CONFIRM_SECONDS:
                        sent = await safe_send(app, f"🪫 {inst} DOWN")
                        if sent > 0:
                            offline_sent.add(inst)

                else:
                    down_since.pop(inst, None)

                    if inst in offline_sent:
                        up_since.setdefault(inst, now)
                        if now - up_since[inst] >= UP_CONFIRM_SECONDS:
                            sent = await safe_send(app, f"🔋 {inst} UP")
                            if sent > 0:
                                offline_sent.remove(inst)
                            up_since.pop(inst, None)
                    else:
                        up_since.pop(inst, None)

                prev_health[inst] = state

            bad_now = {inst for inst, pct in disk.items() if pct >= DISK_ALERT_PCT}
            new_bad = bad_now - disk_alert_state

            if new_bad:
                lines = [f"• {inst}: {disk[inst]:.0f}%" for inst in sorted(new_bad)]
                await safe_send(app, "💽 Диск заполнен выше порога\n\n" + "\n".join(lines))

            disk_alert_state = bad_now

        except Exception:
            log.exception("worker error")

        await asyncio.sleep(POLL_SECONDS)
