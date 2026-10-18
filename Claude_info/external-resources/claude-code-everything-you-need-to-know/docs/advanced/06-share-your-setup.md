# Поделитесь своей настройкой с командой

<sub>**Продвинутый** · Урок 6 из 7 · около 20 минут · Требуется: [GitHub Actions](05-github-actions.md) · Проверено с Claude Code v2.1.292 (stable) на 2026-10-15</sub>

## Цель

К концу этого урока вы сможете поделиться своей настройкой Claude Code с командой: закоммитить настройки, которые должны получить все, не включать личные файлы в git и предоставить команде плагин, который загружается из маркетплейса внутри репозитория.

## Вам понадобится

- Ваш собственный репозиторий с настройкой уровня Intermediate: закоммиченный `.claude/settings.json` из [урока 4 уровня Intermediate](../intermediate/04-permissions-and-sandbox.md), а также навыки, хуки и субагенты из уроков 1, 5 и 6. Настройте папку `.practice/`, как описано в [уроке 1 уровня Beginner](../beginner/01-install-and-look-around.md#you-need), если ещё не сделали этого.
- Ваша копия практического шаблона с Node.js LTS и проверками уровня Advanced ([Практика](README.md#practice)): проверка запускается из копии.
- bash, `curl` и git, на macOS, Linux или WSL 2.
- Использование: лёгкое.

## Идея

То, что должны получить все, коммитится: `.claude/settings.json`, `CLAUDE.md`, `.claude/rules/`, навыки, агенты и `.mcp.json` ([Изучите директорию .claude](https://code.claude.com/docs/en/claude-directory#file-reference)). То, что принадлежит вам, остаётся вне git: `.claude/settings.local.json`, который в этой таблице не помечен для коммита, и `CLAUDE.local.md` ([Что не отображается](https://code.claude.com/docs/en/claude-directory#what%E2%80%99s-not-shown)). Ваш локальный файл имеет приоритет над общим, поэтому коллега может переопределить командную настройку для себя без коммита, хотя списки, такие как правила разрешений, объединяются ([Файлы настроек и приоритет](https://code.claude.com/docs/en/settings#settings-precedence)).

Плагин делится навыками, агентами и хуками с командой как единым целым ([Создание плагина Claude Code](https://code.claude.com/docs/en/plugins/create#decide-when-to-use-a-plugin)), а маркетплейс — это папка, чей `.claude-plugin/marketplace.json` перечисляет плагины ([Создание маркетплейса](https://code.claude.com/docs/en/plugins/create-marketplace)). Закоммитьте маркетплейс внутри репозитория, объявите его в `extraKnownMarketplaces` с относительным путём `directory` и включите его плагин в `enabledPlugins`. Каждый коллега получит плагин, как только примет диалог доверия рабочей области для папки ([Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository)), и ничего не устанавливает: плагин, указанный по относительному пути, загружается из самого маркетплейса ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#enabled-in-project-settings-but-not-installed)).

## Рабочий пример

Ваши коллеги постоянно спрашивают, как работает настройка Claude Code в репозитории. Поделитесь навыком, который объясняет это всем, кто клонирует репозиторий.

1. В корне вашего репозитория скачайте [пример маркетплейса](../../examples/advanced/06-share-your-setup/README.md) из этого руководства в `team-marketplace/`. Прочитайте каждый файл перед коммитом:

   ```bash
   base=https://raw.githubusercontent.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/main/examples/advanced/06-share-your-setup
   curl -fsSL --create-dirs "$base/dot-claude-plugin/marketplace.json" -o team-marketplace/.claude-plugin/marketplace.json
   for f in plugins/team-kit/.claude-plugin/plugin.json plugins/team-kit/skills/onboard/SKILL.md plugins/team-kit/agents/config-reviewer.md; do
     curl -fsSL --create-dirs "$base/$f" -o "team-marketplace/$f"
   done
   ```

   Маркетплейс `team-tools` перечисляет один плагин, `team-kit`, по относительному пути `./plugins/team-kit`. Плагин содержит навык `onboard`, который говорит Claude объяснить общую настройку репозитория без изменения файлов, и субагента `config-reviewer`, который может только читать и искать. Руководство хранит файл маркетплейса в папке с именем `dot-claude-plugin/`, чтобы его собственный репозиторий не мог действовать как маркетплейс; первый `curl` сохраняет его как `.claude-plugin/marketplace.json`, путь, который использует маркетплейс ([Создание маркетплейса](https://code.claude.com/docs/en/plugins/create-marketplace)).
2. Проверьте маркетплейс, затем плагин:

   ```bash
   claude plugin validate ./team-marketplace
   claude plugin validate ./team-marketplace/plugins/team-kit --strict
   ```

   Каждый запуск заканчивается `✔ Validation passed` ([Создание маркетплейса](https://code.claude.com/docs/en/plugins/create-marketplace#create-a-marketplace)). Запуск для маркетплейса проверяет файл маркетплейса и его записи, но не открывает файлы навыков и агентов перечисленных плагинов ([Проверка директории](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)), поэтому второй запуск проверяет директорию плагина, а `--strict` превращает предупреждения в ошибки ([Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference#plugin-validate)).
3. Поделитесь этим в `.claude/settings.json`. Добавьте эти ключи рядом с ключами из уроков Intermediate; если `enabledPlugins` уже есть из урока 8, добавьте строку `team-kit` в него:

   ```json
   "extraKnownMarketplaces": {
     "team-tools": {
       "source": { "source": "directory", "path": "./team-marketplace" }
     }
   },
   "enabledPlugins": {
     "team-kit@team-tools": true
   }
   ```

   Ключ под `extraKnownMarketplaces` — это `name` маркетплейса ([Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org#require-a-marketplace-and-its-plugins)), а идентификатор плагина — `<имя записи>@<имя маркетплейса>`, здесь `team-kit@team-tools` ([Имя записи и имя манифеста](https://code.claude.com/docs/en/plugins/loading#entry-name-and-manifest-name)). Источник `directory` указывает локальную папку в `path` ([Все настройки](https://code.claude.com/docs/en/settings-reference#extraknownmarketplaces)). Относительный `path` разрешается относительно основной рабочей копии репозитория, поэтому сессия в worktree загружает `team-marketplace/` из основной рабочей копии ([Требование плагинов для каждого репозитория](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository)). Файл [`settings.snippet.json`](../../examples/advanced/06-share-your-setup/settings.snippet.json) из примера содержит те же ключи плюс правило запрета для `.env`, для репозитория, у которого их нет.
4. Закоммитьте оба:

   ```bash
   git add team-marketplace .claude/settings.json
   git commit -m "Share the team's Claude Code setup"
   ```

   Если git сообщает, что путь игнорируется, `git check-ignore -v <path>` покажет правило, которое ему соответствует; добавьте путь с помощью `git add -f`, как в [уроке 1 уровня Intermediate](../intermediate/01-first-skill.md).
5. Запустите `claude` в корне репозитория и примите диалог доверия, если он появится. После начала сессии Claude Code регистрирует маркетплейс, объявленный в ваших настройках, и загружает `team-kit` из него, без команды установки ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#plugins-and-marketplaces-that-aren%E2%80%99t-on-disk-at-session-start)). Введите `/team-kit:`, чтобы увидеть навык плагина ([Интерактивный режим](https://code.claude.com/docs/en/interactive-mode#commands)), затем выполните `/team-kit:onboard` ([Добавление компонентов в плагин](https://code.claude.com/docs/en/plugins/components#skills)). Claude читает закоммиченную настройку и объясняет, что репозиторий делает общим, а что остаётся личным; ваши формулировки будут отличаться. Если по пути он попросит выполнить команду, проверьте, что команда только читает файлы, затем одобрите её. Субагент тоже загружается, как `team-kit:config-reviewer` ([Добавление компонентов в плагин](https://code.claude.com/docs/en/plugins/components#agents)): введите `@` и выберите его из автодополнения, где он указан под этим именем, чтобы вызвать его ([Создание пользовательских субагентов](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)).
6. Отключите плагин только для себя. Добавьте этот ключ в `.claude/settings.local.json`, рядом с настройкой песочницы, которую урок 4 Intermediate сохранил там; если `enabledPlugins` уже есть, добавьте строку `team-kit` в него. Если вы создаёте файл, оберните ключ в `{ }`:

   ```json
   "enabledPlugins": {
     "team-kit@team-tools": false
   }
   ```

   Сохраните файл, затем выполните `/reload-plugins` ([Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference#reload-plugins)). `/team-kit:onboard` исчез из вашей сессии, в то время как закоммиченный файл по-прежнему включает плагин для всех остальных: ваш локальный файл имеет приоритет над файлом проекта ([Все настройки](https://code.claude.com/docs/en/settings-reference#enabledplugins)). Если он всё ещё отображается, выполните `/reload-plugins` ещё раз или начните новую сессию: изменение настроек достигает загруженных плагинов только после перезагрузки или при следующем запуске ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#check-which-stage-a-plugin-reached)). Затем удалите запись, сохраните файл и снова выполните `/reload-plugins`. Если `git status` показывает `.claude/settings.local.json`, не коммитьте его: в разделе "Ваша очередь" вы добавите его в `.gitignore`.

## Ваша очередь

**Задание:** переместите одну часть вашей настройки Intermediate в `team-kit`, чтобы все, кто клонирует репозиторий, получали её из плагина. Возьмите навык, например `tdd` из урока 1 Intermediate, или субагента, например `test-gaps` из урока 6. Для более сложного перемещения возьмите хук из урока 5: его запись помещается в `hooks/hooks.json` плагина, в той же форме, что и в файле настроек, со скриптом внутри плагина, вызываемым через `${CLAUDE_PLUGIN_ROOT}` ([Добавление компонентов в плагин](https://code.claude.com/docs/en/plugins/components#hooks)).

**Критерии приёмки:**

- Компонент находится в `team-marketplace/plugins/team-kit/`, как `skills/<name>/SKILL.md`, `agents/<name>.md` или запись в `hooks/hooks.json`, а оригинал удалён из `.claude/`; перемещённый хук также удалён из `.claude/settings.json`.
- `claude plugin validate ./team-marketplace/plugins/team-kit --strict` проходит. Сохраните его отчёт для проверки из корня репозитория: `claude plugin validate ./team-marketplace/plugins/team-kit --strict --json > .practice/a-6-validate.json`.
- Закоммиченный `.gitignore` содержит `.claude/settings.local.json` и `CLAUDE.local.md`, и git не отслеживает ни один из них. Правило, которое Claude Code добавляет для файла локальных настроек, помещается в ваш глобальный файл исключений git, который коллеги не разделяют ([Файлы настроек и приоритет](https://code.claude.com/docs/en/settings#keep-personal-settings-out-of-a-repository)), а документация советует создать `CLAUDE.local.md` вручную и добавить его в `.gitignore` самостоятельно ([Изучите директорию .claude](https://code.claude.com/docs/en/claude-directory#what%E2%80%99s-not-shown)). Добавьте его правило, даже если у вас нет `CLAUDE.local.md`.
- Всё закоммичено, и в новой сессии компонент работает под именем плагина, например `/team-kit:tdd` или субагент `team-kit:test-gaps`.

Поскольку `team-kit` указан по относительному пути в маркетплейсе на вашем диске, Claude Code загружает его на месте: изменение в `team-marketplace/` вступает в силу при следующем запуске сессии или после `/reload-plugins`, без изменения версии ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#in-place-and-copied-plugins)). Проверка Intermediate для перемещаемого компонента читает его из `.claude/`, поэтому после перемещения эта проверка не пройдёт; это ожидаемо.

## Проверка

Вы закончили, когда все следующие пункты верны:

- [ ] Закоммиченный командный маркетплейс перечисляет плагин по относительному пути, и имя записи совпадает с `name` в `plugin.json` плагина.
- [ ] Закоммиченный `.claude/settings.json` регистрирует этот маркетплейс по относительному пути и включает плагин.
- [ ] Перемещённый компонент находится в плагине и удалён из `.claude/`.
- [ ] Закоммиченный `.gitignore` исключает `.claude/settings.local.json` и `CLAUDE.local.md`, и git не отслеживает ни один из них.
- [ ] `.practice/a-6-validate.json` содержит запись о строгой проверке директории плагина, которая прошла успешно.
- [ ] Самопроверка (не тестируется): в новой сессии в вашем репозитории, после доверия, перемещённый компонент загружается из `team-kit` без команды установки.

Запустите `npm run check -- a-6 --dir <your repo>` из вашей копии практики.

Если первый пункт не проходит, выполните `claude plugin validate ./team-marketplace` и сравните `name` записи с `plugin.json` плагина; папка, всё ещё названная `dot-claude-plugin/`, не является маркетплейсом, пока вы не переименуете её в `.claude-plugin/`. Если второй пункт не проходит, проверьте, что ключ под `extraKnownMarketplaces` — это `name` маркетплейса, что `path` относительный, например `./team-marketplace`, и что значение плагина — `true`, а не `"true"`. Если третий пункт не проходит, выполните `git status`: оригинал может всё ещё быть закоммичен в `.claude/`, или копия плагина ещё не закоммичена. Если четвёртый пункт не проходит, выполните `git rm --cached` для отслеживаемого файла, добавьте обе строки в `.gitignore` и закоммитьте. Если пятый пункт не проходит, снова выполните строгую проверку из корня репозитория и сохраните отчёт после её прохождения.

## Осторожно

- Каждый, кто доверяет репозиторию, запускает то, что содержит `team-kit`, со своими правами. Хуки плагина и процессы MCP-сервера выполняются вне песочницы, и правила разрешений не распространяются на код, который они запускают ([Безопасность и доверие плагинов](https://code.claude.com/docs/en/plugins/security#understand-what-a-plugin-can-do)). Просматривайте изменения в `team-marketplace/` так же, как просматриваете код.
- Маркетплейс ждёт, без сообщения, пока каждый коллега не примет диалог доверия для папки, а запуск `claude -p` добавляет его только в папке, доверие к которой они уже приняли в интерактивной сессии, или чей флаг `hasTrustDialogAccepted` установлен в `~/.claude.json` ([Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository)); облачная сессия никогда не добавляет его, потому что никогда не показывает диалог доверия ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#plugins-shared-through-a-repository)). Закоммиченные правила разрешений ждут того же диалога, который их перечисляет ([Настройка разрешений](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)).
- Компонент, оставленный и в `.claude/`, и в плагине, загружается дважды: `/tdd` и `/team-kit:tdd` оба работают, а хук выполняется дважды при каждом срабатывании его события ([Создание плагина Claude Code](https://code.claude.com/docs/en/plugins/create#convert-an-existing-claude-setup)).

## Дальнейшие шаги

- [Размещение и поддержка маркетплейса](https://code.claude.com/docs/en/plugins/host-marketplace): переместите маркетплейс в отдельный репозиторий, когда он понадобится нескольким репозиториям, и выпускайте версии.
- [Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org): требуйте или ограничивайте маркетплейсы и плагины на каждой машине через управляемые настройки.
- [Общие настройки команды](https://code.claude.com/docs/en/settings-example#a-teams-shared-settings): полный закоммиченный файл настроек для сравнения с вашим.

---

<sub>Источники: [Файлы настроек и приоритет](https://code.claude.com/docs/en/settings) · [Изучите директорию .claude](https://code.claude.com/docs/en/claude-directory) · [Создание плагина Claude Code](https://code.claude.com/docs/en/plugins/create) · [Управление плагинами Claude Code для вашей организации](https://code.claude.com/docs/en/plugins/org) · [Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading) · [Создание маркетплейса](https://code.claude.com/docs/en/plugins/create-marketplace) · [Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference) · [Все настройки](https://code.claude.com/docs/en/settings-reference) · [Добавление компонентов в плагин](https://code.claude.com/docs/en/plugins/components) · [Создание пользовательских субагентов](https://code.claude.com/docs/en/sub-agents) · [Интерактивный режим](https://code.claude.com/docs/en/interactive-mode) · [Безопасность и доверие плагинов](https://code.claude.com/docs/en/plugins/security) · [Настройка разрешений](https://code.claude.com/docs/en/permissions)</sub>

<sub>← [GitHub Actions](05-github-actions.md) · [Индекс уровня Advanced](README.md) · [Ограничение автономных запусков](07-bounded-runs.md) → · Тема: [Плагины](../topics/plugins.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-6)</sub>
