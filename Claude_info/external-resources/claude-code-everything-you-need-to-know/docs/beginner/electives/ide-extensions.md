# Используйте Claude Code в вашем редакторе

<sub>**Начинающий** · Электив · около 15 минут · Требуется: [Установка, вход и осмотр](../01-install-and-look-around.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого Электива вы сможете запускать Claude Code внутри VS Code или IDE JetBrains, указывать ему на строки, которые вы просматриваете, и проверять его правки в режиме сравнения редактора.

## Вам понадобится

- Ваша копия практического шаблона, без незакоммиченных изменений, открытая в VS Code или IDE JetBrains, такой как IntelliJ IDEA или PyCharm.
- Для JetBrains — инструмент командной строки Claude Code из урока 1: плагин запускает его в терминале IDE.
- Использование: небольшое.

## Идея

Терминал — не единственное место, где работает Claude Code. Две интеграции с редактором помещают его рядом с вашим кодом:

- **Расширение VS Code** имеет собственную панель чата и поставляется со своей копией Claude Code. В ручном режиме оно показывает каждое предлагаемое изменение рядом с оригиналом и спрашивает перед применением ([VS Code](https://code.claude.com/docs/en/vs-code)).
- **Плагин JetBrains** запускает команду `claude` в терминале IDE и открывает предлагаемые правки в средстве просмотра различий IDE ([JetBrains IDEs](https://code.claude.com/docs/en/jetbrains)).

В любом случае это тот же Claude Code: тот же аккаунт, режимы разрешений и CLAUDE.md.

## Рабочий пример

В VS Code:

1. Откройте представление расширений с помощью `Cmd+Shift+X` (Mac) или `Ctrl+Shift+X` (Windows и Linux), найдите "Claude Code" и нажмите **Установить**. Расширение не работает в ограниченном режиме, поэтому если VS Code показывает баннер ограниченного режима или спрашивает, доверять ли папке, доверьтесь: эта копия — ваш собственный код ([Доверие к рабочей области](https://code.visualstudio.com/docs/editing/workspaces/workspace-trust)).
2. Откройте `src/config.js`. Нажмите значок Spark в правом верхнем углу редактора, чтобы открыть Claude Code, и войдите, если потребуется. Нет значка? Вместо этого нажмите `✻ Claude Code` в строке состояния внизу справа.
3. Выделите тело `parseConfig` и нажмите `Option+K` (Mac) или `Alt+K` (Windows и Linux). В поле подсказки появится ссылка с путём к файлу и номерами строк, например `@src/config.js#7-17`. Спросите:

   ```text
   Что произойдёт, если linkcheck.json содержит массив вместо объекта?
   ```

4. Переключите режим внизу поля подсказки на ручной, затем попросите небольшое изменение, например комментарий над `parseConfig`. Изменение откроется рядом с оригиналом, и Claude запросит разрешение на панели чата. Отклоните изменение там ([VS Code](https://code.claude.com/docs/en/vs-code)). Кнопки **Отклонить это изменение** внутри сравнения только отменяют одно изменение в предложении; они не завершают проверку.

В IDE JetBrains:

1. Установите [плагин Claude Code](https://plugins.jetbrains.com/plugin/27310-claude-code-beta-) из JetBrains Marketplace и перезапустите IDE.
2. Нажмите кнопку Claude Code в IDE или нажмите `Cmd+Esc` (Mac) или `Ctrl+Esc` (Windows и Linux), чтобы запустить Claude Code в терминале IDE. Если ничего не происходит, откройте терминал IDE и выполните `claude`: запущенный там, он сам подключится к IDE. Если IDE показывает "Не удаётся запустить Claude Code", он не может найти `claude` в вашем `PATH`: укажите полный путь к `claude` в разделе **Настройки** > **Инструменты** > **Claude Code [Beta]** > **Команда Claude** ([настройки плагина](https://code.claude.com/docs/en/jetbrains#general-settings)).
3. Откройте `src/config.js`, выделите тело `parseConfig` и нажмите `Cmd+Option+K` (Mac) или `Alt+Ctrl+K` (Windows и Linux). В подсказке появится ссылка, например `@src/config.js#L7-17`. Задайте тот же вопрос.
4. Нажимайте `Shift+Tab`, пока строка состояния под подсказкой не покажет `⏸ ручной режим включён` ([Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)). На нативном Windows, если `Shift+Tab` не работает, нажмите `Alt+M` ([Интерактивный режим](https://code.claude.com/docs/en/interactive-mode)). Затем попросите то же небольшое изменение: оно откроется в средстве просмотра различий IDE, и Claude запросит разрешение в терминале. Выберите **Нет** ([Настройка разрешений](https://code.claude.com/docs/en/permissions#add-a-comment-when-you-answer-a-permission-prompt)).

## Ваша очередь

1. Установите расширение или плагин для используемого вами редактора.
2. Откройте `src/links.js`, выделите всю функцию `findLinks` и нажмите сочетание клавиш для ссылки: `Option+K` (Mac) или `Alt+K` (Windows и Linux) в VS Code, `Cmd+Option+K` (Mac) или `Alt+Ctrl+K` (Windows и Linux) в JetBrains. Затем спросите, какие виды ссылок она находит.
3. Переключитесь в ручной режим, как в рабочем примере, попросите небольшое изменение и просмотрите его в режиме сравнения. Затем отклоните изменение в запросе разрешения Claude: на панели чата в VS Code или выбрав **Нет** в терминале в JetBrains.

## Проверка

В этом Элективе нет `npm run check`: отметьте каждый пункт самостоятельно. Вы закончили, когда все следующие утверждения верны:

- [ ] Интеграция установлена. VS Code: представление расширений (`Cmd+Shift+X` или `Ctrl+Shift+X`) показывает Claude Code как установленный. JetBrains: плагин отображается в разделе **Настройки** > **Плагины** > **Установленные**.
- [ ] `git diff` ничего не выводит, потому что вы отклонили изменение.
- [ ] Самопроверка (не тестируется): вы задали вопрос со ссылкой на выделенные строки.

Если `git diff` показывает изменение, оно было применено: сеанс не был в ручном режиме, или вы его одобрили. Отмените его с помощью `git restore <файл>`, используя имя файла из вывода `git diff`. Затем переключитесь в ручной режим, снова попросите изменение и отклоните его.

## Дальнейшие шаги

- [Быстрый старт для настольного приложения](https://code.claude.com/docs/en/desktop-quickstart): Claude Code в настольном приложении Claude.
- [Команды и сочетания клавиш VS Code](https://code.claude.com/docs/en/vs-code#vs-code-commands-and-shortcuts).

---

<sub>Источники: [VS Code](https://code.claude.com/docs/en/vs-code) · [JetBrains IDEs](https://code.claude.com/docs/en/jetbrains) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Выбор режима разрешений](https://code.claude.com/docs/en/permission-modes) · [Интерактивный режим](https://code.claude.com/docs/en/interactive-mode) · [Доверие к рабочей области](https://code.visualstudio.com/docs/editing/workspaces/workspace-trust)</sub>

<sub>Назад к [индексу для начинающих](../README.md) · Тема: [Память и контекст](../../topics/memory-and-context.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=b-ide)</sub>
