# Ограничьте автономные запуски

<sub>**Продвинутый** · Урок 7 из 7 · около 20 минут плюс время выполнения · Требуется: [Скриптование Claude Code с помощью `claude -p`](04-headless.md), [Поделитесь своей настройкой с командой](06-share-your-setup.md) · Проверено на Claude Code v2.1.292 (stable) 15.10.2026</sub>

## Цель

К концу этого урока вы сможете ограничить автоматический запуск `claude -p` с помощью принципа наименьших привилегий, песочницы, лимитов ходов и расходов, контрольного этапа проверки и оценки стоимости.

## Вам понадобится

- Репозиторий, который вы скриптовали в [уроке 4](04-headless.md) и которым поделились в [уроке 6](06-share-your-setup.md), с тестовой командой, и ваша копия шаблона практики с Node.js LTS и продвинутыми проверками ([Практика](README.md#practice)): проверка запускается из копии. Настройте папку `.practice/` репозитория, как описано в [уроке 1 для начинающих](../beginner/01-install-and-look-around.md#you-need), если ещё не сделали этого.
- bash и `jq` на macOS, Linux или WSL 2. На Linux и WSL 2 песочнице нужны `bubblewrap` и `socat` ([Настройка Linux и WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)).
- Использование: умеренное. Каждый запуск останавливается на своих лимитах. Дешёвый вариант: в разделе «Ваша очередь» установите лимиты из запуска на срезе и запустите скрипт ещё на одном срезе вместо всей задачи.

## Идея

Запуск, за которым никто не следит, делает всё, что вы разрешили заранее, поэтому разрешайте мало, а остальное ограничивайте:

- **Наименьшие привилегии.** Режим `dontAsk` запрещает каждый вызов, который иначе вызвал бы запрос ([режим dontAsk](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)), поэтому разрешайте только папки, которые задача редактирует, и одну команду, которую она запускает.
- **Песочница.** Операционная система ограничивает, куда разрешённая команда может писать и к чему обращаться ([Настройка песочницы для инструмента Bash](https://code.claude.com/docs/en/sandboxing)). Сделайте её строгой и обязательной для запуска.
- **Лимиты.** `--max-turns` ограничивает агентные ходы, а `--max-budget-usd` — предполагаемые расходы ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)).
- **Контрольный этап проверки.** Запретите `git commit` и `git push`: правила запрета действуют во всех режимах ([Доступные режимы](https://code.claude.com/docs/en/permission-modes#available-modes)). `dontAsk` отклоняет формы, которые правило не покрывает, например `git -C . push`, при этом ничто их не разрешает ([Что не покрывает правило Bash](https://code.claude.com/docs/en/permissions#bash-rule-limits)). Вы читаете diff и коммитите то, что принимаете.
- **Оценка стоимости.** Сначала запустите один срез и установите лимит расходов на основе его стоимости.

## Рабочий пример

Работайте в своём репозитории. Папки `src/` и `test/` и команда `npm test` обозначают ваши собственные: замените их на свои во всех местах ниже.

1. Сохраните ограничения как `.claude/bounded-run.json`:

   ```json
   {
     "permissions": {
       "allow": ["Edit(./src/**)", "Edit(./test/**)", "Bash(npm test *)"],
       "deny": ["Agent", "Read(./.env)", "Read(./.env.*)", "Bash(git commit *)", "Bash(git push *)"]
     },
     "sandbox": {
       "enabled": true,
       "failIfUnavailable": true,
       "allowUnsandboxedCommands": false,
       "autoAllowBashIfSandboxed": false
     }
   }
   ```

   - `allow`: редактирование в двух папках и `npm test` с любыми аргументами. Правила `Edit` покрывают все встроенные инструменты, редактирующие файлы, а путь `./` начинается с папки, из которой запускается процесс ([Чтение и редактирование](https://code.claude.com/docs/en/permissions#read-and-edit)).
   - `deny`: файлы `.env`; `git commit` и `git push`, где завершающий ` *` также соответствует команде без аргументов ([Шаблоны с подстановочными знаками](https://code.claude.com/docs/en/permissions#wildcard-patterns)); и инструмент `Agent`, чтобы Claude не мог передать работу субагенту ([Встроенные субагенты](https://code.claude.com/docs/en/sub-agents#built-in-subagents)), который может работать в собственном режиме разрешений ([Режимы разрешений](https://code.claude.com/docs/en/sub-agents#permission-modes)).
   - `sandbox`: включена; выход при запуске, если она не может запуститься ([`sandbox.failIfUnavailable`](https://code.claude.com/docs/en/settings-reference#sandbox-failifunavailable)); никогда не повторять команду вне её ([Строгий режим песочницы](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)); и отправлять команды из песочницы через ваши правила и режим, а не одобрять их все ([`sandbox.autoAllowBashIfSandboxed`](https://code.claude.com/docs/en/settings-reference#sandbox-autoallowbashifsandboxed)).

   Файловые инструменты Claude не могут изменить этот файл во время запуска: в режиме `dontAsk` запись в защищённую папку `.claude/` запрещена, и правила allow это не меняют ([Защищённые пути](https://code.claude.com/docs/en/permission-modes#protected-paths)).
2. Сохраните скрипт запуска как `scripts/bounded-run.sh`:

   ```bash
   #!/bin/bash
   # Runs one unattended task inside the bounds in .claude/bounded-run.json.
   set -u
   if [ $# -ne 2 ]; then
     echo 'Usage: scripts/bounded-run.sh "<task>" <result.json>' >&2
     exit 2
   fi
   before=$(git rev-parse --short HEAD)
   claude -p "$1" \
     --setting-sources project \
     --settings .claude/bounded-run.json \
     --permission-mode dontAsk \
     --model sonnet \
     --max-turns 15 \
     --max-budget-usd 2 \
     --output-format json > "$2"
   status=$?
   jq '{subtype, num_turns, total_cost_usd, denied: [.permission_denials[]? | .tool_input.command // .tool_name]}' "$2"
   echo "HEAD before: $before, after: $(git rev-parse --short HEAD)"
   git status --short
   exit "$status"
   ```

   - `--setting-sources project`: исключает ваши пользовательские и локальные файлы настроек из запуска ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)), чтобы правило allow, сохранённое с «Да, и больше не спрашивать», которое попадает в `.claude/settings.local.json`, не присоединялось к ограничениям ([Система разрешений](https://code.claude.com/docs/en/permissions#permission-system)).
   - `--settings`: файл ограничений, который Claude Code применяет поверх собственных настроек проекта ([Изменение настройки для одной сессии](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)). Правила allow помещаются туда, потому что запуск `-p` игнорирует правила allow в `.claude/settings.json` папки, которой ещё не доверяют ([Что выполняется до доверия папке](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)).
   - `allowUnsandboxedCommands: false` в этом файле: поскольку он берётся из `--settings`, `true` проекта не может снова включить повтор без песочницы ([Строгий режим песочницы](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)). В v2.1.285 или новее Claude Code также игнорирует настройки репозитория, ослабляющие песочницу, например `excludedCommands` ([Настройки репозитория при обязательной песочнице администратора](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)).
   - `--model sonnet`: Sonnet хорошо справляется с большинством задач кодирования и стоит дешевле, чем Opus ([Выбор подходящей модели](https://code.claude.com/docs/en/costs#choose-the-right-model)).
   - `--max-turns` и `--max-budget-usd`: это конфигурация, поэтому задайте свои значения.
3. Сделайте его исполняемым и закоммитьте оба файла, чтобы все, кто его запускает, получали одинаковые ограничения:

   ```bash
   chmod +x scripts/bounded-run.sh
   git add scripts/bounded-run.sh .claude/bounded-run.json
   git commit -m "Add a bounded runner for unattended tasks"
   ```

   Если git сообщает, что путь игнорируется, `git check-ignore -v <path>` покажет правило, которое его игнорирует; добавьте путь с помощью `git add -f`.
4. Посмотрите, как лимит останавливает запуск. Задайте тем же ограничениям крошечный лимит расходов:

   ```bash
   claude -p "Run npm test and summarize the result" \
     --setting-sources project --settings .claude/bounded-run.json \
     --permission-mode dontAsk --model sonnet \
     --max-budget-usd 0.01 --output-format json > .practice/a-7-capped.json
   echo "exit $?"
   jq '{subtype, total_cost_usd}' .practice/a-7-capped.json
   ```

   Он выводит ненулевой код выхода, затем `"subtype": "error_max_budget_usd"`: запуск остановился на лимите, и JSON всё равно это фиксирует ([Обработка результата](https://code.claude.com/docs/en/agent-sdk/agent-loop#handle-the-result)). `total_cost_usd` может быть выше лимита, потому что включает ответ, который его превысил ([Отслеживание затрат при неудачных разговорах](https://code.claude.com/docs/en/agent-sdk/cost-tracking#track-costs-on-failed-conversations)).
5. Оцените стоимость на срезе — небольшой части более крупной задачи:

   ```bash
   scripts/bounded-run.sh "Use your Edit tool to add a test for one untested function in src/<file>. Then run npm test as a command on its own, and then commit the test." .practice/a-7-slice.json
   ```

   В сводке отображается `"subtype": "success"`, использованные ходы, `total_cost_usd`, а под `denied` — каждый вызов, который ваши ограничения отклонили, например `git commit`; ваш список будет другим. HEAD одинаков до и после, а `git status` показывает новый тест, незакоммиченный. Ваш вывод будет отличаться. `total_cost_usd` — это оценка на стороне клиента, а не ваш счёт ([Отслеживание затрат и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking#estimates-not-billing)); на тарифном плане Claude `/usage` в сессии показывает лимиты использования вашего плана ([Команды](https://code.claude.com/docs/en/commands#all-commands)). Чтобы ограничить всю задачу, увеличьте показатель среза и установите лимит расходов выше него с запасом.
6. Будьте контрольным этапом проверки. Прочитайте каждое изменение с помощью `git status` и `git diff`, включая файл ограничений, запустите `npm test` самостоятельно и закоммитьте только то, что принимаете. Для второго мнения запустите `claude` и попросите субагента просмотреть diff в свежем контексте и сообщить о пробелах ([Добавление шага состязательной проверки](https://code.claude.com/docs/en/best-practices#add-an-adversarial-review-step)).

## Ваша очередь

Ограничьте реальную задачу в вашем репозитории, которая больше одного среза, например тесты для каждой непротестированной функции в одной папке.

Критерии приёмки:

- `scripts/bounded-run.sh "<task>" <result.json>` запускает её: один вызов `claude -p` в режиме `dontAsk`, с выводом JSON, сохранённым в путь результата, и ограничениями из закоммиченного файла, переданного через `--settings`.
- Он вызывает `claude` по имени, а не по пути или через `npx`, и не меняет `PATH`: именно так проверка подменяет его заглушкой.
- Каждое правило allow называет одну папку или одну команду: никаких голых `Bash` или `Edit`, и никаких правил для всего проекта или целой программы, например `Bash(npm *)`. Ваш закоммиченный `.claude/settings.json` тоже учитывается: в папке, которой вы доверяете, его правила allow присоединяются к правилам файла ограничений ([Списки объединяются, а не переопределяются](https://code.claude.com/docs/en/settings#lists-merge-instead-of-overriding)). То же касается `allowed-tools` навыков репозитория в запуске, который их вызывает ([Предварительное одобрение инструментов для навыка](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)).
- Правила deny останавливают `git commit` и `git push`, каждое с завершающим ` *`: `Bash(git push)` соответствует только команде без аргументов.
- Песочница включена и строгая, отправляет команды из песочницы через ваши правила, и запуск отказывается начинаться без неё.
- Есть лимит ходов и лимит расходов выше стоимости вашего среза, масштабированный под задачу.
- Скрипт исполняемый, а скрипт и файл ограничений закоммичены.
- Вы запускаете его, затем читаете diff и запускаете тесты самостоятельно, прежде чем что-либо коммитить.

## Проверка

Вы закончили, когда все следующие пункты истинны:

- [ ] `scripts/bounded-run.sh` закоммичен и исполняем, принимает задачу и путь результата (`scripts/bounded-run.sh "<task>" <result.json>`) и запускает `claude -p` в режиме `dontAsk` с выводом JSON и закоммиченным файлом `--settings`.
- [ ] Он устанавливает лимит ходов и лимит расходов.
- [ ] Каждое правило allow называет одну команду или одну папку, а правила deny останавливают `git commit` и `git push`.
- [ ] Файл настроек включает песочницу в строгом режиме без автоодобрения и заставляет запуск отказываться начинаться без неё.
- [ ] `.practice/a-7-slice.json` содержит запуск среза, стоимость которого ниже вашего лимита расходов.
- [ ] `.practice/a-7-capped.json` содержит запуск, остановленный лимитом.
- [ ] Самопроверка (не тестируется): вы прочитали diff и запустили тесты, прежде чем что-либо закоммитить.

Запустите `npm run check -- a-7 --dir <your repo>` из вашей копии практики или `npm run check -- a-7` в самой копии. Проверка запускает ваш закоммиченный скрипт с заглушкой для `claude`, поэтому не расходует ваше использование.

Если первый пункт не выполняется, убедитесь, что закоммиченный скрипт исполняем (`git ls-files -s scripts/bounded-run.sh` начинается с `100755`) и вызывает `claude` по имени, а не по пути или через `npx`, и не задаёт `PATH`: проверка читает закоммиченный скрипт, поэтому коммитьте каждое исправление. Если правило allow не проходит, сузьте его до одной папки или команды, нужной задаче. Если пункт о песочнице называет ключ, добавьте его в файл настроек: без `failIfUnavailable` запуск, чья песочница не может запуститься, выполняется без песочницы ([`sandbox.enabled`](https://code.claude.com/docs/en/settings-reference#sandbox-enabled)). Если пункт о срезе не проходит, убедитесь, что ваш скрипт отправляет в путь результата только JSON-вывод `claude` (stdout), затем снова выполните шаг 5; срез, завершившийся с `error_max_budget_usd`, означает, что ваш лимит расходов ниже одного среза, поэтому повысьте его.

## Осторожно

- Ваши ограничения не покрывают всё, что загружает запуск. Хуки и локальные MCP-серверы работают вне песочницы с вашим полным доступом ([Что работает вне песочницы](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox)). Как предупреждал [урок 4](04-headless.md#watch-out), запуск `-p` использует хуки репозитория и серверы из `.mcp.json` без запроса, а также применяет `allowed-tools` навыков репозитория ([Что выполняется до доверия папке](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)). Прочитайте эти хуки, серверы и навыки перед ограниченным запуском или добавьте `"disableAllHooks": true` в файл ограничений, чтобы отключить хуки для него.
- Правило deny соответствует команде, которую пишет Claude, а не тому, что делает программа ([Что не покрывает правило Bash](https://code.claude.com/docs/en/permissions#bash-rule-limits)). Разрешённый `npm test` запускает тестовые файлы, которые запуск может редактировать. В песочнице этот код может писать куда угодно в вашем рабочем каталоге, кроме защищённых путей, а внутри `.git` защищены только `hooks` и `config` ([Защищённые пути](https://code.claude.com/docs/en/sandboxing#protected-paths)). Так что он даже может сделать коммит. Push из него не достигнет удалённого репозитория: в режиме `dontAsk` песочница отказывает хостам, которые вы не разрешили ([Хосты вне ваших разрешённых доменов](https://code.claude.com/docs/en/sandboxing#hosts-outside-your-allowed-domains), [Отключение запросов разрешений в автоматических запусках](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs)). Поэтому скрипт печатает HEAD до и после, и поэтому ваша проверка охватывает каждый изменённый файл.
- Динамический рабочий процесс запускается через собственный инструмент `Workflow`. В таком запуске он стартует только если правило allow или хук `PreToolUse` одобряет его: `Workflow` одобряет любой рабочий процесс, а `Workflow(<name>)` одобряет один сохранённый рабочий процесс ([Одобрение плана перед запуском](https://code.claude.com/docs/en/workflows#approve-the-plan-before-it-runs)). Агенты рабочего процесса следуют вашим правилам разрешений, а их режим разрешений следует правилам субагентов, поэтому тип агента, в определении которого задан `permissionMode`, может работать в этом режиме ([Режимы разрешений](https://code.claude.com/docs/en/sub-agents#permission-modes)). Они субагенты, поэтому их расходы учитываются в `--max-budget-usd`. Если вы разрешаете один, также добавьте `"workflowSizeGuideline": "small"` в файл ограничений, что просит Claude использовать меньше агентов, но ничего не ограничивает ([`workflowSizeGuideline`](https://code.claude.com/docs/en/settings-reference#workflowsizeguideline)).

## Дальнейшие шаги

- [Выбор среды песочницы](https://code.claude.com/docs/en/sandbox-environments): контейнеры и виртуальные машины для запусков, которые не может покрыть песочница Bash.
- [Как мы сдерживаем Claude в разных продуктах](https://www.anthropic.com/engineering/how-we-contain-claude): инженерный пост Anthropic об ограничении ущерба, который может нанести агент, в Claude Code и других продуктах.
- [Выявление проблем безопасности при написании кода Claude](https://code.claude.com/docs/en/security-guidance): плагин security-guidance, который заставляет Claude проверять собственные изменения на уязвимости, пока вы с ним работаете.

---

<sub>Источники: [Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Расширение Claude навыками](https://code.claude.com/docs/en/skills) · [Настройка песочницы для инструмента Bash](https://code.claude.com/docs/en/sandboxing) · [Все настройки](https://code.claude.com/docs/en/settings-reference) · [Файлы настроек и приоритет](https://code.claude.com/docs/en/settings) · [Справка по CLI](https://code.claude.com/docs/en/cli-reference) · [Создание пользовательских субагентов](https://code.claude.com/docs/en/sub-agents) · [Программный запуск Claude Code](https://code.claude.com/docs/en/headless) · [Как работает агентный цикл](https://code.claude.com/docs/en/agent-sdk/agent-loop) · [Отслеживание затрат и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking) · [Эффективное управление затратами](https://code.claude.com/docs/en/costs) · [Команды](https://code.claude.com/docs/en/commands) · [Лучшие практики](https://code.claude.com/docs/en/best-practices) · [Оркестрация субагентов в масштабе с динамическими рабочими процессами](https://code.claude.com/docs/en/workflows)</sub>

<sub>← [Поделитесь своей настройкой с командой](06-share-your-setup.md) · [Продвинутый индекс](README.md) · [Продвинутый капстоун](capstone.md) → · Тема: [Разрешения и безопасность](../topics/permissions-and-safety.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-7)</sub>
