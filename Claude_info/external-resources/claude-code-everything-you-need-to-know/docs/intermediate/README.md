# Intermediate

<sub>**Intermediate** · около 3 часов · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

Настройка одного разработчика. Вы адаптируете Claude Code под свой проект: skills, project memory, model and effort, permissions and the sandbox, hooks, subagents, MCP servers и plugins.

## Вы готовы к этому уровню, если умеете

- [ ] Устанавливать Claude Code, входить в систему, запускать его в своём репозитории и определять, какая у вас версия, модель и аккаунт.
- [ ] Выбирать и переключать режимы разрешений, а также утверждать план в plan mode перед любыми изменениями.
- [ ] Проводить одно изменение от запроса до коммита: исследовать, планировать, реализовывать, тестировать, просматривать diff, исправлять, коммитить.
- [ ] Удерживать сессию в нужном русле с помощью context, clear, compact, rewind и resume.
- [ ] Создавать проектный CLAUDE.md и показывать, что новая сессия следует ему.

## Практика

Практикуйтесь в своём репозитории: адаптация Claude Code под ваш проект — суть этого уровня. Запускайте каждую проверку из вашей копии [practice template](https://github.com/wesammustafa/claude-code-practice) как `npm run check -- <lesson-id> --dir <your repo>`. Если вы не хотите менять свой репозиторий, используйте саму копию шаблона; capstone выполняется там.

Чтобы идти шаг за шагом, запустите `npm run learn` в своей копии и используйте Claude Code во втором терминале рядом. Приложение проведёт вас через каждый урок и capstone, шаг за шагом, спросит, в какой папке вы практикуетесь, и будет проверять вашу работу по ходу. Каждая страница ниже преподаёт тот же урок самостоятельно.

Копия, сделанная вами для уровня Beginner, может не иметь проверок или уроков Intermediate: `npm run check` тогда не покажет уроков `i-`. Перенесите их из шаблона в свою копию:

```bash
git fetch https://github.com/wesammustafa/claude-code-practice main
git checkout FETCH_HEAD -- checks capstone learn
git commit -m "Add the Intermediate checks and lessons"
```

Копия старше приложения не имеет скрипта `learn`, поэтому `npm run learn` выдаёт `Missing script: "learn"`: вместо этого запустите `node learn/app.mjs`.

## Когда что использовать

Пять способов расширить Claude Code; [Extend Claude Code](https://code.claude.com/docs/en/features-overview) перечисляет остальные. Каждый пункт ссылается на свой урок.

- **Skills:** вы даёте Claude одни и те же инструкции или workflow снова и снова. Проектный skill находится в `.claude/skills/<name>/SKILL.md` ([Extend Claude with skills](https://code.claude.com/docs/en/skills); урок: [Turn a repeated workflow into a skill](01-first-skill.md)).
- **Hooks:** что-то должно происходить каждый раз в определённый момент сессии, например, перед запуском инструмента, независимо от решения Claude. Hooks определяются в файле настроек, таком как `.claude/settings.json` ([Hooks](https://code.claude.com/docs/en/hooks); урок: [Enforce a rule with a hook](05-hooks.md)).
- **Subagents:** побочная задача должна выполняться в собственном контекстном окне и сообщать о результате. Проектный subagent находится в `.claude/agents/` ([Create custom subagents](https://code.claude.com/docs/en/sub-agents); урок: [Delegate to a custom subagent](06-subagents.md)).
- **Dynamic workflows:** задача требует больше агентов, чем может координировать один разговор. Сохранённый проектный workflow находится в `.claude/workflows/` ([Workflows](https://code.claude.com/docs/en/workflows); урок: [Run and save a dynamic workflow](../advanced/03-dynamic-workflows.md)).
- **MCP servers:** Claude нужны инструменты или данные вне ваших файлов, например, браузер, база данных или API. Сервер проектного уровня указан в `.mcp.json` в корне проекта ([Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp); урок: [Connect a tool with MCP](07-mcp.md)).

Они комбинируются: [plugin](https://code.claude.com/docs/en/plugins) упаковывает skills, agents, hooks и MCP servers так, что они устанавливаются как единое целое ([Install and manage plugins](08-plugins.md)).

## Уроки

1. [Turn a repeated workflow into a skill](01-first-skill.md)
2. [Organize project memory and see what loaded](02-organize-memory.md)
3. [Pick the model and effort](03-model-and-effort.md)
4. [Permissions, settings scopes and the sandbox](04-permissions-and-sandbox.md)
5. [Enforce a rule with a hook](05-hooks.md)
6. [Delegate to a custom subagent](06-subagents.md)
7. [Connect a tool with MCP](07-mcp.md)
8. [Install and manage plugins](08-plugins.md)

Каждый урок занимает от 10 до 20 минут.

## Capstone

[Get a repository ready for a new teammate](capstone.md): skill, hook, защищающий папку, read-only reviewer subagent, MCP server проектного уровня и официальный plugin, с настройками проекта, которые держат секреты вне досягаемости и включают sandbox.

## К концу этого уровня вы сможете

- [ ] Написать проектный skill, который запускается по имени и загружается сам, когда применим.
- [ ] Написать hook, который обеспечивает соблюдение правила, и показать, как он срабатывает.
- [ ] Делегировать задачу кастомному subagent с ограниченными инструментами.
- [ ] Добавить MCP server на уровне проекта и установить plugin из Anthropic marketplace.
- [ ] Разместить правила разрешений в нужной области, включить sandbox и выбрать модель и effort для задачи.
- [ ] Организовать project memory и выяснить, что загрузилось, когда инструкция не выполняется.

## Элективы

Дополнительные уроки вне основного пути:

- [Skill patterns](electives/skill-patterns.md): живые данные, вспомогательные файлы и собственный контекст.
- [Claude in Chrome](electives/claude-in-chrome.md): проверка изменений UI в вашем браузере.
- [The status line](electives/status-line.md): отображение модели, папки и контекста в собственной строке.
- [Fast mode](electives/fast-mode.md): более быстрые ответы Opus, оплачиваемые сверх вашего плана.

## Официальные спутники

- [Claude Code in action](https://academy.claude.com/courses/claude-code-in-action): курс Claude Academy по проведению длительных сессий без участия человека, которым можно доверять.
- [Introduction to agent skills](https://academy.claude.com/courses/introduction-to-agent-skills) и [Introduction to subagents](https://academy.claude.com/courses/introduction-to-subagents): курсы Claude Academy по skills и subagents.

## Следующий уровень

[Advanced](../advanced/README.md): за пределами одной сессии.

---

<sub>Источники: [Extend Claude Code](https://code.claude.com/docs/en/features-overview) · [Extend Claude with skills](https://code.claude.com/docs/en/skills) · [Hooks](https://code.claude.com/docs/en/hooks) · [Create custom subagents](https://code.claude.com/docs/en/sub-agents) · [Workflows](https://code.claude.com/docs/en/workflows) · [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) · [Plugins](https://code.claude.com/docs/en/plugins) · [Claude Code in action](https://academy.claude.com/courses/claude-code-in-action) · [Introduction to agent skills](https://academy.claude.com/courses/introduction-to-agent-skills) · [Introduction to subagents](https://academy.claude.com/courses/introduction-to-subagents)</sub>

<sub>Вверх: [Claude Code: Everything You Need to Know](../../README.md#pick-your-level)</sub>
