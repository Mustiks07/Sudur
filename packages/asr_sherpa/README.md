# asr_sherpa

Распознаватель Zipformer CTC на sherpa-onnx. Модель загружается и работает
в долгоживущем изоляте; основной изолят только передаёт аудиобуферы и получает
нумерованные результаты. Распознанный текст возвращается без исправлений.

- **Владелец:** GPT-B
- **Задача:** [P04](../../docs/tasks/P04-asr-sherpa.md)
- **ТЗ:** 2.6, 10.3, 12.3

Правила: [`AGENTS.md`](../../AGENTS.md). Публичный интерфейс — только `lib/asr_sherpa.dart`; внутренности — в `lib/src/`.

## Модели

```sh
packages/asr_sherpa/tool/download_models.sh all
```

Скрипт скачивает закреплённые ревизии `Abdou/quran-asr-small` и
`Abdou/quran-asr-tiny` в игнорируемый `third_party_cache/asr_sherpa/`,
проверяемый пакет содержит `model.json`, `model.int8.onnx`, `tokens.txt`,
`normalizer.json`, `thresholds.json` и лицензию MIT. Модели в git не
добавляются.

## WAV → JSONL

```sh
dart run packages/asr_sherpa/bin/asr_sherpa.dart \
  third_party_cache/asr_sherpa/quran-asr-tiny input.wav output.asr.jsonl
```

PCM16 WAV читается в память и подаётся 20-мс блоками в реальном темпе.
JSONL содержит частичные и окончательный `RecognitionResult`; аудио не
записывается.

## Зависимости

- `sherpa_onnx 2.0.1` (Apache-2.0) — официальный FFI API OfflineRecognizer
  и Zipformer CTC.
- `crypto 3.0.6` (BSD-3-Clause) — проверка SHA-256 модели и токенов перед
  загрузкой.

Интеграционный тест с настоящей моделью включается переменной
`SUDUR_ASR_MODEL_DIR`; без неё тест явно пропускается.
