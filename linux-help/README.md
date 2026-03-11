# linux-help import

Не удалось автоматически скопировать статьи из `https://github.com/soulpastwk/linux-help` в этой среде, потому что исходящие запросы к GitHub блокируются (`CONNECT tunnel failed, response 403`).

Чтобы импортировать все статьи локально, выполните:

```bash
git clone https://github.com/soulpastwk/linux-help /tmp/linux-help-src
mkdir -p linux-help
cp -r /tmp/linux-help-src/* linux-help/
cp -r /tmp/linux-help-src/.github linux-help/ 2>/dev/null || true
```

После этого можно закоммитить содержимое папки `linux-help`.
