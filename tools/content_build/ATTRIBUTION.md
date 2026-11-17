# Источники и лицензии

Файл копируется в каждую сборку (`build/content/<id>/ATTRIBUTION.md`). Реестр прав — ТЗ, раздел 6.1.

| Компонент | Источник | Лицензия (идентификатор в `content_version`) | Статус по ТЗ 6.1 |
|---|---|---|---|
| Канонический текст (Uthmani) | Tanzil Project, https://tanzil.net — `Tanzil Quran Text (Uthmani, Version 1.1)` | `CC-BY-3.0`; текст менять нельзя, нужна ссылка на tanzil.net | Предварительно можно |
| Разметка страниц 15 строк (KFGQPC V2, 1421 г. х.) и коды знаков шрифта QPC V2 | Комплекс короля Фахда (KFGQPC); данные через API Quran.com v4 (`api.quran.com`), тот же набор, что в QUL (https://qul.tarteel.ai) | `LicenseRef-KFGQPC-QUL-unverified` | Проверить: письменное подтверждение условий |
| Шрифты страниц QPC V2 (`p582.ttf`, `p583.ttf`) | KFGQPC, раздача QUL: `static-cdn.tarteel.ai/qul/fonts/quran_fonts/v2/ttf/` | `LicenseRef-KFGQPC-fonts-unverified` | Проверить |
| Место ниспослания и число аятов суры (только для сверки) | API Quran.com v4, `chapters/{n}` | `LicenseRef-QuranCom-API-unverified` | Проверить |

Пока статус «Проверить», сборка годится только для прототипа и тестов, не для выпуска.

## Уведомление Tanzil

Tanzil требует воспроизводить это уведомление во всех файлах, полученных из текста. Оно хранится дословно в `content_version.textNotice` каждой сборки; копия ниже:

```
#  Tanzil Quran Text (Uthmani, Version 1.1)
#  Copyright (C) 2007-2026 Tanzil Project
#  License: Creative Commons Attribution 3.0
#
#  This copy of the Quran text is carefully produced, highly 
#  verified and continuously monitored by a group of specialists 
#  at Tanzil Project.
#
#  TERMS OF USE:
#
#  - Permission is granted to copy and distribute verbatim copies 
#    of this text, but CHANGING IT IS NOT ALLOWED.
#
#  - This Quran text can be used in any website or application, 
#    provided that its source (Tanzil Project) is clearly indicated, 
#    and a link is made to tanzil.net to enable users to keep
#    track of changes.
#
#  - This copyright notice shall be included in all verbatim copies 
#    of the text, and shall be reproduced appropriately in all files 
#    derived from or containing substantial portion of this text.
#
#  Please check updates at: http://tanzil.net/updates/
```
