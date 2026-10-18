# Паттерны навыков: живые данные, вспомогательные файлы и собственный контекст

<sub>**Intermediate** · Elective · около 20 минут · Требуется: [Превращение повторяющегося рабочего процесса в навык](../01-first-skill.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого Elective вы сможете написать навык, который подтягивает живые данные в свой промпт, хранит длинный справочный материал в отдельном файле и работает в собственном субагенте.

## Вам понадобится

- Репозиторий с некоторыми незакоммиченными изменениями для проверки и навыки из [урока 1](../01-first-skill.md).
- Использование: небольшое.

## Идея

Навыки из урока 1 состояли из инструкций и `$ARGUMENTS`. Ещё несколько паттернов позволяют навыку делать больше с меньшим контекстом ([Расширение Claude с помощью навыков](https://code.claude.com/docs/en/skills)):

| Паттерн | Записывается как | Что делает |
|---|---|---|
| Живые данные | `` !`git diff HEAD` `` в теле | Claude Code выполняет команду до того, как Claude прочитает навык, и подставляет её вывод на место |
| Вспомогательные файлы | Файлы рядом с `SKILL.md`, связанные из него | Длинный справочный материал, который Claude читает только при необходимости |
| Собственный контекст | `context: fork` в frontmatter | Навык становится промптом субагента, и субагент работает в фоне. Он не видит ваш разговор, и его результат приходит по завершении |
| Именованные аргументы | `arguments: [focus]`, затем `$focus` | Каждое слово, которое вы вводите после имени, заполняет свой плейсхолдер |
| Разрешения инструментов | `allowed-tools: Read, Grep` | Claude может использовать эти инструменты без запроса во время хода, выполняющего навык. Это не удаляет другие инструменты |

Держите `SKILL.md` коротким: после запуска навыка весь его текст остаётся в разговоре. Документация рекомендует менее 500 строк, с переносом деталей во вспомогательные файлы.

## Рабочий пример

1. Сохраните это как `.claude/skills/changes-review/SKILL.md`:

   ```markdown
   ---
   name: changes-review
   description: Reviews the uncommitted changes in this repository against the team checklist. Use when the user asks for a review before committing.
   context: fork
   allowed-tools: Bash(git diff *)
   ---

   ## Changes

   !`git diff HEAD`

   ## Your task

   Review the changes above against [checklist.md](checklist.md). Report each problem with its file and line, then one line on whether the change is ready to commit.
   ```

2. Сохраните чек-лист рядом, как `.claude/skills/changes-review/checklist.md`:

   ```markdown
   - Every changed function has a test.
   - Errors are reported, not swallowed.
   - No secrets in code or config.
   ```

3. Внесите небольшое изменение в исходный файл, запустите `claude` и выполните `/changes-review`. Claude Code выполнит `git diff HEAD` и подставит его вывод в навык, затем запустит субагента с ним. Субагент прочитает чек-лист, и его отчёт появится в вашем разговоре по завершении. Правило `allowed-tools` предварительно одобряет команды `git diff`. `git diff HEAD` доступна только для чтения и выполнилась бы и без этого, но вне автоматического режима внедрённая команда, которую ваши правила разрешений не допускают, останавливает навык.
4. Для другого навыка, который предварительно одобряет инструменты, прочитайте [`claude-md-review`](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/blob/main/.claude/skills/claude-md-review/SKILL.md) из этого руководства. Его `allowed-tools: Read, Glob, Grep` позволяет читать файлы без запросов; это не мешает Claude использовать другие инструменты ([Предварительное одобрение инструментов для навыка](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)).

## Ваша очередь

Сделайте так, чтобы проверка учитывала фокус:

1. Добавьте `arguments: [focus]` в frontmatter `changes-review`.
2. Измените задачу, чтобы фокус проверки был на первом месте: `Review the changes above against checklist.md, looking hardest at $focus.`
3. Выполните `/changes-review tests`, затем `/changes-review secrets` и сравните два отчёта.

## Проверка

Вы закончили, когда все следующие условия выполнены:

- [ ] `head -8 .claude/skills/changes-review/SKILL.md` показывает `context: fork` и `arguments: [focus]`.
- [ ] `grep -c 'git diff HEAD' .claude/skills/changes-review/SKILL.md` выводит 1, и `checklist.md` находится рядом с `SKILL.md`.
- [ ] Самопроверка (не тестируется): два отчёта сосредоточились на разных вещах.

Если `/changes-review` останавливается с `Shell command failed` или `Shell command permission check failed`, выполните `git diff HEAD` самостоятельно и проверьте строку `allowed-tools`: внедрённая команда, которая завершилась с ошибкой или не разрешена вашими правилами, прерывает весь навык ([Внедрение динамического контекста](https://code.claude.com/docs/en/skills#inject-dynamic-context)).

## Дополнительно

- [Лучшие практики написания навыков](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices): как писать описания, структурировать вспомогательные файлы и тестировать навык.
- [anthropics/skills](https://github.com/anthropics/skills): примеры навыков от Anthropic. Некоторые из них доступны с исходным кодом, но не являются открытым ПО, поэтому читайте лицензию каждого перед копированием.
- [Устранение неполадок](https://code.claude.com/docs/en/skills#troubleshooting): навыки, которые не срабатывают, срабатывают слишком часто или перестают выполняться.

---

<sub>Источники: [Extend Claude with skills](https://code.claude.com/docs/en/skills) · [anthropics/skills](https://github.com/anthropics/skills)</sub>

<sub>Назад к [Intermediate index](../README.md) · Тема: [Skills](../../topics/skills.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-skill-patterns)</sub>
