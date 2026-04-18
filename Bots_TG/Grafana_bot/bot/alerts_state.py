import json
import os
import time
from threading import Lock

# Корневая папка проекта grafana_bot.
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
# Папка для хранения служебных json-файлов состояния.
DATA_DIR = os.path.join(BASE_DIR, "data")
# Файл со статусами отключения алертов по chat_id.
STATE_FILE = os.path.join(DATA_DIR, "alert_mutes.json")

_lock = Lock()


def _ensure_dir():
    os.makedirs(DATA_DIR, exist_ok=True)


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
    """data: словарь состояний mute по chat_id."""
    _ensure_dir()
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, STATE_FILE)


def set_mute_for_seconds(chat_id: str, seconds: int):
    """
    chat_id: Telegram chat id пользователя.
    seconds: на сколько секунд отключить алерты.
    """
    with _lock:
        data = _load()
        data[str(chat_id)] = {
            "mode": "until",
            "until": int(time.time()) + int(seconds),
        }
        _save(data)


def set_manual_off(chat_id: str):
    """chat_id: Telegram chat id пользователя, которому отключаем алерты до ручного включения."""
    with _lock:
        data = _load()
        data[str(chat_id)] = {
            "mode": "manual_off",
            "until": None,
        }
        _save(data)


def clear_mute(chat_id: str):
    """chat_id: Telegram chat id пользователя, у которого снимаем mute."""
    with _lock:
        data = _load()
        data.pop(str(chat_id), None)
        _save(data)


def get_status(chat_id: str):
    """chat_id: Telegram chat id, для которого возвращается текущий статус уведомлений."""
    with _lock:
        data = _load()
        item = data.get(str(chat_id))

    if not item:
        return {"enabled": True, "mode": "enabled", "until": None}

    mode = item.get("mode")
    until = item.get("until")

    if mode == "manual_off":
        return {"enabled": False, "mode": "manual_off", "until": None}

    if mode == "until":
        if until and int(until) > int(time.time()):
            return {"enabled": False, "mode": "until", "until": int(until)}
        else:
            # срок истёк — чистим
            clear_mute(chat_id)
            return {"enabled": True, "mode": "enabled", "until": None}

    return {"enabled": True, "mode": "enabled", "until": None}


def is_muted(chat_id: str) -> bool:
    """chat_id: Telegram chat id пользователя; True = уведомления отключены."""
    status = get_status(chat_id)
    return not status["enabled"]
