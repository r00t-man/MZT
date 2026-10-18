# Проверка изменений UI в браузере с помощью Claude в Chrome

<sub>**Intermediate** · Elective · около 15 минут · Требуется: [Подключение инструмента через MCP](../07-mcp.md) · Проверено с Claude Code v2.1.292 (stable) 2026-10-15</sub>

## Цель

К концу этого Elective вы сможете подключить Claude Code к вашему браузеру и попросить Claude проверить страницу, которую вы изменили: её консоль, отображаемое содержимое и скриншот.

## Вам понадобится

- Google Chrome или Microsoft Edge с расширением [Claude in Chrome](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn), версии 1.0.36 или новее ([Предварительные требования](https://code.claude.com/docs/en/chrome#prerequisites)).
- План Pro, Max, Team или Enterprise, вход выполнен с помощью `/login`. При использовании API-ключа интеграция с Chrome в Claude Code отключена.
- macOS, Linux или нативный Windows: интеграция с Chrome не поддерживается в WSL.
- Один из ваших репозиториев с папкой `.practice/` и `python3` для локального запуска страницы.
- Использование: небольшое.

## Идея

[Claude in Chrome](https://code.claude.com/docs/en/chrome) подключает Claude Code к браузеру, которым вы пользуетесь ежедневно, через расширение. Claude открывает собственные вкладки в видимом окне, так что вы наблюдаете за его работой, и он останавливается, чтобы вы могли обработать страницу входа или CAPTCHA.

В отличие от [урока 7](../07-mcp.md), где использовался MCP-сервер Chrome DevTools с временным профилем, здесь используется состояние входа вашего браузера: Claude может получить доступ к любому сайту, на котором вы вошли. Разрешения расширения определяют, какие сайты Claude может просматривать, нажимать и вводить текст.

> [!WARNING]
> Claude действует с вашими учетными данными. Ограничьте его сайтами, необходимыми для задачи, и читайте каждое приглашение `Claude in Chrome wants to`, прежде чем разрешить сайт.

## Рабочий пример

1. Сохраните страницу с ошибкой, затем запустите сервер для этой папки только на этом компьютере:

   ```bash
   cat > .practice/ui-demo.html <<'EOF'
   <!doctype html>
   <title>Linkcheck status</title>
   <h1>Linkcheck status</h1>
   <p id="status">Loading...</p>
   <script>document.getElementById('stauts').textContent = 'Ready';</script>
   EOF
   python3 -m http.server 8000 --bind 127.0.0.1 --directory .practice
   ```

2. Во втором терминале запустите Claude Code с Chrome: `claude --chrome`. При первом запуске появится диалог с объяснением интеграции; нажмите `Enter`.
3. Выполните `/chrome`. Когда отобразится `Status: Enabled` и `Extension: Installed`, интеграция работает. Если нет, выйдите из Claude Code, перезапустите Chrome и снова выполните `claude --chrome`: при первом запуске Claude Code устанавливает файл подключения, который Chrome читает только при запуске ([Расширение не обнаружено](https://code.claude.com/docs/en/chrome#extension-not-detected)).
4. Спросите:

   ```text
   Open http://127.0.0.1:8000/ui-demo.html and tell me what the page shows. Read its console for errors, reloading the page if you need to catch errors from page load, and save a screenshot of it to disk.
   ```

   Подтверждайте каждое приглашение, начинающееся с `Claude in Chrome wants to`; для сайта вы можете разрешить все его действия на сессию. Claude откроет вкладку, сообщит, что страница по-прежнему показывает `Loading...` и что отображается в консоли, и предоставит путь к скриншоту. Ваша формулировка может отличаться.

## Ваша очередь

Исправьте ошибку и попросите Claude подтвердить исправление в браузере.

1. Попросите Claude исправить скрипт в `.practice/ui-demo.html`, чтобы страница показывала `Ready`.
2. Попросите его перезагрузить страницу в Chrome, снова прочитать консоль и сохранить новый скриншот.

## Проверка

Вы закончили, когда все следующие условия выполнены:

- [ ] `/chrome` показывает `Status: Enabled` и `Extension: Installed`.
- [ ] Оба скриншота существуют: `ls -l` для каждого пути, указанного Claude.
- [ ] Самопроверка (не тестируется): после исправления консоль не показывала ошибок, и новый скриншот отображает `Ready`.

Если Claude не использует браузер, начните сессию с `--chrome` или выполните `/chrome` и выберите **Enabled by default**. Это загружает инструменты браузера в каждой сессии, что потребляет больше контекста.

## Дополнительно

- [Использование Claude Code с Chrome](https://code.claude.com/docs/en/chrome): дополнительные сценарии, от заполнения форм до записи GIF, и устранение неполадок.
- [Начало работы с Claude in Chrome](https://support.claude.com/en/articles/12012173-getting-started-with-claude-in-chrome): само расширение, включая его горячие клавиши и разрешения.

---

<sub>Источники: [Use Claude Code with Chrome](https://code.claude.com/docs/en/chrome)</sub>

<sub>Назад к [Intermediate index](../README.md) · Тема: [MCP](../../topics/mcp.md) · [Застряли на этом уроке?](https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know/issues/new?template=lesson-feedback.yml&lesson=i-chrome)</sub>
