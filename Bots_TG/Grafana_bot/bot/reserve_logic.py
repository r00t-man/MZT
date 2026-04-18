def is_reserve_node(node_name: str, up_map: dict[str, float]) -> bool:
    """Логика резерва отключена: всегда возвращаем False."""
    _ = (node_name, up_map)
    return False


def render_node_status(node_name: str, up_value: float, up_map: dict[str, float]) -> str:
    """
    node_name: имя ноды.
    up_value: текущее значение up для ноды.
    up_map: общая карта up по всем нодам для определения резерва.
    """
    if up_value >= 1:
        return "🔋 Онлайн"

    return "🪫 Оффлайн"
