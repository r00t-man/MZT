# Настройка строки состояния

<sub>**Intermediate** · Elective · около 15 минут · Требуется: [Выбор модели и усилий](../03-model-and-effort.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого Elective вы сможете задать собственную строку состояния Claude Code с помощью скрипта, который показывает модель, папку и заполненность контекстного окна.

## Вам понадобится

- `jq`, а также macOS или Linux: скрипт написан на bash. На Windows [конфигурация Windows](https://code.claude.com/docs/en/statusline#windows-configuration) содержит версии для PowerShell и Git Bash.
- Использование: отсутствует. Строка состояния работает на вашей машине и не использует токены API.

## Идея

[Строка состояния](https://code.claude.com/docs/en/statusline) — это панель внизу Claude Code, которая показывает всё, что выводит ваш скрипт. Claude Code запускает скрипт, передавая JSON о сессии через stdin, например имя модели и заполненность контекстного окна. Он запускается при старте сессии и снова при событиях, таких как каждое новое сообщение от Claude.

Есть два способа настройки. `/statusline` с описанием просит Claude Code написать скрипт и настройку за вас. Или вы пишете скрипт сами и добавляете настройку `statusLine`, которая его запускает, что и делается в этом Elective, чтобы вы понимали, что делает каждая часть.

## Рабочий пример

1. Сохраните этот скрипт как `~/.claude/statusline.sh`, затем выполните `chmod +x ~/.claude/statusline.sh`:

   ```bash
   #!/bin/bash
   input=$(cat)
   MODEL=$(echo "$input" | jq -r '.model.display_name')
   DIR=$(echo "$input" | jq -r '.workspace.current_dir')
   PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
   echo "[$MODEL] ${DIR##*/} | ${PCT}% context"
   ```

2. Протестируйте его без Claude Code, используя JSON, который он получает:

   ```bash
   echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/me/linkcheck"},"context_window":{"used_percentage":12.5}}' | ~/.claude/statusline.sh
   ```

   Он выведет `[Opus] linkcheck | 12% context`.
3. Добавьте настройку в `~/.claude/settings.json`, ваш личный файл, рядом с уже существующими ключами:

   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/statusline.sh"
   }
   ```

4. Запустите `claude` и отправьте запрос. Панель покажет вашу строку, и процент будет расти по мере разговора. Claude Code запускает её только в папке, для которой вы приняли диалог доверия.

## Ваша очередь

Добавьте текущую ветку git в строку. В скрипте перед `echo` добавьте:

```bash
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
```

Затем добавьте ` | $BRANCH` к `echo`, снова протестируйте скрипт с JSON из шага 2, используя `current_dir`, который является git-репозиторием, и посмотрите на панель в сессии.

## Проверка

Вы закончили, когда все следующие условия выполнены:

- [ ] `jq .statusLine ~/.claude/settings.json` показывает вашу команду.
- [ ] Передача JSON из шага 2 с `current_dir` в git-репозитории в ваш скрипт выводит модель, папку, процент и ветку.
- [ ] Самопроверка (не тестируется): в сессии панель показывает вашу строку.

Если панель остаётся пустой, запустите скрипт с JSON из шага 2: скрипт, который завершается с ошибкой или ничего не выводит, оставляет панель пустой ([Устранение неполадок](https://code.claude.com/docs/en/statusline#troubleshooting)). Затем проверьте, что он исполняемый, с помощью `chmod +x`, и что вы приняли диалог доверия для папки.

## Дополнительно

- [Доступные данные](https://code.claude.com/docs/en/statusline#available-data): все поля, которые получает ваш скрипт, такие как стоимость, лимиты скорости и имя сессии.
- [Примеры](https://code.claude.com/docs/en/statusline#examples): цвета, несколько строк, кликабельные ссылки и кэшированный статус git.

---

<sub>Источники: [Customize your status line](https://code.claude.com/docs/en/statusline)</sub>

<sub>Назад к [Intermediate index](../README.md) · Тема: [Models, effort and cost](../../topics/models-effort-and-cost.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-status-line)</sub>
