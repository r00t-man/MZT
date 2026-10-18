# Продвинутый капстоун: добавьте CI-ревью, которым ваша команда может поделиться

<sub>**Продвинутый** · Капстоун · от 30 до 60 минут, плюс время выполнения · Требуется: семь [продвинутых уроков](README.md) или их навыки · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

Это задание объединяет весь продвинутый уровень в новой копии практического шаблона, которую вы удалите в конце. Здесь нет готового примера: в задании сказано, что нужно команде, а вы сами решаете, как это построить. [Продвинутый выход](README.md#by-the-end-of-this-level-you-can) — это список того, что вы сможете делать к концу уровня. Проверка читает то, что вы закоммитили, и два файла, сохранённых в `.practice/`, а остальные пункты выхода вы отмечаете сами в разделе [Что проверка не видит](#what-the-check-cant-see).

## Вам понадобится

- Node.js LTS, git, `jq` и GitHub CLI, в который вы вошли с помощью `gh auth login`.
- Новая приватная копия практического шаблона, созданная для этого капстоуна и удалённая после него. Создайте её так:

  ```bash
  gh repo create claude-capstone --template wesammustafa/claude-code-practice --private --clone
  cd claude-capstone
  ```

  `--template` создаёт новый репозиторий на основе шаблона, а `--clone` клонирует его ([gh repo create](https://cli.github.com/manual/gh_repo_create)). Проверка запускается в этой копии, без `--dir`.
- В копии один раз запустите `claude`, примите диалог доверия и выйдите. В папке, которой вы ещё не доверяли, `claude --worktree` завершится с ошибкой ([Запуск Claude в worktree](https://code.claude.com/docs/en/worktrees#start-claude-in-a-worktree)).
- Учётные данные для CI: ключ API Claude Console, созданный для капстоуна (рекомендуется, потому что при удалении он будет удалён), или, на плане Pro, Max, Team или Enterprise, токен из `claude setup-token` ([Ручная настройка](https://code.claude.com/docs/en/github-actions#manual-setup)).
- На Pro включите динамические рабочие процессы в строке **Dynamic workflows** в `/config` ([Оркестрация субагентов в масштабе с помощью динамических рабочих процессов](https://code.claude.com/docs/en/workflows)).
- macOS, Linux или WSL 2: скрипт ревью написан на bash.
- Использование: интенсивное. Две сессии одновременно, динамический рабочий процесс, скриптовый запуск и запуск в CI. Каждый запуск CI использует ваши минуты GitHub Actions и токены: ключ API оплачивается с вашего аккаунта Console, а токен подписки — из вашего плана ([Управление затратами](https://code.claude.com/docs/en/github-actions#manage-costs)). Дешёвый вариант: начинайте каждую сессию с `--model sonnet` ([Псевдонимы моделей](https://code.claude.com/docs/en/model-config#model-aliases)), добавьте `--model sonnet` в скрипт и в `claude_args` ([Передача аргументов CLI](https://code.claude.com/docs/en/github-actions#pass-cli-arguments)), и пусть динамический рабочий процесс в части 4 проверяет только два файла из `src/`.

## Задание

Команда хочет, чтобы Claude проверял каждый pull request в CI, одинаково на всех машинах, и чтобы ничто из того, что он запускает, не оставалось без ограничений. Задание находится в `capstone/advanced-brief.md` в вашей копии.

Постройте каждую часть так, как учили в соответствующем уроке:

1. **Две сессии одновременно** ([урок 1](01-parallel-sessions.md)). Игнорируйте `.claude/worktrees/` в закоммиченном `.gitignore` и запушьте `main`: новые worktree ответвляются от ветки по умолчанию удалённого репозитория ([Выбор базовой ветки](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)). Затем в двух терминалах одновременно запустите `claude --worktree <name>` дважды, каждый раз с разным именем ([Повторное использование имени worktree](https://code.claude.com/docs/en/worktrees#reuse-a-worktree-name)): одна сессия строит часть 2, другая — часть 3, и каждая коммитит в свою ветку. Когда обе закоммитят и пока оба worktree существуют, сохраните их состояние из основной рабочей копии:

   ```bash
   mkdir -p .practice && git worktree list --porcelain > .practice/a-capstone-worktrees.txt
   ```

   Затем влейте обе ветки в `main` с помощью `git merge`, а не `git merge --squash`, и удалите оба worktree.
2. **Скрипт ревью** ([урок 4](04-headless.md)): `scripts/review-staged.sh`, по критериям урока 4. Он передаёт staged diff в один вызов `claude -p` с JSON-выводом и режимом `dontAsk` ([режим dontAsk](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)), предварительно одобряет только `Read`, `Grep` и `Glob` и ограничивает количество ходов до 10 или меньше ([Флаги CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)). После слияний сделайте stage однострочного изменения в основной рабочей копии, запустите скрипт один раз, прочитайте ревью и закоммитьте изменение:

   ```bash
   mkdir -p .practice && scripts/review-staged.sh .practice/a-capstone-run.json
   ```

   Сохранённый JSON содержит `total_cost_usd` — оценку стоимости одного ревью. Как и в срезе урока 7, это оценка на стороне клиента, а не ваш счёт ([Отслеживание стоимости и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking#estimates-not-billing)).
3. **Плагин команды** ([урок 6](06-share-your-setup.md)): маркетплейс в `team-marketplace/`, который указывает один плагин по относительному пути, при этом плагин находится в собственной папке внутри `team-marketplace/`, как в примере из урока 6, и содержит хотя бы один skill или agent. Закоммиченный `.claude/settings.json` регистрирует маркетплейс по относительному пути и включает плагин ([Требование плагинов для каждого репозитория](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository)). Обе валидации проходят: `claude plugin validate` для маркетплейса и для каталога плагина с `--strict` ([plugin validate](https://code.claude.com/docs/en/plugins/cli-reference#plugin-validate)). Набор — хорошая отправная точка; его [`settings.snippet.json`](../../examples/advanced/06-share-your-setup/settings.snippet.json) также запрещает чтение `.env`, чего в этой копии пока нет. Тестируйте плагин только после слияний: относительный путь разрешается относительно основной рабочей копии репозитория, даже из worktree ([Требование плагинов для каждого репозитория](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository)), поэтому сессия части 3 пока не может его загрузить.
4. **Сохранённый динамический рабочий процесс** ([уроки 2](02-orchestration-patterns.md) и [3](03-dynamic-workflows.md)): из сессии в основной рабочей копии, после слияний, попросите создать рабочий процесс, который проверяет каждый файл в `src/` и имеет второго агента для проверки каждой находки. Пока он работает, `/workflows` показывает использование токенов каждым агентом ([Стоимость](https://code.claude.com/docs/en/workflows#cost)). Сохраните его в проект: сохранение проекта записывает в ближайшую существующую папку `.claude/workflows/` между рабочей директорией сессии и корнем репозитория, или, если её ещё нет, в `.claude/workflows/` в корне репозитория ([Сохранение рабочего процесса для повторного использования](https://code.claude.com/docs/en/workflows#save-the-workflow-for-reuse)). Закоммитьте его.
5. **CI-ревью с ограничениями** ([уроки 5](05-github-actions.md) и [7](07-bounded-runs.md)): `.github/workflows/claude-review.yml` запускается на `pull_request` ([События, запускающие рабочие процессы](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)) и использует `anthropics/claude-code-action` (Anthropic) с `prompt`, который просит ревью изменений pull request ([Параметры действия](https://code.claude.com/docs/en/github-actions#action-parameters)). Соблюдайте ограничения урока 5:
   - действие закреплено за тегом релиза или полным SHA коммита ([Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsuses));
   - учётные данные из секрета репозитория, через соответствующий вход, `anthropic_api_key` или `claude_code_oauth_token` ([Ручная настройка](https://code.claude.com/docs/en/github-actions#manual-setup));
   - токен задания только для чтения: нет прав на запись в `permissions`, кроме `id-token: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions ([Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)), и `github_token` установлен на собственный `GITHUB_TOKEN` задания, чтобы Claude действовал с этим токеном, а не с токеном Claude GitHub App ([Параметры действия](https://code.claude.com/docs/en/github-actions#action-parameters));
   - в `claude_args` `--max-turns` 10 или меньше и список `--allowedTools` без неограниченного Bash;
   - `timeout-minutes` 30 или меньше ([Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)).

   С plain-text prompt у Claude нет оболочки, пока вы не разрешите нужные команды ([Запуск по расписанию](https://code.claude.com/docs/en/github-actions#run-on-a-schedule)). Чтобы он увидел изменения, извлеките полную историю, как это делает `.github/workflows/progress.yml` шаблона, и разрешите `git diff` с помощью `Bash(git diff *)` — правила, которое соответствует только командам `git diff` ([Шаблоны с подстановочными знаками](https://code.claude.com/docs/en/permissions#wildcard-patterns)). Как в prompt среза урока 7 для `npm test`, попросите в `prompt` выполнить `git diff` как отдельную команду: правило должно соответствовать каждой команде в цепочке ([Составные команды](https://code.claude.com/docs/en/permissions#compound-commands)).

   Установите `display_report: true`, как в уроке 5, чтобы ревью Claude появилось на странице сводки запуска ([action.yml на v1.0.237](https://github.com/anthropics/claude-code-action/blob/v1.0.237/action.yml), [Добавление сводки задания](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary)). Действие рекомендует включать это только когда входным данным доверяют, как здесь: pull requests ваши собственные, в приватной копии.

   Добавьте учётные данные как секрет репозитория, как во втором шаге [Ручной настройки](https://code.claude.com/docs/en/github-actions#manual-setup) документации: выполните `gh secret set ANTHROPIC_API_KEY` или `gh secret set CLAUDE_CODE_OAUTH_TOKEN` и вставьте значение, когда попросят ([gh secret set](https://cli.github.com/manual/gh_secret_set)). Никогда не коммитьте учётные данные; храните их в секрете репозитория ([Защита учётных данных](https://code.claude.com/docs/en/github-actions#protect-your-credentials)). Пропустите остальные шаги ручной настройки: действие аутентифицируется как Claude GitHub App только когда `github_token` опущен ([Параметры действия](https://code.claude.com/docs/en/github-actions#action-parameters)), а ваш рабочий процесс ревью заменяет его `claude.yml`.

   Закоммитьте рабочий процесс в `main` и запушьте. Затем запушьте однострочное изменение в новой ветке и откройте pull request. Прочитайте ревью Claude на странице сводки запуска, как в уроке 5, и влейте pull request самостоятельно.

Завершите на `main`, с влитым pull request, всё закоммичено и `npm test` проходит.

Списки проверены по панели списков 2026-10-09.

## Проверка

Вы закончили, когда все эти пункты истинны:

- [ ] Закоммиченный `.gitignore` игнорирует `.claude/worktrees/` и не игнорирует остальную часть `.claude/`.
- [ ] `.practice/a-capstone-worktrees.txt` перечисляет два worktree в `.claude/worktrees/`, чьи коммиты разошлись друг от друга, и оба влиты в вашу ветку.
- [ ] Закоммиченный скрипт в `.claude/workflows/` имеет буквальный `export const meta` с `name` и `description` в качестве первого оператора и запускает субагентов с помощью `agent()`.
- [ ] `scripts/review-staged.sh` закоммичен и исполняемый.
- [ ] Его вызов `claude -p` запрашивает JSON, работает в режиме `dontAsk`, предварительно одобряет только `Read`, `Grep` и `Glob`, ограничивает ходы до 10 или меньше, и prompt стоит сразу после `-p`.
- [ ] Он передаёт staged diff по pipe, сохраняет JSON туда, куда указывает аргумент, печатает результат, завершается с ненулевым кодом при сбое запуска и не вызывает Claude, когда ничего не staged.
- [ ] `.practice/a-capstone-run.json` содержит запуск, который успешно завершился в пределах вашего лимита.
- [ ] Закоммиченный рабочий процесс запускает `anthropics/claude-code-action` на `pull_request`, закреплён за тегом релиза или полным SHA коммита, в режиме автоматизации, с учётными данными из секрета и без них в файле, с токеном задания только для чтения (нет прав на запись в `permissions`, кроме `id-token: write, и `github_token` установлен на собственный токен задания), `--max-turns` 10 или меньше, списком `--allowedTools` без неограниченного Bash и `timeout-minutes` 30 или меньше.
- [ ] Ни один ключ API Claude или токен не закоммичен, ни в `HEAD`, ни в коммите, из которого проверка читает ваш рабочий процесс.
- [ ] Закоммиченный командный маркетплейс указывает плагин по относительному пути, и имя записи совпадает с `name` в `plugin.json` плагина.
- [ ] Закоммиченный `.claude/settings.json` регистрирует этот маркетплейс по относительному пути и включает плагин.
- [ ] `npm test` проходит, и `git status --porcelain` ничего не печатает.

Запустите `npm run check -- a-capstone` в этой копии. Каждый непройденный пункт печатает, что исправить. Проверка запускает ваш скрипт с заменой для `claude`, поэтому не использует ваши ресурсы, и читает рабочий процесс из вашей истории, поэтому проходит и до, и после удаления.

## Что проверка не видит

Проверка не смотрит на эти части продвинутого выхода. Отметьте их сами, честно:

- [ ] Я запускал обе сессии worktree одновременно, и ни одна не видела незакоммиченные правки другой.
- [ ] Я могу провести пофайловое ревью со вторым агентом, проверяющим каждую находку, через вопросы урока 2 и объяснить, почему они заканчиваются динамическим рабочим процессом, а не субагентами в одном разговоре.
- [ ] Я могу сказать, когда автоматическому запуску нужна песочница из [урока 7](07-bounded-runs.md), и нужна ли она моему скрипту ревью и CI-рабочему процессу.
- [ ] Я видел запуск CI на своём pull request и прочитал ревью Claude на его странице сводки до того, как влил.
- [ ] Новая сессия в основной рабочей копии, после слияний, загрузила мой командный плагин без команды установки.
- [ ] Прежде чем включить CI, я использовал `total_cost_usd` локального запуска, как урок 7 использовал свой срез, чтобы оценить, сколько тратит одно ревью в CI, и увидел в `/workflows`, сколько токенов использовало пофайловое ревью.

Когда все галочки на этой странице отмечены, вы продемонстрировали продвинутый выход и завершили последний из трёх уровней руководства. Остался один шаг: удаление ниже.

Если этот уровень помог, звезда поможет другим разработчикам найти руководство.

## Удаление

Когда проверка пройдена, удалите: это обязательно.

> [!WARNING]
> Пока вы не удалите, действующие учётные данные лежат в секретах копии. Удаление секрета оставляет учётные данные, которые он содержал, действительными ([Удаление](https://code.claude.com/docs/en/github-actions#uninstall)). На 2026-10-09 токен из `claude setup-token` действителен один год ([Аутентификация](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token)), и удаление секрета не отзывает его.

1. Удалите рабочий процесс с помощью `git rm .github/workflows/claude-review.yml`, затем закоммитьте и запушьте. Когда рабочий процесс удалён, Claude Code GitHub Action больше не запускается ([Удаление](https://code.claude.com/docs/en/github-actions#uninstall)).
2. Удалите секрет: `gh secret delete ANTHROPIC_API_KEY` или `gh secret delete CLAUDE_CODE_OAUTH_TOKEN` ([gh secret delete](https://cli.github.com/manual/gh_secret_delete)). `gh secret list` больше не показывает его ([gh secret list](https://cli.github.com/manual/gh_secret_list)).
3. Если использовался ключ API, удалите ключ на странице [API keys](https://platform.claude.com/settings/keys) Claude Console.

Запустите `npm run check -- a-capstone` ещё раз: он всё ещё проходит.

---

<sub>Источники: [Запуск параллельных сессий с worktrees](https://code.claude.com/docs/en/worktrees) · [Оркестрация субагентов в масштабе с помощью динамических рабочих процессов](https://code.claude.com/docs/en/workflows) · [Отслеживание стоимости и использования](https://code.claude.com/docs/en/agent-sdk/cost-tracking) · [Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes) · [Справочник CLI](https://code.claude.com/docs/en/cli-reference) · [Конфигурация моделей](https://code.claude.com/docs/en/model-config) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference) · [Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org) · [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions) · [Аутентификация](https://code.claude.com/docs/en/authentication) · claude-code-action на v1.0.237: [action.yml](https://github.com/anthropics/claude-code-action/blob/v1.0.237/action.yml) · GitHub: [События, запускающие рабочие процессы](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [Синтаксис рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [Команды рабочего процесса](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands) · Руководство GitHub CLI: [gh repo create](https://cli.github.com/manual/gh_repo_create), [gh secret set](https://cli.github.com/manual/gh_secret_set), [gh secret delete](https://cli.github.com/manual/gh_secret_delete), [gh secret list](https://cli.github.com/manual/gh_secret_list) · [продвинутые уроки](README.md), которые цитируют официальные страницы для каждого шага.</sub>

<sub>← [Ограничьте автономные запуски](07-bounded-runs.md) · [Продвинутый индекс](README.md) · [За пределами этого руководства](beyond-this-guide.md) → · [Застряли на этом капстоуне?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-capstone)</sub>
