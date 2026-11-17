# 0003. Договоры: путь выравнивания, версии, качество сигнала

- Статус: принято
- Дата: 16.11.2026
- Кто принял: владелец (по предложению Opus в запросах на слияние №3 и №5)

## Контекст

Три вопроса всплыли при работе над `follow` (P06) и `check` (S04).

1. **Путь выравнивания.** `follow` выдаёт путь выравнивания, `check` по нему ищет ошибки (ТЗ 10.4, 10.5). Типы пути (`HeardWord`, `AlignmentStep`, `JumpCandidate`) лежали в `follow`. По правилу зависимостей (`AGENTS.md`) доменный пакет может зависеть только от `contracts` и `quran_text`. Поэтому в `check` пришлось завести копии этих типов (`PathWord`, `PathStep`, `JumpInput`), и сессии нужно было бы перекладывать данные из одних в другие поле в поле.
2. **Версии (ПО-11).** Каждое событие проверки должно хранить версии модели, правил и текста; в ТЗ 4.5 они есть в `CheckEvent`, а в `contracts` поля не было. `check` отдавал версии рядом с событием (`CheckOutput`).
3. **Качество сигнала.** В ТЗ 4.5 есть событие `SignalQuality`, а в `contracts` — нет. `audio_capture` (ветка GPT-B `gpt-b/p05-audio-capture`) описал своё: `SignalQualityLevel { ok, tooQuiet, clipping, noisy }` и `SignalQualityChanged(atMs, level, dbfs, clippedRatio)` — отправляется при смене уровня. `check` принимал плохой сигнал в собственном виде (`UnreliableSpan`).

## Решение

В `packages/contracts`:

| Что | Где | Поля |
|---|---|---|
| `HeardWord`, `AlignmentStepKind`, `AlignmentStep`, `JumpCandidate` | `alignment.dart` | как были в `follow`, без изменений |
| `SearchKey` | `search_key.dart` | перенесён из `quran_text`: его несёт `HeardWord`; `quran_text` переэкспортирует его, его пользователи ничего не меняют |
| `ReadingVersions` | `versions.dart` | `modelId`, `modelVersion`, `rulesVersion`, `textVersion`; `toJson()` — вид `check_event.versions` (ТЗ 12.1) |
| `CheckEvent.versions` | `session_events.dart` | новое обязательное поле `ReadingVersions` |
| `SignalQualityLevel`, `SignalQuality` | `session_events.dart` | `SignalQuality extends SessionEvent`: `sessionId`, `atMs`, `level`; необязательные `sinceMs`, `dbfs`, `clippedRatio` |

- `follow` выдаёт типы пути из `contracts`; `FollowUpdate` остаётся в `follow`.
- `check` принимает `AlignmentStep` и `JumpCandidate` из `contracts`, свои копии удалены. События выходят как `CheckEvent` с версиями (`CheckOutput` и `CheckVersions` удалены).
- `check.onSignalQuality(SignalQuality)`: от уровня не `ok` до следующего `ok` звук ненадёжен, кандидаты там становятся `unverified` (ТЗ 10.5). `deviceTooSlow` по-прежнему передаётся через `markUnreliable`.

**Как выбран вид `SignalQuality`.** Имена уровней — те же, что у GPT-B и в ТЗ 4.5, поэтому `audio_capture` переходит на общий тип без переименований. Событие приходит при смене уровня, как у GPT-B. `dbfs` и `clippedRatio` GPT-B уже считает; они необязательны, чтобы событие можно было создать и без них (например, в тестах). Новое — `sinceMs`: уровень `tooQuiet` или `noisy` определяется после удержания (`signalHoldMs` = 3 с), значит плохой звук начался раньше `atMs`. Если `audio_capture` укажет начало измеренного отрезка, `check` не подтвердит ошибку на этих 3 секундах. Без `sinceMs` `check` считает от `atMs`.

## Рассмотренные варианты

- **Оставить копии типов в `check`.** Отвергнуто: две одинаковые модели и перекладывание в сессии — лишний код и место для ошибок.
- **Разрешить `check` зависеть от `follow`.** Отвергнуто: нарушает правило зависимостей и связывает проверку с одной реализацией следования.
- **`HeardWord.key` как `String`.** Отвергнуто: ключ потерял бы защиту типом и мог бы попасть на экран как текст Корана (ТЗ 10.1).
- **`versions` необязательным полем.** Отвергнуто: ПО-11 требует версии в каждом событии.

## Последствия

- `contracts` меняется несовместимо:
  - `CheckEvent` без `versions` не собирается;
  - у запечатанного `SessionEvent` появился новый подтип `SignalQuality`: исчерпывающие `switch` по `SessionEvent` должны его учесть.
  
  В слитом коде таких мест нет.
- **GPT-B:** перевести `audio_capture` на `SignalQualityLevel` и `SignalQuality` из `contracts` (по возможности с `sinceMs`). `audio_capture` в этом изменении не трогается.
- **Opus:** подключение `check` к `tools/eval` (M01) — после слияния №4 и №5. Если №4 будет слит раньше этого изменения, тесты `tools/eval`, где создаётся `CheckEvent`, получат поле `versions` в этом же запросе.
- ТЗ 4.5 уже описывает версии в `CheckEvent` и событие `SignalQuality`; путь выравнивания — внутренний договор `follow` → `check`, в 4.5 его не вносим.

## Когда пересмотреть

Если появится второй потребитель пути выравнивания (например, разбор после чтения) с другими требованиями к полям или если `audio_capture` не сможет давать `sinceMs`.
