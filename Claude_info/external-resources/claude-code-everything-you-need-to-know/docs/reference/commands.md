<a id="slash-commands--cheatsheet"></a>
# Команды по уровням

<sub>Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

Встроенные команды, входящие в комплект навыки и рабочие процессы, а также формы командной строки `claude`, используемые в уроках, сгруппированы по уровню, на котором они изучаются. Это не полный список: официальный [справочник команд](https://code.claude.com/docs/en/commands#all-commands) содержит все команды и их параметры, [справочник CLI](https://code.claude.com/docs/en/cli-reference#cli-flags) — флаги командной строки, а ввод `/` в сеансе показывает доступные вам команды.

<a id="common-built-in-slash-commands"></a>
## Начинающий

- `/status`: ваша версия, модель, аккаунт и подключение. [Установка, вход и осмотр](../beginner/01-install-and-look-around.md)
- `/exit`: завершить сеанс. [Установка, вход и осмотр](../beginner/01-install-and-look-around.md)
- `/plan`: войти в режим планирования из подсказки, при необходимости с задачей. [Режимы разрешений и режим планирования](../beginner/02-permission-modes-and-plan-mode.md)
- `/diff`: просмотреть изменения в рабочем дереве, включая правки Claude. [Ваше первое изменение, от запроса до коммита](../beginner/03-first-change.md)
- `/context`: насколько заполнено окно контекста, в виде цветной сетки. [Держите сеанс в нужном русле](../beginner/04-keep-a-session-on-track.md)
- `/clear`: начать новый разговор с пустым контекстом. [Держите сеанс в нужном русле](../beginner/04-keep-a-session-on-track.md)
- `/compact`: суммировать разговор до сих пор, чтобы освободить контекст. [Держите сеанс в нужном русле](../beginner/04-keep-a-session-on-track.md)
- `/rewind`: вернуться к более ранней точке разговора, кода или к обоим ([Контрольные точки](https://code.claude.com/docs/en/checkpointing)). [Держите сеанс в нужном русле](../beginner/04-keep-a-session-on-track.md)
- `/resume`: продолжить более ранний разговор ([Управление сеансами](https://code.claude.com/docs/en/sessions)). [Держите сеанс в нужном русле](../beginner/04-keep-a-session-on-track.md)
- `/init`: написать начальный `CLAUDE.md` для проекта. [Память проекта с CLAUDE.md](../beginner/05-project-memory.md)
- `/memory`: редактировать файлы `CLAUDE.md` и управлять автоматической памятью. [Память проекта с CLAUDE.md](../beginner/05-project-memory.md)

Элективы: `/powerup` и `/output-style` ([встроенные учителя](../beginner/electives/built-in-teachers.md)).

## Средний

- `/skills`: перечислить навыки, доступные в этом сеансе. [Превратите повторяющийся рабочий процесс в навык](../intermediate/01-first-skill.md)
- `/doctor`: проверить вашу настройку; `/doctor prompt-audit` проверяет ваши файлы инструкций. [Организуйте память проекта и посмотрите, что загрузилось](../intermediate/02-organize-memory.md)
- `/model`: переключить модель и сохранить её как модель по умолчанию; для моделей, которые это поддерживают, клавиши со стрелками влево и вправо регулируют усилие. [Выберите модель и усилие](../intermediate/03-model-and-effort.md)
- `/effort`: установить уровень усилия. [Выберите модель и усилие](../intermediate/03-model-and-effort.md)
- `/permissions`: управлять правилами allow, ask и deny. [Разрешения, области настроек и песочница](../intermediate/04-permissions-and-sandbox.md)
- `/sandbox`: включить или выключить песочницу. [Разрешения, области настроек и песочница](../intermediate/04-permissions-and-sandbox.md)
- `/hooks`: посмотреть, какие хуки настроены. [Обеспечьте соблюдение правила с помощью хука](../intermediate/05-hooks.md)
- `/agents`: напоминание о том, как создавать и управлять субагентами. [Делегируйте пользовательскому субагенту](../intermediate/06-subagents.md)
- `/mcp`: управлять подключениями к серверам MCP и входами в систему. [Подключите инструмент с помощью MCP](../intermediate/07-mcp.md)
- `/plugin`: просматривать, устанавливать и управлять плагинами. [Установка и управление плагинами](../intermediate/08-plugins.md)

Элективы: `/statusline` ([Строка состояния](../intermediate/electives/status-line.md)); `/chrome` ([Claude в Chrome](../intermediate/electives/claude-in-chrome.md)); `/fast` ([Быстрый режим](../intermediate/electives/fast-mode.md)).

## Продвинутый

- `claude --worktree <name>` (`-w`): начать сеанс в изолированном git worktree в `.claude/worktrees/<name>` ([справочник CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)). [Параллельные сеансы с worktrees](../advanced/01-parallel-sessions.md)
- `/tasks`: просматривать и управлять фоновой работой в этом сеансе, включая завершённых субагентов. [Выберите паттерн оркестрации](../advanced/02-orchestration-patterns.md)
- `/workflows`: наблюдать, приостанавливать, возобновлять и сохранять динамические рабочие процессы. [Запустите и сохраните динамический рабочий процесс](../advanced/03-dynamic-workflows.md)
- `/deep-research <question>`: входящий в комплект рабочий процесс, который распараллеливает веб-поиск по вопросу, перекрёстно проверяет источники и пишет отчёт с цитатами. [Запустите и сохраните динамический рабочий процесс](../advanced/03-dynamic-workflows.md)
- `claude -p "<prompt>"`: выполнить одну подсказку без интерактивного интерфейса, вывести ответ и выйти; скрипт добавляет `--output-format json`, `--allowedTools` и `--max-turns` ([справочник CLI](https://code.claude.com/docs/en/cli-reference#cli-commands)). [Скриптуйте Claude Code с помощью `claude -p`](../advanced/04-headless.md)
- `/install-github-app`: установить Claude GitHub App для репозитория, с необязательной настройкой рабочего процесса и секретов. [GitHub Actions](../advanced/05-github-actions.md)
- `claude plugin validate <dir>`: проверить marketplace или папку плагина перед публикацией; `--strict` также завершается с ошибкой при предупреждениях ([справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference#plugin-validate)). [Поделитесь своей настройкой с командой](../advanced/06-share-your-setup.md)
- `/usage`: стоимость сеанса, лимиты использования вашего плана и статистика активности. [Ограничьте автономные запуски](../advanced/07-bounded-runs.md)

Элективы: `claude agents` и `/background` ([Представление агентов](../advanced/electives/agent-view.md)); `/goal`, `/loop` и `/schedule` ([`/goal`, `/loop` и рутины](../advanced/electives/goal-loop-routines.md)); `claude plugin eval` ([Тестирование и публикация плагина](../advanced/electives/publish-a-plugin.md)).

<a id="custom-slash-commands-skills"></a>
## Ваши собственные команды

Команда, которую вы пишете сами, — это навык: файл `SKILL.md` в `.claude/skills/<name>/` или Markdown-файл в `.claude/commands/`, более старый формат ([Расширение Claude с помощью навыков](https://code.claude.com/docs/en/skills)). Урок среднего уровня [Превратите повторяющийся рабочий процесс в навык](../intermediate/01-first-skill.md) обучает им.

## Горячие клавиши и шпаргалки

- [Интерактивный режим](https://code.claude.com/docs/en/interactive-mode): сочетания клавиш, режимы ввода и интерактивные функции.
- [Шпаргалка Claude Code](https://support.claude.com/en/articles/14553413-claude-code-cheatsheet): команды и сочетания клавиш, которые стоит выучить в первую очередь.

---

<sub>Источники: [Команды](https://code.claude.com/docs/en/commands) · [Справочник CLI](https://code.claude.com/docs/en/cli-reference) · [Контрольные точки](https://code.claude.com/docs/en/checkpointing) · [Управление сеансами](https://code.claude.com/docs/en/sessions) · [Расширение Claude с помощью навыков](https://code.claude.com/docs/en/skills) · [Интерактивный режим](https://code.claude.com/docs/en/interactive-mode) · [Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference) · [Шпаргалка Claude Code](https://support.claude.com/en/articles/14553413-claude-code-cheatsheet)</sub>

<sub>Вверх: [Справочник](README.md)</sub>
