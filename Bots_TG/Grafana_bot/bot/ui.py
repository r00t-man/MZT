from telegram import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    KeyboardButton,
    ReplyKeyboardMarkup,
)


def persistent_menu_keyboard():
    return ReplyKeyboardMarkup(
        [
            [KeyboardButton("🏠 Меню")],
            [KeyboardButton("📊 Статус"), KeyboardButton("🔕 Алерты")],
        ],
        resize_keyboard=True,
        one_time_keyboard=False,
        selective=False,
    )


def main_menu(show_admin: bool = False):
    """show_admin: True — показать админский пункт 'Пользователи'."""
    rows = [
        [
            InlineKeyboardButton("📊 Статус", callback_data="status"),
            InlineKeyboardButton("📈 Трафик сейчас", callback_data="traffic"),
        ],
        [
            InlineKeyboardButton("🧾 Сводка", callback_data="summary"),
            InlineKeyboardButton("🖥 Ноды", callback_data="nodes:0"),
        ],
        [
            InlineKeyboardButton("📦 Трафик периоды", callback_data="trafficmenu"),
        ],
        [
            InlineKeyboardButton("🔕 Алерты", callback_data="alerts_menu"),
        ],
    ]

    if show_admin:
        rows.append([InlineKeyboardButton("👥 Пользователи", callback_data="users:0")])

    rows.append([InlineKeyboardButton("🔄 Обновить", callback_data="refresh")])

    return InlineKeyboardMarkup(rows)


def traffic_menu():
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("📦 24 часа", callback_data="trafficp:24h"),
            InlineKeyboardButton("🗓 7 дней", callback_data="trafficp:7d"),
        ],
        [
            InlineKeyboardButton("📅 30 дней", callback_data="trafficp:30d"),
            InlineKeyboardButton("🧮 Всё время", callback_data="trafficp:all"),
        ],
        [
            InlineKeyboardButton("📊 Сумма по всем нодам", callback_data="trafficsum"),
        ],
        [
            InlineKeyboardButton("⬅️ В меню", callback_data="menu"),
        ],
    ])


def alerts_menu():
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("🔕 На 1 день", callback_data="alerts_mute:1d"),
            InlineKeyboardButton("🗓 На 7 дней", callback_data="alerts_mute:7d"),
        ],
        [
            InlineKeyboardButton("📅 На 30 дней", callback_data="alerts_mute:30d"),
            InlineKeyboardButton("⛔ До включения", callback_data="alerts_mute:manual"),
        ],
        [
            InlineKeyboardButton("🔔 Включить обратно", callback_data="alerts_unmute"),
        ],
        [
            InlineKeyboardButton("📋 Мой статус", callback_data="alerts_status"),
        ],
        [
            InlineKeyboardButton("⬅️ В меню", callback_data="menu"),
        ],
    ])


def nodes_menu(instances, page=0, per_page=8):
    """
    instances: список имён нод.
    page: номер страницы (с 0).
    per_page: сколько нод показывать на одной странице.
    """
    start = page * per_page
    chunk = instances[start:start + per_page]

    rows = []
    row = []

    for idx, name in enumerate(chunk, start=start):
        row.append(InlineKeyboardButton(name, callback_data=f"nodeidx:{idx}:page:{page}"))
        if len(row) == 2:
            rows.append(row)
            row = []

    if row:
        rows.append(row)

    nav = []
    if page > 0:
        nav.append(InlineKeyboardButton("⬅️", callback_data=f"nodes:{page-1}"))
    if start + per_page < len(instances):
        nav.append(InlineKeyboardButton("➡️", callback_data=f"nodes:{page+1}"))

    if nav:
        rows.append(nav)

    rows.append([InlineKeyboardButton("⬅️ В меню", callback_data="menu")])
    return InlineKeyboardMarkup(rows)


def node_details_menu(page=0):
    # page: страница списка нод, куда вернётся кнопка "К списку нод".
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("⬅️ К списку нод", callback_data=f"nodes:{page}")],
        [InlineKeyboardButton("🏠 В меню", callback_data="menu")],
    ])


def users_menu(users, page=0, total=0, per_page=8):
    """
    users: элементы текущей страницы пользователей.
    page: номер страницы (с 0).
    total: общее количество пользователей.
    per_page: размер страницы.
    """
    rows = []

    for user in users:
        label = user.get("full_name") or user.get("username") or str(user.get("user_id"))
        prefix = "⛔" if user.get("blocked") else "👤"
        rows.append([
            InlineKeyboardButton(
                f"{prefix} {label[:40]}",
                callback_data=f"usercard:{user['user_id']}:{page}",
            )
        ])

    nav = []
    if page > 0:
        nav.append(InlineKeyboardButton("⬅️", callback_data=f"users:{page-1}"))
    if (page + 1) * per_page < total:
        nav.append(InlineKeyboardButton("➡️", callback_data=f"users:{page+1}"))

    if nav:
        rows.append(nav)

    rows.append([InlineKeyboardButton("⬅️ В меню", callback_data="menu")])
    return InlineKeyboardMarkup(rows)


def user_card_menu(user_id, page=0, blocked=False):
    """
    user_id: id пользователя для callback-кнопок.
    page: страница списка пользователей для возврата назад.
    blocked: текущий статус блокировки пользователя.
    """
    rows = []

    if blocked:
        rows.append([InlineKeyboardButton("✅ Разблокировать", callback_data=f"userunblock:{user_id}:{page}")])
    else:
        rows.append([InlineKeyboardButton("⛔ Заблокировать", callback_data=f"userblock:{user_id}:{page}")])

    rows.append([InlineKeyboardButton("⬅️ К списку", callback_data=f"users:{page}")])
    rows.append([InlineKeyboardButton("🏠 В меню", callback_data="menu")])

    return InlineKeyboardMarkup(rows)
