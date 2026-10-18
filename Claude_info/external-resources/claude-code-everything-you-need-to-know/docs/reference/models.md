<a id="models--specifications--pricing"></a>
# Модели и усилия

<sub>Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

Какая модель работает в сессии и насколько усердно она думает — это два отдельных выбора. Эта страница — справочник по обоим: псевдонимы моделей, уровни усилий и способы их задания. Какую модель и усилие выбрать для задачи, объясняется в уроке Intermediate [Выбор модели и усилия](../intermediate/03-model-and-effort.md). Чтобы сравнить текущие модели и найти их идентификаторы, смотрите [обзор моделей](https://platform.claude.com/docs/en/about-claude/models/overview) Anthropic.

<a id="the-current-lineup-july-2026"></a><a id="the-current-lineup-as-of-october-4-2026"></a><a id="the-headliners"></a><a id="claude-sonnet-5--the-new-default"></a><a id="claude-sonnet-5-legacy"></a><a id="claude-opus-48--the-opus-flagship"></a><a id="claude-opus-48-legacy"></a><a id="claude-fable-5--the-mythos-class"></a><a id="claude-fable-5-legacy"></a>
## Псевдонимы

Псевдоним выбирает рекомендуемую модель семейства, поэтому вам не нужен номер версии. Выберите его с помощью `/model <alias>`, `claude --model <alias>` или настройки `model` ([Конфигурация модели](https://code.claude.com/docs/en/model-config#model-aliases)).

| Псевдоним | На Anthropic API использует | Используйте, когда |
|---|---|---|
| `sonnet` | Последняя Sonnet | Повседневное кодирование |
| `opus` | Последняя Opus | Сложные рассуждения |
| `fable` | Модель Fable для вашего провайдера | Самые сложные, длительные задачи |
| `best` | Fable, если доступна на вашем аккаунте, иначе Opus | Вам нужна самая сильная доступная модель |
| `haiku` | Haiku | Быстрые, простые задачи |
| `opusplan` | Opus в режиме планирования, затем Sonnet для выполнения плана | Вам нужно глубокое планирование и более дешёвое выполнение |
| `opus[1m]` | Opus с контекстным окном в 1 миллион токенов | Очень длинные сессии, на провайдере, где у `opus` ещё нет такого окна |

- Псевдоним со временем переходит на более новую модель. Чтобы остаться на одной версии, используйте полное имя модели, например `claude-opus-5-5`, из [обзора моделей](https://platform.claude.com/docs/en/about-claude/models/overview).
- `default` не является псевдонимом: он сбрасывает выбранную вами модель и возвращает модель по умолчанию для вашего аккаунта.
- На других провайдерах псевдоним может разрешаться в более старую модель: `sonnet` — на Claude Platform on AWS, Amazon Bedrock, Google Cloud's Agent Platform и Microsoft Foundry, а `opus` — на Microsoft Foundry. [Таблица псевдонимов](https://code.claude.com/docs/en/model-config#model-aliases) перечисляет их.
- Fable может использовать кредиты использования в зависимости от вашего плана и места ([Fable и кредиты использования](https://code.claude.com/docs/en/model-config#fable-and-usage-credits)).

Модель по умолчанию различается в зависимости от типа аккаунта и провайдера. Проверьте свою с помощью `/model` или `/status`, а правила смотрите в [Настройка модели по умолчанию](https://code.claude.com/docs/en/model-config#default-model-setting).

## Уровни усилий

Усилие управляет тем, насколько модель рассуждает на каждом шаге. Более низкое усилие отвечает быстрее и тратит меньше токенов; более высокое усилие больше проверяет собственную работу ([Настройка уровня усилий](https://code.claude.com/docs/en/model-config#adjust-effort-level)).

| Уровень | Подходит |
|---|---|
| `low` | Быстрые обмены, где вы просматриваете каждый результат: первый набросок, переименование |
| `medium` | Повседневная работа с чётким объёмом, например новая функция, на Opus 5.5 и Sonnet 5.5; на моделях с более высоким уровнем по умолчанию — более дешёвый уровень, который жертвует некоторыми возможностями |
| `high` | Работа, где вероятны крайние случаи, например исправление ошибки в существующем коде |
| `xhigh` | Более глубокие рассуждения при большем расходе токенов |
| `max` | Сложные проблемы, которые Claude решает без вас; протестируйте, прежде чем полагаться на него, так как он может переусердствовать |

- Какие уровни предлагает модель и с какого начинает, различается по моделям: смотрите [уровни по моделям](https://code.claude.com/docs/en/model-config#adjust-effort-level) в документации. `/effort status` выводит действующий уровень.
- Установите уровень, который модель не предлагает, и Claude Code использует самый высокий уровень, который она предлагает, ниже этого.
- Шкала откалибрована для каждой модели, поэтому `high` на одной модели — это не то же количество рассуждений, что `high` на другой.

## Установка усилия

| Где | Как долго действует |
|---|---|
| `/effort <level>` или `/effort` для ползунка | Сохраняется как ваш уровень по умолчанию для этой модели; нажмите `s` в ползунке, чтобы применить только к этой сессии |
| Ползунок усилия в `/model` | То же, что `/effort` |
| `claude --effort <level>` | Эта сессия |
| Переменная окружения `CLAUDE_CODE_EFFORT_LEVEL` | Каждая сессия, запущенная с ней. Она переопределяет другие источники, хотя ограничение `maxEffortLevel` всё ещё применяется |
| `modelSettings` или `effortLevel` в файле настроек | Каждая сессия, к которой применяется файл. `modelSettings` устанавливает уровень одной модели; `effortLevel` верхнего уровня в ваших пользовательских настройках не применяется к новейшим моделям |
| `effort` во frontmatter навыка или субагента | Пока работает этот навык или субагент |

`/effort auto` сбрасывает уровень, сохранённый для текущей модели; затем модель использует `effortLevel` из ваших настроек, если он применим, иначе свой собственный уровень по умолчанию ([Установка уровня усилий](https://code.claude.com/docs/en/model-config#set-the-effort-level)).

## Подводные камни

- `max` применяется только к текущей сессии, если вы не установили его с помощью `CLAUDE_CODE_EFFORT_LEVEL`. Настройки `effortLevel` и `modelSettings` не принимают его.
- `ultrathink` в запросе запрашивает более глубокие рассуждения только на этот ход и оставляет уровень усилий неизменным. Фразы вроде "подумай усердно" — это обычный текст ([Использование ultrathink](https://code.claude.com/docs/en/model-config#use-ultrathink-for-one-off-deep-reasoning)).
- Ultracode — это настройка, а не уровень усилий: при её включении Claude планирует [динамический рабочий процесс](https://code.claude.com/docs/en/workflows) для каждой существенной задачи, на любом уровне, на котором работает сессия ([Конфигурация модели](https://code.claude.com/docs/en/model-config#adjust-effort-level)).
- Переключение моделей в середине сессии пересчитывает весь запрос, и на большинстве моделей то же самое происходит при изменении усилия, поэтому Claude Code может сначала попросить подтверждения ([Кэширование запросов](https://code.claude.com/docs/en/prompt-caching)).

<a id="fast-mode"></a>
## Связанные страницы

- Быстрый режим, который в документации помечен как "в исследовательском предпросмотре": более быстрая конфигурация поддерживаемых моделей Opus, за которую подписные планы платят только кредитами использования. Смотрите [Быстрый режим](https://code.claude.com/docs/en/fast-mode) и факультатив [Быстрый режим](../intermediate/electives/fast-mode.md).
- Выбор модели и усилия для задачи: [Выбор модели Claude и уровня усилий в Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) от Anthropic.
- Даты вывода из эксплуатации: [Устаревание моделей](https://platform.claude.com/docs/en/about-claude/model-deprecations).

<a id="pricing"></a><a id="subscription-plans"></a><a id="api-pay-as-you-go"></a>
В руководстве нет цен и лимитов планов. Смотрите [claude.com/pricing](https://claude.com/pricing) для планов и [цены API](https://platform.claude.com/docs/en/about-claude/pricing) для тарифов за токен.

---

<sub>Источники: [Конфигурация модели](https://code.claude.com/docs/en/model-config) · [Обзор моделей](https://platform.claude.com/docs/en/about-claude/models/overview) · [Кэширование запросов](https://code.claude.com/docs/en/prompt-caching) · [Быстрый режим](https://code.claude.com/docs/en/fast-mode) · [Устаревание моделей](https://platform.claude.com/docs/en/about-claude/model-deprecations) · [Цены](https://claude.com/pricing) · [Цены API](https://platform.claude.com/docs/en/about-claude/pricing)</sub>

<sub>Вверх: [Справочник](README.md)</sub>
