# Журнал изменений

Издания этого руководства, сначала новые. Издание помечается тегом `vYYYY.MM`, а исправление между изданиями — `vYYYY.MM.N`. Каждое издание остаётся доступным для чтения по своему тегу.

## Не выпущено

Базовая версия: Claude Code v2.1.292 (stable), зафиксирована 2026-10-15.

Каждое изменение в следующем издании проверяется на этой версии, дистрибутивном теге `stable` пакета [`@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code?activeTab=versions) на 2026-10-15. Она остаётся зафиксированной до выхода издания, если только более поздний релиз `stable` не удалит, не переименует или не изменит поведение по умолчанию того, чему учит урок.

Издания 2 и 3: пути Intermediate и Advanced, с проверяемыми упражнениями. Каждый уровень теперь перестроен, и ни одна страница из предыдущего издания не сохранилась.

### Добавлено

- [Уровень Intermediate](docs/intermediate/README.md): восемь уроков, от первого skill до плагинов, через память проекта, модель и effort, разрешения и песочницу, hooks, subagents и MCP, и итоговый проект, который настраивает репозиторий для нового коллеги. Каждый урок и итоговый проект имеют проверку в [шаблоне для практики](https://github.com/wesammustafa/claude-code-practice). Вы можете запускать проверки уроков на своём репозитории с помощью `--dir`; итоговый проект выполняется в копии шаблона.
- Четыре факультатива Intermediate: [паттерны skill](docs/intermediate/electives/skill-patterns.md), [Claude в Chrome](docs/intermediate/electives/claude-in-chrome.md), [строка состояния](docs/intermediate/electives/status-line.md) и [быстрый режим](docs/intermediate/electives/fast-mode.md).
- [Примеры](examples/README.md) для уроков Intermediate: два skill, три скрипта hook, subagent-ревьюер только для чтения и закреплённая конфигурация Chrome DevTools MCP. Каждый из них инертен, пока вы не скопируете его в проект, и имеет smoke-тест.
- [Уровень Advanced](docs/advanced/README.md): семь уроков, от параллельных сессий в worktrees до ограничений на автономные запуски, через паттерны оркестрации, динамические рабочие процессы, скрипты `claude -p`, GitHub Actions и настройку, общую для команды, и итоговый проект, который добавляет CI-ревью, доступное команде. Каждый урок и итоговый проект имеют проверку в [шаблоне для практики](https://github.com/wesammustafa/claude-code-practice). Большинство проверок уроков выполняются на вашем репозитории с помощью `--dir`; урок по GitHub Actions и итоговый проект выполняются в отдельной копии шаблона, которую вы удаляете после.
- Пять факультативов Advanced: [команды агентов](docs/advanced/electives/agent-teams.md), [вид агента](docs/advanced/electives/agent-view.md), [`/goal`, `/loop` и рутины](docs/advanced/electives/goal-loop-routines.md), [тестирование и публикация плагина](docs/advanced/electives/publish-a-plugin.md) и [dev containers](docs/advanced/electives/dev-containers.md).
- [За пределами этого руководства](docs/advanced/beyond-this-guide.md): куда двигаться дальше для создания собственных агентов и MCP-серверов, а также для запуска и развёртывания Claude Code в организации.
- [Примеры](examples/README.md) для уровня Advanced: marketplace `team-tools` с плагином `team-kit` (skill `onboard` и subagent `config-reviewer` только для чтения) и настройки, которые его публикуют, а также subagents `security-reviewer` и `test-reviewer` только для чтения для факультатива по командам агентов. Каждый из них инертен, пока вы не скопируете его в проект, и имеет smoke-тест.

### Изменено

- Анимированный маскот Claude снова рядом с заголовком README, и социальная карточка показывает его вместо следов. Он взят из [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) под лицензией MIT.
- Каждая страница с отметкой повторно проверена на Claude Code v2.1.292 (stable), и социальная карточка несёт полный слоган: "Изучите это на трёх уровнях, с подтверждёнными фактами и проверяемыми упражнениями".
- Тематические страницы, [Команды по уровням](docs/reference/commands.md) и [Карта возможностей](docs/reference/feature-map.md) ссылаются на уроки и факультативы Intermediate и Advanced, а "Когда что использовать" на [индексе Intermediate](docs/intermediate/README.md#when-to-use-what) ссылается на урок по динамическим рабочим процессам.
- docs/reference/effort-levels.md и docs/skills.md теперь являются заглушками, указывающими на уроки и справочные страницы, которые их заменяют, а заглушки `mcp-servers/` и `specialized-agents/` указывают на уроки по MCP и subagents.
- docs/agent-teams.md, docs/workflows.md и docs/reference/faq.md теперь являются заглушками, указывающими на уроки, факультативы и справочные страницы, которые их заменяют.
- Проверка `inertness` также не проходит, если манифест marketplace в примере не переименован в `dot-claude-plugin/`, и если папка `.claude-plugin/` находится в корне репозитория. Проверка `static-validation` также охватывает skills и agents плагинов в примере marketplace.

### Удалено

<a id="removed-legacy-intermediate"></a>
- Страницы предыдущего издания о skills, hooks, MCP и быстром режиме в `docs/legacy/`, а также раздел о subagents на странице о subagents и параллельной работе: уроки и факультативы Intermediate заменяют их. Ссылки на разделы README предыдущего издания ведут на строку, указывающую на новую страницу.
- Диаграмма разрешения skill, которую больше не использовала ни одна страница.
<a id="removed-legacy-advanced"></a>
- Последняя страница предыдущего издания в `docs/legacy/`, о subagents и параллельной работе, и строка индекса README со страницами предыдущего издания: уроки и факультативы Advanced заменяют их, и `docs/legacy/` удалена. Ссылки на разделы README предыдущего издания ведут на строку, указывающую на новую страницу.

## v2026.10 - 2026-10-05

Проверено на Claude Code v2.1.285 (stable).

Издание 1: путь Beginner, с проверяемыми упражнениями, и структура, на которой строятся следующие два уровня. Intermediate и Advanced перестраиваются; копии разделов README предыдущего издания о skills, hooks, subagents и параллельной работе, MCP и быстром режиме остаются доступными для чтения в `docs/legacy/`, помеченные как ещё не повторно проверенные.

### Добавлено

- [Уровень Beginner](docs/beginner/README.md): пять уроков, от установки Claude Code до создания памяти проекта, итоговый проект и три факультатива. Каждый урок и итоговый проект имеют проверку, которую вы запускаете в [шаблоне для практики](https://github.com/wesammustafa/claude-code-practice), чья ветка `solutions` проходит все проверки.
- Входная страница, которая определяет ваш уровень, и индексы для трёх уровней, [тем](docs/topics/README.md) и [справочных страниц](docs/reference/README.md), включая [Карту возможностей](docs/reference/feature-map.md) и [глоссарий](docs/reference/glossary.md).
- Страницы из предыдущего издания, сохранённые для чтения в `docs/legacy/` с примечанием, пока не появятся заменяющие их уроки.
- Формы для сообщения о проблемах с уроками, ошибках и устаревших фактах, со ссылкой "Застряли на этом уроке?" внизу каждого урока.
- Проверки на каждом pull request: внутренние ссылки и якоря, отметки страниц, структура уроков, изображения, длинные тире, валидация конфигурации и безопасность `examples/`. Запланированные проверки следят за внешними ссылками, маркерами истечения срока и новыми релизами `stable` и открывают issue, когда что-то требует внимания.
- Политика листинга в [CONTRIBUTING.md](CONTRIBUTING.md#listing-policy) и форма для предложения ресурса.
- Правила для агентов в [AGENTS.md](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/blob/main/AGENTS.md), которые импортирует новый [CLAUDE.md](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/blob/main/CLAUDE.md).
- Переписанный [CONTRIBUTING.md](CONTRIBUTING.md), шаблон pull request с таблицей утверждений и разделом пробного запуска, и файл CODEOWNERS.

### Изменено

- Заморозка листинга завершена: предложения ресурсов снова рассматриваются в соответствии с [планкой листинга](CONTRIBUTING.md#the-listing-bar).
- У руководства появился собственный знак — три следа, взбирающихся на столб, вместо изображения маскота, так что оно больше не использует образ персонажа Anthropic. Вместе с ним новая социальная карточка, не содержащая ничего, что может устареть.
- Справочные страницы переписаны для поиска: [Модели и effort](docs/reference/models.md), [Команды по уровням](docs/reference/commands.md) и [Дальнейшее обучение](docs/reference/further-reading.md). Они не содержат цен, лимитов планов или спецификаций моделей и ссылаются на официальные страницы для этого.

### Удалено

<a id="removed-changelog-mirror"></a>
- Сводка релизов Claude Code в руководстве, docs/reference/changelog.md, теперь является заглушкой, указывающей на официальный [CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) и [What's new](https://code.claude.com/docs/en/whats-new).

<a id="removed-listings"></a>
- Сторонние листинги, которые не использует ни один урок: каталог экосистемы skills (реестры, курируемые списки и названия community skills), таблицы MCP-серверов и обзор экосистемы MCP, четыре пошаговых руководства по MCP-серверам в `mcp-servers/`, фреймворки SuperClaude и BMAD, а также десять ролевых промптов и девять описаний ролей в `specialized-agents/`. [Политика листинга](CONTRIBUTING.md#listing-policy) говорит, что руководство перечисляет сейчас. Старые ссылки на эти страницы и разделы ведут на строку, которая об этом сообщает.

<a id="removed-further-reading-listings"></a>
- Из раздела "Дальнейшее обучение": анонсы моделей, калькулятор токенов, примеры сторонних MCP-серверов и пост об аутентификации MCP, коллекции hooks и рабочих процессов, инструменты для терминала и заметок, ещё один ассистент для кодинга и анонс об интероперабельности агентов. Ни один урок их не использует.

<a id="removed-live-config"></a>
- Живая настройка Claude Code в репозитории больше ничего не запускает, когда вы клонируете репозиторий и доверяете папке. Удалены: голосовой Notification hook с его вспомогательными скриптами text-to-speech и LLM, 14 правил allow, пять персон subagents в `.claude/agents/`, семь slash commands в `.claude/commands/`, а также каталог skills и рецепты рабочих процессов в docs/skills.md, которые их описывали. В `.claude/` остаются правило deny для чтения файлов `.env`, skill claude-md-review и рабочий процесс stale-docs-audit. Чтобы сохранить собственное голосовое уведомление, добавьте Notification hook в `~/.claude/settings.json`.
