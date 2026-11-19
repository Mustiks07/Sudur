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
| `fixtures/manifest/` | Тестовый подписанный манифест, тестовый пакет и тестовые ключи Ed25519 (`TEST-ONLY`) для `content` и `content_build`; см. [`fixtures/README.md`](fixtures/README.md) | O05 |
| `modelLetters`, `isModelOutput`, `FakeSpeechRecognizer.modelOutput`, `RecognitionScript(modelOutput: true)`, `SyntheticRecording(modelOutput: true)` | Распознанный текст **как выдаёт модель** (29 голых букв, ТЗ 12.3) и проверка, что поддельный распознаватель подаёт только такой текст. Канонический ключ с огласовками — `ArgumentError`. Подавайте тестам следования и проверки вывод модели, а не ключи | вывод модели |
| `fixtures/models/normalizer.abdou.json` | `normalizer.json` моделей `Abdou/quran-asr` строго по ТЗ 12.3 (коды символов, без набора букв) | вывод модели |
| `FakeSpeechRecognizer` | `SpeechRecognizer`, который проигрывает заранее подготовленные результаты (СЛ-07, ПО-12) | P06 |
| `FakeSessionAudioSource` | управляемый из теста источник открытий, кадров, закрытий и качества сигнала | S05 |
| `RecognitionScript` | Строит последовательность результатов как у распознавателя (ТЗ 10.3): растущие частичные, окончательный, заданные частичные, скользящее окно, паузы | P06 |
| `dropLetter`, `swapLetters` | Искажения букв для наборов результатов | P06 |

Наборы результатов строятся из канона (пропуски, повторы, искажения), а не из набранного вручную арабского текста; распознанный текст — в виде вывода модели (`modelLetters`), иначе нормализатор, не совпадающий с моделью, тесты не заметят (так было до 19.11.2026).
