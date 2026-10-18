# Agent view

<sub>**Продвинутый** · Электив · около 20 минут, плюс время выполнения · Требуется: [Параллельные сессии с worktrees](../01-parallel-sessions.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

> [!NOTE]
> "Agent view находится в research preview. Интерфейс и сочетания клавиш могут меняться по мере развития функции." ([Manage multiple agents with agent view](https://code.claude.com/docs/en/agent-view))

## Цель

К концу этого электива вы сможете передавать несколько независимых задач фоновым сессиям с одного экрана, вмешиваться только когда это необходимо, и объединять или отбрасывать результаты каждой сессии.

## Вам понадобится

- Ваша копия практического шаблона и Node.js LTS для рабочего примера; один из ваших собственных репозиториев для раздела "Ваша очередь". Вы практикуетесь в одноразовых клонах, удалённый репозиторий которых — папка на вашей машине, так что ничего, что сессия отправляет, не покидает вашу машину. Шаг 1 создаёт клон для рабочего примера.
- macOS, Linux или WSL 2, и два терминала: один для agent view, один для git. На macOS держите клоны вне Desktop, Documents и Downloads, где фоновая сессия может сообщать `Operation not permitted`, пока вы не предоставите ей доступ ([Background sessions can't read Desktop, Documents, or Downloads on macOS](https://code.claude.com/docs/en/agent-view#background-sessions-can%E2%80%99t-read-desktop-documents-or-downloads-on-macos)).
- Использование: умеренное. Каждая сессия расходует ваш лимит независимо ([Quick start](https://code.claude.com/docs/en/agent-view#quick-start)), и однострочное резюме каждой строки — это короткий запрос класса Haiku при завершении хода и каждые несколько минут во время длинного хода ([Row summaries](https://code.claude.com/docs/en/agent-view#row-summaries)). Дешёвый вариант: на шаге 3 отправьте только первую задачу, затем введите `! npm test` как вторую. Shell-задание выполняет команду вместо Claude, поэтому модель не вызывается, и его строка очищается через несколько минут после завершения команды ([Run a shell command](https://code.claude.com/docs/en/agent-view#run-a-shell-command)). Шаги с 4 по 8 затем применяются к одной сессии Claude: ожидайте один worktree, одну ветку и одну сессию для удаления.

## Идея

[Agent view](https://code.claude.com/docs/en/agent-view), открываемый командой `claude agents`, — это один экран для ваших фоновых сессий: полноценные разговоры Claude Code, работающие без прикреплённого терминала. Каждый введённый там промпт запускает свою собственную сессию, которую фоновый сервис продолжает выполнять после закрытия экрана. Каждая строка показывает, работает ли сессия, нуждается ли в вашем вводе или завершена ([Read session state](https://code.claude.com/docs/en/agent-view#read-session-state)).

В [уроке 1](../01-parallel-sessions.md) вы создавали worktrees самостоятельно. Здесь Claude делает это: перед тем как отправленная сессия редактирует файл, она перемещается в свой собственный worktree в `.claude/worktrees/`. Claude Code инструктирует её делать коммиты в ветке worktree и отправлять эту ветку, если у репозитория есть удалённый репозиторий, если только задача, ваш `CLAUDE.md` или память не говорят, что вы сами управляете git. Ей запрещено отправлять в `main` или `master`, делать force-push или merge. Какова бы ни была задача, она заканчивается отчётом о том, что было сделано и где находится работа ([How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)).

> [!WARNING]
> Фоновая сессия действует, пока вы не смотрите. Открытый из вашей оболочки без `--permission-mode`, agent view запускает каждую сессию так же, как новая сессия `claude` в этой папке, обычно в auto mode ([Permission mode](https://code.claude.com/docs/en/agent-view#permission-mode), [Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)), где Claude делает коммиты без запроса и отправляет свою ветку, если у репозитория есть удалённый репозиторий. Открывайте agent view с выбранным вами режимом разрешений, никогда с `--dangerously-skip-permissions`, и практикуйтесь в клоне, удалённый репозиторий которого — папка на вашей машине.

## Рабочий пример

1. Из папки, содержащей вашу копию практического шаблона, сделайте одноразовый клон с локальным удалённым репозиторием и проверьте, что его тесты проходят. Замените `<template copy>` на имя папки вашей копии:

   ```bash
   git clone --bare <template copy> av-origin.git
   git clone av-origin.git av-practice
   cd av-practice
   mkdir -p .practice
   printf '%s\n' .practice/ .claude/worktrees/ >> "$(git rev-parse --git-path info/exclude)"
   npm test
   ```

   `npm test` проходит, и `origin` теперь папка `av-origin.git`, так что push остаётся на вашей машине. Строки exclude скрывают две папки из `git status` без коммита: `.practice/`, где "Ваша очередь" сохраняет свои файлы (как в [Beginner lesson 1](../../beginner/01-install-and-look-around.md#you-need)), и worktrees, которые создаёт Claude ([gitignore](https://git-scm.com/docs/gitignore), [Start Claude in a worktree](https://code.claude.com/docs/en/worktrees#start-claude-in-a-worktree)).
2. В первом терминале откройте agent view с двумя значениями по умолчанию для отправки: Manual mode, в котором только чтение выполняется без запроса ([Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)), и Sonnet ([Model aliases](https://code.claude.com/docs/en/model-config#model-aliases)):

   ```bash
   claude agents --permission-mode manual --model sonnet
   ```

   Примите диалог доверия для новой папки. Заголовок называет модель, которую используют новые сессии ([Set the model](https://code.claude.com/docs/en/agent-view#set-the-model)), и каждая сессия, отправленная из этого представления, начинается с обоими значениями по умолчанию ([Dispatch defaults](https://code.claude.com/docs/en/agent-view#dispatch-defaults)). Если у вас нет других фоновых сессий, список показывает пустые заголовки разделов, каждый с описанием. Если `claude agents` перечисляет ваши subagents и завершается, проверьте, что ни один файл настроек не устанавливает `disableAgentView` в `true` и что `CLAUDE_CODE_DISABLE_AGENT_VIEW` не задана ([Turn off agent view](https://code.claude.com/docs/en/agent-view#turn-off-agent-view)).
3. Отправьте две задачи, затрагивающие разные файлы. Введите каждую и нажмите `Enter`; каждый промпт запускает свою собственную сессию:

   ```text
   Add a --json option to src/cli.js that prints the broken links as a JSON array instead of text lines. Add a test for it in a new file, test/cli.test.js, and run npm test.
   ```

   ```text
   Write docs/config.md describing each linkcheck.json option in src/config.js, with its default and an example. Don't change any code.
   ```

   Появляются две строки в разделе `Working`, каждая названа по своему промпту.
4. Когда сессия нуждается в вашем одобрении, для редактирования или команды, её строка перемещается в раздел `Needs input`. Выберите её с помощью `↑` или `↓` и нажмите `Space`: панель просмотра показывает, чего она ожидает ([Peek and reply](https://code.claude.com/docs/en/agent-view#peek-and-reply)). Ответ, введённый там, не отвечает на запрос разрешения, поэтому нажмите `→`, чтобы присоединиться. В v2.1.285 фоновая сессия, ожидающая вашего одобрения, может отображаться как завершённая (исправлено в v2.1.286), и `claude agents` иногда не показывает запрос разрешения, которого ожидает сессия (исправлено в v2.1.287) ([CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)): если строка отображается как завершённая без отчёта, или её просмотр не показывает запроса, присоединитесь с помощью `→`.
5. Присоединившись, сессия заполняет терминал с кратким резюме того, что произошло, пока вас не было. Прочитайте, что Claude хочет сделать, и одобрите, если это соответствует задаче, но не с `Yes, and switch to auto mode`, который может предложить запрос команды: это переключит эту ненаблюдаемую сессию в auto mode ([Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)). Вы можете оставаться присоединённым и одобрять её следующие запросы, такие как `git commit` или `git push`, которые она просит выполнить, затем нажмите `←` на пустом промпте: вы вернётесь в таблицу, и сессия продолжит работу ([Attach to a session](https://code.claude.com/docs/en/agent-view#attach-to-a-session)). Делайте то же самое, когда какая-либо строка нуждается в вас.
6. Во втором терминале, в `av-practice`, посмотрите на ваш checkout, пока сессии работают:

   ```bash
   git status --short
   git worktree list
   ```

   `git status --short` ничего не выводит: сессии редактируют в другом месте. Как только сессия попросила редактировать, `git worktree list` показывает worktree для неё в `.claude/worktrees/`, с её веткой в скобках.
7. Когда строка каждой сессии находится в разделе `Completed`, просмотрите её: результат говорит, что она сделала и где находится работа, например, её ветка (ваша формулировка будет отличаться). Результат, который не говорит, что сессия сделала и где находится работа, может всё ещё ожидать вашего одобрения, как предупреждает шаг 4: присоединитесь с помощью `→` и сначала ответьте. Во втором терминале объедините то, что хотите сохранить, затем запустите тесты:

   ```bash
   git merge --no-edit <branch>
   npm test
   ```

   Выполните merge один раз для каждой ветки, которую вы сохраняете, используя имя ветки из результата её сессии или из `git worktree list`. `npm test` проходит; если вы сохранили ветку `--json`, она запускает больше тестов, чем на шаге 1.
8. Очистите из второго терминала. Перечислите сессии этой папки, каждую с её коротким `id`, затем удалите каждую:

   ```bash
   claude agents --json --all --cwd "$PWD"
   claude rm <id>
   ```

   `claude rm` также удаляет worktree, который Claude создал для сессии, когда это безопасно. Он сохраняет worktree, содержащий незакоммиченные изменения, или коммиты, которые он не может подтвердить как сохранённые в другом месте, и говорит почему. Коммиты в удалённом репозитории или объединённые в ветку по умолчанию, которую вы извлекли, считаются сохранёнными ([What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes)). После этого `git worktree list` показывает только ваш checkout. Нажмите `Esc` в agent view, чтобы вернуться в вашу оболочку.

## Ваша очередь

**Краткое описание:** в одноразовом клоне вашего собственного репозитория, сделанном как на шаге 1 с новыми именами папок и вашей собственной командой тестирования, передайте две задачи, которые вы откладывали, затрагивающие разные файлы. Каждый worktree — это свежий checkout ([Set up the worktree environment](https://code.claude.com/docs/en/worktrees#set-up-the-worktree-environment)), поэтому задача, которая запускает ваши тесты, должна сказать сначала установить зависимости в её worktree, как это делала тестовая задача урока 1. Пока обе сессии работают, сохраните два файла `.practice/`, названные в критериях ниже.

Затем во втором терминале запустите сессию в клоне самостоятельно с помощью `claude --permission-mode manual`: сессия, которую вы перемещаете, сохраняет режим, в котором она была, а обычный `claude` обычно запускается в auto mode ([Permission mode](https://code.claude.com/docs/en/agent-view#permission-mode)). Задайте ей вопрос о коде, не требующий правок, и переместите её в agent view с помощью `/background`, что освобождает этот терминал и возвращает вас в оболочку ([Send the session to the background](https://code.claude.com/docs/en/agent-view#send-the-session-to-the-background)). Сессия, которую вы перемещаете, продолжает работать в вашем checkout, без собственного worktree. Наблюдайте за всеми тремя из agent view, пока работа каждой отправленной сессии не будет объединена или отброшена.

**Критерии приёмки:**

- Agent view открыт с режимом разрешений и моделью, которые вы выбрали для работы.
- Две отправленные сессии изменяют файлы, которые другая не трогает.
- Пока обе работают, после того как каждая попросила редактировать, и до того как вы запустите сессию, которую перемещаете, вы сохраняете состояние вашего checkout:

  ```bash
  git status --short > .practice/a-view-status.txt
  git worktree list > .practice/a-view-worktrees.txt
  ```

- Эта сессия перемещена в agent view с помощью `/background` (алиас `/bg`) после вашего вопроса ([Commands](https://code.claude.com/docs/en/commands)).
- На каждую строку `Needs input` дан ответ: на вопрос из панели просмотра, на запрос разрешения — присоединением.
- То, что вы сохраняете, объединено в вашу ветку, ваши тесты проходят, и каждая сессия, которую вы запустили, удалена с помощью `claude rm <id>`.

## Проверка

Вы закончили, когда все следующие пункты верны:

- [ ] Ваш checkout оставался чистым, пока отправленные сессии работали, и у каждой был собственный worktree: `.practice/a-view-status.txt` пуст, и `.practice/a-view-worktrees.txt` перечисляет путь в `.claude/worktrees/` для каждой из них. В вашем клоне `[ ! -s .practice/a-view-status.txt ] && grep /.claude/worktrees/ .practice/a-view-worktrees.txt` выводит одну строку для каждой.
- [ ] `git log --oneline` на вашей ветке показывает работу, которую вы сохранили, и ваши тесты проходят.
- [ ] `claude agents --json --all --cwd "$PWD"` не перечисляет ни одной сессии, у которой `kind` равен `background`, и `git worktree list` не показывает ничего в `.claude/worktrees/`.
- [ ] Самопроверка (не тестируется): вы ответили на каждую строку `Needs input` из agent view, не переключаясь в вашу оболочку, и можете сказать, на какие запросы ответила панель просмотра, а какие потребовали присоединения.

Если первый пункт не выполнен, сохраните файлы снова при следующем запуске, пока обе отправленные сессии работают: сессия, которая ещё не попросила редактировать, не имеет worktree, сессия, которую вы переместили, редактирует ваш checkout на месте, а файл настроек, устанавливающий [`worktree.bgIsolation`](https://code.claude.com/docs/en/settings-reference#worktree-bgisolation) в `"none"`, отключает worktrees. Если в вашей ветке отсутствует работа, которую вы сохранили, или ваши тесты не проходят после merge, найдите сессию, стоящую за этим. Сессия оставляет git вам, когда задача, ваш `CLAUDE.md` или память говорят, что вы управляете им, и работа, оставленная незакоммиченной в её worktree, должна быть закоммичена там, прежде чем вы сможете её объединить: присоединитесь к этой сессии и попросите её сделать коммит. Для ветки, которая сломала ваши тесты, исправьте её самостоятельно или присоединитесь к этой сессии до её удаления и скажите, что не удалось; затем объедините исправление. Если `claude rm` сохранил сессию, прочитайте причину, которую он вывел, например, незакоммиченные изменения или неотправленные коммиты, и следуйте [What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes). Удалите worktree, оставшийся без сессии, с помощью `git worktree remove <path>` ([`.claude/worktrees/` is filling up](https://code.claude.com/docs/en/agent-view#claude%2Fworktrees%2F-is-filling-up)), сначала выполнив `git worktree unlock <path>`, если git говорит, что он заблокирован ([Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)).

## Осторожно

- Удаление сессии в agent view с помощью `Ctrl+X` дважды удаляет worktree, который Claude создал для неё, включая незакоммиченные изменения; `claude rm` сохраняет worktree, в котором они есть ([What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes)). Сначала сделайте коммит или merge того, что хотите сохранить.
- Фоновые сессии используют ваш лимит так же, как интерактивные, поэтому несколько одновременно расходуют его в несколько раз быстрее ([Limitations](https://code.claude.com/docs/en/agent-view#limitations)).
- `/agents` внутри сессии — это другая команда, отличная от `claude agents`, несмотря на похожее название ([Check on running work](https://code.claude.com/docs/en/agents#check-on-running-work)).

## Дальнейшие шаги

- [Read session state from a script](https://code.claude.com/docs/en/agent-view#read-session-state-from-a-script): опрашивайте `claude agents --json --all` из строки состояния или другой программы.
- [Copy the session with /fork](https://code.claude.com/docs/en/agent-view#copy-the-session-with-%2Ffork): отправьте копию вашего разговора в фон и продолжайте работать там, где вы находитесь.
- [Message your other Claude Code sessions](https://code.claude.com/docs/en/cross-session-messaging): позвольте сессиям, которые вы отправляете, передавать находки друг другу.

---

<sub>Источники: [Manage multiple agents with agent view](https://code.claude.com/docs/en/agent-view) · [Run agents in parallel](https://code.claude.com/docs/en/agents) · [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) · [Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees) · [All settings](https://code.claude.com/docs/en/settings-reference) · [Commands](https://code.claude.com/docs/en/commands) · [Model configuration](https://code.claude.com/docs/en/model-config) · [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) · [gitignore](https://git-scm.com/docs/gitignore)</sub>

<sub>Назад к [индексу Advanced](../README.md) · Тема: [Subagents and parallel work](../../topics/subagents-and-parallel-work.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-agent-view)</sub>
