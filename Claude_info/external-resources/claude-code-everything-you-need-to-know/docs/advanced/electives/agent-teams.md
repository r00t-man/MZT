# Команды агентов

<sub>**Продвинутый** · Электив · около 20 минут плюс время выполнения · Требуется: [Выберите паттерн оркестрации](../02-orchestration-patterns.md) · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

> [!NOTE]
> "Команды агентов экспериментальны и отключены по умолчанию." ([Оркестрация команд сессий Claude Code](https://code.claude.com/docs/en/agent-teams))

## Цель

К концу этого Электива вы сможете укомплектовать команду агентов из собственных определений субагентов, показать, что команда сформировалась, и завершить работу её участников по имени.

## Вам понадобится

- [Выберите паттерн оркестрации](../02-orchestration-patterns.md) и определения субагентов, которые вы написали в [Делегирование пользовательскому субагенту](../../intermediate/06-subagents.md).
- Один из ваших репозиториев с настроенной папкой `.practice/`, как описано в [Уроке 1 для начинающих](../../beginner/01-install-and-look-around.md#you-need).
- macOS, Linux или WSL 2, а также `jq`: хуки, которые логируют команду, — это shell-команды, использующие его.
- Интерактивная сессия: в запуске `-p` Claude не порождает участников ([Включение команд агентов](https://code.claude.com/docs/en/agent-teams#enable-agent-teams)). Стандартный внутрипроцессный режим отображения, где участники работают внутри вашего терминала, работает в любом терминале ([Выбор режима отображения](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode)).
- Использование: интенсивное. Каждый участник — это отдельный экземпляр Claude со своим контекстным окном, и расход токенов растёт с числом активных участников ([Расход токенов](https://code.claude.com/docs/en/agent-teams#token-usage)). Дешёвый вариант: измените один небольшой файл в Рабочем примере, запустите двух участников в разделе «Ваша очередь» и завершите их работу, как только они отчитаются.

## Идея

Команда агентов — это несколько сессий Claude Code, работающих вместе. Ваша сессия является ведущей: она порождает участников, каждого в своём контекстном окне. Участники обмениваются сообщениями напрямую, и вы можете написать любому из них, тогда как субагенты в основном возвращают результат вызывающему ([Сравнение с субагентами](https://code.claude.com/docs/en/agent-teams#compare-with-subagents)).

Участник загружает ваш CLAUDE.md, MCP-серверы и навыки, а также промпт порождения от ведущего, но не разговор ведущего, поэтому промпт несёт задачу ([Контекст и коммуникация](https://code.claude.com/docs/en/agent-teams#context-and-communication)). Назовите в нём определение субагента, и участник будет работать с `tools` и инструкциями этого определения, а также с его `model`, если промпт порождения не укажет модель; внутрипроцессный участник также получает `SendMessage`, так что даже участник только для чтения может связаться с остальными ([Использование определений субагентов для участников](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)).

Команды "используют значительно больше токенов, чем одна сессия" ([Расход токенов](https://code.claude.com/docs/en/agent-teams#token-usage)), и участники разделяют ваше рабочее дерево ([Выбор подхода](https://code.claude.com/docs/en/agents#choose-an-approach)). Используйте их там, где независимые взгляды окупаются: обзор через разные призмы или соперничающие гипотезы, которые нужно обсудить.

## Рабочий пример

1. В вашем репозитории скачайте двух рецензентов только для чтения из [примера команд агентов](../../../examples/advanced/electives/agent-teams/README.md) этого руководства. Прочитайте их перед использованием:

   ```bash
   mkdir -p .claude/agents
   for a in security-reviewer test-reviewer; do
     curl -fsSL https://raw.githubusercontent.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/main/examples/advanced/electives/agent-teams/dot-claude/agents/$a.md -o ".claude/agents/$a.md"
   done
   grep -H '^tools:' .claude/agents/security-reviewer.md .claude/agents/test-reviewer.md
   ```

   Каждая строка заканчивается на `tools: Read, Grep, Glob`: рецензенты могут читать файлы, но не могут их редактировать или запускать команды, включая `git`. Grep и Glob, инструменты поиска, по умолчанию отсутствуют на macOS, Linux и WSL; субагент, который перечисляет их и не указывает Bash, получает их обратно ([Поведение инструмента Glob](https://code.claude.com/docs/en/tools-reference#glob-tool-behavior)). Оба устанавливают `model: sonnet`. Если сессия уже открыта здесь, а `.claude/agents/` новая, перезапустите её: Claude Code отслеживает только папки агентов, существовавшие на момент запуска сессии ([Запись файлов субагентов](https://code.claude.com/docs/en/sub-agents#write-subagent-files)).
2. Используйте изменение, над которым вы работаете, или сделайте временное: измените один отслеживаемый исходный файл так, как это сделало бы реальное изменение, например функцию, читающую пользовательский ввод, без нового теста. Оставьте его незакоммиченным. Рецензенты не могут запустить `git diff`, поэтому сохраните изменение там, где они смогут его прочитать:

   ```bash
   git diff > .practice/a-teams.diff
   ```

3. Сохраните это как `.practice/a-teams.json`:

   ```json
   {
     "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
     "teammateMode": "in-process",
     "hooks": {
       "TeammateIdle": [
         { "hooks": [ { "type": "command", "command": "jq -r '.teammate_name' >> \"$CLAUDE_PROJECT_DIR/.practice/a-teams-teammates.txt\"" } ] }
       ]
     }
   }
   ```

   Это включает команды агентов только для сессий, которые вы запускаете с этим файлом ([Включение команд агентов](https://code.claude.com/docs/en/agent-teams#enable-agent-teams), [Claude порождает участников вместо субагентов](https://code.claude.com/docs/en/agent-teams#claude-spawns-teammates-instead-of-subagents)), а `teammateMode` сохраняет их участников во внутрипроцессном отображении, которое описывают эти шаги ([`teammateMode`](https://code.claude.com/docs/en/settings-reference#teammatemode)). Его хук [`TeammateIdle`](https://code.claude.com/docs/en/hooks#teammateidle) записывает имя каждого участника в `.practice/a-teams-teammates.txt`, когда тот собирается перейти в режим ожидания.
4. Запустите ведущего с файлом:

   ```bash
   CLAUDE_CODE_ENABLE_TODO_TOOLS=1 claude --settings .practice/a-teams.json
   ```

   `--settings` применяет ключи файла поверх ваших настроек только для этой сессии ([Справочник CLI](https://code.claude.com/docs/en/cli-reference#cli-flags)). Переменная даёт сессии инструменты Task на любой модели; без неё Claude Code предоставляет их только на старых моделях, перечисленных в [Доступность инструмента Task](https://code.claude.com/docs/en/tools-reference#task-tool-availability), и участники координируются через сообщения, а не общий список задач. Выполните `/context`: среди пользовательских субагентов будут `security-reviewer` и `test-reviewer` ([Просмотр загруженного в контекст](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)).
5. Запросите команду. Дайте каждому участнику одну призму, как в [параллельном обзоре кода](https://code.claude.com/docs/en/agent-teams#run-a-parallel-code-review) из документации, плюс имя и [тип агента](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates):

   ```text
   Create an agent team to review the change saved in .practice/a-teams.diff and the files it touches.
   Spawn two teammates: one named security, using the security-reviewer agent type, and one named
   tests, using the test-reviewer agent type. When both have reported, write one combined report
   to .practice/a-teams-review.md.
   ```

   Claude Code запускает участников без запроса подтверждения ([Как Claude запускает команды агентов](https://code.claude.com/docs/en/agent-teams#how-claude-starts-agent-teams)). Для каждого появляется строка в панели агентов под промптом. Субагенты отображаются в той же панели, поэтому одна панель не доказывает формирование команды ([Запуск первой команды агентов](https://code.claude.com/docs/en/agent-teams#start-your-first-agent-team)): доказательство — лог из шага 7. `Ctrl+T` переключает список задач ([Общение с участниками напрямую](https://code.claude.com/docs/en/agent-teams#talk-to-teammates-directly)). Промпт не называет модель, поэтому каждый участник работает на `model` из своего определения, если вы не установили `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` ([Указание участников и моделей](https://code.claude.com/docs/en/agent-teams#specify-teammates-and-models)). Когда оба отчитаются, ведущий пишет объединённый отчёт (ваша формулировка может отличаться); одобрите запись, если Claude Code попросит.
6. Завершите работу участников по имени:

   ```text
   Ask the security and tests teammates to shut down.
   ```

   Каждый участник одобряет и выходит или отклоняет запрос с объяснением ([Завершение работы участников](https://code.claude.com/docs/en/agent-teams#shut-down-teammates)); если кто-то отклонит, прочтите причину и попросите снова. Участник, чья строка исчезла из панели, скрыт, а не остановлен, поэтому также назовите его в запросе ([Запуск первой команды агентов](https://code.claude.com/docs/en/agent-teams#start-your-first-agent-team)). Затем выйдите из сессии. Claude Code удаляет конфигурацию команды при завершении сессии и сохраняет её список задач для возобновлённых сессий, так что отдельного шага очистки нет ([Архитектура](https://code.claude.com/docs/en/agent-teams#architecture)).
7. Прочитайте лог:

   ```bash
   sort -u .practice/a-teams-teammates.txt
   ```

   Он содержит `security` и `tests`, значит, команда сформировалась.

## Ваша очередь

Отладьте с конкурирующими гипотезами, как в примере документации [Расследование с конкурирующими гипотезами](https://code.claude.com/docs/en/agent-teams#investigate-with-competing-hypotheses). Выберите реальный баг или странное поведение в вашем репозитории, причину которого вы не знаете и которое можно объяснить чтением кода. Напишите определение исследователя только для чтения, например скопировав `test-reviewer.md` в `.claude/agents/hypothesis-tester.md` и переписав его. Запустите новую сессию тем же способом, чтобы ведущий начал с чистого листа, и попросите его породить трёх участников из вашего определения, каждый из которых отвечает за одну гипотезу и пишет другим, чтобы оспорить их теории. Дешёвый вариант: два участника.

Критерии приёмки:

- Ваше определение имеет собственные `name` и `description`, `model: sonnet` и однострочный `tools:`, где перечислены только `Read`, `Grep` и `Glob`, как в строках двух рецензентов и как в примере только для чтения из документации ([Быстрый старт: создание первого субагента](https://code.claude.com/docs/en/sub-agents#quickstart-create-your-first-subagent)). Определение без строки `tools` наследует все инструменты, доступные субагентам ([Справочник frontmatter](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)).
- Каждый участник работает из вашего определения под именем, которое вы выбрали в промпте порождения.
- Ведущий сохраняет выжившее объяснение и отвергнутые теории в `.practice/a-teams-debate.md`.
- Нет изменений отслеживаемых файлов, кроме вашего изменения из Рабочего примера.
- Вы просите каждого участника по имени завершить работу.

## Проверка

Вы закончили, когда всё перечисленное верно:

- [ ] Каждое определение, использованное участником, только для чтения. Эта команда ничего не выводит, если у каждого однострочный `tools:`, где перечислены только `Read`, `Grep` и `Glob` (используйте имя файла вашего определения):

  ```bash
  for f in .claude/agents/security-reviewer.md .claude/agents/test-reviewer.md .claude/agents/hypothesis-tester.md; do
    grep -qxE 'tools: *(Read|Grep|Glob)( *, *(Read|Grep|Glob))* *' "$f" || echo "$f: tools: names more than Read, Grep and Glob, or is missing"
  done
  ```

- [ ] Команда сформировалась, а не только субагенты: `sort -u .practice/a-teams-teammates.txt` перечисляет каждое имя участника, которое вы выбрали.
- [ ] Оба результата сохранены: `ls .practice/a-teams-review.md .practice/a-teams-debate.md` показывает оба файла.
- [ ] Команды не изменили отслеживаемые файлы: `git diff | diff - .practice/a-teams.diff` ничего не выводит.
- [ ] Самопроверка (не тестируется): отчёт о дебатах говорит, какие теории участники отвергли и почему, и вы попросили каждого участника по имени завершить работу.

Если лог участников отсутствует, команда не сформировалась: запустите ведущего командой из шага 4 и явно попросите команду агентов. Если `git diff` отличается от сохранённого изменения, ведущий или участник отредактировал отслеживаемый файл: прочтите разницу, отмените правку и проверьте строку `tools:` в каждом определении. Когда закончите, оставьте изменение или отмените временное с помощью `git restore <file>`.

## Будьте внимательны

- Участники запускаются с вашим режимом разрешений, кроме `dontAsk`, и если вы запускаете с `--dangerously-skip-permissions`, каждый участник тоже. Их запросы разрешений появляются в вашей сессии, чтобы вы ответили ([Разрешения](https://code.claude.com/docs/en/agent-teams#permissions)). Пока команды включены, субагент, которого называет Claude, запускается как участник, так что команда может сформироваться, когда вы её не просили: этот Электив включает команды только для сессий, запущенных с `--settings`, а не в ваших пользовательских или проектных настройках ([Включение команд агентов](https://code.claude.com/docs/en/agent-teams#enable-agent-teams)).
- Каждый активный участник продолжает использовать токены, пока не выйдет или сессия не закончится. Держите команды маленькими, ставьте Sonnet в определениях, держите промпты порождения сфокусированными и завершайте работу участников, когда их работа сделана ([Затраты токенов команд агентов](https://code.claude.com/docs/en/costs#agent-team-token-costs)).
- Два участника, редактирующие один файл, перезаписывают работу друг друга, поэтому дайте каждому свои файлы ([Избегание конфликтов файлов](https://code.claude.com/docs/en/agent-teams#avoid-file-conflicts)). А `/resume` и `/rewind` не возвращают внутрипроцессных участников: после возобновления попросите ведущего породить новых ([Ограничения](https://code.claude.com/docs/en/agent-teams#limitations)).

## Дальнейшие шаги

- [Обеспечение контроля качества с помощью хуков](https://code.claude.com/docs/en/agent-teams#enforce-quality-gates-with-hooks): хуки `TeammateIdle`, `TaskCreated` и `TaskCompleted`, которые завершаются с кодом 2, заставляют участника продолжать работу или останавливают создание или завершение задачи, пока ваше правило не выполнится.
- [Планирование участниками перед реализацией](https://code.claude.com/docs/en/agent-teams#have-teammates-plan-before-implementing): планирование только для чтения для команд, меняющих код. Claude Code одобряет каждый план по мере поступления, без проверки ведущим; правки и команды участника по-прежнему проходят через ваши запросы разрешений.
- [Выбор режима отображения](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode): каждый участник в своей панели tmux или iTerm2 вместо внутрипроцессной панели.

---

<sub>Источники: [Оркестрация команд сессий Claude Code](https://code.claude.com/docs/en/agent-teams) · [Запуск агентов параллельно](https://code.claude.com/docs/en/agents) · [Создание пользовательских субагентов](https://code.claude.com/docs/en/sub-agents) · [Справочник хуков](https://code.claude.com/docs/en/hooks) · [Справочник инструментов](https://code.claude.com/docs/en/tools-reference) · [Все настройки](https://code.claude.com/docs/en/settings-reference) · [Справочник CLI](https://code.claude.com/docs/en/cli-reference) · [Отладка конфигурации](https://code.claude.com/docs/en/debug-your-config) · [Эффективное управление затратами](https://code.claude.com/docs/en/costs)</sub>

<sub>Назад к [индексу продвинутого уровня](../README.md) · Тема: [Субагенты и параллельная работа](../../topics/subagents-and-parallel-work.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-agent-teams)</sub>
