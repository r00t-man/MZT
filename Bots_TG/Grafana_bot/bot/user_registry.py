import json
import os
from datetime import datetime
from threading import Lock

# Корневая папка проекта grafana_bot.
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
# Папка для хранения служебных json-файлов состояния.
DATA_DIR = os.path.join(BASE_DIR, "data")
# Файл с реестром гостей и их статусом блокировки.
STATE_FILE = os.path.join(DATA_DIR, "users_registry.json")

_lock = Lock()


def _ensure_dir():
    os.makedirs(DATA_DIR, exist_ok=True)


def _now_str():
    return datetime.now().strftime("%d.%m.%Y %H:%M:%S")


def _load():
    _ensure_dir()
    if not os.path.exists(STATE_FILE):
        return {}

    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                return data
    except Exception:
        pass

    return {}


def _save(data):
    """data: словарь пользователей, где ключ — user_id."""
    _ensure_dir()
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, STATE_FILE)


def register_guest_user(update, is_admin: bool = False):
    """
    Пишем только не-админов и только из лички.
    """
    chat = update.effective_chat
    user = update.effective_user

    if not chat or not user:
        return

    if chat.type != "private":
        return

    if is_admin:
        return

    uid = str(user.id)

    with _lock:
        data = _load()
        old = data.get(uid, {})

        data[uid] = {
            "user_id": user.id,
            "chat_id": chat.id,
            "username": user.username or "",
            "first_name": user.first_name or "",
            "last_name": user.last_name or "",
            "full_name": " ".join(x for x in [user.first_name, user.last_name] if x).strip(),
            "language_code": getattr(user, "language_code", "") or "",
            "is_bot": bool(getattr(user, "is_bot", False)),
            "first_seen": old.get("first_seen") or _now_str(),
            "last_seen": _now_str(),
            "blocked": bool(old.get("blocked", False)),
        }

        _save(data)


def list_users():
    data = _load()
    items = list(data.values())
    items.sort(key=lambda x: x.get("last_seen", ""), reverse=True)
    return items


def get_user(user_id: str):
    """user_id: id пользователя, которого нужно найти в реестре."""
    data = _load()
    return data.get(str(user_id))


def set_blocked(user_id: str, blocked: bool):
    """
    user_id: id пользователя в реестре.
    blocked: True — заблокировать, False — разблокировать.
    """
    uid = str(user_id)

    with _lock:
        data = _load()
        if uid not in data:
            return False

        data[uid]["blocked"] = bool(blocked)
        data[uid]["last_admin_action"] = _now_str()
        _save(data)
        return True


def is_blocked(user_id: str) -> bool:
    """user_id: id пользователя в реестре."""
    user = get_user(str(user_id))
    if not user:
        return False
    return bool(user.get("blocked", False))


def users_page(page: int = 0, per_page: int = 8):
    """
    page: номер страницы (с 0).
    per_page: количество элементов на страницу.
    """
    items = list_users()
    start = page * per_page
    end = start + per_page
    return items[start:end], len(items)
