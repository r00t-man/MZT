# Установка и управление плагинами

<sub>**Intermediate** · Урок 8 из 8 · около 20 минут · Требуется: [Превратите повторяющийся рабочий процесс в skill](01-first-skill.md), [Обеспечьте соблюдение правила с помощью hook](05-hooks.md), [Делегируйте задачи пользовательскому subagent](06-subagents.md), [Подключите инструмент через MCP](07-mcp.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете установить плагин из одного из маркетплейсов Anthropic в подходящем scope, увидеть, что он добавляет, а также отключить, обновить или удалить его.

## Что вам понадобится

- Репозиторий из [урока 4](04-permissions-and-sandbox.md) с файлом `.claude/settings.json` и ваша копия практического шаблона с Node.js LTS: проверка выполняется из копии.
- Использование: небольшое.

## Идея

[Плагин](https://code.claude.com/docs/en/plugins/overview) объединяет элементы предыдущих уроков — skills, subagents, hooks и MCP-серверы — так, что они устанавливаются как единое целое из маркетплейса. Anthropic публикует три маркетплейса общего назначения ([Маркетплейсы Anthropic](https://code.claude.com/docs/en/plugins/anthropic-marketplaces)):

- `claude-plugins-official`, который Claude Code добавляет автоматически при первом запуске интерактивной сессии;
- `claude-community` — сторонние плагины, авторы которых отправили их в Anthropic;
- `claude-code-plugins` — демонстрационный набор.

Плагин устанавливается как `<plugin>@<marketplace>` с указанием scope, который определяет, в каком файле настроек он будет включён ([Выбор scope установки](https://code.claude.com/docs/en/plugins/install#choose-an-install-scope)):

| Scope | Кто получает | Запись `enabledPlugins` в |
|---|---|---|
| User | Вы, во всех проектах | `~/.claude/settings.json` |
| Project | Все, кто работает в репозитории | `.claude/settings.json`, закоммичен |
| Local | Вы, в этом репозитории | `.claude/settings.local.json` |

Закоммитив запись с project scope, вы включаете плагин для своих коллег, но он может быть ещё не установлен на их машинах, поэтому каждый из них должен один раз выполнить `claude plugin install <plugin>@<marketplace> --scope project`. Включённый плагин участвует в каждой сессии: описания его skills находятся в контексте Claude, а его hooks и MCP-серверы запускаются от вашего имени.

## Практический пример

1. В сессии в вашем репозитории откройте плагин `commit-commands` из официального маркетплейса (Anthropic):

   ```text
   /plugin install commit-commands@claude-plugins-official
   ```

   Пока ничего не устанавливается. На панели отображается описание плагина и, в разделе **Will install**, команды, которые он добавляет. Прочитайте это перед выбором.
2. Выберите **Install for you, in this repo only (local scope)**. Итог установки заканчивается сообщением `Plugin is now active.`
3. Введите `/commit-commands:`. Команды плагина будут перечислены под его именем, например `/commit-commands:commit`.
4. Управляйте плагином из командной строки ([Управление плагинами из командной строки](https://code.claude.com/docs/en/plugins/install#manage-plugins-from-your-shell)):

   ```bash
   claude plugin list
   claude plugin disable commit-commands@claude-plugins-official
   claude plugin uninstall commit-commands@claude-plugins-official --scope local
   ```

   `claude plugin list` показывает версию плагина, `Scope: local` и его статус. `disable` отключает плагин, но оставляет его установленным; `uninstall` удаляет его.

## Ваша очередь

Включите плагин `claude-code-setup` (Anthropic) для всех, кто работает в вашем репозитории, а затем установите его так, как это сделал бы ваш коллега.

1. Добавьте этот блок в `.claude/settings.json` рядом с ключами из предыдущих уроков и замените `TODO` на полное имя плагина `<plugin>@<marketplace>`:

   ```json
   "enabledPlugins": {
     "TODO: claude-code-setup at the official marketplace": true
   }
   ```

2. Закоммитьте `.claude/settings.json`.
3. Установите плагин так, как это сделал бы коллега после получения вашего коммита:

   ```bash
   claude plugin install claude-code-setup@claude-plugins-official --scope project
   ```

   Будет выведено `Successfully installed plugin: claude-code-setup@claude-plugins-official (scope: project)`. Выполните `git status`: если установка изменила `.claude/settings.json`, закоммитьте и это изменение.
4. Запустите `claude` и спросите `Recommend Claude Code automations for this project.` Claude использует read-only skill плагина ([его https://github.com/anthropics/claude-plugins-official/blob/main/plugins/claude-code-setup/README.md и предложит hooks, skills, subagents и MCP-серверы. Формулировка у вас может отличаться.
5. Сохраните список плагинов для проверки в корне репозитория: `claude plugin list --json > .practice/i-8-plugins.json`.

## Проверка

Вы справились, если все следующие условия выполнены:

- [ ] Закоммиченные настройки включают плагин для проекта: `git show HEAD:.claude/settings.json | jq .enabledPlugins` показывает `"claude-code-setup@claude-plugins-official": true`.
- [ ] Плагин установлен с project scope и включён: `jq '.[] | select(.id == "claude-code-setup@claude-plugins-official") | {scope, enabled, projectEnabled}' .practice/i-8-plugins.json` показывает `"project"`, `true` и `true`.
- [ ] Самопроверка (не тестируется): вы можете объяснить, что `disable` сохраняет, а `uninstall` удаляет, и почему коллеге может всё ещё понадобиться `claude plugin install` после получения настроек.

Запустите `npm run check -- i-8 --dir <your repo>` из вашей практической копии или `npm run check -- i-8` в самой копии.

Если первый пункт не выполнен, проверьте имя после `@`: это имя маркетплейса, `claude-plugins-official`, а не его репозитория. Если второй пункт не выполнен, выполните команду установки в самом репозитории, а затем снова сохраните список оттуда.

## Обратите внимание

- Hooks и MCP-серверы плагина выполняются с правами вашего пользователя, и Anthropic не проверяет сторонние маркетплейсы. Сначала прочитайте список **Will install** ([Безопасность и доверие к плагинам](https://code.claude.com/docs/en/plugins/security)).
- В официальном маркетплейсе также есть плагин `chrome-devtools-mcp` (Vendor: Google), привязанный к определённому коммиту репозитория сервера ([его каталог](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json)). На 2026-10-06 [его манифест](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/1cec9cd1a3bbf1895c98fa4b4e0e2da5a36e4075/.claude-plugin/plugin.json) запускал сервер из [урока 7](07-mcp.md), но более ранней версии и без флагов того урока, поэтому его статистика использования, запросы CrUX и проверки обновлений остаются со значениями по умолчанию, которые включены ([upstream README](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/chrome-devtools-mcp-v1.10.1/README.md)). Лучше оставить `.mcp.json` из урока 7.
- Плагины из `claude-plugins-official` обновляются автоматически; запущенная сессия сохраняет загруженную версию до `/reload-plugins` или следующей сессии. Плагины из community-маркетплейса не обновляются автоматически, если вы не включите для него автообновление ([Поддержание плагинов в актуальном состоянии](https://code.claude.com/docs/en/plugins/install#keep-plugins-updated)).

Сторонние плагины: они могут выполнять код на вашей машине или давать Claude новые инструменты. Изучите плагин перед установкой; данное руководство не проводит аудит.

Списки проверены по панели листинга 2026-10-06.

## Дополнительно

- [Маркетплейсы Anthropic](https://code.claude.com/docs/en/plugins/anthropic-marketplaces): три маркетплейса и где просматривать официальный. Здесь стоит искать другие плагины.
- [Обзор плагинов](https://code.claude.com/docs/en/plugins/overview): что может содержать плагин и чего стоит каждый включённый плагин в каждой сессии.
- [Создание плагина Claude Code](https://code.claude.com/docs/en/plugins/create): упакуйте собственные skills, hooks и subagents.

---

<sub>Источники: [Обзор плагинов](https://code.claude.com/docs/en/plugins/overview) · [Установка и управление плагинами](https://code.claude.com/docs/en/plugins/install) · [Маркетплейсы Anthropic](https://code.claude.com/docs/en/plugins/anthropic-marketplaces) · [Безопасность и доверие к плагинам](https://code.claude.com/docs/en/plugins/security) · [README claude-code-setup](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/claude-code-setup/README.md) · [Каталог официального маркетплейса](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json) · [Манифест плагина chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/1cec9cd1a3bbf1895c98fa4b4e0e2da5a36e4075/.claude-plugin/plugin.json) · [README Chrome DevTools MCP](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/chrome-devtools-mcp-v1.10.1/README.md)</sub>

<sub>← [Подключите инструмент через MCP](07-mcp.md) · [Индекс Intermediate](README.md) · [Intermediate capstone](capstone.md) → · Тема: [Плагины](../topics/plugins.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-8)</sub>
