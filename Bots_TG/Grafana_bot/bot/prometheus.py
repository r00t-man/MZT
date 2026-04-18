import os
import re
import time
import requests
import urllib3

# URL Prometheus (например: http://127.0.0.1:9090).
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "").rstrip("/")
# Логин для Basic Auth (если включена авторизация).
PROMETHEUS_USER = os.getenv("PROMETHEUS_USER", "")
# Пароль для Basic Auth.
PROMETHEUS_PASS = os.getenv("PROMETHEUS_PASS", "")
# Проверять ли SSL-сертификат при HTTPS-запросах к Prometheus.
PROMETHEUS_VERIFY_SSL = os.getenv("PROMETHEUS_VERIFY_SSL", "true").strip().lower() in (
    "1", "true", "yes", "on"
)

# Имя job в Prometheus, по которому фильтруются ноды.
JOB = os.getenv("JOB_FILTER", "nodes")
# Таймаут HTTP-запроса к Prometheus в секундах.
HTTP_TIMEOUT = int(os.getenv("HTTP_TIMEOUT", "10"))
# TTL кэша ответов Prometheus в секундах.
CACHE_TTL = int(os.getenv("PROM_CACHE_TTL", "10"))

if not PROMETHEUS_URL.startswith(("http://", "https://")):
    raise RuntimeError(
        f"Некорректный PROMETHEUS_URL={PROMETHEUS_URL!r}. "
        f"Пример: http://127.0.0.1:9090 или https://prometheus.example.com"
    )

if not PROMETHEUS_VERIFY_SSL:
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

_session = requests.Session()
_cache = {}

FLAG_MAP = {
    "estonia": "🇪🇪",
    "finland": "🇫🇮",
    "france": "🇫🇷",
    "germany": "🇩🇪",
    "hong kong": "🇭🇰",
    "latvia": "🇱🇻",
    "moscow": "🇷🇺",
    "russia": "🇷🇺",
    "netherlands": "🇳🇱",
    "poland": "🇵🇱",
    "sweden": "🇸🇪",
    "yandex": "🇷🇺",
    "adguard": "🛡️",
}

LEADING_FLAG_RE = re.compile(
    r"^(?:[\U0001F1E6-\U0001F1FF]{2}|🛡️|🛡)\s+"
)


def _display_instance(raw_name: str) -> str:
    name = str(raw_name or "").strip()
    lower = name.lower()

    for key, flag in FLAG_MAP.items():
        if lower.startswith(key):
            return f"{flag} {name}"

    return name


def _raw_instance(display_name: str) -> str:
    name = str(display_name or "").replace("\u200b", "").strip()
    name = LEADING_FLAG_RE.sub("", name).strip()
    return name


def _cache_get(key):
    """key: ключ кэша для конкретного запроса."""
    item = _cache.get(key)
    if not item:
        return None

    ts, value = item
    if time.monotonic() - ts > CACHE_TTL:
        _cache.pop(key, None)
        return None

    return value


def _cache_set(key, value):
    """key: ключ кэша; value: данные ответа Prometheus."""
    _cache[key] = (time.monotonic(), value)
    return value


def _auth():
    if PROMETHEUS_USER or PROMETHEUS_PASS:
        return (PROMETHEUS_USER, PROMETHEUS_PASS)
    return None


def query(q: str, force_refresh: bool = False):
    """
    q: PromQL-запрос.
    force_refresh: True — игнорировать кэш и сходить в Prometheus напрямую.
    """
    key = f"query:{q}"

    if not force_refresh:
        cached = _cache_get(key)
        if cached is not None:
            return cached

    r = _session.get(
        f"{PROMETHEUS_URL}/api/v1/query",
        params={"query": q},
        timeout=HTTP_TIMEOUT,
        auth=_auth(),
        verify=PROMETHEUS_VERIFY_SSL,
    )
    r.raise_for_status()

    data = r.json()
    if data.get("status") != "success":
        raise RuntimeError(f"Prometheus query failed: {data}")

    return _cache_set(key, data["data"]["result"])


def result_map(result):
    out = {}
    for x in result:
        raw_inst = x.get("metric", {}).get("instance", "unknown")
        display_inst = _display_instance(raw_inst)

        try:
            out[display_inst] = float(x["value"][1])
        except Exception:
            out[display_inst] = 0.0
    return out


def result_single_value(result):
    if not result:
        return 0.0
    try:
        return float(result[0]["value"][1])
    except Exception:
        return 0.0


def _escape(val: str) -> str:
    return str(val).replace("\\", "\\\\").replace('"', '\\"')


def _q_up():
    return f'up{{job="{JOB}"}}'


def _q_cpu(instance=None):
    """instance: instance ноды (опционально, если нужно запросить только одну ноду)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'100 - (avg by (instance) '
        f'(irate(node_cpu_seconds_total{{job="{JOB}"{flt},mode="idle"}}[5m])) * 100)'
    )


def _q_mem(instance=None):
    """instance: instance ноды (опционально, если нужно запросить только одну ноду)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'100 - (node_memory_MemAvailable_bytes{{job="{JOB}"{flt}}} '
        f'/ node_memory_MemTotal_bytes{{job="{JOB}"{flt}}} * 100)'
    )


def _q_disk(instance=None):
    """instance: instance ноды (опционально, если нужно запросить только одну ноду)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'100 - (node_filesystem_avail_bytes{{job="{JOB}"{flt},mountpoint="/",fstype!~"tmpfs|devtmpfs"}} '
        f'/ node_filesystem_size_bytes{{job="{JOB}"{flt},mountpoint="/",fstype!~"tmpfs|devtmpfs"}} * 100)'
    )


def _q_rx(instance=None):
    """instance: instance ноды (опционально, если нужно запросить только одну ноду)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(rate(node_network_receive_bytes_total{{job="{JOB}"{flt},device!~"lo"}}[5m])) * 8 / 1000000'
    )


def _q_tx(instance=None):
    """instance: instance ноды (опционально, если нужно запросить только одну ноду)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(rate(node_network_transmit_bytes_total{{job="{JOB}"{flt},device!~"lo"}}[5m])) * 8 / 1000000'
    )


def _q_period_rx(period: str, instance=None):
    """
    period: интервал Prometheus (например 24h, 7d).
    instance: instance ноды (опционально).
    """
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(increase(node_network_receive_bytes_total{{job="{JOB}"{flt},device!~"lo"}}[{period}]))'
    )


def _q_period_tx(period: str, instance=None):
    """
    period: интервал Prometheus (например 24h, 7d).
    instance: instance ноды (опционально).
    """
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(increase(node_network_transmit_bytes_total{{job="{JOB}"{flt},device!~"lo"}}[{period}]))'
    )


def _q_total_rx(instance=None):
    """instance: instance ноды (опционально)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(node_network_receive_bytes_total{{job="{JOB}"{flt},device!~"lo"}})'
    )


def _q_total_tx(instance=None):
    """instance: instance ноды (опционально)."""
    if instance:
        instance = _raw_instance(instance)
    flt = f',instance="{_escape(instance)}"' if instance else ""
    return (
        f'sum by (instance) '
        f'(node_network_transmit_bytes_total{{job="{JOB}"{flt},device!~"lo"}})'
    )


def get_up(force_refresh: bool = False):
    return result_map(query(_q_up(), force_refresh=force_refresh))


def get_cpu(force_refresh: bool = False):
    return result_map(query(_q_cpu(), force_refresh=force_refresh))


def get_mem(force_refresh: bool = False):
    return result_map(query(_q_mem(), force_refresh=force_refresh))


def get_disk(force_refresh: bool = False):
    return result_map(query(_q_disk(), force_refresh=force_refresh))


def get_traffic(force_refresh: bool = False):
    rx = result_map(query(_q_rx(), force_refresh=force_refresh))
    tx = result_map(query(_q_tx(), force_refresh=force_refresh))

    out = {}
    for k in set(rx) | set(tx):
        out[k] = rx.get(k, 0.0) + tx.get(k, 0.0)
    return out


def get_traffic_rx(force_refresh: bool = False):
    return result_map(query(_q_rx(), force_refresh=force_refresh))


def get_traffic_tx(force_refresh: bool = False):
    return result_map(query(_q_tx(), force_refresh=force_refresh))


def get_traffic_period(period: str, force_refresh: bool = False):
    """
    period: интервал Prometheus (например 24h, 7d).
    force_refresh: True — не использовать кэш.
    """
    rx = result_map(query(_q_period_rx(period), force_refresh=force_refresh))
    tx = result_map(query(_q_period_tx(period), force_refresh=force_refresh))

    out = {}
    for k in set(rx) | set(tx):
        out[k] = rx.get(k, 0.0) + tx.get(k, 0.0)
    return out


def get_traffic_total(force_refresh: bool = False):
    rx = result_map(query(_q_total_rx(), force_refresh=force_refresh))
    tx = result_map(query(_q_total_tx(), force_refresh=force_refresh))

    out = {}
    for k in set(rx) | set(tx):
        out[k] = rx.get(k, 0.0) + tx.get(k, 0.0)
    return out


def get_traffic_sum_now(force_refresh: bool = False):
    q = (
        f'sum(rate(node_network_receive_bytes_total{{job="{JOB}",device!~"lo"}}[5m])) * 8 / 1000000 + '
        f'sum(rate(node_network_transmit_bytes_total{{job="{JOB}",device!~"lo"}}[5m])) * 8 / 1000000'
    )
    return result_single_value(query(q, force_refresh=force_refresh))


def get_traffic_sum_period(period: str, force_refresh: bool = False):
    """
    period: интервал Prometheus (например 24h, 7d).
    force_refresh: True — не использовать кэш.
    """
    q = (
        f'sum(increase(node_network_receive_bytes_total{{job="{JOB}",device!~"lo"}}[{period}])) + '
        f'sum(increase(node_network_transmit_bytes_total{{job="{JOB}",device!~"lo"}}[{period}]))'
    )
    return result_single_value(query(q, force_refresh=force_refresh))


def get_traffic_sum_total(force_refresh: bool = False):
    q = (
        f'sum(node_network_receive_bytes_total{{job="{JOB}",device!~"lo"}}) + '
        f'sum(node_network_transmit_bytes_total{{job="{JOB}",device!~"lo"}})'
    )
    return result_single_value(query(q, force_refresh=force_refresh))


def get_summary_snapshot(force_refresh: bool = False):
    return {
        "up": get_up(force_refresh=force_refresh),
        "cpu": get_cpu(force_refresh=force_refresh),
        "mem": get_mem(force_refresh=force_refresh),
        "disk": get_disk(force_refresh=force_refresh),
        "rx": get_traffic_rx(force_refresh=force_refresh),
        "tx": get_traffic_tx(force_refresh=force_refresh),
    }


def get_node_snapshot(instance: str, force_refresh: bool = False):
    """
    instance: имя ноды, которую нужно детально запросить.
    force_refresh: True — не использовать кэш.
    """
    raw_instance = _raw_instance(instance)

    def one(q):
        raw_result = query(q, force_refresh=force_refresh)
        mapped = {}
        for x in raw_result:
            inst = x.get("metric", {}).get("instance", "unknown")
            try:
                mapped[inst] = float(x["value"][1])
            except Exception:
                mapped[inst] = 0.0
        return mapped.get(raw_instance, 0.0)

    escaped_instance = _escape(raw_instance)

    return {
        "up": one(f'up{{job="{JOB}",instance="{escaped_instance}"}}'),
        "cpu": one(_q_cpu(raw_instance)),
        "mem": one(_q_mem(raw_instance)),
        "disk": one(_q_disk(raw_instance)),
        "rx_mbps": one(_q_rx(raw_instance)),
        "tx_mbps": one(_q_tx(raw_instance)),
        "rx_24h": one(_q_period_rx("24h", raw_instance)),
        "tx_24h": one(_q_period_tx("24h", raw_instance)),
    }
