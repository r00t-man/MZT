# 🧪 Тестовая статья: основные команды Ubuntu 24

Эта статья создана как тестовый материал для раздела `info` и содержит базовый набор команд, которые полезны при ежедневной работе в **Ubuntu 24.04 LTS**.

---

## 1) Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

- `apt update` — обновляет список доступных пакетов.
- `apt upgrade -y` — устанавливает обновления для уже установленных пакетов.

Полезно дополнительно:

```bash
sudo apt full-upgrade -y
sudo apt autoremove -y
```

---

## 2) Работа с пакетами

Установка пакета:

```bash
sudo apt install htop -y
```

Удаление пакета:

```bash
sudo apt remove htop -y
```

Поиск пакета:

```bash
apt search nginx
```

Информация о пакете:

```bash
apt show nginx
```

---

## 3) Проверка версии и информации о системе

```bash
lsb_release -a
uname -a
hostnamectl
```

- `lsb_release -a` — версия дистрибутива.
- `uname -a` — информация о ядре.
- `hostnamectl` — имя хоста и данные системы.

---

## 4) Файлы и каталоги

```bash
pwd
ls -la
cd /etc
mkdir test-dir
touch test.txt
cp test.txt test-copy.txt
mv test-copy.txt renamed.txt
rm renamed.txt
```

Кратко:
- `pwd` — текущая директория.
- `ls -la` — список файлов с правами.
- `cp`, `mv`, `rm` — копирование, перемещение, удаление.

---

## 5) Просмотр диска и памяти

```bash
df -h
du -sh /var/log/*
free -h
```

- `df -h` — занятость файловых систем.
- `du -sh` — размер каталогов/файлов.
- `free -h` — состояние ОЗУ и swap.

---

## 6) Пользователи и права

```bash
whoami
id
sudo adduser demo
sudo usermod -aG sudo demo
```

Права на файл:

```bash
chmod 644 file.txt
chown user:user file.txt
```

---

## 7) Сеть и диагностика

```bash
ip a
ip r
ping -c 4 8.8.8.8
ss -tulpen
curl -I https://ubuntu.com
```

- `ip a` — сетевые интерфейсы.
- `ip r` — таблица маршрутизации.
- `ss -tulpen` — активные порты и сокеты.

---

## 8) Сервисы systemd

Проверить статус:

```bash
systemctl status ssh
```

Запустить/остановить/перезапустить:

```bash
sudo systemctl start ssh
sudo systemctl stop ssh
sudo systemctl restart ssh
```

Включить автозапуск:

```bash
sudo systemctl enable ssh
sudo systemctl disable ssh
```

---

## 9) Логи

```bash
journalctl -xe
journalctl -u ssh --since "today"
```

Просмотр системного лога в реальном времени:

```bash
sudo tail -f /var/log/syslog
```

---

## 10) Полезные команды для администрирования

```bash
ps aux | grep nginx
top
htop
uptime
history
```

- `ps aux` — список процессов.
- `top` / `htop` — мониторинг ресурсов.
- `history` — история команд.

---

## Мини-чеклист после установки Ubuntu 24

1. Обновить систему (`apt update && apt upgrade`).
2. Установить базовые утилиты: `curl`, `wget`, `htop`, `git`, `ufw`.
3. Проверить доступ по SSH и отключить вход по паролю (если сервер).
4. Настроить файрвол (`ufw`).
5. Проверить логи и автозагрузку сервисов.

---

> 💡 Подсказка: перед потенциально опасными командами (удаление, изменение прав, обновление критичных пакетов) удобно создавать резервные копии конфигов и использовать `tmux`/`screen` при удалённой работе.
