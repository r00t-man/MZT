import os

from .user_registry import is_blocked as registry_is_blocked


def parse_ids(val):
    """val: строка вида '123,456,789'."""
    # Преобразует строку id через запятую в set[int] (только числа).
    return set(int(x.strip()) for x in val.split(",") if x.strip().isdigit())


# ID чатов/групп, в которых разрешено управление ботом.
CONTROL_CHAT_IDS = parse_ids(os.getenv("CONTROL_CHAT_IDS", ""))
# ID администраторов бота.
ADMIN_IDS = parse_ids(os.getenv("ADMIN_IDS", ""))
# Белый список пользователей (если пусто — доступ всем, кроме заблокированных).
USER_IDS = parse_ids(os.getenv("USER_IDS", ""))


def is_admin(update):
    """update: объект Telegram Update."""
    return bool(update.effective_user and update.effective_user.id in ADMIN_IDS)


def is_blocked(update):
    """update: объект Telegram Update."""
    user = update.effective_user
    if not user:
        return False

    if user.id in ADMIN_IDS:
        return False

    return registry_is_blocked(str(user.id))


def is_user(update):
    """update: объект Telegram Update."""
    if not update.effective_user:
        return False

    if is_blocked(update):
        return False

    # если USER_IDS пуст — всем можно
    if not USER_IDS:
        return True

    return update.effective_user.id in USER_IDS or is_admin(update)


def is_control_chat(update):
    """update: объект Telegram Update."""
    chat = update.effective_chat
    user = update.effective_user

    if not chat:
        return False

    # разрешённые группы / супергруппы / каналы
    if chat.id in CONTROL_CHAT_IDS:
        return True

    # личка — разрешена всем, если не блок
    if chat.type == "private" and user:
        if is_blocked(update):
            return False
        return True

    return False
