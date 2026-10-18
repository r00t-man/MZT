# Начинающий

<sub>**Начинающий** · около 2,5 часов · Проверено с Claude Code v2.1.292 (stable) 15.10.2026</sub>

Одна сессия, одно изменение. Вы устанавливаете Claude Code, решаете, что ему разрешено делать без спроса, проводите одно изменение от запроса до коммита, удерживаете длинную сессию в нужном русле и даёте ему память проекта.

## Вы готовы к этому уровню, если умеете

- [ ] Работать в терминале: менять папки, запускать команды и читать их вывод.
- [ ] Использовать git: клонировать репозиторий, делать коммит и читать `git status` и `git diff`.
- [ ] Иметь подписку Claude (Pro, Max, Team или Enterprise; бесплатный план не включает Claude Code), аккаунт Claude Console или доступ через поддерживаемого облачного провайдера ([Quickstart](https://code.claude.com/docs/en/quickstart), [Advanced setup](https://code.claude.com/docs/en/setup)). Урок 1 показывает, как войти.

Новичок в терминале? Официальное [Terminal guide for new users](https://code.claude.com/docs/en/terminal-guide) проведёт вас через открытие терминала и установку Claude Code.

## Практика

Перед уроком 1 сделайте собственную копию [practice template](https://github.com/wesammustafa/claude-code-practice): выберите **Use this template**, затем **Create a new repository** и клонируйте свою копию. Все упражнения для начинающих и капстоун выполняются в ней.

Чтобы идти шаг за шагом, запустите `npm run learn` в своей копии и используйте Claude Code во втором терминале рядом. Приложение проведёт вас через каждый основной урок и капстоун, шаг за шагом, и проверяет вашу работу по ходу. Каждая страница ниже обучает тому же уроку самостоятельно.

Каждый основной урок и капстоун заканчиваются проверкой, которую вы запускаете в своей копии как `npm run check -- <id>`, где id — `b-1`–`b-5` для уроков и `b-capstone` для капстоуна. Элективы заканчиваются чек-листом, который вы подтверждаете сами. Для проверок нужен Node.js LTS, который предустановлен в Codespace на вашей копии. Чтобы практиковаться в одном из своих репозиториев, сохраните и копию шаблона: проверки запускаются из неё с `--dir`.

На нативном Windows, если PowerShell отказывается запускать `npm` с ошибкой `running scripts is disabled on this system` ([Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install#running-scripts-is-disabled-on-this-system)), следуйте примечанию для Windows в [уроке 1](01-install-and-look-around.md#you-need).

## Уроки

1. [Установка, вход и осмотр](01-install-and-look-around.md)
2. [Режимы разрешений и режим плана](02-permission-modes-and-plan-mode.md)
3. [Ваше первое изменение, от запроса до коммита](03-first-change.md)
4. [Удержание сессии в нужном русле](04-keep-a-session-on-track.md)
5. [Память проекта с CLAUDE.md](05-project-memory.md)

Каждый урок занимает около 20 минут, капстоун — 30–60.

## Капстоун

[Исправление зарегистрированного бага, от плана до коммита](capstone.md): запишите версию Claude Code, затем исправьте зарегистрированный баг в шаблоне практики: спланируйте исправление, измените два исходных файла, добавьте тест, который падает до исправления и проходит после, и сделайте коммит. Проверка покрывает то, что видно в файлах и git, а страница капстоуна перечисляет остальное из [Beginner Exit](#by-the-end-of-this-level-you-can), чтобы вы отметили сами.

## К концу этого уровня вы умеете

Этот список — Beginner Exit ([Glossary](../reference/glossary.md)), который капстоун объединяет в одну задачу.

- [ ] Устанавливать Claude Code, входить, запускать его в своём репозитории и определять, какая у вас версия, модель и аккаунт.
- [ ] Выбирать и переключать режимы разрешений, а также одобрять план в режиме плана перед любым изменением.
- [ ] Проводить одно изменение от запроса до коммита: исследовать, планировать, реализовывать, тестировать, просматривать diff, исправлять, коммитить.
- [ ] Удерживать сессию в нужном русле с помощью context, clear, compact, rewind и resume.
- [ ] Создавать проектный CLAUDE.md и показывать, что новая сессия следует ему.

## Элективы

Необязательные уроки вне основного пути:

- [Расширения IDE](electives/ide-extensions.md)
- [Скриншоты и изображения](electives/screenshots-and-images.md)
- [Встроенные учителя](electives/built-in-teachers.md): `/powerup`, стили вывода Learning и Explanatory, а также субагент `claude-code-guide`

## Официальные спутники

- [Quickstart](https://code.claude.com/docs/en/quickstart): пошаговое руководство Anthropic от установки до первого изменения.
- [Claude Code 101](https://academy.claude.com/courses/claude-code-101): курс для начинающих от Claude Academy.
- `/powerup`: интерактивные уроки внутри Claude Code ([Commands](https://code.claude.com/docs/en/commands)).

## Следующий уровень

[Intermediate](../intermediate/README.md): настройка одного разработчика.

---

<sub>Источники: [Quickstart](https://code.claude.com/docs/en/quickstart) · [Advanced setup](https://code.claude.com/docs/en/setup) · [Terminal guide for new users](https://code.claude.com/docs/en/terminal-guide) · [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) · [Commands](https://code.claude.com/docs/en/commands) · [Output styles](https://code.claude.com/docs/en/output-styles) · [Create custom subagents](https://code.claude.com/docs/en/sub-agents)</sub>

<sub>Вверх: [Claude Code: Everything You Need to Know](../../README.md#pick-your-level)</sub>
