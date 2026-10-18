# Разрешения, области настроек и песочница

<sub>**Средний уровень** · Урок 4 из 8 · около 20 минут · Требуется: [Организуйте память проекта и посмотрите, что загрузилось](02-organize-memory.md) · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете поместить правило разрешений в файл настроек с подходящей областью действия, увидеть, какие правила действуют, и включить песочницу, чтобы команды оболочки, которые запускает Claude, не могли писать за пределами вашего проекта, временной папки и любых добавленных вами папок.

## Вам понадобится

- Ваша копия шаблона для практики, для рабочего примера, с Node.js LTS: проверка выполняется из неё. Один из ваших собственных репозиториев с тестовой командой, для раздела «Ваша очередь»; или используйте копию шаблона для обоих.
- macOS, Linux или WSL 2. На Linux и WSL 2 песочнице нужны `bubblewrap` и `socat` ([Настройка Linux и WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)); в Codespace на вашей копии шаблона есть оба.
- Использование: небольшое.

## Идея

Claude Code читает настройки из четырёх файлов, и файл, в котором находится правило, определяет, на кого оно влияет ([Настройки](https://code.claude.com/docs/en/settings#settings-files-and-who-they-affect)):

| Файл | Влияет на | Поместите сюда |
|---|---|---|
| `~/.claude/settings.json` | Вас, в каждом проекте | Ваши собственные предпочтения |
| `.claude/settings.json`, закоммичен | Всех в проекте | Командные правила: файлы, которые Claude никогда не должен читать, команды, которые все запускают |
| `.claude/settings.local.json`, вне git | Вас, в этом проекте | Ваши собственные исключения. «Да, и больше не спрашивать» для команды Bash сохраняется сюда |
| Управляемые настройки | Всех, кому ваша организация их развёртывает | Политика, которую ваши настройки не могут переопределить, за исключением нескольких ключей безопасности, где действует более строгое значение |

Когда один и тот же ключ задан в нескольких местах, побеждает более высокий уровень: управляемые, затем командная строка, затем локальные, затем общие проектные, затем пользовательские ([Приоритет настроек](https://code.claude.com/docs/en/settings#settings-precedence)). Списки правил, такие как `permissions.allow`, вместо этого объединяются между файлами. Среди правил сначала проверяется deny, затем ask, затем allow, и первое совпадение решает ([Настройка разрешений](https://code.claude.com/docs/en/permissions#manage-permissions)).

Правила разрешений управляют инструментами Claude. [Песочница](https://code.claude.com/docs/en/sandboxing) добавляет границу, которую операционная система применяет к командам оболочки, запускаемым Claude: по умолчанию они могут писать только в проекте, временной папке пользователя и любых папках, добавленных вами с помощью `--add-dir` или `/add-dir`, а сеть доступна только через прокси, который проверяет каждый хост на соответствие разрешённым вами хостам. Она выключена, пока вы её не включите. В режиме auto-allow команда, выполняющаяся внутри неё, не требует запроса разрешения.

## Рабочий пример

В вашей копии для практики:

1. Запустите `claude` и выполните `/status`. Строка `Setting sources` показывает файлы настроек, загруженные в этой сессии.
2. Сохраните командные правила как `.claude/settings.json`. Это правила документации, чтобы Claude не читал файлы `.env` ([Исключение конфиденциальных файлов](https://code.claude.com/docs/en/settings-reference#exclude-sensitive-files)), плюс тестовая команда:

   ```json
   {
     "permissions": {
       "allow": ["Bash(npm test)"],
       "deny": ["Read(./.env)", "Read(./.env.*)"]
     }
   }
   ```

   Claude Code перезагружает файл настроек при его изменении ([Когда правки вступают в силу](https://code.claude.com/docs/en/settings#when-edits-take-effect)). Выполните `/permissions`: он покажет `Bash(npm test)` среди правил allow и два правила `Read` среди правил deny.
3. Попросите Claude `Run npm test`. Он выполнится без запроса разрешения: правило allow его покрывает.
4. Включите песочницу. Выполните `/sandbox` и на вкладке Mode выберите auto-allow. Claude Code сохранит настройку в `.claude/settings.local.json`, ваш личный файл ([Начало работы](https://code.claude.com/docs/en/sandboxing#get-started)).
5. Попросите Claude попробовать запись вне проекта:

   ```text
   Run this exact command and show me its output: touch ~/sandbox-probe
   ```

   Он выполнится без запроса и завершится ошибкой: `Operation not permitted` на macOS, `Read-only file system` на Linux и WSL 2 ([Подтверждение, что команды выполняются внутри песочницы](https://code.claude.com/docs/en/sandboxing#confirm-commands-run-inside-the-sandbox)). Если Claude предложит повторить вне песочницы, откажитесь.

## Ваша очередь

Настройте такое же разделение в вашем собственном репозитории.

1. Сохраните этот частичный файл как `.claude/settings.json` и замените каждый `TODO` правилом. Разрешите только одну команду, которая запускает ваши тесты, например `Bash(npm test)` или `Bash(pytest)`:

   ```json
   {
     "permissions": {
       "allow": ["TODO: the command that runs your tests"],
       "deny": ["TODO: reading .env", "TODO: reading .env.local and the other .env.* files"]
     }
   }
   ```

2. Закоммитьте его: это правила для всех, кто работает в репозитории.
3. В сессии там включите песочницу с помощью `/sandbox` в режиме auto-allow и повторите шаг 5 рабочего примера.
4. Выполните `git status`. `.claude/settings.local.json` не отображается: Claude Code не добавляет его в git при создании ([Не храните личные настройки в репозитории](https://code.claude.com/docs/en/settings#keep-personal-settings-out-of-a-repository)).

## Проверка

Вы закончили, когда всё перечисленное верно:

- [ ] Закоммиченный `.claude/settings.json` запрещает чтение файлов `.env` и `.env.*` и разрешает одну тестовую команду: `git show HEAD:.claude/settings.json | jq .permissions` показывает их.
- [ ] Песочница включена, и ваш личный файл не попадает в git: `jq .sandbox .claude/settings.local.json` показывает `"enabled": true`, а `git ls-files .claude/settings.local.json` ничего не выводит.
- [ ] Самопроверка (не тестируется): команда Claude `touch ~/sandbox-probe` завершилась ошибкой, не спросив вас.

Выполните `npm run check -- i-4 --dir <your repo>` из вашей копии для практики или `npm run check -- i-4` в самой копии.

Если первый пункт не проходит из-за слишком широкого правила, замените его одной командой: `Bash(npm *)` позволил бы Claude запускать любую команду npm без запроса. Если `/sandbox` показывает только вкладку Dependencies, установите `bubblewrap` и `socat`, перезапустите Claude Code и снова выполните `/sandbox`.

## Осторожно

- Песочница оборачивает только команды оболочки. Файловые и веб-инструменты Claude работают вне её и подчиняются вашим правилам разрешений; хуки и локальные MCP-серверы работают вне её с вашим полным доступом ([Что работает вне песочницы](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox)). Если песочница не может запуститься, Claude Code выполняет команды без песочницы, если только `sandbox.failIfUnavailable` не равен `true`.
- Само по себе правило deny для `Read` покрывает файловые инструменты Claude и файловые команды, которые Claude Code распознаёт в Bash, такие как `cat`, но не скрипт, который сам открывает файлы ([Read и Edit](https://code.claude.com/docs/en/permissions#read-and-edit)). При включённой песочнице Claude Code также добавляет ваши пути deny для `Read` в [`filesystem.denyRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-denyread) песочницы, так что команды в песочнице и запускаемые ими процессы тоже не могут читать эти файлы.
- В Codespace или другом контейнере, если команды в песочнице завершаются ошибкой `Can't mount proc on /newroot/proc`, см. [Bubblewrap не запускается внутри контейнера](https://code.claude.com/docs/en/sandboxing#bubblewrap-fails-to-start-inside-a-container).

## Дальнейшее изучение

- [Как мы создали авторежим Claude Code](https://www.anthropic.com/engineering/claude-code-auto-mode): Anthropic о том, что классификатор авторежима улавливает, а что пропускает.
- [Делаем Claude Code более безопасным и автономным с помощью песочницы](https://www.anthropic.com/engineering/claude-code-sandboxing): почему у песочницы есть граница файловой системы и граница сети.
- [Безопасность](https://code.claude.com/docs/en/security): как защитные механизмы Claude Code сочетаются друг с другом.

---

<sub>Источники: [Файлы настроек и приоритет](https://code.claude.com/docs/en/settings) · [Все настройки](https://code.claude.com/docs/en/settings-reference) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Настройка песочницы для инструмента Bash](https://code.claude.com/docs/en/sandboxing)</sub>

<sub>← [Выбор модели и усилий](03-model-and-effort.md) · [Индекс среднего уровня](README.md) · [Принудительное применение правила с помощью хука](05-hooks.md) → · Тема: [Разрешения и безопасность](../topics/permissions-and-safety.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-4)</sub>
