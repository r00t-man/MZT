# Примеры

Готовые к копированию файлы для уроков: skills, hooks, subagents и фрагменты настроек. Каждый находится в папке урока, который его использует, по пути `examples/<level>/<NN-lesson>/`.

Здесь ничего не запускается само по себе. Файлы, которые Claude Code загружал бы из проекта, в этой папке имеют другое имя, поэтому они остаются инертными, пока вы их не скопируете:

- `dot-claude/` становится `.claude/` в вашем проекте;
- `dot-mcp.json` становится `.mcp.json`;
- `CLAUDE.example.md` становится `CLAUDE.md`, а `AGENTS.example.md` становится `AGENTS.md`;
- `dot-claude-plugin/` становится `.claude-plugin/` в скопированной папке marketplace. Его манифест marketplace переименован, чтобы ни папку marketplace, ни репозиторий этого руководства нельзя было добавить как plugin marketplace по пути к папке или как `owner/repo` ([Marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference#marketplace-file)). Плагин сохраняет свой собственный `.claude-plugin/plugin.json`, потому что Claude Code не обнаруживает плагин здесь сам по себе: он не сканирует каталог `.claude/plugins/` проекта, и ничто здесь не находится в папке `.claude/skills/` ([Plugin loading reference](https://code.claude.com/docs/en/plugins/loading#plugins-shared-through-a-repository)).

Каждый исполняемый пример следует [safety contract](../CONTRIBUTING.md#adding-a-skill) руководства. Его заголовок говорит, что он делает, когда запускается, как его удалить и был ли он протестирован в сессии Claude Code на версии этого издания. Просмотрите каждый файл перед копированием в проект.

## Указатель

Каждый пример перечислен здесь с указанием урока, платформ и строки тестирования.

- [`intermediate/01-first-skill/`](intermediate/01-first-skill/README.md): skill `five-whys` и незавершённый skill `tdd`, для [Turn a repeated workflow into a skill](../docs/intermediate/01-first-skill.md). Любая платформа. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-06.
- [`intermediate/05-hooks/`](intermediate/05-hooks/README.md): три обучающих hook (protect-files, format-after-edit и desktop-notify) и настройки, которые их регистрируют, для [Enforce a rule with a hook](../docs/intermediate/05-hooks.md). macOS, Linux и WSL 2, с bash, jq и python3. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-06.
- [`intermediate/06-subagents/`](intermediate/06-subagents/README.md): subagent `code-reviewer` только для чтения, для [Delegate to a custom subagent](../docs/intermediate/06-subagents.md). Любая платформа. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-06.
- [`intermediate/07-mcp/`](intermediate/07-mcp/README.md): Chrome DevTools MCP на уровне проекта, закреплённый, с отключёнными потоками данных в Google и npm, для [Connect a tool with MCP](../docs/intermediate/07-mcp.md). macOS, Linux и WSL 2, с Node.js и Chrome. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-06.
- [`advanced/06-share-your-setup/`](advanced/06-share-your-setup/README.md): marketplace `team-tools`, его плагин `team-kit` (skill `onboard` и subagent `config-reviewer` только для чтения) и настройки, которые им делятся, для [Share your setup with a team](../docs/advanced/06-share-your-setup.md). Любая платформа; для smoke test нужны bash, jq и awk. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-09.
- [`advanced/electives/agent-teams/`](advanced/electives/agent-teams/README.md): subagents `security-reviewer` и `test-reviewer` только для чтения, для [Agent teams](../docs/advanced/electives/agent-teams.md) Elective. Любая платформа; для smoke test нужны bash и awk. Протестировано в Claude Code v2.1.285 (stable) на macOS, 2026-10-09.
