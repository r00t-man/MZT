from html import escape

from .prometheus import get_summary_snapshot, get_up
from .reserve_logic import render_node_status


def make_summary(force_refresh: bool = False):
    """force_refresh: True — брать свежие данные из Prometheus, игнорируя кэш."""
    data = get_summary_snapshot(force_refresh=force_refresh)

    cpu = data.get("cpu", {})
    mem = data.get("mem", {})
    disk = data.get("disk", {})
    rx = data.get("rx", {})
    tx = data.get("tx", {})

    cpu_top = sorted(cpu.items(), key=lambda x: x[1], reverse=True)[:5]
    mem_top = sorted(mem.items(), key=lambda x: x[1], reverse=True)[:5]
    disk_top = sorted(disk.items(), key=lambda x: x[1], reverse=True)[:5]
    rx_top = sorted(rx.items(), key=lambda x: x[1], reverse=True)[:5]
    tx_top = sorted(tx.items(), key=lambda x: x[1], reverse=True)[:5]

    def lines(title, subtitle, items, suffix, digits=2):
        if not items:
            return (
                f"{title}\n"
                f"<blockquote>{escape(subtitle)}</blockquote>\n"
                f"Нет данных\n"
            )

        body = "\n".join(
            f"• {escape(k)}: {v:.{digits}f}{suffix}" for k, v in items
        )

        return (
            f"{title}\n"
            f"<blockquote>{escape(subtitle)}</blockquote>\n"
            f"{body}\n"
        )

    return (
        "<b>📊 Сводка по нодам</b>\n\n"
        + lines(
            "<b>🔥 CPU</b>",
            "Текущая загрузка процессора. Чем выше значение, тем сильнее нагружена нода.",
            cpu_top,
            "%",
        )
        + "\n"
        + lines(
            "<b>🧠 RAM</b>",
            "Использование оперативной памяти. Показывает, сколько памяти уже занято.",
            mem_top,
            "%",
        )
        + "\n"
        + lines(
            "<b>💽 Disk /</b>",
            "Заполнение корневого раздела /. Чем выше процент, тем меньше свободного места на диске.",
            disk_top,
            "%",
        )
        + "\n"
        + lines(
            "<b>⬇️ RX</b>",
            "Входящий трафик в реальном времени. Это текущая скорость приёма данных нодой.",
            rx_top,
            " Mbps",
        )
        + "\n"
        + lines(
            "<b>⬆️ TX</b>",
            "Исходящий трафик в реальном времени. Это текущая скорость отдачи данных нодой.",
            tx_top,
            " Mbps",
        )
    )


def make_status_text(force_refresh: bool = False):
    """force_refresh: True — брать свежие данные из Prometheus, игнорируя кэш."""
    up = get_up(force_refresh=force_refresh)
    if not up:
        return "<b>📊 Статус нод</b>\n\nНет данных от Prometheus"

    online = []
    offline = []

    for name, state in sorted(up.items()):
        status = render_node_status(name, state, up)

        if status == "🔋 Онлайн":
            online.append(f"🔋 {escape(name)}")
        else:
            offline.append(f"🪫 {escape(name)}")

    total = len(online) + len(offline)
    text = "<b>📊 Статус нод</b>\n\n"
    text += f"📦 Всего нод: <b>{total}</b>\n"
    text += f"🔋 Онлайн: <b>{len(online)}</b>\n"
    text += f"🪫 Оффлайн: <b>{len(offline)}</b>\n\n"

    if online:
        text += "<b>Онлайн:</b>\n" + "\n".join(online) + "\n\n"
    if offline:
        text += "<b>Оффлайн:</b>\n" + "\n".join(offline)

    return text.strip()
