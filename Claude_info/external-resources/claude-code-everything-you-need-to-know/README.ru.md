# Claude Code: всё, что вам нужно знать <img src="assets/brand/claude-jumping.svg" width="44" height="40" alt="Анимированный Claude" align="right" />

**Изучите Claude Code на трёх уровнях: от первой сессии до автономных запусков с несколькими агентами.**

Вы учитесь на практике: каждый основной урок и итоговый проект заканчиваются проверкой, которую вы запускаете в своей учебной копии, а каждый урок для начинающих и среднего уровня, включая итоговые проекты, пошагово выполняется в терминальном приложении рядом с Claude Code.
**[Попробуйте сейчас](#try-it-now)** · [Выберите свой уровень](#pick-your-level) · [Все страницы](#everything-in-the-guide)

[![Проверено с Claude Code v2.1.285 (stable)](https://img.shields.io/badge/verified-v2.1.285_stable-2e6e57)](CHANGELOG.md#v202610---2026-10-05) [![Дата выпуска издания](https://img.shields.io/github/release-date/wesammustafa/Claude-Code-Everything-You-Need-to-Know?label=edition&color=2e6e57)](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/releases/latest) [![Лицензия: MIT](https://img.shields.io/badge/license-MIT-5b6470)](LICENSE) [![Упоминается в Awesome Claude Code](https://awesome.re/mentioned-badge.svg)](https://github.com/hesreallyhim/awesome-claude-code)

<p align="center">
  <!-- Захвачено с Claude Code v2.1.292 (stable) 2026-10-17. -->
  <img src="assets/readme/learn-welcome.gif" width="640" alt="Пип, маскот приложения, просыпается, смотрит влево, вправо и вверх, улыбается, затем отдыхает рядом с приветствием. Вы держите два терминала открытыми рядом: в этом запускается npm run learn, показывает по одному шагу и проверяет вашу работу, а в другом вы вводите команды и запускаете Claude Code." />
  <br />
  <sub>Учебное приложение, <code>npm run learn</code>, при первом запуске.</sub>
</p>

<a id="install"></a>
## Попробуйте сейчас

Вам понадобится платный план Claude (Pro, Max, Team или Enterprise), аккаунт Claude Console или поддерживаемый облачный провайдер ([Quickstart](https://code.claude.com/docs/en/quickstart)), а также Node.js LTS и git.

1. Создайте свою учебную копию: откройте [claude-code-practice](https://github.com/wesammustafa/claude-code-practice), выберите **Use this template** > **Create a new repository** и склонируйте свою копию. Или откройте свою копию в Codespace, где Node.js и Claude Code уже предустановлены.
2. В своей копии запустите приложение:

   ```bash
   npm run learn
   ```

3. Откройте второй терминал в той же папке. Приложение подскажет, что вводить, начиная с установки Claude Code, и будет проверять вашу работу по ходу.

Приложение обучает каждому уроку для начинающих и среднего уровня и обоим итоговым проектам. В нём нет ИИ, и оно не изменяет вашу работу.

Для продвинутого уровня или если вы предпочитаете читать, каждый урок работает только со своей страницы. Каждый основной урок заканчивается проверкой, которую вы запускаете из своей учебной копии, например `npm run check -- b-1`: каждый пункт выводит `PASS` или `FAIL` с подсказкой, что исправить.

## Помощь, которая исчезает по мере обучения

Помощь сокращается каждый раз, когда навык возвращается: GUIDED показывает каждую команду, HINTED даёт цель и подсказку при каждом нажатии `h`, а CHALLENGE — только цель.

<table>
  <tr>
    <td width="50%" valign="top"><img src="assets/readme/learn-help-guided.png" width="380" alt="На шаге 1 приложение называет окно для ввода, объясняет словами урока и показывает точную команду установки." /></td>
    <td width="50%" valign="top"><img src="assets/readme/learn-help-challenge.png" width="380" alt="К шагу 11 приложение даёт только цель и правило урока, а из git status сообщает, что в копии ещё ничего не изменилось." /></td>
  </tr>
  <tr>
    <td><b>Шаг 1 из 12, GUIDED:</b> точная команда и окно для её ввода.</td>
    <td><b>Шаг 11 из 12, CHALLENGE:</b> только цель, пока приложение следит за вашей копией.</td>
  </tr>
</table>

<!-- Оба захвачены с Claude Code v2.1.292 (stable) 2026-10-17. -->
<sub>Урок 1 для начинающих, шаги 1 и 11.</sub>

<a id="-choose-your-path"></a>
## Выберите свой уровень

### Начинающий
**Для вас, если** вы новичок в Claude Code и уверенно работаете с терминалом и git.
Вы проведёте одно изменение от запроса до коммита, безопасно, и дадите своему проекту память. Около 2,5 часов: 5 уроков, итоговый проект и 3 факультатива.
**[Начать уровень «Начинающий»](docs/beginner/README.md)**

### Средний
**Готовы, если** можете спланировать изменение в режиме плана, просмотреть diff и закоммитить его, а также удерживать длинную сессию в нужном русле.
Вы настроите Claude Code под свой проект с помощью skills, hooks, subagents, MCP и plugins. Около 3 часов: 8 уроков, итоговый проект и 4 факультатива.
**[Начать уровень «Средний»](docs/intermediate/README.md)**

### Продвинутый
**Готовы, если** можете написать project skill, enforce правило с помощью hook, делегировать задачу subagent и подключить MCP-сервер.
Вы будете запускать Claude Code параллельно, автономно в CI и для команды, в заданных вами пределах. Около 3 часов 20 минут плюс время выполнения: 7 уроков, итоговый проект и 5 факультативов.
**[Начать уровень «Продвинутый»](docs/advanced/README.md)**

<a id="-whats-inside"></a><a id="-reading-tips"></a>
## Всё в гайде

<details>
<summary>Все страницы по уровням</summary>

**Начинающий:** [Индекс уровня](docs/beginner/README.md) · [Установка, вход и осмотр](docs/beginner/01-install-and-look-around.md) · [Режимы разрешений и режим плана](docs/beginner/02-permission-modes-and-plan-mode.md) · [Ваше первое изменение, от запроса до коммита](docs/beginner/03-first-change.md) · [Удержание сессии в нужном русле](docs/beginner/04-keep-a-session-on-track.md) · [Память проекта с CLAUDE.md](docs/beginner/05-project-memory.md) · [Итоговый проект](docs/beginner/capstone.md)

**Факультативы для начинающих:** [Расширения IDE](docs/beginner/electives/ide-extensions.md) · [Скриншоты и изображения](docs/beginner/electives/screenshots-and-images.md) · [Встроенные учителя](docs/beginner/electives/built-in-teachers.md)

**Средний:** [Индекс уровня](docs/intermediate/README.md) · [Превращение повторяющегося рабочего процесса в skill](docs/intermediate/01-first-skill.md) · [Организация памяти проекта и просмотр загруженного](docs/intermediate/02-organize-memory.md) · [Выбор модели и усилия](docs/intermediate/03-model-and-effort.md) · [Разрешения, области настроек и песочница](docs/intermediate/04-permissions-and-sandbox.md) · [Обеспечение правила с помощью hook](docs/intermediate/05-hooks.md) · [Делегирование пользовательскому subagent](docs/intermediate/06-subagents.md) · [Подключение инструмента через MCP](docs/intermediate/07-mcp.md) · [Установка и управление plugins](docs/intermediate/08-plugins.md) · [Итоговый проект](docs/intermediate/capstone.md)

**Факультативы для среднего уровня:** [Паттерны skills](docs/intermediate/electives/skill-patterns.md) · [Claude в Chrome](docs/intermediate/electives/claude-in-chrome.md) · [Строка состояния](docs/intermediate/electives/status-line.md) · [Fast mode](docs/intermediate/electives/fast-mode.md)

**Продвинутый:** [Индекс уровня](docs/advanced/README.md) · [Параллельные сессии с worktrees](docs/advanced/01-parallel-sessions.md) · [Выбор паттерна оркестрации](docs/advanced/02-orchestration-patterns.md) · [Запуск и сохранение динамического рабочего процесса](docs/advanced/03-dynamic-workflows.md) · [Скриптование Claude Code с `claude -p`](docs/advanced/04-headless.md) · [GitHub Actions](docs/advanced/05-github-actions.md) · [Общий доступ к вашей настройке для команды](docs/advanced/06-share-your-setup.md) · [Ограничения автономных запусков](docs/advanced/07-bounded-runs.md) · [Итоговый проект](docs/advanced/capstone.md) · [За пределами этого гайда](docs/advanced/beyond-this-guide.md)

**Факультативы для продвинутых:** [Команды агентов](docs/advanced/electives/agent-teams.md) · [Agent view](docs/advanced/electives/agent-view.md) · [`/goal`, `/loop` и routines](docs/advanced/electives/goal-loop-routines.md) · [Тестирование и публикация plugin](docs/advanced/electives/publish-a-plugin.md) · [Dev containers](docs/advanced/electives/dev-containers.md)

**Темы:** [Все темы](docs/topics/README.md) · [Разрешения и безопасность](docs/topics/permissions-and-safety.md) · [Память и контекст](docs/topics/memory-and-context.md) · [Модели, усилия и стоимость](docs/topics/models-effort-and-cost.md) · [Skills](docs/topics/skills.md) · [Hooks](docs/topics/hooks.md) · [Subagents и параллельная работа](docs/topics/subagents-and-parallel-work.md) · [MCP](docs/topics/mcp.md) · [Plugins](docs/topics/plugins.md) · [Автоматизация](docs/topics/automation.md)

**Справочник:** [Индекс справочника](docs/reference/README.md) · [Модели и усилия](docs/reference/models.md) · [Команды по уровням](docs/reference/commands.md) · [Карта функций](docs/reference/feature-map.md) · [Дальнейшее обучение](docs/reference/further-reading.md) · [Глоссарий](docs/reference/glossary.md) · [Журнал изменений](docs/reference/changelog.md)

**Примеры:** [Как использовать примеры](examples/README.md)

</details>

<a id="how-the-guide-stays-current"></a>
<details>
<summary>Как гайд остаётся актуальным</summary>

- Каждая страница урока несёт штамп: версию Claude Code `stable`, с которой сверялись утверждения, и дату ([Штамп](CONTRIBUTING.md#the-stamp)).
- Проверки тоже тестируются: в учебном шаблоне CI показывает, что все проверки не проходят на ветке `main`, где не выполнено ни одно упражнение, и проходят на эталонных решениях ([Assert checks](https://github.com/wesammustafa/claude-code-practice/blob/main/.github/workflows/assert-checks.yml)).
- Запланированные проверки следят за актуальностью между изданиями: внешние ссылки и новые релизы `stable` еженедельно, маркеры истечения срока ежедневно, а цитаты уроков в приложении еженедельно. Каждая открывает отслеживающую issue ([Рутина мейнтейнера](CONTRIBUTING.md#maintainer-routine)).
- Примеры инертны, пока вы не скопируете их в проект, и следуют [контракту безопасности](CONTRIBUTING.md#adding-a-skill): только локально (кроме закреплённого сервера в уроке MCP), минимальные привилегии и smoke-тест, который запускается без Claude.

</details>

---

Нашли что-то устаревшее? [Сообщите об этом с источником](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=stale-content.yml). Застряли на уроке? Используйте ссылку внизу этого урока. Claude Code — продукт Anthropic; это независимый community-гайд, не связанный с Anthropic и не одобренный ею.

Если гайд помог вам, звезда поможет другим учащимся найти его.

[Лицензия MIT](LICENSE) · [Участие](CONTRIBUTING.md) · [Журнал изменений](CHANGELOG.md) · [Безопасность](SECURITY.md)

*Маскот: [`assets/brand/claude-jumping.svg`](assets/brand/claude-jumping.svg) взят из [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice), Copyright (c) 2025-2026 Shayan Rais, используется по [лицензии MIT](https://github.com/shanraisshan/claude-code-best-practice/blob/main/LICENSE).*

<a id="links-from-the-previous-edition"></a><a id="sdlc"></a><a id="what-are-llms-and-how-do-they-differ-from-ai-tools-like-claude-code"></a><a id="what-is-claude-code"></a><a id="claude-code-setup"></a><a id="1-install"></a><a id="2-authenticate"></a><a id="3-run-your-first-prompt"></a><a id="prompt-engineering-deep-dive"></a><a id="1-explore--plan--code--commit"></a><a id="2-test-driven-workflow-write-tests--code--commit"></a><a id="4-optional-generate-a-claudemd"></a><a id="3-visual-iteration-code--screenshot--iterate--commit"></a><a id="claude-opus-46-the-latest-powerhouse"></a><a id="claude-opus-47-the-latest-flagship"></a><a id="the-claude-5-era-todays-model-lineup"></a><a id="effort-levels"></a><a id="4-effort-levels--how-hard-claude-thinks"></a><a id="claude-commands"></a><a id="built-in-slash-commands"></a><a id="day-1-essentials"></a><a id="custom-slash-commands"></a><a id="claude-skills"></a><a id="your-first-skill-in-3-minutes"></a><a id="want-more-depth"></a><a id="what-are-skills"></a><a id="built-in-vs-custom-skills"></a><a id="skills-faq"></a><a id="creating-custom-skills"></a><a id="available-skills-reference"></a><a id="using-skills-in-workflow"></a><a id="troubleshooting-skills"></a><a id="skills-best-practices"></a><a id="hooks"></a><a id="setting-up-claude-hooks"></a><a id="setting-up-hooks"></a><a id="hook-events"></a><a id="hook-input"></a><a id="hook-output"></a><a id="security-considerations"></a><a id="hook-execution-details-and-debugging"></a><a id="execution--debugging"></a><a id="2-general-purpose-subagents--when-one-claude-isnt-enough"></a><a id="3-specialized-subagents--drop-in-role-prompts"></a><a id="ai-agents"></a><a id="running-agents-in-parallel"></a><a id="subagents--running-agents-in-parallel"></a><a id="orchestrating-specialists-from-the-main-session"></a><a id="1-git-worktrees--parallel-branches-parallel-sessions"></a><a id="agent-teams-experimental---2026"></a><a id="agent-teams-experimental"></a><a id="enable-it"></a><a id="the-example-that-justifies-the-cost"></a><a id="staff-a-team-with-the-role-prompts-you-already-have"></a><a id="three-things-that-catch-people-out"></a><a id="monitoring-and-the-naming-trap"></a><a id="best-practices"></a><a id="dynamic-workflows"></a><a id="try-it-in-2-minutes--no-script-required"></a><a id="starting-your-own"></a><a id="beyond-one-terminal--the-2026-automation-surface"></a><a id="model-context-protocol-mcp"></a><a id="the-nm-problem-mcp-solves"></a><a id="three-pillars"></a><a id="the-mcp-registry--self-discovering-agents"></a><a id="the-mcp-ecosystem-today"></a><a id="fast-mode"></a><a id="fast-mode-"></a><a id="beyond-your-own-skills--the-ecosystem"></a><a id="featured-mcp-servers"></a><a id="more-mcp-servers-worth-knowing"></a><a id="super-claude-framework"></a><a id="the-bmad-method--ai-agent-framework"></a><a id="updates--deprecations-february-2026"></a><a id="updates--deprecations"></a><a id="updates--deprecations-as-of-july-2026"></a><a id="faq"></a><a id="references"></a><a id="steal-this-setup"></a><a id="5-bonus-steal-this-repos-setup"></a><a id="-when-to-use-what"></a>

<details>
<summary>Перешли по ссылке из предыдущего издания?</summary>

Разделы README предыдущего издания перемещены:

- **SDLC, что такое LLM и Claude Code, настройка, установка, вход и первый промпт:** перемещено в [Установка, вход и осмотр](docs/beginner/01-install-and-look-around.md).
- **Prompt engineering, explore-plan-code-commit и разработка через тестирование:** перемещено в [Ваше первое изменение, от запроса до коммита](docs/beginner/03-first-change.md).
- **Генерация CLAUDE.md:** перемещено в [Память проекта с CLAUDE.md](docs/beginner/05-project-memory.md).
- **Визуальная итерация со скриншотами:** перемещено в [Дайте Claude скриншот](docs/beginner/electives/screenshots-and-images.md).
- **Линейка моделей:** перемещено в [Модели и усилия](docs/reference/models.md).
- **Уровни усилий:** перемещено в [Выбор модели и усилия](docs/intermediate/03-model-and-effort.md).
- **Команды и основы первого дня:** перемещено в [Команды по уровням](docs/reference/commands.md).
- **Пользовательские slash commands и skills:** перемещено в [Превращение повторяющегося рабочего процесса в skill](docs/intermediate/01-first-skill.md).
- **Справочник по skills и skills в рабочем процессе:** перемещено в [Превращение повторяющегося рабочего процесса в skill](docs/intermediate/01-first-skill.md), где показано, как запускать skill. Каталог собственных skills этого репозитория и его рецепты рабочих процессов были удалены в издании v2026.10: см. [CHANGELOG](CHANGELOG.md#removed-live-config).
- **Устранение неполадок со skills и лучшие практики:** перемещено в [Паттерны skills](docs/intermediate/electives/skill-patterns.md).
- **Hooks:** перемещено в [Обеспечение правила с помощью hook](docs/intermediate/05-hooks.md).
- **Subagents общего назначения и специализированные:** перемещено в [Делегирование пользовательскому subagent](docs/intermediate/06-subagents.md). Готовые role prompts были удалены в издании v2026.10: см. [CHANGELOG](CHANGELOG.md#removed-listings).
- **AI-агенты и запуск агентов параллельно:** перемещено в [Выбор паттерна оркестрации](docs/advanced/02-orchestration-patterns.md).
- **Git worktrees:** перемещено в [Параллельные сессии с worktrees](docs/advanced/01-parallel-sessions.md).
- **Команды агентов:** перемещено в [Команды агентов](docs/advanced/electives/agent-teams.md).
- **Динамические рабочие процессы:** перемещено в [Запуск и сохранение динамического рабочего процесса](docs/advanced/03-dynamic-workflows.md).
- **Поверхность автоматизации:** перемещено в [Карта функций](docs/reference/feature-map.md).
- **Model Context Protocol (MCP):** перемещено в [Подключение инструмента через MCP](docs/intermediate/07-mcp.md).
- **Fast mode:** перемещено в [Fast mode](docs/intermediate/electives/fast-mode.md).
- **Экосистема skills:** перемещено в [Установка и управление plugins](docs/intermediate/08-plugins.md). Каталог экосистемы skills был удалён в издании v2026.10: см. [CHANGELOG](CHANGELOG.md#removed-listings).
- **Списки MCP-серверов:** перемещено в [Подключение инструмента через MCP](docs/intermediate/07-mcp.md). Таблицы MCP-серверов были удалены в издании v2026.10: см. [CHANGELOG](CHANGELOG.md#removed-listings).
- **Super Claude и метод BMAD:** удалено в издании v2026.10: списки, которые не используются ни в одном уроке. См. [CHANGELOG](CHANGELOG.md#removed-listings).
- **Обновления и устаревания:** удалено в издании v2026.10: сводки гайда о релизах Claude Code. См. [CHANGELOG](CHANGELOG.md#removed-changelog-mirror).
- **FAQ:** перемещено в [FAQ](docs/reference/faq.md), где указано, куда делся каждый ответ.
- **Ссылки:** перемещено в [Дальнейшее обучение](docs/reference/further-reading.md).
- **Steal this setup:** перемещено в [Общий доступ к вашей настройке для команды](docs/advanced/06-share-your-setup.md).
- **Когда что использовать:** перемещено в [Когда что использовать](docs/intermediate/README.md#when-to-use-what).

</details>