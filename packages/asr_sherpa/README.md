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
SUDUR_ASR_EVAL_DIR=/path/to/reviewed-eval \
  packages/asr_sherpa/tool/download_models.sh all
```

Скрипт скачивает закреплённые ревизии `Abdou/quran-asr-small` и
`Abdou/quran-asr-tiny` в игнорируемый `third_party_cache/asr_sherpa/`,
проверяемый пакет содержит `model.json`, `model.int8.onnx`, `tokens.txt`,
`normalizer.json`, `thresholds.json`, `eval.json` и лицензию MIT. Проверенные
отчёты подаются как `small.json` и `tiny.json` через `SUDUR_ASR_EVAL_DIR`,
чтобы скрипт не выдумывал показатели модели. Модели и отчёты в git не
добавляются. Таблица `replace` записывается упорядоченным списком объектов.

Установку и атомарное переключение версии выполняет пакет `content`. ASR
получает активный каталог только через `AsrModelPackageSource`; прямой
download/activation из распознавателя невозможен. `AsrDeviceModelSelector`
прогоняет встроенный 10-секундный образец, выбирает small/tiny/самопроверку и
при явном повторе запускает измерения заново.

Тест скорости декодирует 10 секунд детерминированного ненулевого шума с
фиксированным seed. Падение worker-isolate переводит распознаватель в
терминальное состояние `workerStopped`: ожидающие и новые запросы завершаются
явной ошибкой.

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
