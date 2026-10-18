# Память проекта с CLAUDE.md

<sub>**Начинающий** · Урок 5 из 5 · около 20 минут · Требуется: [Ваше первое изменение, от запроса до коммита](03-first-change.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете создать CLAUDE.md проекта и показать, что новая сессия следует ему.

## Вам понадобится

- Ваша копия практического шаблона без незакоммиченных изменений и Node.js LTS (Codespace на вашей копии уже имеет его). Чтобы практиковаться в одном из ваших собственных репозиториев, сохраните также копию шаблона: проверка выполняется из неё. Настройте папку `.practice/` репозитория, как описано в [уроке 1](01-install-and-look-around.md#you-need), если ещё не сделали этого.
- Использование: небольшое.

## Идея

Каждая сессия начинается с чистого контекстного окна, поэтому вы можете повторять привычки вашего проекта. Файл `CLAUDE.md` в корне проекта решает эту проблему: Claude Code читает его в начале каждой сессии ([Как Claude помнит ваш проект](https://code.claude.com/docs/en/memory)).

- Поместите в него то, что должна знать каждая сессия: команды сборки и тестирования, соглашения, структуру проекта, правила «всегда делай X». Делайте его кратким; документация рекомендует менее 200 строк.
- Закоммитьте его, чтобы все, кто работает над проектом, получали одинаковые инструкции.
- `/init` пишет первую версию за вас на основе того, что найдёт в коде.
- Claude рассматривает CLAUDE.md как контекст, а не как конфигурацию, которой он обязан подчиняться. Правило, которое никогда не должно нарушаться, требует [hook](https://code.claude.com/docs/en/hooks-guide), о котором рассказывается на [среднем уровне](../intermediate/README.md).

Сессия читает CLAUDE.md при запуске, поэтому после изменения файла начните новую сессию, чтобы убедиться, что она использует изменение.

## Разобранный пример

1. Запустите `claude` в вашей практической копии и выполните:

   ```text
   /init
   ```

   Claude читает код и пишет `CLAUDE.md` с найденными командами и соглашениями. Одобрите файл, если он попросит. Во втором терминале прочитайте его с помощью `cat CLAUDE.md`.
2. Откройте `CLAUDE.md` в вашем редакторе или введите `/memory` и выберите **Project instructions**, `./CLAUDE.md` в этой папке. Не выбирайте пользовательский файл в `~/.claude/`: он применяется ко всем вашим проектам ([Просмотр и редактирование с помощью `/memory`](https://code.claude.com/docs/en/memory#view-and-edit-with-%2Fmemory)). Терминальный редактор, такой как Vim, занимает терминал, пока вы не сохраните и не выйдете.

   В практической копии `/init` может также описать собственные файлы курса: `checks/`, `learn/`, `capstone/` и `.github/`. Удалите то, что он говорит о них и о `npm run check`, `npm run learn` и `npm run test:checks`, включая любое правило, которое говорит держать вашу работу вне `main`: это правило для репозитория-шаблона, а не для вашей копии. Оставьте другие команды, включая `npm test`, которую проверяет [capstone](capstone.md).

   Затем добавьте правило, которое проявляется в файлах, чтобы вы могли видеть, следует ли ему сессия. Поместите его под заголовком `## Conventions` и добавьте этот заголовок в конец файла, если `/init` не написал его:

   ```markdown
   - Every new source file starts with the line `// Part of linkcheck.`
   ```

   Во втором терминале сохраните точную строку правила для проверки:

   ```bash
   echo '// Part of linkcheck.' > .practice/b-5-rule.txt
   ```

   **Windows:** `'// Part of linkcheck.' | Set-Content .practice/b-5-rule.txt`
3. Сохраните `CLAUDE.md`, затем закоммитьте его во втором терминале:

   ```bash
   git add CLAUDE.md
   git commit -m "Add project instructions for Claude Code"
   ```

4. Введите `/exit`, затем начните новую сессию с `claude`, чтобы она загрузила CLAUDE.md с вашим правилом. Введите `/context all` и найдите `CLAUDE.md` в разделе **Memory files**: сессия загрузила его. Обычный `/context` может свернуть этот список, а `all` разворачивает его ([Команды](https://code.claude.com/docs/en/commands)).
5. Попросите изменение, которое создаёт новый файл:

   ```text
   Add src/stats.js with a function countLinks(markdown) that returns how many links findLinks finds. Add a test in test/stats.test.js, run the tests and commit.
   ```

   Одобряйте любые запросы разрешений, которые показывает Claude. В автоматическом режиме вы можете не увидеть их: автоматический режим позволяет Claude работать без рутинных запросов разрешений ([Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)).
6. Во втором терминале посмотрите первую строку нового файла, сохраните коммит для проверки и убедитесь, что ничего не осталось:

   ```bash
   head -1 src/stats.js
   git rev-parse HEAD > .practice/b-5-commit.txt
   git status
   ```

   **Windows:** `Get-Content src/stats.js -TotalCount 1` заменяет `head -1`.

   Первая строка должна быть `// Part of linkcheck.`, хотя вы не просили об этом в этой сессии. `git status` должен показать `nothing to commit, working tree clean`. Если он показывает `src/stats.js`, Claude ещё не закоммитил: попросите его закоммитить, затем сохраните коммит снова.

## Ваша очередь

Повторите пример в вашей практической копии или вашем собственном репозитории с новым правилом и новым файлом. В вашей практической копии уже есть `CLAUDE.md`, поэтому пропустите `/init` там:

1. Откройте `CLAUDE.md` и замените правило из примера на новое:

   ```markdown
   - Every new source file starts with the line `// linkcheck source.`
   ```

2. Во втором терминале сохраните точную строку нового правила: `echo '// linkcheck source.' > .practice/b-5-rule.txt` (**Windows:** `'// linkcheck source.' | Set-Content .practice/b-5-rule.txt`).
3. Закоммитьте `CLAUDE.md` там.
4. Выйдите, начните новую сессию и проверьте, что `/context all` показывает `CLAUDE.md` в разделе **Memory files**.
5. Попросите новый файл и его тест и позвольте Claude закоммитить:

   ```text
   Add src/external.js with a function countExternal(markdown) that returns how many of the links findLinks finds are external, according to isExternal. Add a test in test/external.test.js, run the tests and commit.
   ```

6. Как в шаге 6 примера, проверьте первую строку `src/external.js`, сохраните коммит в `.practice/b-5-commit.txt` и выполните `git status`.

В вашем собственном репозитории начните с `/init`; если в репозитории уже есть `CLAUDE.md`, `/init` предлагает улучшения, а не перезаписывает его. Напишите правило в стиле комментариев вашего языка, например `# Part of my-project.`, сохраните эту точную строку в `.practice/b-5-rule.txt` на шаге 2 и попросите небольшой новый файл. Если в репозитории есть `AGENTS.md`, поместите `@AGENTS.md` в первую строку `CLAUDE.md`: по умолчанию, как только существует `CLAUDE.md`, Claude читает его вместо `AGENTS.md` ([AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)).

## Проверка

Вы закончили, когда все следующие условия истинны:

- [ ] Закоммиченный CLAUDE.md содержит правило, сохранённое в `.practice/b-5-rule.txt`: `git show HEAD:CLAUDE.md` показывает его.
- [ ] Коммит, указанный в `.practice/b-5-commit.txt`, добавляет по крайней мере один файл, кроме тестов и Markdown, и каждый такой файл начинается с этого правила: `git show --stat $(cat .practice/b-5-commit.txt)` показывает их. **Windows:** `git show --stat (Get-Content .practice/b-5-commit.txt)`.
- [ ] Самопроверка (не тестируется): вы начали новую сессию после добавления правила в CLAUDE.md и можете объяснить, почему это важно.

Выполните `npm run check -- b-5` в вашей практической копии. В вашем собственном репозитории выполните `npm run check -- b-5 --dir <your repo>` из вашей практической копии.

Если CLAUDE.md не закоммичен, выполните `git add CLAUDE.md` и закоммитьте его. Если новый файл не начинается с правила, начните новую сессию и выполните `/context all`. Если `CLAUDE.md` отсутствует в разделе **Memory files**, сессия не видит его: запустите `claude` в папке, содержащей `CLAUDE.md`. Если он есть в списке, Claude прочитал правило, но не последовал ему. В любом случае попросите сессию создать другой новый файл, например `src/summary.js` с тестом, и закоммитить его. Затем сохраните этот коммит с помощью `git rev-parse HEAD > .practice/b-5-commit.txt` и выполните проверку снова. Исправление старого файла на месте не пройдёт, потому что проверка читает только файлы, добавленные этим коммитом.

## Дальнейшие шаги

- [Написание эффективного CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md): что включать и что исключать.
- [Использование файлов CLAUDE.md](https://claude.com/blog/using-claude-md-files): руководство Anthropic с примерами.

---

<sub>Источники: [Как Claude помнит ваш проект](https://code.claude.com/docs/en/memory) · [Команды](https://code.claude.com/docs/en/commands) · [Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes) · [Лучшие практики](https://code.claude.com/docs/en/best-practices) · [Автоматизация действий с помощью hooks](https://code.claude.com/docs/en/hooks-guide)</sub>

<sub>← [Держите сессию в курсе](04-keep-a-session-on-track.md) · [Индекс для начинающих](README.md) · [Capstone для начинающих](capstone.md) → · Тема: [Память и контекст](../topics/memory-and-context.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=b-5)</sub>
