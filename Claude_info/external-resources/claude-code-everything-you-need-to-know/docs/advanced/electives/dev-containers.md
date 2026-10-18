# Dev containers

<sub>**Продвинутый** · Электив · около 20 минут, плюс время выполнения · Требуется: [Ограничьте автономные запуски](../07-bounded-runs.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого электива вы сможете запускать Claude Code внутри dev container, сохранять вход в систему при пересборке и позволять ему работать без присмотра за брандмауэром.

## Вам понадобится

- Для рабочего примера: ваша копия практического шаблона на GitHub и GitHub Codespaces в вашей учётной записи. Ничего устанавливать на компьютер не нужно: dev container копии устанавливает Claude Code.
- Для вашей очереди: один из ваших собственных репозиториев без папки `.devcontainer/`, с настроенной папкой `.practice/`, как описано в [Уроке 1 для начинающих](../../beginner/01-install-and-look-around.md#you-need).
- Также для вашей очереди: Docker, VS Code с [расширением Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) ([Системные требования](https://code.visualstudio.com/docs/devcontainers/containers#_system-requirements)) и `jq` на macOS, Linux или WSL 2. Без Docker выполните рабочий пример и самопроверку из раздела Check.
- Использование: лёгкое. Codespace также использует вычислительные ресурсы Codespaces вашей учётной записи GitHub во время работы и хранилище, пока он существует ([Тарификация GitHub Codespaces](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces)).

## Идея

[Dev container](https://code.claude.com/docs/en/devcontainer) — это Docker-контейнер, к которому подключается ваш редактор, на вашем компьютере или облачном хосте, таком как GitHub Codespaces. С Claude Code внутри команды Claude выполняются в контейнере, а его правки попадают в ваш репозиторий. В отличие от песочницы Bash из [Урока 4 для среднего уровня](../../intermediate/04-permissions-and-sandbox.md), которая оборачивает только команды оболочки, он содержит весь процесс Claude Code: файловые инструменты, MCP-серверы и хуки тоже ([Сравнение подходов к песочнице](https://code.claude.com/docs/en/sandbox-environments#compare-sandboxing-approaches)).

Три части, каждая добавляет к предыдущей:

- **Claude Code Dev Container Feature** добавляет CLI в любой dev container ([Добавьте Claude Code в ваш dev container](https://code.claude.com/docs/en/devcontainer#add-claude-code-to-your-dev-container)).
- **Именованный том** в `~/.claude`, плюс `CLAUDE_CONFIG_DIR`, указывающий на этот путь, сохраняет ваш вход в систему, когда пересборка удаляет домашнюю папку ([Сохранение аутентификации и настроек при пересборках](https://code.claude.com/docs/en/devcontainer#persist-authentication-and-settings-across-rebuilds)).
- **Эталонный контейнер** добавляет пользователя без прав root и брандмауэр, который ограничивает исходящий трафик только теми адресами, которые разрешает его скрипт. Документация поддерживает его для автономных запусков с `--dangerously-skip-permissions`, которые пропускают запросы разрешений (режим обхода); CLI отказывается от этого флага при запуске от root ([Запуск без запросов разрешений](https://code.claude.com/docs/en/devcontainer#run-without-permission-prompts), [Dev containers](https://code.claude.com/docs/en/sandbox-environments#dev-containers)).

> [!WARNING]
> С `--dangerously-skip-permissions` "dev containers не предотвращают вредоносному проекту эксфильтрацию всего, что доступно внутри контейнера, включая учётные данные Claude Code, хранящиеся в `~/.claude`" ([Development containers](https://code.claude.com/docs/en/devcontainer)). Расширение VS Code Dev Containers также повторно использует ваши локальные учётные данные Git в контейнере и пересылает работающий SSH-агент, а эталонный брандмауэр пропускает GitHub и SSH, так что запуск может пушить с их помощью ([Предоставление учётных данных Git вашему контейнеру](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials)). Используйте dev container только с репозиториями, которым вы доверяете, и никогда не монтируйте секреты хоста, такие как `~/.ssh` или файлы облачных учётных данных, в него.

## Рабочий пример

1. На GitHub откройте `.devcontainer/devcontainer.json` в вашей копии шаблона:

   ```json
   {
     "name": "Claude Code practice",
     "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
     "features": {
       "ghcr.io/devcontainers/features/node:1": { "version": "lts" },
       "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {}
     },
     "postCreateCommand": "sudo apt-get update && sudo apt-get install -y bubblewrap socat"
   }
   ```

   Тег `:1.0` закрепляет скрипт установки функции, а не Claude Code: функция устанавливает последний релиз, который затем обновляется сам ([Добавьте Claude Code в ваш dev container](https://code.claude.com/docs/en/devcontainer#add-claude-code-to-your-dev-container)). `postCreateCommand` устанавливает `bubblewrap` и `socat`, которые нужны песочнице Bash в Linux ([Настройка Linux и WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)).
2. Выберите **Code**, затем вкладку **Codespaces** и создайте codespace на `main` ([Создание codespace для репозитория](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository)). Он откроется в редакторе, заданном в настройках Codespaces ([Настройка редактора по умолчанию для GitHub Codespaces](https://docs.github.com/en/codespaces/setting-your-user-preferences/setting-your-default-editor-for-github-codespaces)); шаги 3–6 используют VS Code в браузере или настольном приложении.
3. В его терминале:

   ```bash
   echo "$CODESPACES"; whoami; claude --version
   ```

   Он выведет три строки: `true` (GitHub устанавливает `CODESPACES` в каждом codespace, [Переменные окружения по умолчанию для вашего codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/default-environment-variables-for-your-codespace)), `vscode` (пользователь без прав root из образа, [Ubuntu image](https://github.com/devcontainers/images/tree/main/src/base-ubuntu)) и версию, которая может быть новее, чем указано на этой странице.
4. Запустите `claude`, войдите в систему и доверьте папке, когда она спросит. Если браузер показывает код вместо возврата в терминал, вставьте его в приглашение `Paste code here if prompted` ([Вход в Claude Code](https://code.claude.com/docs/en/authentication#log-in-to-claude-code)). Затем спросите:

   ```text
   Run uname -a and whoami, then tell me which machine you're running on.
   ```

   Одобрите команду, если Claude спросит. Claude опишет Linux-контейнер, а не ваш компьютер; ваша формулировка будет отличаться. Выйдите с помощью `/exit`.
5. Выполните `claude auth status --text`: вы вошли в систему ([CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands)). Пересборка: откройте палитру команд (`Ctrl+Shift+P` или `Cmd+Shift+P` на Mac), выполните **Codespaces: Rebuild Container** и выберите **Rebuild** ([Пересборка контейнера в codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/rebuilding-the-container-in-a-codespace)). Когда он переподключится:

   ```bash
   claude auth status --text; echo "exit $?"
   ```

   Он закончится с `exit 1`: не вошли в систему. Пересборка сохраняет `/workspaces`, где находится ваш репозиторий, и очищает `~/.claude` ([Сохранение данных при https://docs.github.com/en/codespaces/developing-in-a-codespace/rebuilding-the-container-in-a-codespace#persisting-data-over-a-rebuild
6. Остановите codespace: выполните **Codespaces: Stop Codespace** из палитры команд или выберите **Stop codespace** в меню **...** рядом с ним на [github.com/codespaces](https://github.com/codespaces). Закрытие вкладки браузера не останавливает его ([Остановка и запуск codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/stopping-and-starting-a-codespace)).

## Ваша очередь

**Краткое задание:** поместите один из ваших собственных репозиториев в [эталонный контейнер](https://code.claude.com/docs/en/devcontainer#try-the-reference-container) с включённым брандмауэром и закреплённой версией Claude Code. Сохраните вход в систему при пересборке и позвольте Claude завершить одну небольшую задачу без присмотра, затем просмотрите результат на своём компьютере.

Шаги из документации открывают собственный репозиторий Claude Code в контейнере; чтобы использовать его с вашим проектом, скопируйте папку `.devcontainer/` в ваш репозиторий и настройте Dockerfile под инструменты вашего проекта ([Попробуйте эталонный контейнер](https://code.claude.com/docs/en/devcontainer#try-the-reference-container)). На новой ветке получите [три файла](https://github.com/anthropics/claude-code/tree/d945a61bc6346abce607252d5667df8a3bf0461a/.devcontainer) из коммита, с которым сверялось это руководство:

```bash
git switch -c try-devcontainer
mkdir -p .devcontainer
ref=d945a61bc6346abce607252d5667df8a3bf0461a
for f in devcontainer.json Dockerfile init-firewall.sh; do
  curl -fsSL "https://raw.githubusercontent.com/anthropics/claude-code/$ref/.devcontainer/$f" -o ".devcontainer/$f"
done
```

**Критерии приёмки:**

- Вы прочитали все три файла до первой сборки. `init-firewall.sh` выполняется от root при каждом запуске контейнера: `devcontainer.json` запускает его как `postStartCommand` ([Справочник метаданных Dev Container](https://containers.dev/implementors/json_reference/)), а Dockerfile позволяет пользователю `node` запускать его через `sudo`.
- До первой сборки вы добавили `claude.ai` и `platform.claude.com` в домены, которые разрешает `init-firewall.sh`, рядом с `api.anthropic.com`: вход в систему и обновление входа требуют их ([Требования к доступу к сети](https://code.claude.com/docs/en/network-config#network-access-requirements)). Хосты могут иметь общий адрес, и скрипт останавливается на первом `ipset add`, который встречает уже добавленный адрес, поэтому в том же цикле измените `ipset add allowed-domains "$ip"` на `ipset add -exist allowed-domains "$ip"`: `-exist` игнорирует запись, которая уже есть в наборе ([ipset](https://ipset.netfilter.org/ipset.man.html)).
- `devcontainer.json` закрепляет Claude Code: аргумент сборки `CLAUDE_CODE_VERSION` называет выбранную вами версию, например `2.1.285`, вместо `latest`, а `containerEnv` добавляет `"DISABLE_AUTOUPDATER": "1"`. Это рецепт из документации: установите фиксированную версию из Dockerfile и отключите автообновление ([Принудительная политика организации](https://code.claude.com/docs/en/devcontainer#enforce-organization-policy)). Три файла с вашими изменениями закоммичены в вашей ветке.
- **Dev Containers: Reopen in Container** собирает и открывает его. Строки `npm warn EBADENGINE` в журнале сборки ожидаемы: эталонный образ использует Node.js 20, а пакет npm требует 22 или новее, но npm только предупреждает, установка завершается и `claude` всё равно работает ([Установка через npm](https://code.claude.com/docs/en/setup#install-with-npm)). В его терминале (`` Ctrl+` ``) `whoami` выводит `node`, `claude --version` выводит вашу версию, `curl -sS --connect-timeout 5 https://example.com` завершается ошибкой, а `curl -sS --connect-timeout 5 https://api.github.com/zen` успешно.
- Вы один раз входите в систему с помощью `claude`. После **Dev Containers: Rebuild Container** `claude auth status` по-прежнему завершается с кодом `0`: эталонный контейнер монтирует именованный том в `/home/node/.claude` и указывает `CLAUDE_CONFIG_DIR` на него, а Docker сохраняет том после удаления контейнера ([Volumes](https://docs.docker.com/engine/storage/volumes/)).
- Один автономный запуск завершается в терминале контейнера на задаче, которой не нужен инструмент, отсутствующий в образе, например `claude -p "Add a one-line summary of this repository to the top of README.md" --dangerously-skip-permissions --model sonnet --max-turns 10` ([CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)).
- В терминале на вашем компьютере, после проверок из первого пункта Watch out, вы сохраняете `git status --porcelain > .practice/a-dc-status.txt`, затем читаете `git diff`, включая `.devcontainer/`, прежде чем закоммитить или отбросить изменение запуска.

Когда каждый пункт в разделе Check ниже истинен, выполните очистку:

1. В терминале контейнера выполните `claude auth logout` ([CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands)). Пока вы не выйдете из системы, том конфигурации хранит ваши учётные данные, и том переживает контейнер.
2. Закройте окно VS Code, подключённое к контейнеру. Закрытие останавливает контейнер по умолчанию (`shutdownAction` в [Справочнике метаданных Dev Container](https://containers.dev/implementors/json_reference/)).
3. Удалите контейнер: в Remote Explorer VS Code выберите **Containers**, затем щёлкните правой кнопкой мыши контейнер и удалите его ([Управление контейнерами](https://code.visualstudio.com/docs/devcontainers/containers#_managing-containers)) или выполните `docker rm <container>` ([docker container rm](https://docs.docker.com/reference/cli/docker/container/rm/)).
4. Удалите два тома, имена которых начинаются с `claude-code-config-` и `claude-code-bashhistory-`: `docker volume ls` перечисляет их, затем `docker volume rm <name>` удаляет каждый. Docker не удалит том, который всё ещё используется контейнером, поэтому этот шаг идёт после шага 3 ([docker volume rm](https://docs.docker.com/reference/cli/docker/volume/rm/)).

## Check

Вы закончили, когда все эти пункты истинны:

- [ ] На вашем компьютере `git ls-tree --name-only try-devcontainer .devcontainer/` перечисляет три файла, а `git show try-devcontainer:.devcontainer/devcontainer.json | jq -r '.build.args.CLAUDE_CODE_VERSION, .containerEnv.DISABLE_AUTOUPDATER'` выводит вашу версию и `1`.
- [ ] В контейнере `whoami` выводит `node`, `claude --version` выводит вашу версию, запрос к `example.com` завершается ошибкой, а к `api.github.com/zen` — успешно.
- [ ] В контейнере после пересборки `claude auth status >/dev/null; echo $?` выводит `0`.
- [ ] На вашем компьютере `.practice/a-dc-status.txt` перечисляет файл, изменённый автономным запуском.
- [ ] Самопроверка (не тестируется): в codespace `claude auth status` завершился с кодом `1` после пересборки, и вы можете назвать две вещи, которые контейнер не защищает: всё, что можно прочитать или использовать внутри него, например `~/.claude` и ваши пересланные учётные данные Git, и каждый файл в смонтированном проекте.

Если jq сообщает об ошибке разбора, удалите любой комментарий или висячую запятую, добавленные вами в `devcontainer.json`. Если `example.com` отвечает или `api.github.com` нет, скрипт брандмауэра не сработал: выполните `sudo /usr/local/bin/init-firewall.sh` в контейнере и прочитайте его ошибку. `Element cannot be added to the set: it's already added` означает, что изменение `-exist` отсутствует. Если `claude auth status` завершается с кодом `1` после пересборки, `target` тома и `CLAUDE_CONFIG_DIR` в `containerEnv` должны указывать один и тот же путь ([Сохранение аутентификации и настроек при пересборках](https://code.claude.com/docs/en/devcontainer#persist-authentication-and-settings-across-rebuilds)). Если файл статуса пуст, запуск ничего не изменил, закоммитил своё изменение (`git log -1` показывает его) или остановился на `--max-turns`, что завершается с ошибкой ([CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)): прочитайте, что он вывел, и дайте ему меньшую задачу, если у него закончились ходы.

## Watch out

- С `--dangerously-skip-permissions` Claude также может переписать `.devcontainer/` и `.git/`: это защищённые пути, но режим обхода записывает защищённые пути без запроса ([Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)). Через монтирование изменение попадает на ваш компьютер: следующая пересборка использует `.devcontainer/`, а git запускает хуки из `.git/hooks` или из папки, указанной в `.git/config`, во время команд, таких как `git commit` ([githooks](https://git-scm.com/docs/githooks)). Прежде чем пересобирать или запускать git на вашем компьютере, прочитайте `.git/config` и перечислите `.git/hooks`, затем сравните `.devcontainer/` с коммитом, который вы сделали (`git log --oneline`, затем `git diff <your commit> -- .devcontainer`).
- Codespace продолжает работать, пока вы не остановите его или не истечёт тайм-аут, а остановленный всё ещё использует хранилище ([Остановка и запуск codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/stopping-and-starting-a-codespace)). Удалите его, когда закончите, из меню **...** рядом с ним на [github.com/codespaces](https://github.com/codespaces) или с помощью `gh codespace delete` ([Удаление codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/deleting-a-codespace)).
- Брандмауэр блокирует исходящий трафик, который не разрешает его скрипт, для всего в контейнере, включая команды Claude. Когда вашему проекту нужен другой хост, например PyPI или частный реестр, добавьте его в список доменов скрипта и пересоберите ([Dev containers](https://code.claude.com/docs/en/sandbox-environments#dev-containers)). [Требования к доступу к сети](https://code.claude.com/docs/en/network-config#network-access-requirements) перечисляет хосты, которые используют собственные функции Claude Code.

## Дальнейшие шаги

- [Выберите среду песочницы](https://code.claude.com/docs/en/sandbox-environments): dev containers рядом с песочницей Bash, другие контейнеры, виртуальные машины и облачные сессии.
- [Принудительная политика организации](https://code.claude.com/docs/en/devcontainer#enforce-organization-policy): управляемые настройки, встроенные в образ, и почему файл в репозитории не является границей принуждения.
- [Изучите каталог .claude](https://code.claude.com/docs/en/claude-directory): что содержит том в `~/.claude`, включая учётные данные, настройки и историю сессий.

---

<sub>Источники: [Development containers](https://code.claude.com/docs/en/devcontainer) · [Choose a sandbox environment](https://code.claude.com/docs/en/sandbox-environments) · [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) · [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing) · [Authentication](https://code.claude.com/docs/en/authentication) · [Advanced setup](https://code.claude.com/docs/en/setup) · [CLI reference](https://code.claude.com/docs/en/cli-reference) · [Enterprise network configuration](https://code.claude.com/docs/en/network-config) · Claude Code: [reference dev container at d945a61](https://github.com/anthropics/claude-code/tree/d945a61bc6346abce607252d5667df8a3bf0461a/.devcontainer) · GitHub: [Creating a codespace for a repository](https://docs.github.com/en/codespaces/developing-in-a-codespace/creating-a-codespace-for-a-repository), [Setting your default editor for GitHub Codespaces](https://docs.github.com/en/codespaces/setting-your-user-preferences/setting-your-default-editor-for-github-codespaces), [Default environment variables for your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/default-environment-variables-for-your-codespace), [Rebuilding the container in a codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/rebuilding-the-container-in-a-codespace), [Stopping and starting a codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/stopping-and-starting-a-codespace), [Deleting a codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/deleting-a-codespace), [GitHub Codespaces billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces) · VS Code: [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers), [Sharing Git credentials with your container](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials) · [Dev Container metadata reference](https://containers.dev/implementors/json_reference/) · Dev Container images: [Ubuntu](https://github.com/devcontainers/images/tree/main/src/base-ubuntu) · Docker: [Volumes](https://docs.docker.com/engine/storage/volumes/), [docker container rm](https://docs.docker.com/reference/cli/docker/container/rm/), [docker volume rm](https://docs.docker.com/reference/cli/docker/volume/rm/) · Git: [githooks](https://git-scm.com/docs/githooks) · [ipset](https://ipset.netfilter.org/ipset.man.html)</sub>

<sub>Назад к [индексу Advanced](../README.md) · Тема: [Разрешения и безопасность](../../topics/permissions-and-safety.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-dev-containers)</sub>
