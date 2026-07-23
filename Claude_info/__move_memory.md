# Что делать с этим архивом после установки AI DevOps-ассистента

Эта инструкция — для сервера, где уже пройдена официальная установка по
[r00t-man/MZT/Claude_info](https://github.com/r00t-man/MZT/tree/main/Claude_info)
(Claude Code нативно, `/opt/.claude/settings.json`, `/opt/.claude/hooks/guard.sh`,
`/opt/CLAUDE.md`, шаг 4 проверки хука пройден — `guard.sh` реально блокирует).

Пакет знаний (`knowledge-export/`) **не трогает** `settings.json`/`guard.sh` — это отдельный слой
(память + стиль кода + референсные модули), безопасность агента как была настроена MZT-установкой,
так и остаётся.

## 0. Предусловие

`claude --version` работает, `cd /opt && claude` уже запускался хотя бы раз (авторизация пройдена),
`/opt/CLAUDE.md` и `/opt/.claude/hooks/guard.sh` на месте.

## 1. Распаковать архив

```bash
cd /opt
tar xzf knowledge-export.tar.gz     # создаст /opt/knowledge-export/, ничего не перезапишет
```

Папку `/opt/knowledge-export/` после разбора по местам (шаги 2-4) можно оставить как есть —
`code/` и `ponytail/README.md` пригодятся дальше как справочник, ничего страшного, если полежат в `/opt`.

## 2. Подключить память

```bash
mkdir -p /root/.claude/projects/-opt/memory
cp -n /opt/knowledge-export/memory/*.md /root/.claude/projects/-opt/memory/
```

`-n` — не перезаписывает, если файл с таким именем уже есть (актуально, если Claude Code на этом
сервере уже что-то себе туда насохранял). Файл `MEMORY.md` — исключение, это индекс:

```bash
ls /root/.claude/projects/-opt/memory/MEMORY.md 2>/dev/null && echo "уже есть свой MEMORY.md — слить руками" \
  || cp /opt/knowledge-export/memory/MEMORY.md /root/.claude/projects/-opt/memory/MEMORY.md
```

Если свой `MEMORY.md` уже существовал — открой оба файла и вручную добавь строки нашего индекса
(по одной строке на файл, формат `- [Title](file.md) — hook`) в конец своего.

## 3. Вшить Ponytail-правила в устав агента

`/opt/CLAUDE.md` уже существует (устав из `CLAUDE.md.example`, заполненный под твою топологию) —
Ponytail-блок дописывается сверху, ничего не заменяя:

```bash
cat /opt/knowledge-export/ponytail/CLAUDE_ponytail_snippet.md /opt/CLAUDE.md > /tmp/CLAUDE.md.new \
  && mv /tmp/CLAUDE.md.new /opt/CLAUDE.md
```

5 slash-команд:

```bash
mkdir -p /opt/.claude/commands
cp /opt/knowledge-export/ponytail/commands/*.md /opt/.claude/commands/
```

## 4. code/ — не разворачивать вслепую

Это справочные модули (Remnawave/H1cloud клиенты, SSH fleet-обвязка, AI-ассистент-обёртка,
готовый Prometheus-экспортёр), не готовый деплой. Разворачивать по мере необходимости, когда
дело дойдёт до своего бота — сначала вписать свои `RW_API_URL`/`RW_API_TOKEN`/пути в константы
наверху каждого файла. Экспортёр (`code/remna_exporter/`) — единственное, что можно поднять
буквально как есть, только заполнив `config.json`.

## 5. Запуск и первая сессия

```bash
cd /opt && claude
```

Первым сообщением — явно попросить пройти сценарий инициализации (не полагаться на то, что
подходящая память "сама вспомнится" с первого раза):

> Прочитай `/root/.claude/projects/-opt/memory/MEMORY.md`, конкретно
> `onboarding-setup-wizard`, и проведи меня по нему — сверим мою инфраструктуру с описанными
> паттернами и донастроим, чего не хватает.

## 6. Проверка, что всё подключилось

- `/hooks` — `guard.sh` на месте (из MZT-установки, экспорт его не менял).
- Спросить агента: «Что ты знаешь про Remnawave/H1cloud из памяти?» — должен процитировать
  что-то из скопированных файлов (например, про `activeInbounds` только вложенно через
  `configProfile`, или про фейковый CPU/RAM в мониторинге H1cloud).

## 7. Уборка (по желанию)

`knowledge-export.tar.gz` можно удалить после распаковки. Саму папку `knowledge-export/` —
оставить (в ней `code/` и `ponytail/README.md`, к которым может понадобиться вернуться) либо
удалить, если всё нужное уже растащено по местам (шаги 2-4) — тогда она не несёт новой информации.
