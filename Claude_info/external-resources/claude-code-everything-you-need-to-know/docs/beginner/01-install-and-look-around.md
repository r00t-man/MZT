# Установка, вход и осмотр

<sub>**Начинающий** · Урок 1 из 5 · около 20 минут · Требуется: [Индекс для начинающих](README.md) · Проверено на Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого урока вы сможете установить Claude Code, войти в систему, запустить его в репозитории и определить, какие версию, модель и аккаунт использует сессия.

## Вам понадобится

- Терминал и git, а также подписка Claude (Pro, Max, Team или Enterprise; бесплатный план не включает Claude Code), аккаунт Claude Console или доступ через поддерживаемого облачного провайдера ([Быстрый старт](https://code.claude.com/docs/en/quickstart), [Расширенная настройка](https://code.claude.com/docs/en/setup)).
- Ваша копия практического шаблона, склонированная, как описано в [Индексе для начинающих](README.md#practice), и Node.js LTS для его проверок. В Codespace на вашей копии Claude Code уже установлен: начните с шага 3.
- Чтобы практиковаться в одном из ваших собственных репозиториев, сохраните также копию шаблона: проверка запускается из неё. В вашем репозитории создайте папку, куда уроки сохраняют снимки, и скажите git игнорировать её без коммита ([gitignore](https://git-scm.com/docs/gitignore)):

  ```bash
  mkdir -p .practice
  echo '.practice/' >> "$(git rev-parse --git-path info/exclude)"
  ```

  **Windows:** `New-Item -ItemType Directory -Force .practice` и `Add-Content (git rev-parse --git-path info/exclude) '.practice/'`.
- Использование: лёгкое, то есть несколько коротких запросов в одной сессии. Внутри Claude Code `/usage` показывает стоимость сессии и лимиты использования плана ([Команды](https://code.claude.com/docs/en/commands)).

> [!NOTE]
> На нативном Windows выполняйте каждую команду в PowerShell. Команда без строки **Windows** работает там как написано; если после команды идёт строка **Windows**, используйте её вместо неё. Установка [Git for Windows](https://git-scm.com/downloads/win) позволяет Claude Code использовать Bash; без неё Claude Code использует PowerShell ([Быстрый старт](https://code.claude.com/docs/en/quickstart)).
>
> Если PowerShell отказывается запускать `npm` с сообщением `running scripts is disabled on this system`, вводите `npm.cmd` везде, где урок говорит `npm` (например `npm.cmd run check -- b-1`), или разрешите локальные скрипты для вашего аккаунта, как показано в [Устранении неполадок установки](https://code.claude.com/docs/en/troubleshoot-install#running-scripts-is-disabled-on-this-system).

## Идея

Claude Code — это программа, которую вы запускаете в терминале внутри папки проекта. Она читает файлы там и отвечает на вопросы о них; в следующих уроках она также изменяет их.

Прежде чем доверять ответу, узнайте три вещи о сессии:

- **версию**, потому что функции и значения по умолчанию меняются между выпусками;
- **модель**, потому что модели различаются по своим возможностям;
- **аккаунт**, потому что он определяет, какие функции и модели вы можете использовать.

Заголовок, который Claude Code показывает при запуске, содержит версию и модель. Команда `/status` показывает версию, модель и аккаунт вместе ([Команды](https://code.claude.com/docs/en/commands)).

## Рабочий пример

1. Установите Claude Code ([Быстрый старт](https://code.claude.com/docs/en/quickstart)):

   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

   **Windows:** `irm https://claude.ai/install.ps1 | iex`

   Когда установка завершится, откройте новое окно терминала.
2. Проверьте установку. Рабочая установка выводит номер версии, за которым следует `(Claude Code)`:

   ```bash
   claude --version
   ```

   Если ваша оболочка говорит, что `claude` не найден или не распознан, папка установки ещё не в вашем `PATH`: исправьте это с помощью [Устранения неполадок установки](https://code.claude.com/docs/en/troubleshoot-install#command-not-found-claude-after-installation), прежде чем продолжить.
3. Перейдите в вашу практическую копию и сохраните этот вывод для проверки: подставьте полный путь к папке вашей копии вместо `<your practice copy>`, в кавычках, если путь содержит пробел. В Codespace это `/workspaces/`, за которым следует имя вашей копии ([Codespaces глубокое погружение](https://docs.github.com/en/codespaces/about-codespaces/deep-dive), [Codespaces с GitHub CLI](https://docs.github.com/en/codespaces/developing-in-a-codespace/using-github-codespaces-with-github-cli)):

   ```bash
   cd <your practice copy>
   mkdir -p .practice
   claude --version > .practice/version.txt
   ```

   **Windows:** `New-Item -ItemType Directory -Force .practice` заменяет строку с `mkdir`.
4. Запустите сессию в той же папке:

   ```bash
   claude
   ```

   При первом запуске Claude Code попросит вас войти. В приглашении входа в терминале выберите тип вашего аккаунта; с подпиской Claude или аккаунтом Console вы затем завершите вход в браузере. Если браузер показывает код вместо того, чтобы отправить вас обратно, вставьте его в терминал в приглашении `Paste code here if prompted` ([Аутентификация](https://code.claude.com/docs/en/authentication)). С API-ключом или облачным провайдером следуйте [Быстрому старту](https://code.claude.com/docs/en/quickstart).

   В репозитории, которому вы ещё не доверяете, Claude Code также показывает диалог доверия рабочей области, который спрашивает, доверяете ли вы папке ([Безопасность](https://code.claude.com/docs/en/security#additional-safeguards)). **Нет, выйти** выделено по умолчанию, и нажатие Enter на нём завершает Claude Code. Вы создали эту копию, поэтому нажмите стрелку вниз, чтобы выбрать **Да, я доверяю этой папке**, затем нажмите Enter. Claude Code сохраняет это доверие для всего репозитория, поэтому больше не спрашивает здесь ([Настройка разрешений](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)).

   Заголовок над приглашением затем показывает версию, модель и папку.
5. Введите `/status`. Вкладка **Статус** перечисляет версию, модель и аккаунт, под которым вы вошли (строки, такие как **Метод входа** и **Email**). Нажмите `Esc`, чтобы закрыть её ([Интерактивный режим](https://code.claude.com/docs/en/interactive-mode#general-controls)). Ваша версия может быть новее, чем указанная вверху этой страницы: это руководство проверено на канале выпуска `stable`, а Claude Code следует `latest`, если вы не выберете иное ([Настройка канала выпуска](https://code.claude.com/docs/en/setup#configure-release-channel)).
6. Задайте два вопроса о коде:

   ```text
   что делает этот проект?
   ```

   ```text
   какой файл разбирает linkcheck.json и как мне запустить тесты?
   ```

   Claude читает файлы, чтобы ответить. Ваши формулировки будут отличаться, но ответы должны называть `src/config.js` и `npm test`.
7. Завершите сессию с помощью `/exit`.

## Ваша очередь

Повторите пример в вашей практической копии или в вашем собственном репозитории с вашими собственными вопросами:

1. В этой папке сохраните `claude --version` в `.practice/version.txt`.
2. Запустите `claude` там. Ваш собственный репозиторий снова покажет диалог доверия, потому что доверие сохраняется для каждого репозитория: выбирайте **Да, я доверяю этой папке** только для кода, который вы знаете.
3. Откройте `/status` и отметьте модель и аккаунт.
4. Задайте два своих вопроса о коде, затем завершите сессию с помощью `/exit`.

## Проверка

Вы закончили, когда все следующие пункты истинны:

- [ ] `.practice/version.txt` содержит строку вида `X.Y.Z (Claude Code)`. Проверьте это с помощью `cat .practice/version.txt`.
- [ ] Самопроверка (не тестируется): вы можете сказать, какую модель и какой аккаунт показал `/status`.

Запустите `npm run check -- b-1` в вашей практической копии. В вашем собственном репозитории вместо этого запустите `npm run check -- b-1 --dir <your repo>` из вашей практической копии. Ошибка npm, такая как `Could not read package.json` или `Missing script: "check"`, означает, что вы запустили её вне вашей практической копии: перейдите в копию с помощью `cd` и запустите снова.

Если первый пункт не выполняется, запустите `claude --version` отдельно: если он выводит ошибку, исправьте её, как описано в шаге 2 рабочего примера; если он выводит версию, сохраните её снова в папке, которую читает проверка (ваша практическая копия или репозиторий, переданный в `--dir`).

## Осторожно

- Новая сессия может редактировать большинство файлов и запускать большинство команд без предварительного запроса ([Быстрый старт](https://code.claude.com/docs/en/quickstart)). В этом уроке только задавайте вопросы; следующий урок покажет, как выбирать, что Claude может делать самостоятельно. Даже вопрос может привести к тому, что Claude запустит команду, которая записывает файлы, например запустит тесты, чтобы ответить вам: выполните `git status`, когда сессия закончится, и перед уроком 2 закоммитьте или удалите всё, что он перечислит.

## Дальнейшее изучение

- [Как работает Claude Code](https://code.claude.com/docs/en/how-claude-code-works): что происходит между вашим вопросом и его ответом.
- [Настройка канала выпуска](https://code.claude.com/docs/en/setup#configure-release-channel): как перейти на `stable`, который пропускает выпуски с серьёзными регрессиями.
- [Устранение неполадок установки](https://code.claude.com/docs/en/troubleshoot-install): исправления ошибок установки и входа.

---

<sub>Источники: [Быстрый старт](https://code.claude.com/docs/en/quickstart) · [Расширенная настройка](https://code.claude.com/docs/en/setup) · [Аутентификация](https://code.claude.com/docs/en/authentication) · [Безопасность](https://code.claude.com/docs/en/security) · [Настройка разрешений](https://code.claude.com/docs/en/permissions) · [Команды](https://code.claude.com/docs/en/commands) · [Интерактивный режим](https://code.claude.com/docs/en/interactive-mode) · [Устранение неполадок установки](https://code.claude.com/docs/en/troubleshoot-install) · [gitignore](https://git-scm.com/docs/gitignore) · [Codespaces глубокое погружение](https://docs.github.com/en/codespaces/about-codespaces/deep-dive) · [Codespaces с GitHub CLI](https://docs.github.com/en/codespaces/developing-in-a-codespace/using-github-codespaces-with-github-cli)</sub>

<sub>← [Индекс для начинающих](README.md) · [Режимы разрешений и режим плана](02-permission-modes-and-plan-mode.md) → · Тема: [Модели, усилия и стоимость](../topics/models-effort-and-cost.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=b-1)</sub>
