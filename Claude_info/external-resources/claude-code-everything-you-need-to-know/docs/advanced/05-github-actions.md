# GitHub Actions

<sub>**Продвинутый уровень** · Урок 5 из 7 · около 20 минут, плюс время выполнения · Требуется: [Скриптовый запуск Claude Code с `claude -p`](04-headless.md) · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете запускать Claude Code в автономном режиме в рабочем процессе GitHub Actions, который считывает учётные данные из секрета репозитория и останавливается в пределах, записанных в файле.

## Вам понадобится

- Флаги `claude -p` из [урока 4](04-headless.md), такие как `--max-turns` и `--allowedTools`.
- [GitHub CLI](https://cli.github.com), выполнен вход с помощью `gh auth login`, что необходимо для быстрой настройки ([Быстрая настройка](https://code.claude.com/docs/en/github-actions#quick-setup)).
- Новая приватная копия практического шаблона, только для этого урока. Вы владеете ею, поэтому имеете полный контроль ([Уровни разрешений для репозитория личного аккаунта](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository#owner-access-for-a-repository-owned-by-a-personal-account)), включая доступ администратора, необходимый для настройки ([Настройка](https://code.claude.com/docs/en/github-actions#setup)). Создайте её с помощью:

  ```bash
  gh repo create claude-actions-practice --template wesammustafa/claude-code-practice --private --clone
  cd claude-actions-practice
  ```

  `--template` создаёт новый репозиторий на основе шаблона, а `--clone` клонирует его ([gh repo create](https://cli.github.com/manual/gh_repo_create)). Проверка выполняется в этой копии, с Node.js LTS, без `--dir`. В конце вы удалите из неё рабочие процессы, секрет и доступ приложения.
- Учётные данные. Рекомендуется создать API-ключ Claude Console специально для этого урока, потому что при демонтаже он будет удалён. На плане Pro, Max, Team или Enterprise ([Ручная настройка](https://code.claude.com/docs/en/github-actions#manual-setup)) вы можете вместо этого позволить быстрой настройке создать токен подписки ([Быстрая настройка](https://code.claude.com/docs/en/github-actions#quick-setup)). Если Claude Code на вашем компьютере уже использует API-ключ, быстрая настройка повторно использует этот ключ, поэтому демонтаж удалит ключ, который использует ваш собственный Claude Code; шаг 3 рабочего примера показывает, как заменить его на ключ урока.
- Использование: небольшое. Каждый запуск короткий, а также использует минуты GitHub Actions (см. раздел «Осторожно»).

## Идея

[GitHub Action для Claude Code](https://code.claude.com/docs/en/github-actions), `anthropics/claude-code-action` (Anthropic), запускает Claude Code как шаг в рабочем процессе. Без входного параметра `prompt` он ждёт `@claude` в issue или pull request и отвечает в комментарии; с `prompt` он запускается без ожидания упоминания ([Интерактивный и автоматический режимы](https://code.claude.com/docs/en/github-actions#interactive-and-automation-modes)), а его входной параметр `display_report` помещает отчёт Claude на страницу сводки запуска ([action.yml на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/action.yml)).

Рабочий процесс указывает секрет репозитория, в котором хранятся учётные данные ([Ручная настройка](https://code.claude.com/docs/en/github-actions#manual-setup)).

Никого нет за клавиатурой, поэтому ограничения записываются в файл. `claude_args` передаёт флаги CLI Claude Code, такие как `--max-turns` и `--allowedTools` ([Передача аргументов CLI](https://code.claude.com/docs/en/github-actions#pass-cli-arguments)), а при использовании промпта, записанного как текст, а не как навык, у Claude нет оболочки, пока вы не разрешите нужные команды ([Запуск по расписанию](https://code.claude.com/docs/en/github-actions#run-on-a-schedule)). `permissions` и `timeout-minutes` задания ограничивают его токен GitHub и время выполнения ([Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idpermissions)).

## Рабочий пример

Подключите копию с помощью быстрой настройки, затем задайте Claude вопрос в issue.

1. В копии запустите `claude`, выполните `/install-github-app` и следуйте подсказкам для этого репозитория: Claude Code установит GitHub App Claude ([Быстрая настройка](https://code.claude.com/docs/en/github-actions#quick-setup)). Когда GitHub спросит, к каким репозиториям приложение может получить доступ, выберите **Только выбранные репозитории** и укажите только эту копию ([Установка GitHub App](https://docs.github.com/en/apps/using-github-apps/installing-a-github-app-from-a-third-party#installing-a-github-app)). Если приложение уже установлено в вашем аккаунте, добавьте эту копию в разделе **Доступ к репозиториям** ([Изменение доступа к репозиториям](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps#modifying-repository-access)).
2. Затем Claude Code спросит, продолжать ли настройку GitHub Actions. Продолжите и выберите только рабочий процесс `@claude`, `claude.yml`, а не рабочий процесс проверки. Для учётных данных вставьте ключ урока или создайте токен подписки, если только Claude Code не повторно использует свой собственный API-ключ (см. раздел «Вам понадобится»). Claude Code сохранит учётные данные как секрет `ANTHROPIC_API_KEY` или `CLAUDE_CODE_OAUTH_TOKEN`, отправит ветку с выбранным рабочим процессом и откроет GitHub в вашем браузере с готовым к созданию pull request ([Быстрая настройка](https://code.claude.com/docs/en/github-actions#quick-setup)).
3. Создайте и объедините этот pull request, затем обновите свой клон и выведите список секретов:

   ```bash
   git pull
   gh secret list
   ```

   В списке будет `ANTHROPIC_API_KEY` или `CLAUDE_CODE_OAUTH_TOKEN` ([gh secret list](https://cli.github.com/manual/gh_secret_list)). Объединённый `.github/workflows/claude.yml` уже настроен на использование этого секрета, и `@claude` теперь работает в репозитории ([Быстрая настройка](https://code.claude.com/docs/en/github-actions#quick-setup)). Если быстрая настройка повторно использовала API-ключ, который использует ваш собственный Claude Code, замените его на ключ урока сейчас: `gh secret set ANTHROPIC_API_KEY` попросит вставить его ([gh secret set](https://cli.github.com/manual/gh_secret_set)).
4. Откройте issue, в котором упомянут `@claude`. В интерактивном режиме Claude отвечает на `@claude` в теле или заголовке вновь открытого issue ([Интерактивный и автоматический режимы](https://code.claude.com/docs/en/github-actions#interactive-and-automation-modes)):

   ```bash
   gh issue create --title "What does links.js do?" --body "@claude In one paragraph, what does src/links.js do? Don't change any files."
   ```

   `gh issue create` выводит URL нового issue ([gh issue create](https://cli.github.com/manual/gh_issue_create)). `gh run list --limit 3` показывает запуск, который он инициировал ([gh run list](https://cli.github.com/manual/gh_run_list)). Когда он завершится, `gh issue view <issue-url> --comments` покажет ответ Claude в виде комментария ([gh issue view](https://cli.github.com/manual/gh_issue_view)). Формулировка будет отличаться, но она должна описывать, как `src/links.js` находит ссылки Markdown.

## Ваша очередь

**Задание:** добавьте `.github/workflows/linkcheck-report.yml`, рабочий процесс, который вы запускаете вручную, в котором Claude запускает проверку ссылок шаблона на `samples/` и объясняет каждую неработающую ссылку на странице сводки запуска, не изменяя никаких файлов. Пример [Запуск по расписанию](https://code.claude.com/docs/en/github-actions#run-on-a-schedule) в документации — это отправная точка. Он задаёт модель с помощью `--model`: выберите одну, как в [уроке 3 среднего уровня](../intermediate/03-model-and-effort.md), или удалите эту строку, чтобы использовать модель Claude Code по умолчанию ([Передача аргументов CLI](https://code.claude.com/docs/en/github-actions#pass-cli-arguments)).

**Критерии приёмки:**

- Запускается только вручную: `on: workflow_dispatch`, и никаких других триггеров.
- Использует `anthropics/claude-code-action`, закреплённый за тегом релиза или полным SHA коммита, а не `@v1` (в разделе «Осторожно» объясняется почему). Релиз v1.0.237 устанавливает Claude Code v2.1.285, версию, с которой сверялась эта страница ([run.ts на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/src/entrypoints/run.ts)).
- Имеет `prompt`, поэтому работает в автоматическом режиме.
- Учётные данные берутся из секрета, сохранённого быстрой настройкой, через соответствующий входной параметр, `anthropic_api_key` или `claude_code_oauth_token` ([Ручная настройка](https://code.claude.com/docs/en/github-actions#manual-setup)). Никакие учётные данные не записываются в файл.
- Имеет токен задания только для чтения: нет доступа на запись в `permissions`, кроме `id-token: https://code.claude.com/docs/en/github-actions#respond-to-@claude-mentions `permissions` задания предоставляют `contents: read`, плюс `id-token: https://code.claude.com/docs/en/github-actions#respond-to-@claude-mentions если вы сохраните его из примеров документации, где он служит для аутентификации GitHub App по умолчанию для действия ([Ответ на упоминания @claude](https://code.claude.com/docs/en/github-actions#respond-to-@claude-mentions)). `github_token` устанавливается в собственный `GITHUB_TOKEN` задания, поэтому Claude действует с этим токеном, а не с токеном приложения ([Параметры действия](https://code.claude.com/docs/en/github-actions#action-parameters)).
- `claude_args` устанавливает `--max-turns` равным 10 или меньше, и правило `--allowedTools` только для команды проверки ссылок, никогда не для всего Bash ([Настройка разрешений](https://code.claude.com/docs/en/permissions#wildcard-patterns)). Запишите ограничение ходов двумя словами, `--max-turns <n>`, как в примере документации [Передача аргументов CLI](https://code.claude.com/docs/en/github-actions#pass-cli-arguments): действие считывает значение флага из следующего слова ([parse-sdk-options.ts на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/base-action/src/parse-sdk-options.ts)).
- Задание имеет `timeout-minutes` 30 или меньше ([Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)).
- Перед запуском действия выполняется извлечение репозитория и настройка Node.js, как в `.github/workflows/progress.yml` шаблона, чтобы проверка ссылок могла работать.
- `display_report` равен `true`, поэтому отчёт Claude с его ответом появляется на странице сводки запуска ([action.yml на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/action.yml), [Добавление сводки задания](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary)). Действие рекомендует включать его только когда входные данные доверенные, как здесь: вы запускаете процесс, а промпт и файлы — ваши собственные. `show_full_output` остаётся выключенным, и вы не включаете режим отладки GitHub Actions (секрет `ACTIONS_STEP_DEBUG`, установленный в `true`), который включает полный вывод: полный вывод может напечатать секреты в журнал ([заметки по безопасности](https://github.com/anthropics/claude-code-action/blob/v1.0.237/docs/security.md)). Без него журнал скрывает сообщения Claude и вызовы инструментов и показывает сводку результата со строкой, предлагающей включить полный вывод ([run-claude-sdk.ts на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/base-action/src/run-claude-sdk.ts)).

Затем запустите его, сохраните запись и выполните демонтаж:

1. Зафиксируйте рабочий процесс и отправьте его в `main`. Ручной запуск начинается только когда файл рабочего процесса находится в ветке по умолчанию ([`workflow_dispatch`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch)).
2. Запустите его, найдите его id, проследите за ним до конца и откройте в браузере ([gh workflow run](https://cli.github.com/manual/gh_workflow_run), [gh run watch](https://cli.github.com/manual/gh_run_watch), [gh run view](https://cli.github.com/manual/gh_run_view)):

   ```bash
   gh workflow run linkcheck-report.yml
   gh run list --workflow linkcheck-report.yml --limit 1
   gh run watch <run-id> --exit-status
   gh run view <run-id> --web
   ```

   На странице сводки запуска находится отчёт Claude с объяснением каждой неработающей ссылки. Формулировка будет отличаться.
3. Сохраните запись запуска для проверки, с полями, которые она считывает ([gh run list](https://cli.github.com/manual/gh_run_list)):

   ```bash
   mkdir -p .practice
   gh run list --workflow linkcheck-report.yml --json databaseId,status,conclusion,event,headSha,url,workflowName > .practice/a-5-runs.json
   ```

4. Выполните `npm run check -- a-5` (проверка ниже). Когда она пройдёт, выполните демонтаж: это обязательно. Не выполняйте демонтаж раньше: исправление неудачного запуска требует секрета, который демонтаж удаляет.

> [!WARNING]
> Удаление секрета оставляет хранившиеся в нём учётные данные действительными ([Удаление](https://code.claude.com/docs/en/github-actions#uninstall)). Секрет `CLAUDE_CODE_OAUTH_TOKEN` содержит OAuth-токен того типа, который генерирует `claude setup-token` ([Параметры действия](https://code.claude.com/docs/en/github-actions#action-parameters)). На 2026-10-09 токен от `claude setup-token` действителен один год ([Аутентификация](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token)), и удаление секрета не отзывает его.

5. Удалите оба рабочих процесса, затем зафиксируйте и отправьте:

   ```bash
   git rm .github/workflows/claude.yml .github/workflows/linkcheck-report.yml
   git commit -m "Remove the Claude workflows"
   git push
   ```

6. Удалите секрет: `gh secret delete ANTHROPIC_API_KEY` или `gh secret delete CLAUDE_CODE_OAUTH_TOKEN` ([gh secret delete](https://cli.github.com/manual/gh_secret_delete)).
7. При использовании API-ключа удалите ключ, хранившийся в секрете, на странице [API keys](https://platform.claude.com/settings/keys) Claude Console. Если это ключ, который использует ваш собственный Claude Code, то Claude Code на вашем компьютере после этого потребуется новый ключ.
8. На GitHub откройте **Settings** > **Applications** > **Installed GitHub Apps** и выберите **Configure** рядом с Claude. Затем либо удалите эту копию в разделе **Repository access** и нажмите **Save**, либо, если эта копия — единственный репозиторий, к которому приложение может получить доступ, и больше ничто ваше его не использует, нажмите **Uninstall** ([Изменение доступа к репозиториям](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps#modifying-repository-access), [Блокировка доступа](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps#blocking-access)).

## Проверка

Вы закончили, когда все следующие пункты истинны:

- [ ] Зафиксированный рабочий процесс запускает `anthropics/claude-code-action`, закреплённый за тегом релиза или полным SHA коммита, в автоматическом режиме, с учётными данными из секрета и без них в файле.
- [ ] Ограничения записаны в файле: `--max-turns` 10 или меньше, список `--allowedTools` без неограниченного Bash, токен задания только для чтения (нет доступа на запись в `permissions`, кроме `id-token: write`) и `timeout-minutes` 30 или меньше.
- [ ] `.practice/a-5-runs.json` показывает завершённый, успешный ручной запуск на коммите, содержащем рабочий процесс.
- [ ] Самопроверка (не тестируется): Claude ответил на ваш issue в комментарии, и страница сводки вашего запуска объясняет каждую неработающую ссылку.

Выполните `npm run check -- a-5` в этой копии.

Если первый пункт не проходит на строке `uses:`, закрепите тег релиза, например `@v1.0.237`, или полный SHA коммита этого релиза. Если второй пункт не проходит, его подсказка называет ограничение, которое нужно добавить или исправить. Если сохранённый запуск не удался, `gh run view <run-id> --log-failed` покажет причину, например, имя секрета, не совпадающее с рабочим процессом, или достижение лимита ходов, что завершается ошибкой ([Справочник CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)); отправьте исправление, запустите рабочий процесс снова и сохраните запись снова.

Проверка считывает рабочий процесс из вашей истории, поэтому она всё ещё проходит после демонтажа. Как только она пройдёт, выполните демонтаж, как описано в шагах 5–8 раздела «Ваша очередь».

## Осторожно

- Любой, у кого есть доступ на запись в репозиторий, может запустить процесс с помощью `@claude`, и текст issue или комментария является входными данными для Claude, поэтому он может содержать скрытые инструкции ([Кто может запускать процессы](https://code.claude.com/docs/en/github-actions#who-can-trigger-runs), [заметки по безопасности действия](https://github.com/anthropics/claude-code-action/blob/v1.0.237/docs/security.md)). Держите эту копию приватной и своей: только люди с доступом на чтение могут видеть журналы её запусков ([Использование журналов запусков рабочего процесса](https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs)).
- Каждый запуск использует минуты GitHub Actions и токены. В приватном репозитории минуты берутся из включённых минут вашего аккаунта ([Биллинг GitHub Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions)). Токены оплачиваются с вашего аккаунта Console при использовании API-ключа или берутся из вашего плана при использовании токена подписки. `--max-turns` и `timeout-minutes` ограничивают объём работы, который может выполнить запуск, что снижает оба показателя ([Управление затратами](https://code.claude.com/docs/en/github-actions#manage-costs)).
- Тег `v1` в примерах документации перемещается на каждый новый релиз ([теги](https://github.com/anthropics/claude-code-action/tags)), и каждый релиз закрепляет версию Claude Code, которую он устанавливает, поэтому рабочий процесс на `@v1` может запустить более новую версию Claude Code, чем вы тестировали. GitHub называет файл блокировки зависимостей рабочего процесса самой сильной защитой, предлагает закрепление за полным SHA коммита для репозиториев, которые не могут его принять, и предупреждает, что тег может быть перемещён или удалён, если злоумышленник получит доступ к репозиторию действия ([Справочник по безопасному использованию](https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions)). Тег релиза, такой как `v1.0.237`, — это более лёгкое закрепление, которое также принимается в этом уроке.

Листинги сверены с панелью листинга 2026-10-09.

## Дальнейшие шаги

- [Запуск по расписанию](https://code.claude.com/docs/en/github-actions#run-on-a-schedule): тот же автоматический режим с триггером cron.
- [Настройка для организации](https://code.claude.com/docs/en/github-actions#set-up-for-an-organization): одна установка приложения и один секрет организации для многих репозиториев или федерация удостоверений рабочей нагрузки вместо хранимого ключа.
- [Руководство по решениям действия](https://github.com/anthropics/claude-code-action/blob/v1.0.237/docs/solutions.md) (Anthropic): полные рабочие процессы для проверки pull request, планового обслуживания и сортировки issue.

---

<sub>Источники: [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions) · [Аутентификация](https://code.claude.com/docs/en/authentication) · [Справочник CLI](https://code.claude.com/docs/en/cli-reference) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · claude-code-action на v1.0.237: [action.yml](https://github.com/anthropics/claude-code-action/blob/v1.0.237/action.yml), [run.ts](https://github.com/anthropics/claude-code-action/blob/v1.0.237/src/entrypoints/run.ts), [parse-sdk-options.ts](https://github.com/anthropics/claude-code-action/blob/v1.0.237/base-action/src/parse-sdk-options.ts), [run-claude-sdk.ts](https://github.com/anthropics/claude-code-action/blob/v1.0.237/base-action/src/run-claude-sdk.ts), [security](https://github.com/anthropics/claude-code-action/blob/v1.0.237/docs/security.md) и его [теги](https://github.com/anthropics/claude-code-action/tags) · GitHub: [Установка GitHub App от третьей стороны](https://docs.github.com/en/apps/using-github-apps/installing-a-github-app-from-a-third-party), [Уровни разрешений для репозитория личного аккаунта](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository), [События, запускающие рабочие процессы](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [Команды рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands), [Справочник по безопасному использованию](https://docs.github.com/en/actions/reference/security/secure-use), [Использование журналов запусков рабочего процесса](https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs), [Просмотр и изменение установленных GitHub Apps](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps), [Биллинг GitHub Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions) · Руководство GitHub CLI: [gh repo create](https://cli.github.com/manual/gh_repo_create), [gh issue create](https://cli.github.com/manual/gh_issue_create), [gh issue view](https://cli.github.com/manual/gh_issue_view), [gh secret list](https://cli.github.com/manual/gh_secret_list), [gh secret set](https://cli.github.com/manual/gh_secret_set), [gh workflow run](https://cli.github.com/manual/gh_workflow_run), [gh run list](https://cli.github.com/manual/gh_run_list), [gh run watch](https://cli.github.com/manual/gh_run_watch), [gh run view](https://cli.github.com/manual/gh_run_view), [gh secret delete](https://cli.github.com/manual/gh_secret_delete)</sub>

<sub>← [Скриптовый запуск Claude Code с `claude -p`](04-headless.md) · [Указатель продвинутого уровня](README.md) · [Поделитесь своей настройкой с командой](06-share-your-setup.md) → · Тема: [Автоматизация](../topics/automation.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-5)</sub>
