# Скриптование Claude Code с помощью `claude -p`

<sub>**Продвинутый** · Урок 4 из 7 · около 20 минут · Требуется: [Запуск и сохранение динамического рабочего процесса](03-dynamic-workflows.md) · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете написать скрипт, который запускает Claude Code без участия человека за клавиатурой, читает его JSON-результат и код выхода, а также ограничивает его инструментами и количеством шагов, необходимыми для задачи.

## Вам понадобится

- Один из ваших собственных репозиториев с тестовой командой и ваша копия практического шаблона с Node.js LTS: проверка выполняется из копии. Чтобы практиковаться в копии шаблона, используйте её для обоих. Настройте папку `.practice/` репозитория, как описано в [Уроке 1 для начинающих](../beginner/01-install-and-look-around.md#you-need), если ещё не сделали этого.
- bash и `jq` на macOS, Linux или WSL 2.
- Использование: лёгкое. Каждый запуск `claude -p` — это одна короткая сессия.

## Идея

`claude -p "<prompt>"` выполняет один запрос без интерактивного интерфейса, печатает ответ и завершается с кодом 0 или ненулевым кодом при сбое ([Программный запуск Claude Code](https://code.claude.com/docs/en/headless)). Он читает stdin, поэтому скрипт может передать diff через конвейер.

С помощью [`--output-format json`](https://code.claude.com/docs/en/headless#get-structured-output) он печатает один JSON-объект с полями `result`, `is_error`, `num_turns`, `session_id` и `permission_denials` ([`SDKResultMessage`](https://code.claude.com/docs/en/agent-sdk/typescript#sdkresultmessage)). `result` содержит ответ или сообщение об ошибке, если что-то пошло не так внутри запуска ([Основное использование](https://code.claude.com/docs/en/headless#basic-usage)). `subtype` — это `success` или причина ранней остановки, например `error_max_turns`; в таком запуске нет `result` ([Обработка результата](https://code.claude.com/docs/en/agent-sdk/agent-loop#handle-the-result)). Проверяйте код выхода и `is_error` перед использованием `result`.

Никто не может ответить на запрос разрешения, поэтому всегда передавайте режим: запуск, в котором ничего не задано, может начаться в автоматическом режиме ([Автоодобрение инструментов](https://code.claude.com/docs/en/headless#auto-approve-tools)). Три флага задают ограничения: `--permission-mode dontAsk` запрещает все вызовы, которые иначе вызвали бы запрос, `--allowedTools` указывает, что можно выполнять в любом случае, а `--max-turns` ограничивает количество шагов ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)).

## Разобранный пример

В вашем репозитории:

1. Задайте один вопрос и сохраните JSON:

   ```bash
   claude -p "In one sentence, what does this repository do?" --output-format json --permission-mode dontAsk > .practice/a-4-first.json
   echo "exit $?"
   jq '{is_error, subtype, num_turns, session_id}' .practice/a-4-first.json
   jq -r .result .practice/a-4-first.json
   ```

   Он напечатает `exit 0`, затем `"is_error": false` и `"subtype": "success"` с количеством шагов и идентификатором сессии, затем одно предложение о вашем репозитории (формулировка может отличаться). Чтение файлов в вашем рабочем каталоге не требует одобрения, поэтому `dontAsk` позволил Claude прочитать то, что ему нужно ([Режим dontAsk](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)).
2. Попросите что-то, требующее одобрения. `--setting-sources user` исключает файлы настроек вашего проекта из запуска ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)), поэтому ни правило allow, ни режим автоодобрения песочницы из [Урока 4 для среднего уровня](../intermediate/04-permissions-and-sandbox.md) не одобряют тестовую команду ([Режим автоодобрения](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)). Это также исключает правила deny проекта, такие как ваши правила для `.env` из того урока, поэтому шаги 2–4 снова передают их с помощью `--disallowedTools`, который принимает правила deny ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)):

   ```bash
   claude -p "Run the test suite and say how many tests pass" --output-format json --permission-mode dontAsk --setting-sources user --disallowedTools "Read(./.env)" "Read(./.env.*)" > .practice/a-4-denied.json
   jq -c '.permission_denials[] | {tool_name, command: .tool_input.command}' .practice/a-4-denied.json
   jq -r .result .practice/a-4-denied.json
   ```

   Каждая строка — это вызов, который `dontAsk` запретил ([`SDKPermissionDenial`](https://code.claude.com/docs/en/agent-sdk/typescript#sdkpermissiondenial)), например `{"tool_name":"Bash","command":"npm test 2>&1 | tail -20"}`; Claude сам выбирает команду, поэтому ваша может отличаться. Результат говорит, что Claude не смог запустить тесты (формулировка может отличаться).
3. Разрешите команду, указанную в шаге 2 (здесь `npm test`), и ограничьте количество шагов:

   ```bash
   claude -p "Run the test suite and say how many tests pass" --output-format json --permission-mode dontAsk --setting-sources user --disallowedTools "Read(./.env)" "Read(./.env.*)" --allowedTools "Bash(npm test *)" --max-turns 3 | jq '{subtype, num_turns, denied: (.permission_denials | length)}'
   ```

   Он показывает `"subtype": "success"` и `"denied": 0`: на этот раз Claude запустил тесты. Пробел перед `*` важен, а завершающий ` *` также соответствует команде без аргументов ([Шаблоны с подстановочными знаками](https://code.claude.com/docs/en/permissions#wildcard-patterns)). Правило также покрывает конвейер, такой как `npm test 2>&1 | tail -20`: Claude Code проверяет каждую часть конвейера отдельно, а `tail` — одна из команд только для чтения, которые выполняются без одобрения ([Составные команды](https://code.claude.com/docs/en/permissions#compound-commands), [Команды только для чтения](https://code.claude.com/docs/en/permissions#read-only-commands)).
4. Достигните предела. Эта задача требует двух последовательных шагов, а `--max-turns 1` разрешает один шаг, вызывающий инструменты. Оставьте `Read` и используйте то же правило Bash, что и в шаге 3:

   ```bash
   claude -p "Read the file that defines this project's test command, then run that command, then summarize any failures" --output-format json --permission-mode dontAsk --setting-sources user --disallowedTools "Read(./.env)" "Read(./.env.*)" --allowedTools "Read,Bash(npm test *)" --max-turns 1 > .practice/a-4-capped.json
   echo "exit $?"
   jq '{subtype, has_result: has("result")}' .practice/a-4-capped.json
   ```

   Он печатает ненулевой код выхода, затем `"subtype": "error_max_turns"` и `"has_result": false`: запуск, остановленный на пределе, не имеет `result`. `--max-turns` считает только шаги, вызывающие инструменты ([Шаги и сообщения](https://code.claude.com/docs/en/agent-sdk/agent-loop#turns-and-messages)), поэтому если запуск завершился, дайте ему задачу с большим количеством шагов.

## Ваша очередь

Напишите обзор, который можно запускать перед каждым коммитом: `scripts/review-staged.sh` отправляет ваши подготовленные изменения в Claude, печатает обзор Claude и сохраняет JSON-результат. Продвинутый итоговый проект повторно использует его.

Критерии приёмки:

- Bash-скрипт `scripts/review-staged.sh`, закоммиченный и исполняемый.
- Он передаёт `git diff --cached`, подготовленные изменения ([git diff](https://git-scm.com/docs/git-diff)), через конвейер в один вызов `claude -p`. Claude не нужен Bash для чтения diff, потому что он поступает через stdin ([Добавление Claude в скрипт сборки](https://code.claude.com/docs/en/headless#add-claude-to-a-build-script)).
- Этот вызов помещает запрос сразу после `-p`, как в примерах [Передача данных через Claude](https://code.claude.com/docs/en/headless#pipe-data-through-claude) и [Добавление Claude в скрипт сборки](https://code.claude.com/docs/en/headless#add-claude-to-a-build-script), и передаёт `--output-format json`, `--permission-mode dontAsk`, `--allowedTools` с указанием только `Read`, `Grep` и `Glob`, и `--max-turns` с числом от 1 до 10. На macOS, Linux и WSL Glob и Grep по умолчанию отсутствуют, и указание любого из них в `--allowedTools` возвращает оба ([Поведение инструмента Glob](https://code.claude.com/docs/en/tools-reference#glob-tool-behavior)).
- Он вызывает `claude` по имени, а не по пути или через `npx`, и не изменяет `PATH`: именно так проверка подменяет его заглушкой.
- Он сохраняет JSON по пути из первого аргумента или в `.practice/a-4-result.json`, если аргумента нет, создавая папку при необходимости.
- Он печатает текст `result` и завершается с ненулевым кодом, если `claude` завершился с ошибкой или `is_error` равно `true`.
- Если ничего не подготовлено, он сообщает об этом и завершается с ненулевым кодом, не вызывая Claude. `git diff --cached --quiet` завершается с кодом 0, когда ничего не подготовлено ([git diff](https://git-scm.com/docs/git-diff)).

Закоммитьте скрипт. Затем подготовьте небольшое изменение, например однострочное исправление, и запустите `scripts/review-staged.sh` один раз: он сохранит `.practice/a-4-result.json`. Прочитайте обзор перед коммитом этого изменения.

## Проверка

Вы закончили, когда все следующие условия истинны:

- [ ] `scripts/review-staged.sh` закоммичен и исполняем.
- [ ] Его вызов `claude -p` имеет запрос сразу после `-p`, запрашивает JSON, работает в режиме `dontAsk`, предварительно одобряет только `Read`, `Grep` и `Glob` и ограничивает шаги до 10 или меньше.
- [ ] Он передаёт подготовленный diff через конвейер, сохраняет JSON по указанному пути, печатает результат, завершается с ненулевым кодом при сбое и не вызывает Claude, когда ничего не подготовлено.
- [ ] `.practice/a-4-result.json` содержит запуск, который успешно завершился в пределах вашего лимита.
- [ ] Самопроверка (не тестируется): вы видели, как запуск остановился на `--max-turns`, в шаге 4 разобранного примера.

Запустите `npm run check -- a-4 --dir <your repo>` из вашей практической копии или `npm run check -- a-4` в самой копии. Проверка запускает ваш закоммиченный скрипт с заглушкой для `claude`, поэтому она не использует ваше использование.

Если первый пункт не выполнен, выполните `chmod +x scripts/review-staged.sh`, затем `git add` и снова закоммитьте. Если второй пункт не выполнен, прочитайте подсказку: она называет флаг, который не был найден, или говорит, что ваш скрипт вызывает `claude` по пути или через `npx`, или изменяет `PATH`. Сравните вашу строку `claude -p` с критериями в разделе «Ваша очередь», начиная с того, где находится запрос. Если третий пункт не выполнен, запустите скрипт вручную без подготовленных изменений и снова с подготовленным изменением, и выполните `echo $?` после каждого; проверка запускает закоммиченный скрипт, поэтому коммитьте каждое исправление перед повторным запуском проверки. Если четвёртый пункт не выполнен, подготовьте изменение и запустите скрипт снова: запуск, остановленный на вашем лимите, не считается, поэтому увеличьте лимит или сузьте запрос.

## Осторожно

- Запуск `-p` не показывает диалог доверия: он выполняет хуки из `.claude/settings.json` проекта и подключает серверы из его `.mcp.json`, даже в папке, которой вы никогда не доверяли ([Более быстрый старт с bare-режимом](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)). Прежде чем скриптовать Claude Code в репозитории, который вы не писали, передайте `--setting-sources user`, чтобы Claude Code не читал ни файлы настроек проекта, ни его `.mcp.json` ([Что выполняется до доверия папке](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)).
- Когда установлен `ANTHROPIC_API_KEY`, запуск `-p` всегда использует этот ключ вместо вашего плана ([Приоритет аутентификации](https://code.claude.com/docs/en/authentication#authentication-precedence)). `total_cost_usd` в JSON — это оценка на стороне клиента, а не ваш счёт ([Отслеживание стоимости и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking#estimates-not-billing)).
- В папке, которой вы никогда не доверяли, запуск `-p` игнорирует правила `permissions.allow` в `.claude/settings.json` проекта и печатает предупреждение `this workspace has not been trusted` в stderr; доверие родительской папке не считается ([Правила allow проекта и доверие рабочей области](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust), [Справочник ошибок](https://code.claude.com/docs/en/errors#workspace-has-not-been-trusted)). Передавайте правила, необходимые скрипту, в командной строке с помощью `--allowedTools`.

## Дальнейшие шаги

- [Программный запуск Claude Code](https://code.claude.com/docs/en/headless): структурированный вывод с `--json-schema`, потоковый JSON и продолжение запуска с `--resume` и его `session_id`.
- [Одобрение плана перед запуском](https://code.claude.com/docs/en/workflows#approve-the-plan-before-it-runs): запустите рабочий процесс, сохранённый на предыдущем уроке, из скрипта с `Workflow(<name>)` в ваших правилах allow.
- [Обзор Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview): тот же цикл агента из Python или TypeScript.

---

<sub>Источники: [Программный запуск Claude Code](https://code.claude.com/docs/en/headless) · [Справочник CLI](https://code.claude.com/docs/en/cli-reference) · [Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Настройка песочницы Bash](https://code.claude.com/docs/en/sandboxing) · [Как работает цикл агента](https://code.claude.com/docs/en/agent-sdk/agent-loop) · [Справочник Agent SDK — TypeScript](https://code.claude.com/docs/en/agent-sdk/typescript) · [Отслеживание стоимости и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking) · [Аутентификация](https://code.claude.com/docs/en/authentication) · [Справочник инструментов](https://code.claude.com/docs/en/tools-reference) · [Справочник ошибок](https://code.claude.com/docs/en/errors) · [git diff](https://git-scm.com/docs/git-diff)</sub>

<sub>← [Запуск и сохранение динамического рабочего процесса](03-dynamic-workflows.md) · [Индекс продвинутого уровня](README.md) · [GitHub Actions](05-github-actions.md) → · Тема: [Автоматизация](../topics/automation.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-4)</sub>
