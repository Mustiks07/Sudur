# testing

Общие подделки (fakes) и тестовые данные для всех пакетов.

- **Владелец:** Астра (пополняют все)
- **Задача:** —
- **ТЗ:** 17.6

Правила: [`AGENTS.md`](../../AGENTS.md). Публичный интерфейс — только `lib/testing.dart`; внутренности — в `lib/src/`.

## Что есть

| Что | Зачем | Добавлено |
|---|---|---|
| `fixtures/quran_text.json` | Текст всего Корана из Tanzil без изменений (ADR 0004); см. [`fixtures/README.md`](fixtures/README.md) | S03 |
| `fixtures/content_p582_583.json` | Данные страниц 582–583 (сура 78, 79:1–15) из `tools/content_build`; см. [`fixtures/README.md`](fixtures/README.md) | P03 |
| `fixtures/lessons_test_stage1.json` | Тестовый пакет уроков: по примеру каждого типа шага (УЧ-03). Только заглушки `TODO_CONTENT`, без настоящего содержания; см. [`fixtures/README.md`](fixtures/README.md) | K01 |
| `fixtures/derived.json` | Отрывки по умолчанию и похожие места из текста Tanzil (D01) | D01 |
| `fixtures/manifest/` | Тестовый подписанный манифест, тестовый пакет и тестовые ключи Ed25519 (`TEST-ONLY`) для `content` и `content_build`; см. [`fixtures/README.md`](fixtures/README.md) | O05 |
| `FakeSpeechRecognizer` | `SpeechRecognizer`, который проигрывает заранее подготовленные результаты (СЛ-07, ПО-12) | P06 |
| `FakeSessionAudioSource` | управляемый из теста источник открытий, кадров, закрытий и качества сигнала | S05 |
| `RecognitionScript` | Строит последовательность результатов как у распознавателя (ТЗ 10.3): растущие частичные, окончательный, заданные частичные, скользящее окно, паузы | P06 |
| `dropLetter`, `swapLetters` | Искажения букв для наборов результатов | P06 |

Наборы результатов строятся из канона (ключи слов, пропуски, повторы, искажения), а не из набранного вручную арабского текста.
