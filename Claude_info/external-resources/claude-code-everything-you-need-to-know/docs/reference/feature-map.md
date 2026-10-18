# Карта функций

<sub>Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

Каждая текущая функция и поверхность Claude Code, с которой может столкнуться учащийся, с её меткой стабильности, как она указана в документации, и планами или провайдерами, у которых она есть. Каждая функция ссылается на свою официальную страницу и, где урок или Elective её преподаёт, на страницы руководства, которые её преподают. О том, что изменилось недавно, смотрите официальный [CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) и [What's new](https://code.claude.com/docs/en/whats-new).

Как это читать:

- **Метка** цитирует предложение, где документация помечает функцию как beta, research preview или experimental. Прочерк означает, что в документации нет метки.
- **Кому доступно** взято из [Feature availability](https://code.claude.com/docs/en/feature-availability) или со страницы самой функции, если на той странице нет строки. "Каждый провайдер" означает подписку Claude, Claude Console, Claude Platform на AWS, Amazon Bedrock, Google Cloud Agent Platform и Microsoft Foundry одинаково: CLI и всё, что работает локально, работает на всех них.
- В руководстве нет цен или лимитов использования; смотрите [claude.com/pricing](https://claude.com/pricing).

## Где вы это запускаете

| Функция | Метка | Кому доступно |
|---|---|---|
| [Терминал](https://code.claude.com/docs/en/quickstart); преподаётся в [Установка, вход и осмотр](../beginner/01-install-and-look-around.md) | – | Каждый провайдер |
| [VS Code](https://code.claude.com/docs/en/vs-code); преподаётся в [Расширения IDE](../beginner/electives/ide-extensions.md) | – | Каждый провайдер |
| [JetBrains IDE](https://code.claude.com/docs/en/jetbrains); преподаётся в [Расширения IDE](../beginner/electives/ide-extensions.md) | На странице нет предложения с меткой, но путь настроек гласит "Claude Code [Beta]" | Каждый провайдер |
| [Настольное приложение](https://code.claude.com/docs/en/desktop) | На Linux: "Поддержка Linux для настольного приложения Claude находится в beta." ([Linux](https://code.claude.com/docs/en/desktop-linux)) | Подписка Claude; на Bedrock, Agent Platform и Foundry через Claude Desktop у этих провайдеров |
| [Облачные сессии в вебе](https://code.claude.com/docs/en/claude-code-on-the-web) | – | Pro, Max и Team; Enterprise с premium или Chat + Claude Code seat |
| [Мобильный](https://code.claude.com/docs/en/mobile) | – | Подписка Claude |
| [Remote Control](https://code.claude.com/docs/en/remote-control) | – | Pro и Max; Team и Enterprise, когда администратор включит |
| [Claude Code в Slack](https://code.claude.com/docs/en/slack) | – | Pro и Max, в рабочем пространстве Slack, которое ни одна организация не подключила к Claude Tag; Team и Enterprise используют Claude Tag |
| [Claude Tag](https://claude.com/docs/claude-tag/overview) | На странице помечено "Public Beta" | Team и Enterprise, на собственном сервисе Anthropic |
| [Claude в Chrome](https://code.claude.com/docs/en/chrome); преподаётся в [Claude в Chrome](../intermediate/electives/claude-in-chrome.md) | – | Pro, Max, Team или Enterprise |
| [Computer use](https://code.claude.com/docs/en/computer-use) | "Computer use — это research preview на macOS, требующий план Pro или Max." | Pro и Max |
| [Dispatch](https://code.claude.com/docs/en/desktop#sessions-from-dispatch) | – | Pro и Max |
| [Голосовой ввод](https://code.claude.com/docs/en/voice-dictation) | – | Подписка Claude |

## В сессии

| Функция | Метка | Кому доступно |
|---|---|---|
| [Plan mode](https://code.claude.com/docs/en/permission-modes); преподаётся в [Режимы разрешений и plan mode](../beginner/02-permission-modes-and-plan-mode.md) | – | Каждый провайдер |
| [Auto mode](https://code.claude.com/docs/en/permission-modes); преподаётся в [Режимы разрешений и plan mode](../beginner/02-permission-modes-and-plan-mode.md) | – | Подписка Claude, Console и Claude Platform на AWS; на Bedrock, Agent Platform и Foundry только с новыми моделями. Администраторы Team и Enterprise могут отключить |
| [Контрольные точки и откат](https://code.claude.com/docs/en/checkpointing); преподаётся в [Держите сессию в курсе](../beginner/04-keep-a-session-on-track.md) | – | Каждый провайдер |
| [Память CLAUDE.md](https://code.claude.com/docs/en/memory); преподаётся в [Память проекта с CLAUDE.md](../beginner/05-project-memory.md) и [Организуйте память проекта и смотрите, что загружено](../intermediate/02-organize-memory.md) | – | Каждый провайдер |
| [Песочница](https://code.claude.com/docs/en/sandboxing); преподаётся в [Разрешения, области настроек и песочница](../intermediate/04-permissions-and-sandbox.md) и [Ограничьте автономные запуски](../advanced/07-bounded-runs.md) | – | Каждый провайдер |
| [Стили вывода](https://code.claude.com/docs/en/output-styles); преподаётся в [встроенные учителя](../beginner/electives/built-in-teachers.md) | – | Каждый провайдер |
| [Строка состояния](https://code.claude.com/docs/en/statusline); преподаётся в [Строка состояния](../intermediate/electives/status-line.md) | – | Каждый провайдер |
| [`/goal`](https://code.claude.com/docs/en/goal); преподаётся в [`/goal`, `/loop` и routines](../advanced/electives/goal-loop-routines.md) | – | Каждый провайдер |
| [`/powerup`](https://code.claude.com/docs/en/commands); преподаётся в [встроенные учителя](../beginner/electives/built-in-teachers.md) | – | В документации не указано ограничений |
| [Fast mode](https://code.claude.com/docs/en/fast-mode); преподаётся в [Fast mode](../intermediate/electives/fast-mode.md) | "Fast mode находится в research preview." | Подписка Claude, оплачиваемая кредитами использования (Owner включает для Team и Enterprise), и организации Console с предоставленным доступом; не Claude Platform на AWS, Bedrock, Agent Platform или Foundry |
| [Advisor](https://code.claude.com/docs/en/advisor) | "Инструмент advisor экспериментальный и требует Anthropic API." | Подписка Claude и Console |
| [Веб-поиск](https://code.claude.com/docs/en/tools-reference#websearch-tool-behavior) | – | Подписка Claude, Console, Claude Platform на AWS и Foundry; на Agent Platform с Opus 4, Sonnet 4, Haiku 4.5 и более поздними моделями; не Bedrock |

## Расширение Claude Code

| Функция | Метка | Кому доступно |
|---|---|---|
| [Skills](https://code.claude.com/docs/en/skills); преподаётся в [Превратите повторяющийся рабочий процесс в skill](../intermediate/01-first-skill.md) и [Паттерны skill](../intermediate/electives/skill-patterns.md) | – | Каждый провайдер |
| [Hooks](https://code.claude.com/docs/en/hooks-guide); преподаётся в [Обеспечьте правило с помощью hook](../intermediate/05-hooks.md) | – | Каждый провайдер |
| [Agent hooks](https://code.claude.com/docs/en/hooks-guide#agent-based-hooks) | "Agent hooks экспериментальны." | Как для hooks |
| [Subagents](https://code.claude.com/docs/en/sub-agents); преподаётся в [Делегируйте пользовательскому subagent](../intermediate/06-subagents.md) и [Выберите паттерн оркестрации](../advanced/02-orchestration-patterns.md) | – | Каждый провайдер |
| [MCP](https://code.claude.com/docs/en/mcp); преподаётся в [Подключите инструмент с MCP](../intermediate/07-mcp.md) | – | Каждый провайдер; коннекторы claude.ai только при входе с подпиской Claude |
| [Плагины и маркетплейсы](https://code.claude.com/docs/en/plugins/overview); преподаётся в [Установка и управление плагинами](../intermediate/08-plugins.md), [Поделитесь настройкой с командой](../advanced/06-share-your-setup.md) и [Тестирование и публикация плагина](../advanced/electives/publish-a-plugin.md) | – | Каждый провайдер |
| [Channels](https://code.claude.com/docs/en/channels) | "Channels находятся в research preview." | Подписка Claude (Team и Enterprise, когда администратор включит) и Console; не Claude Platform на AWS, Bedrock, Agent Platform или Foundry |
| [Dev containers](https://code.claude.com/docs/en/devcontainer); преподаётся в [Dev containers](../advanced/electives/dev-containers.md) | – | Каждый провайдер |

## Параллельная и автономная работа

| Функция | Метка | Кому доступно |
|---|---|---|
| [Worktrees](https://code.claude.com/docs/en/worktrees); преподаётся в [Параллельные сессии с worktrees](../advanced/01-parallel-sessions.md) | – | Каждый провайдер |
| [Динамические рабочие процессы](https://code.claude.com/docs/en/workflows); преподаётся в [Запуск и сохранение динамического рабочего процесса](../advanced/03-dynamic-workflows.md) | – | Каждый провайдер; на Pro включите их в `/config` |
| [Agent view](https://code.claude.com/docs/en/agent-view); преподаётся в [Agent view](../advanced/electives/agent-view.md) | "Agent view находится в research preview." | Каждый провайдер ([Настройки и провайдер](https://code.claude.com/docs/en/agent-view#settings-and-provider)) |
| [Agent teams](https://code.claude.com/docs/en/agent-teams); преподаётся в [Agent teams](../advanced/electives/agent-teams.md) | "Agent teams экспериментальны и отключены по умолчанию." | Каждый провайдер |
| [Обмен сообщениями между сессиями](https://code.claude.com/docs/en/cross-session-messaging) | – | Подписка Claude; в других местах только между сессиями на одной машине |
| [Projects](https://code.claude.com/docs/en/claude-projects) | "Projects находятся в публичной beta на планах Pro и Max и разворачиваются постепенно …" | Pro и Max; пока не Team или Enterprise |
| [`/loop` и запланированные подсказки](https://code.claude.com/docs/en/scheduled-tasks); преподаётся в [`/goal`, `/loop` и routines](../advanced/electives/goal-loop-routines.md) | – | Каждый провайдер |
| [Routines](https://code.claude.com/docs/en/routines); преподаётся в [`/goal`, `/loop` и routines](../advanced/electives/goal-loop-routines.md) | "Routines находятся в research preview." | Pro, Max, Team и Enterprise |
| [Запуск Claude Code из скриптов](https://code.claude.com/docs/en/headless); преподаётся в [Скриптуйте Claude Code с `claude -p`](../advanced/04-headless.md) и [Ограничьте автономные запуски](../advanced/07-bounded-runs.md) | – | Каждый провайдер |
| [GitHub Actions](https://code.claude.com/docs/en/github-actions); преподаётся в [GitHub Actions](../advanced/05-github-actions.md) | – | Подписка Claude, Console, Bedrock, Agent Platform и Foundry; не Claude Platform на AWS |
| [GitLab CI/CD](https://code.claude.com/docs/en/gitlab-ci-cd) | "Claude Code для GitLab CI/CD в настоящее время в beta." | Каждый провайдер, кроме Microsoft Foundry |

## Обзор и безопасность

| Функция | Метка | Кому доступно |
|---|---|---|
| [Code Review](https://code.claude.com/docs/en/code-review) | "Code Review находится в research preview, доступен для подписок Team и Enterprise." | Team и Enterprise |
| [Ultrareview](https://code.claude.com/docs/en/ultrareview) | "Ultrareview — это функция research preview." | Подписка Claude |
| [Плагин руководства по безопасности](https://code.claude.com/docs/en/security-guidance) | – | Все планы; требуется Python 3.7 или новее, и 3.10 или новее для агентного обзора коммитов и, на стороннем провайдере, для каждого обзора на основе модели |
| [Claude Security](https://code.claude.com/docs/en/claude-security) | – | Платный план, доступ к Anthropic API или сторонний провайдер |

## Прочее

| Функция | Метка | Кому доступно |
|---|---|---|
| [Artifacts](https://code.claude.com/docs/en/artifacts) | – | Pro, Max, Team и Enterprise, на Anthropic API |
| [`/design` и `/slides` шаблоны](https://code.claude.com/docs/en/artifacts#start-from-a-slides-design-or-docs-template) | "Шаблоны находятся в beta." | Включены по умолчанию на Pro, Max и Team; на Enterprise Owner включает каждый шаблон |

---

<sub>Источники: [Feature availability](https://code.claude.com/docs/en/feature-availability) и страница каждой функции по ссылке, проверено 2026-10-05.</sub>

<sub>Вверх: [Reference](README.md)</sub>
