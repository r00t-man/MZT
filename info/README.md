# ℹ️ Раздел Info

В этой папке собраны отдельные тематические статьи и справка по настройкам.

## 📚 Материалы

- 🛣️ [Правила маршрутизации Remna](./Правила%20маршрутизации%20Remna.md)
- ⚖️ [Балансировка remna](./Балансировка%20remna.md)
- 📘 [Базовые команды Ubuntu 24 для подготовки VPN-ноды](./Базовые%20команды%20Ubuntu%2024%20для%20подготовки%20VPN-ноды.md)
- 📊 [Мониторинг Beszel — быстрый старт](./Мониторинг%20Beszel%20—%20быстрый%20старт.md)
- 🔄 [Автоматическая передача файлов между серверами через rsync и SSH](./Автоматическая%20передача%20файлов%20между%20серверами%20через%20rsync%20и%20SSH.md)

---

## 🆕 Новая статья по мониторингу

- 📘 [Grafana Prometheus Setup](../my-wiki/Grafana%20Prometheus%20Setup.md)

**Быстрый старт (центральный сервер):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_grafana_prometheus.sh)"
```

**Быстрый старт (агенты/ноды):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/r00t-man/MZT/main/files/install_node_exporter_agent.sh)"
```
