# Тестовые данные

| Файл | Что внутри | Откуда |
|---|---|---|
| `content_p582_583.json` | Страницы 582–583 мединского мусхафа: сура 78 целиком и аяты 79:1–15. Таблицы `surah`, `ayah`, `word`, `page`, `line`, `content_version` (ТЗ 12.2), без шрифтов | Собрано `tools/content_build` из скачанных источников, вручную не правится |

Пересобрать:

```bash
dart run tools/content_build/bin/content_build.dart --no-fonts --fixture-out packages/testing/fixtures/content_p582_583.json
```

## Атрибуция

Текст Корана в `textUthmani` — дословная копия текста Tanzil (https://tanzil.net), лицензия CC BY 3.0, изменять текст нельзя. Слова — это куски текста аята между пробелами; знак паузы, стоящий в Tanzil отдельно, присоединён к предыдущему слову вместе с пробелом, так что слова аята, соединённые пробелом, дают исходный текст байт в байт.

Разметка страниц и коды знаков — KFGQPC V2 через API Quran.com / QUL; условия использования ещё не подтверждены (ТЗ 6.1).

Полное уведомление Tanzil — в поле `contentVersion.textNotice` файла и в [`tools/content_build/ATTRIBUTION.md`](../../../tools/content_build/ATTRIBUTION.md).
