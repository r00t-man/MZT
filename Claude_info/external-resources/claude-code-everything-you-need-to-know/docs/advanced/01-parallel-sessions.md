# Параллельные сессии с worktrees

<sub>**Продвинутый** · Урок 1 из 7 · около 20 минут · Требуется: [Продвинутый индекс](README.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете запускать две сессии Claude Code одновременно, каждую в своём git worktree, и объединять их работу в одну ветку.

## Вам понадобится

- Один из ваших собственных репозиториев с тестовой командой и без незакоммиченных изменений, на ветке по умолчанию и синхронизированный с удалённым репозиторием, в который вы можете пушить (см. «Watch out»), и ваша копия практического шаблона с Node.js LTS и продвинутыми проверками ([Практика](README.md#practice)): проверка запускается из копии. Настройте папку `.practice/` репозитория, как описано в [Уроке 1 для начинающих](../beginner/01-install-and-look-around.md#you-need), если ещё не сделали.
- Если вы ещё не запускали `claude` в этом репозитории, запустите его там один раз и примите диалог доверия: до этого `claude --worktree` завершается с ошибкой ([Запуск Claude в worktree](https://code.claude.com/docs/en/worktrees#start-claude-in-a-worktree)).
- macOS, Linux или WSL 2, и три открытых терминала в корне репозитория: два для сессий, один для git.
- Использование: умеренное. Две сессии работают одновременно.

## Идея

[git worktree](https://git-scm.com/docs/git-worktree) — это вторая рабочая папка, на своей ветке, которая разделяет историю репозитория. `claude --worktree <name>` (или `-w <name>`) создаёт её в `.claude/worktrees/<name>/` на новой ветке `worktree-<name>` и запускает сессию в ней ([Запуск Claude в worktree](https://code.claude.com/docs/en/worktrees#start-claude-in-a-worktree)). Каждая сессия редактирует свою копию файлов. Claude Code также не позволяет инструментам редактирования файлов worktree-сессии изменять вашу основную рабочую копию, а её командам — выполняться там или указывать git на неё ([Как Claude Code обеспечивает изоляцию](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)).

Коммиты и ветки общие. Незакоммиченные правки, установленные зависимости и gitignored-файлы, такие как `.env`, — нет: каждый worktree — это свежая выписка. Файл `.worktreeinclude` в корне репозитория копирует перечисленные в нём gitignored-файлы в каждый новый worktree ([Копирование gitignored-файлов в worktrees](https://code.claude.com/docs/en/worktrees#copy-gitignored-files-into-worktrees)); перечисляйте только то, что нужно проекту, поскольку каждый worktree получает свою копию каждого секрета.

Работа возвращается через git: каждая сессия коммитит в свою ветку, вы объединяете ветки из основной рабочей копии, затем удаляете worktrees.

## Практический пример

1. В основной рабочей копии добавьте в игнор папку, в которой находятся worktrees, затем закоммитьте и запушьте правило. Без него содержимое worktrees отображается как неотслеживаемые файлы в основной рабочей копии. Пуш помещает его в ветку по умолчанию удалённого репозитория, откуда начинаются новые worktrees (см. «Watch out»):

   ```bash
   printf '\n.claude/worktrees/\n' >> .gitignore
   git add .gitignore && git commit -m "Ignore Claude Code worktrees"
   git push
   ```

   Ведущий `\n` помещает правило на отдельную строку, даже если ваш `.gitignore` не заканчивается переводом строки. После этого `git status --short` ничего не выводит, а `git log -1 --oneline` показывает коммит.
2. В терминале 1 запустите сессию в новом worktree и дайте ей задачу по документации:

   ```bash
   claude --worktree docs-pass
   ```

   ```text
   Приведи в порядок формулировки первого раздела README, затем подожди меня, прежде чем коммитить.
   ```

   Claude Code создаёт `.claude/worktrees/docs-pass/` на ветке `worktree-docs-pass`, и сессия работает там. Одобрите правку, когда она попросит. Просьба подождать откладывает коммит до шага 4, даже если запрос разрешения не появится: worktree-сессия использует `.claude/settings.local.json` из основной рабочей копии ([Файлы настроек и приоритет](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)), поэтому при включённом режиме авторазрешения песочницы из [Урока 4 для среднего уровня](../intermediate/04-permissions-and-sandbox.md) команды в песочнице, такие как `git commit`, выполняются без запроса ([Режимы песочницы](https://code.claude.com/docs/en/sandboxing#sandbox-modes)).
3. В терминале 2 запустите вторую сессию с коротким флагом и дайте ей задачу по тестам:

   ```bash
   claude -w test-pass
   ```

   ```text
   Этот worktree — свежая выписка: установи зависимости, затем добавь один недостающий тест для небольшой экспортируемой функции и запусти тесты. Подожди меня, прежде чем коммитить.
   ```

   Claude Code создаёт `.claude/worktrees/test-pass/` на ветке `worktree-test-pass`; сессия устанавливает зависимости там, прежде чем добавить тест. Одобряйте её шаги так же.
4. В терминале 3, в основной рабочей копии, посмотрите на все три рабочие копии, пока обе сессии ждут вас:

   ```bash
   git worktree list
   git status --short
   git -C .claude/worktrees/docs-pass status --short
   git -C .claude/worktrees/test-pass status --short
   ```

   `git worktree list` показывает сначала основную рабочую копию, затем `.claude/worktrees/docs-pass` на `[worktree-docs-pass]` и `.claude/worktrees/test-pass` на `[worktree-test-pass]`; git может пометить каждый как `locked`, пока работает его сессия. `git status --short` не показывает правки ни одной из сессий: они происходят в других папках. Каждая команда `git -C` показывает только изменения сессии в этой папке, например README в `docs-pass`, и никогда — другой сессии. Теперь скажите каждой сессии закоммитить: `git log --oneline --graph --all` затем покажет новый коммит в каждой ветке.
5. Всё ещё в основной рабочей копии объедините обе ветки, затем запустите тесты:

   ```bash
   git merge worktree-docs-pass
   git merge worktree-test-pass
   ```

   [`git merge`](https://git-scm.com/docs/git-merge) переносит коммиты каждой ветки в вашу. Первое слияние просто перемещает вашу ветку вперёд (fast-forward): `worktree-docs-pass` началась с коммита, который вы запушили на шаге 1, поэтому у вашей ветки нет коммитов, которых ей не хватает. Второе создаёт коммит слияния, потому что у вашей ветки теперь есть коммит, которого нет у `worktree-test-pass`, и открывает ваш редактор для сообщения: сохраните и закройте его. Выполните этот шаг самостоятельно: пока сессия изолирована в своём worktree, Claude Code блокирует её git-команды, которые обращаются к основной рабочей копии. Если обе задачи изменили одни и те же строки, git остановится с конфликтом: разрешите его или запустите `claude` в основной рабочей копии и попросите его сделать это.
6. В каждой сессии выполните `/exit`. Ветка worktree имеет новый коммит, поэтому Claude Code спрашивает, сохранить или удалить worktree: выберите удалить ([Очистка worktrees](https://code.claude.com/docs/en/worktrees#clean-up-worktrees)). `git worktree list` больше не показывает ни один worktree.

> [!CAUTION]
> Удаление worktree удаляет его папку и ветку вместе с любой работой в них, которую вы не объединили. Сначала объедините или выберите сохранить.

## Ваша очередь

Выберите два небольших изменения в вашем репозитории, которые затрагивают разные файлы, например исправление в одном модуле и недостающий тест для другого. Сделайте каждое в своей worktree-сессии, запустив обе сессии одновременно, и перенесите оба в свою ветку.

Если работа, на которой они должны основываться, ещё не в ветке по умолчанию удалённого репозитория (см. «Watch out»), сначала поместите её туда или добавьте `"worktree": {"baseRef": "head"}` в `.claude/settings.local.json`, ваш личный файл настроек из [Урока 4 для среднего уровня](../intermediate/04-permissions-and-sandbox.md), чтобы новые worktrees начинались с вашего локального `HEAD` ([`worktree.baseRef`](https://code.claude.com/docs/en/settings-reference#worktree-baseref)).

Критерии приёмки:

- Закоммиченный `.gitignore` игнорирует `.claude/worktrees/` и не игнорирует остальную часть `.claude/`.
- Каждое изменение сделано в своей сессии, запущенной с `claude --worktree <name>`, и закоммичено в ветке этого worktree.
- `.practice/a-1-worktrees.txt` содержит вывод `git worktree list --porcelain`, сохранённый из основной рабочей копии, пока оба worktree существовали и оба закоммитили:

  ```bash
  git worktree list --porcelain > .practice/a-1-worktrees.txt
  ```

- Обе ветки объединены в вашу ветку с помощью `git merge`, а не [`git merge --squash`](https://git-scm.com/docs/git-merge#Documentation/git-merge.txt---squash).
- Ваши тесты проходят после обоих слияний (не проверяется).
- Оба worktree удалены, а любая сохранённая ветка удаляется только после объединения.
- Необязательно, не проверяется: если вашему проекту для запуска нужен gitignored-файл, например локальный конфиг, перечислите его в файле `.worktreeinclude` в корне репозитория.

## Проверка

Вы закончили, когда все следующие условия истинны:

- [ ] Закоммиченный `.gitignore` игнорирует `.claude/worktrees/`, а не остальную часть `.claude/`.
- [ ] `.practice/a-1-worktrees.txt` перечисляет два worktree в `.claude/worktrees/`, чьи коммиты разошлись друг от друга, и оба объединены в вашу ветку.
- [ ] Ни один из этих worktree больше не существует: `git worktree list` их не показывает.
- [ ] Самопроверка (не тестируется): пока обе сессии работали, ни одна не видела незакоммиченные правки другой.

Запустите `npm run check -- a-1 --dir <your repo>` из вашей практической копии.

Если первый пункт не выполнен, запустите `git -c core.excludesFile=/dev/null check-ignore -v .claude/worktrees/x` в вашем репозитории (часть `-c` заменяет ваш глобальный файл исключений, [`core.excludesFile`](https://git-scm.com/docs/gitignore), на пустой, как делает проверка): он должен указать ваш `.gitignore` и строку, которая совпадает ([git-check-ignore](https://git-scm.com/docs/git-check-ignore#Documentation/git-check-ignore.txt---verbose)). Правило только в `.git/info/exclude` или вашем глобальном файле исключений не закоммичено, а широкое правило, такое как `.claude/`, также скрыло бы настройки и навыки, которые вы коммитите для своей команды. Если второй пункт не выполнен, прочитайте подсказку, которую печатает проверка: сохраните файл после того, как обе сессии закоммитят, и до удаления любого worktree, и объедините каждую ветку с помощью `git merge`. Если третий пункт не выполнен, запустите `git worktree remove <path>` из основной рабочей копии для каждого пути, указанного проверкой, с `git worktree unlock <path>` сначала, если git говорит, что он заблокирован. Это оставит ветку worktree: удалите её после объединения с помощью `git merge-base --is-ancestor worktree-<name> HEAD && git branch -D worktree-<name>`. Первая команда завершается успешно только когда ветка является частью `HEAD` ([git-merge-base](https://git-scm.com/docs/git-merge-base#Documentation/git-merge-base.txt---is-ancestor)), а `-D` удаляет её без собственной проверки git на объединение, которая проверяет upstream ветки, если он есть, а не `HEAD` ([git-branch](https://git-scm.com/docs/git-branch#Documentation/git-branch.txt--D)).

## Watch out

- В большинстве репозиториев на macOS, Linux и WSL 2 выбор «Yes, and don't ask again» для команды Bash в worktree-сессии сохраняет правило в `.claude/settings.local.json` основной рабочей копии. Затем оно применяется в основной рабочей копии и во всех worktree репозитория и остаётся после удаления worktree ([Что worktrees разделяют с основной рабочей копией](https://code.claude.com/docs/en/worktrees#what-worktrees-share-with-the-main-checkout)). Одобряйте только команды, которые вы разрешили бы везде.
- Запуск нескольких сессий одновременно умножает использование токенов ([Запуск агентов параллельно](https://code.claude.com/docs/en/agents)). Давайте каждой сессии одну небольшую задачу и выходите из неё, как только её ветка объединена.
- Новый worktree ответвляется от ветки по умолчанию удалённого репозитория, а не от вашего локального `HEAD` ([Выбор базовой ветки](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)). Коммиты, которых ещё нет в этой ветке, например незапушенные коммиты или работа вашей функциональной ветки, в нём отсутствуют, а объединение его ветки в ветку, отстающую от ветки по умолчанию удалённого репозитория, привносит коммиты, которых не хватает этой ветке. Без удалённого репозитория новый worktree начинается с вашего локального `HEAD`.

## Дальнейшие шаги

- [Изоляция субагентов с worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees): `isolation: worktree` во frontmatter субагента даёт каждому запуску собственную рабочую копию.
- [Обмен сообщениями между вашими сессиями Claude Code](https://code.claude.com/docs/en/cross-session-messaging): позвольте сессиям в ваших worktrees передавать находки друг другу.
- [Запуск нескольких сессий Claude](https://code.claude.com/docs/en/best-practices#run-multiple-claude-sessions): паттерн Writer/Reviewer, где свежая сессия проверяет то, что написала другая.

---

<sub>Источники: [Запуск параллельных сессий с worktrees](https://code.claude.com/docs/en/worktrees) · [Все настройки](https://code.claude.com/docs/en/settings-reference) · [Файлы настроек и приоритет](https://code.claude.com/docs/en/settings) · [Настройка песочницы Bash tool](https://code.claude.com/docs/en/sandboxing) · [Запуск агентов параллельно](https://code.claude.com/docs/en/agents) · [git-worktree](https://git-scm.com/docs/git-worktree) · [git-merge](https://git-scm.com/docs/git-merge) · [git-check-ignore](https://git-scm.com/docs/git-check-ignore) · [gitignore](https://git-scm.com/docs/gitignore) · [git-merge-base](https://git-scm.com/docs/git-merge-base) · [git-branch](https://git-scm.com/docs/git-branch)</sub>

<sub>← [Продвинутый индекс](README.md) · [Выбор паттерна оркестрации](02-orchestration-patterns.md) → · Тема: [Субагенты и параллельная работа](../topics/subagents-and-parallel-work.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-1)</sub>
