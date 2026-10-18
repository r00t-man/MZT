# Тестирование и публикация плагина

<sub>**Продвинутый** · Электив · около 20 минут плюс время выполнения · Требуется: [Поделитесь своей настройкой с командой](../06-share-your-setup.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого электива вы сможете проверять файлы плагина с помощью `claude plugin validate`, измерять, что он меняет, с помощью `claude plugin eval`, и публиковать его в marketplace, из которого другие люди устанавливают и обновляют его.

## Вам понадобится

- Структура marketplace из [урока 6](../06-share-your-setup.md): marketplace, который перечисляет плагин по относительному пути.
- Где практиковаться: новая папка вне ваших других репозиториев, которая станет собственным приватным репозиторием GitHub. У элективов нет проверки шаблона.
- bash, `jq` и git на macOS, Linux или WSL 2 для команд этого урока. `claude plugin eval` требует git 2.31 или новее, если git установлен: с более старым git он останавливается до запуска любого кейса ([Требования](https://code.claude.com/docs/en/plugin-evals#requirements)).
- GitHub CLI, выполнен вход с помощью `gh auth login`. Claude Code клонирует приватный marketplace с git-учетными данными, которые уже есть на вашей машине, SSH или HTTPS, и никогда не запрашивает их; для HTTPS `gh auth setup-git` после входа сохраняет те, которые можно использовать ([Предоставление доступа к приватному marketplace](https://code.claude.com/docs/en/plugins/host-marketplace#grant-access-to-a-private-marketplace)).
- Использование: умеренное. Каждый запуск eval — это реальный вызов модели на вашем аккаунте ([Тестирование плагинов с помощью evals](https://code.claude.com/docs/en/plugin-evals)). В рабочем примере выполняется один запуск. Полный запуск в разделе «Ваша очередь» выполняет каждый кейс три раза с плагином и три раза без него; дешевый вариант выполняет каждый кейс один раз.

## Идея

Проверьте плагин двумя способами перед тем, как им поделиться. `claude plugin validate` читает файлы: манифесты и frontmatter; с `--strict` предупреждение также приводит к ошибке ([Тестирование и отладка](https://code.claude.com/docs/en/plugins/create#test-and-debug)). `claude plugin eval` измеряет поведение: каждый кейс, промпт плюс грейдеры (проверки, которые оценивают каждый запуск), выполняется в свежей изолированной сессии только с вашим плагином, по умолчанию три раза (группа «с»), и столько же раз без плагина (группа «без»). Разница между их оценками, `WITH` и `W/OUT`, — это `Δ`: то, что добавил плагин ([Как работает запуск eval](https://code.claude.com/docs/en/plugin-evals#how-an-eval-run-works)).

Грейдеры `regex`, `tool_used`, `tool_order` и `file_exists` ничего не стоят; `llm` и `baseline` вызывают модель-судью. Дайте каждому кейсу один грейдер на результат и один на шаги, например «skill запустился» ([Выбор и взвешивание грейдеров](https://code.claude.com/docs/en/plugin-evals#grade-the-result)).

Публикация — это `.claude-plugin/marketplace.json` в git-репозитории: как только он запушен, плагин опубликован, без формы отправки ([Публикация и распространение плагина](https://code.claude.com/docs/en/plugins/publish#publish-through-your-own-marketplace)). Когда плагин задает `version`, пользователь получает ваш следующий релиз только когда вы его измените ([Выпуск новой версии](https://code.claude.com/docs/en/plugins/host-marketplace#release-a-new-version)).

> [!WARNING]
> Прежде чем сделать репозиторий marketplace публичным, прочитайте каждый файл в нем: публичный репозиторий может читать каждый ([О репозиториях](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility)), и любой, кто может его клонировать, может из него устанавливать ([Контроль того, кто может устанавливать](https://code.claude.com/docs/en/plugins/publish#control-who-can-install)). Хук или stdio MCP-сервер, который вы добавите в более поздней версии, запускается на машине каждого, кто обновится до нее, с их правами ([Безопасность и доверие к плагинам](https://code.claude.com/docs/en/plugins/security#understand-what-a-plugin-can-do)).

## Рабочий пример

1. Создайте репозиторий с одним плагином, `commit-helper`, в `plugins/`, как в структуре [Создание marketplace](https://code.claude.com/docs/en/plugins/create-marketplace#create-a-marketplace). Его единственный skill составляет сообщения коммитов. В каждом файле и команде замените `<you>` на ваше имя пользователя GitHub и `Your Name` на ваше имя:

   ```bash
   mkdir -p claude-plugins/.claude-plugin claude-plugins/plugins/commit-helper/{.claude-plugin,skills/commit-message}
   cd claude-plugins && git init
   mkdir -p .practice && echo '.practice/' >> "$(git rev-parse --git-path info/exclude)"
   echo '**/evals/results/' > .gitignore
   echo '# commit-helper: drafts commit messages in a short, consistent format.' > plugins/commit-helper/README.md
   ```

   `.practice/` содержит файл, который читает проверка, игнорируется без коммита, как в [уроке 1 для начинающих](../../beginner/01-install-and-look-around.md#you-need). Строка в `.gitignore` не допускает результаты, которые каждый запуск eval записывает в `evals/results/` ([Написание и уточнение кейсов](https://code.claude.com/docs/en/plugin-evals#write-and-refine-cases)), а чек-лист релиза требует README ([Подготовка плагина к релизу](https://code.claude.com/docs/en/plugins/publish#prepare-your-plugin-for-release)). Затем сохраните манифест плагина с полями, которые требует этот чек-лист, как `plugins/commit-helper/.claude-plugin/plugin.json`:

   ```json
   {
     "name": "commit-helper", "version": "1.0.0", "author": { "name": "Your Name" },
     "description": "Drafts commit messages in a short, consistent format.",
     "homepage": "https://github.com/<you>/claude-plugins", "repository": "https://github.com/<you>/claude-plugins"
   }
   ```

   Skill как `plugins/commit-helper/skills/commit-message/SKILL.md`:

   ```markdown
   ---
   name: commit-message
   description: Drafts a commit message for a described change. Use when the user asks for a commit message.
   ---

   Write a commit message for the change the user describes: a subject line in the imperative mood, at most 50 characters, with no trailing period; a blank line; then one sentence on why.
   ```

   И marketplace как `.claude-plugin/marketplace.json`. Сохраните `name` записи таким же, как в манифесте ([Сохраняйте имя записи и имя манифеста одинаковыми](https://code.claude.com/docs/en/plugins/create-marketplace#keep-the-entry-name-and-the-manifest-name-the-same)):

   ```json
   {
     "name": "<you>-plugins", "description": "Plugins from <you>", "owner": { "name": "Your Name" },
     "plugins": [{ "name": "commit-helper", "source": "./plugins/commit-helper", "description": "Drafts commit messages." }]
   }
   ```

2. Проверьте плагин, затем marketplace: `claude plugin validate --strict ./plugins/commit-helper`, затем `claude plugin validate --strict .`. Каждый запуск заканчивается `✔ Validation passed`. Запуск для marketplace проверяет файл marketplace и `plugin.json` каждого плагина, перечисленного по относительному пути ([Проблемы, о которых сообщает валидация](https://code.claude.com/docs/en/plugins/create-marketplace#problems-that-validation-reports)), но не открывает их файлы skill, поэтому проверьте и сам каталог плагина ([Проверка каталога](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)).
3. Напишите один eval-кейс. `claude plugin eval init --bare` записывает пустой кейс: `prompt.md` и один грейдер-заглушку, `graders/criteria.md`, который ожидает рубрику для модели-судьи. Он ничего не запускает ([Написание кейса вручную](https://code.claude.com/docs/en/plugin-evals#write-a-case-manually)). Замените рубрику двумя грейдерами, которые ничего не стоят:

   ```bash
   cd plugins/commit-helper
   claude plugin eval init --bare names-the-rename
   cd evals/names-the-rename && rm graders/criteria.md
   printf '%s\n' '---' 'max_turns: 10' 'allowed_tools: [Skill]' '---' '' 'Write me a commit message for this change: I renamed getUser to fetchUser and updated the three call sites.' > prompt.md
   printf '%s\n' '---' 'type: tool_used' 'tool: Skill' "input_match: 'commit-message'" '---' > graders/skill-fired.md
   printf '%s\n' '---' 'type: regex' "pattern: 'fetchUser'" '---' > graders/mentions-rename.md
   cd ../..
   ```

   Запуск получает только те инструменты только для чтения, которые перечислены в его кейсе, поэтому `allowed_tools: [Skill]` — это то, что позволяет Claude запустить ваш skill ([frontmatter prompt.md](https://code.claude.com/docs/en/plugin-evals#prompt-md-fields)). `skill-fired` проходит, когда Claude вызвал инструмент `Skill` с `commit-message` в его входных данных, то есть запустил skill; `mentions-rename` проверяет ответ ([Типы грейдеров](https://code.claude.com/docs/en/plugin-evals#grader-types)). Пусть regex ищет факт, который дает промпт, например `fetchUser`: Claude пишет ответ, поэтому его формулировка варьируется. `evals/names-the-rename/graders/` теперь содержит `mentions-rename.md` и `skill-fired.md`.
4. Запустите кейс один раз, только с плагином, и сохраните отчет на своей машине: `claude plugin eval . --runs 1 --ablation none --no-publish` ([Параметры команды](https://code.claude.com/docs/en/plugin-evals#command-options)). Если спросит `Trust this plugin directory?`, ответьте `y`; внутри git-репозитория это доверяет всему репозиторию, в том числе для интерактивных сессий ([Доверие каталогу плагина](https://code.claude.com/docs/en/plugin-evals#trust-the-plugin-directory)). В сводной таблице есть столбцы `SCORE` и `PASS%`, а строка `Report:` дает путь к `report.html` в `evals/results/` ([Создание вашего первого eval-набора](https://code.claude.com/docs/en/plugin-evals#create-your-first-eval-suite)). Ваши оценки будут отличаться.
5. Опубликуйте. Вернувшись в корень репозитория (`cd ../..`), выполните `git add -A && git status --short`, прочитайте каждый файл из списка, затем:

   ```bash
   git commit -m "Publish commit-helper 1.0.0"
   gh repo create claude-plugins --private --source . --push
   ```

   `--source .` создает репозиторий GitHub из этого, а `--push` пушит ваш коммит ([gh repo create](https://cli.github.com/manual/gh_repo_create)). Marketplace теперь опубликован для всех, кто может клонировать репозиторий: пока только для вас. Сделать репозиторий публичным — это то, что позволит всем устанавливать его.
6. Установите его так, как это сделал бы пользователь, с GitHub:

   ```bash
   claude plugin marketplace add <you>/claude-plugins
   claude plugin install commit-helper@<you>-plugins
   claude plugin details commit-helper
   ```

   Команда add выводит `✔ Successfully added marketplace: <you>-plugins (declared in user settings)`, install выводит `✔ Successfully installed plugin: commit-helper@<you>-plugins (scope: user)`, а в `Component inventory` команды details указано `Skills (1)  commit-message` ([Создание marketplace](https://code.claude.com/docs/en/plugins/create-marketplace#create-a-marketplace)). Имя marketplace берется из вашего `marketplace.json`, а не из репозитория ([Размещение вашего marketplace](https://code.claude.com/docs/en/plugins/host-marketplace#host-your-marketplace)). Плагин остается установленным для вас до конца раздела «Ваша очередь».

## Ваша очередь

**Задание:** выпустите `commit-helper` 1.0.1, с проверкой его evals, и обновите установленную копию.

**Критерии приемки:**

- Второй кейс, `ignores-unrelated`, имеет тот же frontmatter, что и `names-the-rename`, чтобы skill мог запуститься, и отправляет запрос, который skill должен оставить без внимания, например `Explain what a git rebase does.` Грейдер `tool_used` на `Skill` с `min: 0`, `max: 0` и `arm: both` проверяет, что Claude не запускал skill. `arm: both` нужен, потому что при двустороннем запуске иначе каждый грейдер `tool_used` на `Skill` исключается из оценки ([Оценка относительно базового уровня без плагина](https://code.claude.com/docs/en/plugin-evals#compare-against-a-no-plugin-baseline)). Грейдер `regex` проверяет ответ, например `pattern: 'rebase'` с `flags: i`.
- Skill делает одно изменение, которое видит грейдер, например начинает каждую тему с типа вроде `refactor:`, проверяемого новым грейдером `regex` в `names-the-rename`. `version` в `plugin.json` — `1.0.1`, и запись marketplace не задает собственный `version` ([Выпуск новой версии](https://code.claude.com/docs/en/plugins/host-marketplace#release-a-new-version)).
- Обе строгие валидации проходят, и один полный запуск, `claude plugin eval . --threshold <score> --no-publish` из папки плагина, заканчивается тем, что каждый кейс на уровне или выше выбранного вами порога, оценка от 0 до 1, например `0.8` ([Параметры команды](https://code.claude.com/docs/en/plugin-evals#command-options)). Дешевый вариант: добавьте `--runs 1 --ablation none`.
- `evals/` закоммичен, `evals/results/` нет, и релиз запушен.
- `claude plugin update commit-helper@<you>-plugins` устанавливает 1.0.1 и заканчивается `Restart to apply changes.` ([Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading#check-which-stage-a-plugin-reached)). Если говорится, что плагин уже последней версии, версия, которую Claude Code вычисляет для плагина, не изменилась ([Версии и обновления](https://code.claude.com/docs/en/plugins/loading#versions-and-updates)): проверьте, что `plugin.json` с `1.0.1` запушен.

Затем из корня репозитория сохраните список плагинов с помощью `claude plugin list --json > .practice/a-publish-list.json` ([Вывод JSON](https://code.claude.com/docs/en/plugins/cli-reference#json-output)) и только после этого выполните `claude plugin marketplace remove <you>-plugins --scope user`. Удаление marketplace из последней области также удаляет его плагины ([plugin marketplace remove](https://code.claude.com/docs/en/plugins/cli-reference#plugin-marketplace-remove)), поэтому сохраненный список — это то, что читает проверка ниже. Удаление репозитория необязательно: `gh repo delete <you>/claude-plugins --yes` требует область `delete_repo`, которую добавляет `gh auth refresh -s delete_repo` ([gh repo delete](https://cli.github.com/manual/gh_repo_delete)).

## Проверка

Вы закончили, когда все перечисленное верно, из корня репозитория:

- [ ] `claude plugin validate --strict ./plugins/commit-helper` и `claude plugin validate --strict .` каждый заканчивается `✔ Validation passed`.
- [ ] `git ls-files plugins/commit-helper/evals` перечисляет файлы двух кейсов и ничего в `results/`.
- [ ] Самый новый результат eval охватывает оба кейса, и каждый кейс прошел ([Результат JSON](https://code.claude.com/docs/en/plugin-evals#json-result)): `jq '.partial != true and .aggregates.casesTotal == 2 and .aggregates.casesPassed == .aggregates.casesTotal' "$(ls -d plugins/commit-helper/evals/results/*/ | tail -1)aggregate-result.json"` выводит `true`.
- [ ] `jq -r '.[] | select(.id == "commit-helper@<you>-plugins") | .version' .practice/a-publish-list.json` выводит `1.0.1`.
- [ ] Самопроверка (не тестируется): вы можете сказать, что измеряет `Δ`, и почему двусторонний запуск не оценивает «skill запустился».

Если валидация не проходит только с `--strict`, строки над вердиктом называют предупреждение для исправления, например отсутствующий `description` или `version` ([Вывод и коды выхода](https://code.claude.com/docs/en/plugins/cli-reference#output-and-exit-codes)). Если `results/` перечислен, выполните `git rm -r --cached plugins/commit-helper/evals/results`, проверьте строку в `.gitignore` и закоммитьте. Если результат выводит `false`, запустите оба кейса снова, если в последнем запуске был только один, или откройте его `report.html`, чтобы увидеть, какой грейдер не прошел: без `--threshold` любой кейс ниже идеальной оценки не проходит ([Запуск завершается с кодом 1, но результаты выглядят нормально](https://code.claude.com/docs/en/plugin-evals#the-run-exits-1-but-the-results-look-fine)). Если проверка версии ничего не выводит или выводит `1.0.0`, проверьте, что `<you>` заменен, запушьте новый `version` при необходимости, добавьте marketplace, установите плагин снова и сохраните список перед удалением marketplace.

## Осторожно

- `claude plugin eval` запускает skills, хуки и агенты плагина на вашей машине, как вы, и прошедший набор ничего не говорит о безопасности плагина. Передавайте `--allow-tools`, `--scaffold` или `--allow-real-servers` только для плагина и набора, которые вы прочитали ([Что может получить доступ при запуске](https://code.claude.com/docs/en/plugin-evals#security)).
- Грейдеры-судьи добавляют вызовы модели к каждому запуску, поэтому оставляйте их для того, что не может проверить бесплатный грейдер. `--max-cost-usd` ограничивает оценку по прейскуранту запуска, а не использование вашего плана, и как только вы достигнете лимита использования в середине набора, последующие запуски обычно получают 0, при этом набор не помечается как `partial` ([Параметры команды](https://code.claude.com/docs/en/plugin-evals#command-options), [Устранение неполадок](https://code.claude.com/docs/en/plugin-evals#runs-fail-with-a-usage-limit-or-rate-limit-error-partway-through)).
- Считайте `name` плагина постоянным: пользователи устанавливают, включают и настраивают его по `name@marketplace`, поэтому переименованный плагин — это другой плагин для каждой существующей установки. Измените `displayName` для новой метки ([Подготовка плагина к релизу](https://code.claude.com/docs/en/plugins/publish#prepare-your-plugin-for-release)). Некоторые имена marketplace зарезервированы, например начинающиеся с `claudeai-`; если add отклоняет ваше, выберите другое ([Зарезервированные имена](https://code.claude.com/docs/en/plugins/marketplace-reference#reserved-names)).

## Дальнейшие шаги

- [Запуск evals в CI](https://code.claude.com/docs/en/plugin-evals#run-evals-in-ci): `--trust-plugin`, закрепленные модели, `--json` и потолок затрат для задачи, подобной той, что в [GitHub Actions](../05-github-actions.md).
- [Отправка в каталог Anthropic](https://code.claude.com/docs/en/plugins/publish#submit-to-anthropics-directory): перечислите плагин в каталоге, который люди просматривают на claude.ai.
- [Размещение и поддержка marketplace](https://code.claude.com/docs/en/plugins/host-marketplace): автообновление, каналы релизов, переименование или удаление плагина.

---

<sub>Источники: [Тестирование плагинов с помощью evals](https://code.claude.com/docs/en/plugin-evals) · [Публикация и распространение плагина](https://code.claude.com/docs/en/plugins/publish) · [Создание плагина Claude Code](https://code.claude.com/docs/en/plugins/create) · [Создание marketplace](https://code.claude.com/docs/en/plugins/create-marketplace) · [Размещение и поддержка marketplace](https://code.claude.com/docs/en/plugins/host-marketplace) · [Справочник команд плагинов](https://code.claude.com/docs/en/plugins/cli-reference) · [Справочник по загрузке плагинов](https://code.claude.com/docs/en/plugins/loading) · [Справочник marketplace](https://code.claude.com/docs/en/plugins/marketplace-reference) · [Безопасность и доверие к плагинам](https://code.claude.com/docs/en/plugins/security) · GitHub: [О репозиториях](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories) · Руководство GitHub CLI: [gh repo create](https://cli.github.com/manual/gh_repo_create), [gh repo delete](https://cli.github.com/manual/gh_repo_delete)</sub>

<sub>Назад к [индексу продвинутых уроков](../README.md) · Тема: [Плагины](../../topics/plugins.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-publish-plugin)</sub>
