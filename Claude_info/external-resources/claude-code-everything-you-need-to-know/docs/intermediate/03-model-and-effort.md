# Выбор модели и уровня усилий

<sub>**Средний уровень** · Урок 3 из 8 · около 15 минут · Требуется: [Превратите повторяющийся рабочий процесс в skill](01-first-skill.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете выбирать модель и уровень усилий для задачи, устанавливать их для сессии или для одного skill и определять по неверному результату, нужно ли повысить усилия или выбрать более крупную модель.

## Вам понадобится

- Репозиторий, в котором вы выполняли [урок 1](01-first-skill.md), с его skills, и ваша копия практического шаблона с Node.js LTS: проверка запускается из копии.
- Использование: небольшое. Более крупная модель стоит дороже за токен, а более высокий уровень усилий обычно производит больше токенов, поэтому и то и другое, как правило, увеличивает расход вашего тарифного плана.

## Идея

Два отдельных выбора формируют ответ ([Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)):

- **Модель** определяет, насколько способным может быть ответ.
- **Уровень усилий** определяет, сколько работы Claude выполняет над каждым запросом: сколько файлов он читает, сколько проверяет и как далеко заходит, прежде чем обратиться к вам ([Model configuration](https://code.claude.com/docs/en/model-config#adjust-effort-level)).

Рекомендация Anthropic — начинать с уровня усилий по умолчанию для модели в большинстве задач. Когда результат неверен, выясните причину, прежде чем что-то менять:

| Что произошло или какова задача | Что изменить |
|---|---|
| Claude не хватило контекста: расплывчатый промпт, отсутствующий инструмент или skill | Контекст: промпт, `CLAUDE.md`, skill |
| Claude недостаточно постарался: пропустил файл или не запустил тесты | Более высокий уровень усилий |
| У Claude был контекст, он старался, но всё равно ошибся: тонкая ошибка, незнакомая область, проектное решение | Более крупная модель, например `opus` |
| Рутинная работа: правки, которые вы можете точно описать, механические изменения | Меньшая модель, например `sonnet`, и более низкий уровень усилий ([Choose an effort level](https://code.claude.com/docs/en/model-config#choose-an-effort-level)) |
| Глубокое планирование, затем рутинная работа | `opusplan`: Opus в режиме plan, затем Sonnet для выполнения плана |

Где применяется выбор, определяет, как его установить. Страница [Models and effort](../reference/models.md) перечисляет псевдонимы и уровни:

| Область действия | Модель | Уровень усилий |
|---|---|---|
| Эта сессия | `/model`, затем `s` на строке | `/effort`, затем `s` в ползунке |
| Ваш стандарт | `/model <alias>` | `/effort <level>` |
| Один ход | – | `ultrathink` в промпте запрашивает более глубокое рассуждение; уровень остаётся |
| Один skill или subagent | `model:` в его frontmatter | `effort:` в его frontmatter |

## Разобранный пример

1. Запустите `claude` в вашем репозитории. Выполните `/status`: он показывает модель. Выполните `/effort status`: он выводит действующий уровень усилий ([Commands](https://code.claude.com/docs/en/commands)).
2. Переключите модель только для этой сессии: выполните `/model`, перейдите к Sonnet и нажмите `s`. `/status` теперь показывает Sonnet, а ваш стандарт для новых сессий не изменился ([Setting your model](https://code.claude.com/docs/en/model-config#setting-your-model)).
3. Запросите более глубокое рассуждение на один ход, не меняя уровень усилий. В практическом шаблоне:

   ```text
   ultrathink: which links could linkcheck report as broken although their file exists?
   ```

   Claude Code распознаёт `ultrathink` и запрашивает более глубокое рассуждение только на этот ход. Фразы вроде "think hard" — обычный текст ([Use ultrathink](https://code.claude.com/docs/en/model-config#use-ultrathink-for-one-off-deep-reasoning)).
4. Задайте одной задаче собственный уровень усилий. `five-whys` из урока 1 прослеживает причину по уликам, где проверка важна. Добавьте строку в его frontmatter в `.claude/skills/five-whys/SKILL.md`:

   ```yaml
   effort: high
   ```

   С этого момента skill работает на уровне `high`, пока он активен, поверх уровня сессии. Уровень усилий, заданный переменной `CLAUDE_CODE_EFFORT_LEVEL`, и любое ограничение усилий всё равно имеют приоритет ([Set the effort level](https://code.claude.com/docs/en/model-config#set-the-effort-level)).

## Ваша очередь

Дайте рутинной задаче наименьшие модель и уровень усилий, которые справляются с работой.

1. Сохраните этот skill как `.claude/skills/changelog/SKILL.md`:

   ```markdown
   ---
   name: changelog
   description: Adds a one-line entry for the staged changes to CHANGELOG.md. Use when the user asks for a changelog entry.
   model: TODO
   effort: TODO
   disable-model-invocation: true
   ---

   Read the staged changes with `git diff --staged`. Add one list item (`- `) under `## Unreleased` in CHANGELOG.md that says what changed for someone using the tool, creating the file and the heading if they don't exist. Change no other file.
   ```

2. Замените оба `TODO`, используя первую таблицу. В режиме auto используйте `sonnet`: режим auto не поддерживает Haiku, поэтому skill, установленный на `haiku`, сохранит модель сессии там ([Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)).
3. Застейджите небольшое собственное изменение, выполните `/changelog` и одобрите правку. Если Claude Code скажет, что команда неизвестна, сначала выполните `/reload-skills`.
4. Закоммитьте изменение, `CHANGELOG.md` и skill вместе.

## Проверка

Вы закончили, когда все следующие условия истинны:

- [ ] Закоммиченный skill выбирает меньшую модель и низкий или средний уровень усилий: `git show HEAD:.claude/skills/changelog/SKILL.md | grep -E '^(model|effort):'` показывает оба.
- [ ] Закоммиченный `CHANGELOG.md` имеет запись `- ` под `## Unreleased`: `git show HEAD:CHANGELOG.md` показывает её.
- [ ] Самопроверка (не тестируется): для точного переименования, новой функции с чёткой областью и ошибки, которую Claude постоянно делает неверно при наличии всего контекста, вы можете сказать, какую модель и уровень усилий выбрали бы и почему.

Запустите `npm run check -- i-3 --dir <your repo>` из вашей практической копии или `npm run check -- i-3` в самой копии.

Если проверка skill говорит, что модель больше, чем нужно задаче, установите `model: sonnet`: изменение, которое вы можете точно описать, — рутинная работа. Если записи нет, застейджите изменение перед запуском `/changelog`, потому что skill читает только застейдженные изменения.

## Осторожно

- `/model <alias>` и `/effort <level>` сохраняют ваш выбор как стандарт для новых сессий. Чтобы изменить только текущую сессию, нажмите `s` в выборе или ползунке.
- Переключение модели в середине сессии, а на большинстве моделей и изменение уровня усилий, заставляет следующий запрос читать весь разговор без попаданий в кэш; пока кэш тёплый, Claude Code просит подтверждения ([How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#switching-models)).
- Установленный через `/effort`, `max` действует только на текущую сессию и может переусердствовать: протестируйте его, прежде чем полагаться ([Choose an effort level](https://code.claude.com/docs/en/model-config#choose-an-effort-level)).

## Дальнейшие шаги

- [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code): руководство Anthropic по двум настройкам с тестом "try or know", который используется в этом уроке.
- [Models and effort](../reference/models.md): псевдонимы моделей, уровни усилий и способы их установки.
- [Model configuration](https://code.claude.com/docs/en/model-config): стандарты по аккаунту и провайдеру, а также ограничения организации.

---

<sub>Источники: [Model configuration](https://code.claude.com/docs/en/model-config) · [Commands](https://code.claude.com/docs/en/commands) · [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) · [Extend Claude with skills](https://code.claude.com/docs/en/skills) · [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) · [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)</sub>

<sub>← [Организуйте память проекта и посмотрите, что загрузилось](02-organize-memory.md) · [Индекс среднего уровня](README.md) · [Права, области настроек и песочница](04-permissions-and-sandbox.md) → · Тема: [Модели, усилия и стоимость](../topics/models-effort-and-cost.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-3)</sub>
