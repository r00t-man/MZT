# `/goal`, `/loop` и рутины

<sub>**Продвинутый** · Электив · около 20 минут плюс время выполнения · Требуется: [Ограничьте автономные запуски](../07-bounded-runs.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

> [!NOTE]
> "Рутины находятся в стадии исследовательского предпросмотра. Поведение, ограничения и API могут измениться." ([Автоматизируйте работу с рутинами](https://code.claude.com/docs/en/routines))

## Цель

К концу этого электива вы сможете поддерживать работу Claude без подсказок на каждом шаге: к условию с помощью `/goal`, по интервалу с помощью `/loop` и по расписанию в облаке с помощью рутины.

## Вам понадобится

- Ваша копия практического шаблона с Node.js LTS для рабочего примера и один из ваших собственных репозиториев для раздела «Ваша очередь».
- Для рутины, только шаги 7–9: план Pro, Max, Team или Enterprise, вход с помощью `/login` ([Доступность по тарифным планам](https://code.claude.com/docs/en/feature-availability#availability-by-subscription-plan)). Рутинам нужна подписка Claude, поэтому с ключом API Console или облачным провайдером пропустите эти шаги ([Доступность функций](https://code.claude.com/docs/en/feature-availability#features-that-require-a-claude-subscription)). На Team и Enterprise владелец может отключить рутины для всех ([Автоматизируйте работу с рутинами](https://code.claude.com/docs/en/routines)).
- Также для рутины: доступ GitHub для облачных сессий к вашей копии через Claude GitHub App или `/web-setup`; с App для приватной копии нужно установить App на неё ([Варианты аутентификации GitHub](https://code.claude.com/docs/en/claude-code-on-the-web#github-authentication-options)). На Team и Enterprise в любом случае сначала нужен владелец: коннектор GitHub для входа через браузер в App или быстрая настройка для `/web-setup` ([Подключите GitHub](https://code.claude.com/docs/en/web-quickstart#connect-github), [Быстрая настройка для Team и Enterprise](https://code.claude.com/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise)).
- Использование: умеренное. Цель выполняет несколько ходов, каждый запуск цикла снова отправляет весь контекст сессии ([Почему расход растёт в длинной сессии](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session)), а запуск рутины — это полная облачная сессия, которая расходует ваш план ([Использование и лимиты](https://code.claude.com/docs/en/routines#usage-and-limits)). Шаги делают каждый запуск небольшим: Sonnet, лимит ходов, короткий цикл и рутина, которая выполняется один раз. Дешёвый вариант: пропустите рутину (шаги 7–9).

## Идея

`/goal`, `/loop` и рутина запускают следующий запуск Claude без вас ([Сравните способы поддерживать сессию](https://code.claude.com/docs/en/goal#compare-ways-to-keep-a-session-running), [Сравните варианты планирования](https://code.claude.com/docs/en/scheduled-tasks#compare-scheduling-options)):

| | Следующий запуск начинается, когда | Останавливается, когда |
|---|---|---|
| `/goal` | Заканчивается ход, и вторая модель, оценщик, решает, что ваше условие ещё не выполнено | Оно признано выполненным или невозможным, ход сталкивается с ошибкой, которую вы должны исправить, или `/goal clear` |
| `/loop` | Проходит интервал, пока сессия простаивает | Вы отменяете его, Claude завершает цикл в своём темпе, или он истекает |
| Рутина | Расписание, вызов API или событие GitHub в облаке | Вы приостанавливаете или удаляете её; одноразовая отключается сама |

Оценщик читает только разговор, поэтому ваше условие должно называть проверку, результат которой виден в выводе Claude, например «`npm test` завершается с кодом 0», указывать, что не должно меняться, и заканчиваться лимитом ходов ([Напишите эффективное условие](https://code.claude.com/docs/en/goal#write-an-effective-condition)). Цели и циклы сохраняют режим разрешений сессии: в автоматическом режиме они работают без присмотра, а в ручном режиме Claude сначала спрашивает ([Установите цель](https://code.claude.com/docs/en/goal#set-a-goal), [Сравните варианты планирования](https://code.claude.com/docs/en/scheduled-tasks#compare-scheduling-options)).

> [!WARNING]
> Рутина выполняется как полная облачная сессия, которая не останавливается для одобрения, за исключением некоторых действий с артефактами, и действует от вашего имени: её коммиты и pull request'ы используют вашего пользователя GitHub ([Создайте рутину](https://code.claude.com/docs/en/routines#create-a-routine)). Она может использовать каждый инструмент каждого включённого коннектора, включая запись, без запроса, и по умолчанию включены все коннекторы вашего аккаунта claude.ai ([Создание из веба](https://code.claude.com/docs/en/routines#create-from-the-web), [Коннекторы](https://code.claude.com/docs/en/routines#connectors)). Удалите коннекторы, которые рутине не нужны, и пока учитесь, ограничивайте её промпт работой только на чтение.

## Рабочий пример

Работайте в своей практической копии на новой ветке.

1. Создайте ветку и папку для журнала, которую git уже игнорирует в копии, затем запустите Claude Code на Sonnet:

   ```bash
   git switch -c keep-working
   mkdir -p .practice
   claude --model sonnet
   ```

   **Windows:** `New-Item -ItemType Directory -Force .practice` заменяет строку с `mkdir`.

   В строке состояния показан режим разрешений ([Переключение режимов разрешений](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)). Если отображается `⏸ manual mode on`, одобряйте каждый вызов инструмента по запросу Claude; если отображается `⏵⏵ auto mode on`, ходы цели и запуски цикла выполняются самостоятельно.
2. Установите цель. Проверка ссылок сообщает о ссылке вида `setup.md?plain=1` как о битой, даже если `setup.md` существует, потому что она удаляет только часть `#` из ссылки:

   ```text
   /goal npm test exits 0, a new test in test/links.test.js shows that a link such as setup.md?plain=1 to a file that exists is not reported as broken, no existing test changes, and the fix is committed; or stop after 8 turns
   ```

   Claude сразу начинает работу, и `◎ /goal active` показывает, как долго выполняется цель. После каждого хода в транскрипте отображается вердикт оценщика; нажмите `Ctrl+O`, чтобы увидеть причину ([Установите цель](https://code.claude.com/docs/en/goal#set-a-goal)).
3. Когда оценщик решает, что условие выполнено, Claude Code снимает цель и записывает запись о достижении в транскрипт ([Как работает оценка](https://code.claude.com/docs/en/goal#how-evaluation-works)). Выполните `/goal`: он покажет достигнутое условие с длительностью, количеством ходов и расходом токенов ([Проверьте статус](https://code.claude.com/docs/en/goal#check-status)). Во втором терминале `git log --oneline -1` покажет коммит, и `npm test` пройдёт. Если `npm test` всё ещё падает или `git log` не показывает новый коммит, цель завершилась до исправления, например, на лимите ходов или была признана невозможной, и `/goal` покажет, активна ли она: попросите Claude завершить исправление и закоммитить его.
4. Запустите цикл, который записывает результаты тестов каждую минуту:

   ```text
   /loop 1m run npm test and append one line to .practice/loop-log.txt with the time and the number of passing and failing tests. Don't change any other file.
   ```

   Claude планирует его и подтверждает периодичность и идентификатор задания ([Запуск через фиксированный интервал](https://code.claude.com/docs/en/scheduled-tasks#run-on-a-fixed-interval)). Каждый запуск происходит между вашими ходами, никогда во время ответа Claude ([Как выполняются запланированные задачи](https://code.claude.com/docs/en/scheduled-tasks#how-scheduled-tasks-run)).
5. В своём редакторе, не через Claude, сломайте один тест: в `test/config.test.js` измените `files: ['.']` первого теста на `files: ['docs']`. Подождите, пока в журнале появится строка с ошибкой, затем отмените изменение с помощью `git restore test/config.test.js`.
6. Попросите Claude `cancel the npm test loop`, затем `what scheduled tasks do I have?`: ничего не осталось ([Управление запланированными задачами](https://code.claude.com/docs/en/scheduled-tasks#manage-scheduled-tasks)). `cat .practice/loop-log.txt` покажет строку для каждого запуска, по крайней мере одна из них с ошибкой. Ваши формулировки будут отличаться.
7. Для шагов 7–9 нужна подписка; без неё переходите к шагу 10. Запланируйте рутину, которая выполнится один раз через пять минут:

   ```text
   /schedule in 5 minutes, run npm test in this repository and reply with the number of passing and failing tests. Don't edit files, commit or push.
   ```

   Claude задаст уточняющие вопросы о расписании, репозитории и промпте и подтвердит абсолютное время перед сохранением ([Создание из CLI](https://code.claude.com/docs/en/routines#create-from-the-cli), [Запланируйте одноразовый запуск](https://code.claude.com/docs/en/routines#schedule-a-one-off-run)). Скажите ему не включать коннекторы; если не получится, удалите их сразу после сохранения с помощью `/schedule update` или формы **Edit** рутины на `claude.ai/code/routines` ([Коннекторы](https://code.claude.com/docs/en/routines#connectors)).
   Если Claude добавит примечание о настройке доступа GitHub, следуйте ему до времени запуска; если время уже прошло, отредактируйте рутину и установите новое одноразовое время ([Репозитории и разрешения веток](https://code.claude.com/docs/en/routines#repositories-and-branch-permissions), [Редактирование и управление рутинами](https://code.claude.com/docs/en/routines#edit-and-control-routines)). Если Claude ответит, что нужна аутентификация, рутина не была сохранена; если `/schedule` нет в меню команд, см. [`/schedule` возвращает "Unknown command"](https://code.claude.com/docs/en/routines#schedule-returns-unknown-command).
8. `/schedule list` покажет рутину ([Управление рутинами из CLI](https://code.claude.com/docs/en/routines#manage-routines-from-the-cli)). После выполнения откройте её на `claude.ai/code/routines`, откройте запуск и прочитайте транскрипт, чтобы увидеть количество тестов ([Просмотр и взаимодействие с запусками](https://code.claude.com/docs/en/routines#view-and-interact-with-runs)). Запуск склонировал вашу ветку по умолчанию, поэтому его количество не включает тест, который вы добавили на `keep-working` ([Репозитории и разрешения веток](https://code.claude.com/docs/en/routines#repositories-and-branch-permissions)). Одноразовая рутина теперь отмечена как **Ran**.
9. Удалите рутину: откройте меню рядом с её именем и выберите **Delete** ([Редактирование и управление рутинами](https://code.claude.com/docs/en/routines#edit-and-control-routines)).
   Если вы подключили GitHub только для рутины, отключите его на `claude.ai/customize/connectors`, что удалит учётные данные независимо от того, получены они из браузера или через `/web-setup`; сам токен `gh` остаётся действительным на GitHub ([Удалите токен `/web-setup`](https://code.claude.com/docs/en/web-quickstart#remove-the-web-setup-token)). Если вы установили Claude GitHub App только для рутины, также удалите свою копию из доступа к репозиторию и удалите App, только если он больше нигде не используется ([Просмотр и изменение установленных GitHub Apps](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps)).
10. `git switch -` вернёт вашу копию на ветку, с которой вы начали; `keep-working` сохранит исправление.

## Ваша очередь

В одном из своих репозиториев выберите задачу, конечное состояние которой можно доказать командой, например, падающий тест или ошибку линтера. Завершите её с помощью цели. Затем закоммитьте `.claude/loop.md`, который продолжит следить за ней: файл заменяет встроенный промпт `/loop`, который вы запускаете без собственного промпта ([Настройте промпт по умолчанию с помощью loop.md](https://code.claude.com/docs/en/scheduled-tasks#customize-the-default-prompt-with-loop-md)). С подпиской вы также можете запустить одноразовую рутину для выполнения команды в облаке, когда ваша работа окажется в ветке по умолчанию, или указать свою ветку в промпте рутины ([Репозитории и разрешения веток](https://code.claude.com/docs/en/routines#repositories-and-branch-permissions)).

Готово, когда:

- Ваше условие называет команду, доказывающую конечное состояние, одну вещь, которая не должна меняться, и лимит ходов.
- Работа закоммичена, и команда завершается с кодом 0.
- `.claude/loop.md` закоммичен. В нём указано, что проверять, и сообщать одной строкой, не меняя файлы. `/loop 10m` (интервал без промпта) выполнил его как минимум дважды, затем вы его отменили ([Запустите встроенный промпт обслуживания](https://code.claude.com/docs/en/scheduled-tasks#run-the-built-in-maintenance-prompt)).
- Не осталось запланированных задач или рутин: `what scheduled tasks do I have?` ничего не показывает, и все созданные рутины удалены.

## Проверка

Вы закончили, когда всё перечисленное верно:

- [ ] В вашем репозитории работа по цели закоммичена (`git log -1` показывает её), и команда, названная в условии, завершается с кодом 0.
- [ ] В вашей практической копии `.practice/loop-log.txt` содержит строки как минимум от двух запусков цикла, по крайней мере одна из них с ошибкой.
- [ ] `.claude/loop.md` закоммичен в вашем репозитории (`git ls-files .claude/loop.md` выводит его), и `git status --porcelain` ничего не выводит.
- [ ] Самопроверка (не тестируется): ваше условие называло команду, одну вещь, которая не должна меняться, и лимит ходов; `/loop 10m` выполнил ваш `loop.md` как минимум дважды до отмены; `what scheduled tasks do I have?` ничего не показывает; и если вы создавали рутину, вы прочитали транскрипт её запуска и удалили её.

Если команда всё ещё падает, цель завершилась до окончания работы, например, на лимите ходов или была признана невозможной: нажмите `Ctrl+O`, чтобы прочитать причину последнего вердикта ([Как работает оценка](https://code.claude.com/docs/en/goal#how-evaluation-works)), затем исправьте причину или установите новую цель; если `/goal` не запускается, он скажет почему, обычно это недоверенная папка или `disableAllHooks` ([Требования](https://code.claude.com/docs/en/goal#requirements)). Если ни одна строка журнала не показывает ошибку, цикл не выполнялся, пока тест был сломан: запустите цикл снова, как в шаге 4, сломайте тест, как в шаге 5, дождитесь строки с ошибкой, восстановите файл, затем отмените цикл, как в шаге 6. Если `git ls-files` ничего не выводит, `git check-ignore -v .claude/loop.md` назовёт правило, скрывающее файл: добавьте его с помощью `git add -f`, затем закоммитьте.

## Осторожно

- Цикл срабатывает, даже когда вас нет, каждый раз отправляя весь контекст сессии, и продолжается, пока вы его не отмените или он не истечёт ([Остановите цикл](https://code.claude.com/docs/en/scheduled-tasks#stop-a-loop)). На плане Pro, Max, Team или Enterprise `/usage` покажет самые тяжёлые циклы ([Разбивка использования плана](https://code.claude.com/docs/en/costs#plan-usage-breakdown)).
- Оценщик не может подтвердить условие, которое вывод Claude не может показать, например, «код чистый». Назовите команду и её результат ([Как работает оценка](https://code.claude.com/docs/en/goal#how-evaluation-works)).
- Зелёный статус в списке запусков рутины означает лишь, что сессия началась и завершилась без ошибок инфраструктуры. Откройте запуск и прочитайте транскрипт, чтобы увидеть, сработала ли задача ([Просмотр и взаимодействие с запусками](https://code.claude.com/docs/en/routines#view-and-interact-with-runs)).

## Дальнейшие шаги

- [Loop engineering: Getting started with loops](https://claude.com/resources/articles/getting-started-with-loops): команда Claude Code в Anthropic о циклах на основе ходов, целей, времени и проактивных циклах, и когда какой использовать.
- [Prompt-based hooks](https://code.claude.com/docs/en/hooks-guide#prompt-based-hooks): тип Stop hook, который оборачивает `/goal` ([Как работает оценка](https://code.claude.com/docs/en/goal#how-evaluation-works)), для проверки, которую вы хотите в каждой сессии.
- [Schedule recurring tasks in Claude Code Desktop](https://code.claude.com/docs/en/desktop-scheduled-tasks): запланированные задачи, которые выполняются на вашей машине с вашими локальными файлами, пока открыто приложение Desktop.

---

<sub>Источники: [Keep Claude working toward a goal](https://code.claude.com/docs/en/goal) · [Run prompts on a schedule](https://code.claude.com/docs/en/scheduled-tasks) · [Automate work with routines](https://code.claude.com/docs/en/routines) · [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) · [Manage costs effectively](https://code.claude.com/docs/en/costs) · [Feature availability](https://code.claude.com/docs/en/feature-availability) · [Use Claude Code in the cloud](https://code.claude.com/docs/en/claude-code-on-the-web) · [Get started with Claude Code in the cloud](https://code.claude.com/docs/en/web-quickstart) · [Reviewing and modifying installed GitHub Apps](https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps)</sub>

<sub>Назад к [индексу Advanced](../README.md) · Тема: [Автоматизация](../../topics/automation.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=a-goal-loop)</sub>
