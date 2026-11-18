# 12. Форматы данных и параметры

Точные схемы, по которым пишется код. Изменения схем — через запись решения (раздел 7.3).

## 12.1 База пользователя (drift, SQLite)

Время — в миллисекундах от 1970 года (UTC). Идентификаторы — UUID v4 строкой. `word_index` — сквозной номер слова в Коране из базы содержания.

| Таблица | Поля | Ключи и индексы |
|---|---|---|
| `profile` | `id`, `created_at`, `ui_language` (ru/kk/uz), `path` (read/hifz/restore), `daily_minutes`, `behavior` (gentle/strict), `show_first_word` (bool) | PK `id`; в V1 одна запись |
| `unit` | `id`, `profile_id`, `kind` (passage/junction/hardSpot/skill), `from_word_index`, `to_word_index`, `skill_id`, `surah`, `origin` (default/knownBefore/error/lesson), `parent_unit_id`, `created_at` | PK `id`; индекс `(profile_id, kind)` |
| `unit_state` | `unit_id`, `queue` (notStarted/learning/recent/old/closed), `memory_state`, `fsrs_card` (JSON пакета `fsrs`), `due_at`, `recent_since`, `last_attempt_at`, `last_method` (voice/self/listener), `updated_at` | PK `unit_id`; индекс `due_at` |
| `attempt` | `id`, `unit_id`, `session_id`, `mode` (supported/recall/test/self), `outcome` (clean/withHints/corrected/withErrors/unverified/disputed), `hints` (JSON: вид → число), `error_event_ids` (JSON), `rating` (again/hard/good/easy/null), `method`, `duration_ms`, `words`, `model_id`, `model_version`, `rules_version`, `text_version`, `created_at` | PK `id`; индекс `(unit_id, created_at)` |
| `check_event` | `id`, `session_id`, `kind`, `state`, `word_indexes` (JSON), `expected_text`, `heard_text`, `jump_from_word_index`, `jump_to_word_index`, `audio_start_ms`, `audio_end_ms`, `versions` (JSON), `created_at`, `updated_at` | PK `id`; индекс `session_id` |
| `session` | `id`, `profile_id`, `from_word_index`, `to_word_index`, `mode`, `behavior`, `started_at`, `ended_at`, `listening_ms`, `signal_ok_ratio`, `summary` (JSON) | PK `id` |
| `daily_plan` | `date` (ГГГГ-ММ-ДД), `items` (JSON), `created_at` | PK `date`; план дня не меняется при каждом открытии |
| `lesson_progress` | `lesson_id`, `state`, `step_index`, `quiz_percent`, `content_version`, `updated_at` | PK `lesson_id` |
| `setting` | `key`, `value` (JSON) | PK `key` |
| `download` | `package_id`, `kind`, `active_version`, `pending_version`, `state`, `bytes_total`, `bytes_done`, `updated_at` | PK `package_id` |
| `search_key_cache` | `normalizer_id`, `word_index`, `key` | PK `(normalizer_id, word_index)` |
| `ngram_cache` | `normalizer_id`, `ngram`, `word_indexes` (список) | PK `(normalizer_id, ngram)` |
| `saved_recording` | `id`, `session_id`, `path`, `duration_ms`, `created_at` | PK `id` |
| `upload_queue` | `id`, `session_id`, `file_path`, `meta` (JSON, 12.5), `priority`, `bytes`, `state`, `tries`, `created_at` | PK `id`; индекс `(state, priority)` |
| `entitlement_cache` | `id` ('premium'), `state`, `expires_at`, `last_verified_at` | PK `id` |
| `free_usage` | `date`, `listening_ms` | PK `date` |
| `outbox` | `id`, `event` (JSON), `created_at` | V2; создаётся пустой |

## 12.2 База содержания (только чтение)

Текст и разметка страниц хранятся раздельно, как пакеты `text` и `layout` (4.9; ADR 0004). Текст есть для всего Корана; разметка — только для страниц, на которые есть права (ADR 0002). Пустых полей «страница неизвестна» нет: у слова либо есть строка в `word_layout`, либо нет.

**Текст** — весь Коран:

| Таблица | Поля |
|---|---|
| `surah` | `number`, `name_ar`, `name_ru`, `name_kk`, `name_uz`, `ayah_count`, `revelation` (makkah/madinah) |
| `ayah` | `surah`, `ayah`, `first_word_index`, `word_count`, `juz`, `hizb`, `sajda` (bool); `juz`, `hizb`, `sajda` пусты, пока нет источника |
| `word` | `word_index`, `surah`, `ayah`, `position`, `text_uthmani` (канон) |

**Разметка** — только страницы с правами; `layout_id` позволяет заменить разметку или добавить другой мусхаф, не трогая текст:

| Таблица | Поля |
|---|---|
| `word_layout` | `layout_id`, `word_index`, `page`, `line`, `line_position`, `glyph_code` |
| `ayah_layout` | `layout_id`, `surah`, `ayah`, `page`, `end_page`, `end_line`, `end_line_position`, `end_glyph_code` — место и знак конца аята (ADR 0002) |
| `page` | `layout_id`, `number`, `first_word_index`, `last_word_index` |
| `line` | `layout_id`, `page`, `line`, `kind` (ayah/surahName/basmala), `first_word_index`, `last_word_index`, `centered`, номер суры для строк заголовка (ADR 0002) |

**Прочее:**

| Таблица | Поля |
|---|---|
| `passage_default` | `id`, `from_word_index`, `to_word_index` |
| `similar_pair` | `id`, `a_from`, `a_to`, `b_from`, `b_to`, `verified` |
| `tajweed_mark` | `word_index`, `char_offset`, `rule` |
| `content_version` | `key`, `value`: версия, источник текста, лицензия, контрольная сумма канона |

Ключи для поиска не хранятся здесь: они зависят от нормализатора модели и строятся в базе пользователя (10.1).

## 12.3 Пакеты

### Манифест

```json
{
  "manifestVersion": 1,
  "issuedAt": "2026-12-01T00:00:00Z",
  "packages": [
    {
      "id": "model-quran-asr-small",
      "kind": "model",
      "version": "1.0.0",
      "url": "https://cdn.example/models/quran-asr-small-1.0.0.zip",
      "size": 37748736,
      "sha256": "…",
      "license": "MIT",
      "minAppVersion": "1.0.0",
      "dependsOn": []
    }
  ],
  "signature": { "keyId": "main-2026", "ed25519": "…" }
}
```

Подписывается JSON без поля `signature`, в каноническом виде (ключи по алфавиту, без пробелов).

### Пакет модели

| Файл | Что внутри |
|---|---|
| `model.json` | `modelId`, `version`, `output` (uthmaniLettersNoDiacritics/phonemes), `isStreaming`, `hasTokenTimes`, `sampleRate` (16000), `minRamMb`, `license`, `normalizerId` |
| `model.int8.onnx`, `tokens.txt` | Модель для sherpa-onnx |
| `normalizer.json` | `id`, `removeRanges` (диапазоны Unicode), `replace` — таблица замен: **список** объектов `{"from": "…", "to": "…"}`, применяется строго по порядку (не объект: в объекте порядок замен не задан), `wordSeparator` |
| `thresholds.json` | Пороги следования и проверки, откалиброванные для этой модели (12.4, группы «Следование» и «Проверка») |
| `eval.json` | Результаты модели на наборе записей: показатели раздела 5.3 по группам |

### Пакет параметров (`config`)

JSON с параметрами из 12.4, кроме порогов модели. Подписан так же, как манифест.

### Пакет уроков

Схема — раздел 4.9 и 11.2. Один пакет — один этап курса.

## 12.4 Все параметры

Значения — начальные [Г]. Пороги следования и проверки приходят с моделью; остальные — в пакете `config`; в приложении есть встроенные значения по умолчанию.

### Звук

| Параметр | По умолчанию | Где |
|---|---|---|
| `ringBufferSec` | 30 | 10.2 |
| `preRollMs`, `postRollMs` | 300, 300 | 10.2 |
| `segmentEndPauseMs` | 700 | 10.2 |
| `maxSegmentMs` | 15 000 | 10.2 |
| `reviewSnippetPadMs` | 3000 | ЗВ-02 |
| `quietDbfs`, `noisyDbfs` | −42, −35 | 10.2 |
| `clippingRatio` | 0,01 | 10.2 |
| `signalHoldMs` | 3000 | 10.2 |

### Распознавание

| Параметр | По умолчанию | Где |
|---|---|---|
| `asrThreads` | 2 | 10.3 |
| `partialIntervalMs` | 500 | 10.3 |
| `maxPartialWindowMs` | 8000 | 10.3 |
| `deviceTestSmallMax` | 0,3 | 10.3 |
| `deviceTestTinyMax` | 0,6 | 10.3 |

### Следование (в `thresholds.json`)

| Параметр | По умолчанию |
|---|---|
| `beamSize` | 5 |
| `maxSkip` | 4 |
| `maxBack` | 8 |
| `costSkip`, `costBack`, `costInsert` | 1,0; 0,3; 1,0 |
| `simFloor` | 0,4 |
| `openThreshold` | 0,70 |
| `lostCostThreshold` | 0,6 |
| `ambiguityMargin` | 0,15 |
| `ngramSize` | 3 |
| `stableConfirmations` | 2 |
| `openDelayWords` | 2 — сколько устойчивых слов ждать перед открытием, если пути гипотез расходятся (10.4; ADR 0002) |
| `lostWindowWords` | 4 — по скольким последним словам считать среднюю стоимость для потери позиции (10.4; ADR 0002) |

### Проверка (в `thresholds.json`)

| Параметр | По умолчанию |
|---|---|
| `strongMatch` | 0,85 |
| `substitutionMax` | 0,60 |
| `confirmContextWords` | 2 |
| `jumpMinWords` | 3 |
| `selfCorrectionMs`, `selfCorrectionWords` | 2500, 2 |
| `hesitationPauseMs`, `hesitationTempoFactor` | 2500, 3 |
| `strictMaxFails`, `strictMaxWaitMs` | 3, 15 000 |
| `stuckWordTries` | 3 |

### План

| Параметр | По умолчанию |
|---|---|
| `newShare`, `recentShare`, `oldShare` | 0,2; 0,3; 0,5 |
| `hardSpotMaxShare` | 0,25 |
| `recentDays` | 30 |
| `recentLadderDays` | [1, 2, 4, 7] |
| `desiredRetention` | 0,9 |
| `breakDays` | 7 |
| `diagnosticSize` | 3–5 |
| `afterBreakNewFactor`, `afterBreakDays` | 0,5; 7 |
| `defaultSecondsPerWord` | 1,0 |
| `speedWindow` | 10 попыток |
| `debtLimitFactor` | 1,0 × бюджет |
| `passageMaxAyahs` | 5 |
| Множители шагов | 1,3; 3,0; 8,0 (11.1) |
| `learnListenRepeats`, `learnSupportedRepeats` | 3, 2 |

### Прочее

| Параметр | По умолчанию | Где |
|---|---|---|
| `quizPassPercent` | 80 | УЧ-04 |
| `skillReviewQuestions` | 3 | 11.2 (повторение навыка) |
| `listenRepeatPauseFactor` | 1,2 | АУ-06 |
| `freeVoiceMinutesPerDay` | 10 | 11.6 |
| `trialDays` | 7 | 11.6 |
| `offlineGraceDays` | 14 | 11.6 |
| `uploadQueueMaxMb` | 200 | 11.7 |
| `uploadWifiOnly` | true | 11.7 |
| `opusBitrateKbps` | 16 | 11.7 |
| `maxRemindersPerDay` | 2 | 11.8 |
| `pageFontWindow` | 3 | 11.3 |
| `manifestCheckHours` | 24 | 11.4 |

## 12.5 Метаданные отправляемой записи

```json
{
  "schema": 1,
  "installId": "uuid",
  "consentVersion": "2026-12",
  "recordedAt": "2026-12-05T18:20:00Z",
  "range": { "from": "78:1:1", "to": "78:5:4" },
  "mode": "recall",
  "device": { "model": "SM-A155F", "os": "Android 14" },
  "versions": { "app": "1.0.0", "model": "quran-asr-small@1.0.0", "rules": "1", "text": "1" },
  "asr": [ { "segmentId": 1, "isFinal": true, "text": "…", "startMs": 0, "endMs": 4200 } ],
  "events": [ { "kind": "substitution", "state": "disputed", "wordKey": "78:3:2", "heard": "…" } ],
  "audio": { "codec": "opus", "bitrateKbps": 16, "durationMs": 61000, "sha256": "…" }
}
```

Нет имени, телефона, геолокации и аккаунта.

## 12.6 Форматы набора записей для `tools/eval`

### Разметка записи (`<id>.ann.json`)

```json
{
  "recordingId": "p012_r03",
  "speaker": { "id": "p012", "nativeLanguage": "kk", "gender": "f", "ageGroup": "25-34" },
  "conditions": { "device": "budget-android", "noise": "quiet" },
  "expected": { "from": "78:1:1", "to": "78:10:5" },
  "words": [
    { "wordKey": "78:1:1", "status": "correct", "startMs": 410, "endMs": 900 },
    { "wordKey": "78:1:2", "status": "substituted", "heard": "…", "startMs": 950, "endMs": 1500 },
    { "wordKey": "78:2:1", "status": "omitted" },
    { "wordKey": "78:2:2", "status": "selfCorrected", "startMs": 2100, "endMs": 3300 }
  ],
  "insertions": [ { "afterWordKey": "78:3:1", "heard": "…", "startMs": 4000, "endMs": 4400 } ],
  "jumps": [],
  "annotators": ["a1", "a2"]
}
```

Статусы: `correct`, `omitted`, `substituted`, `selfCorrected`, `repeated`, `unclear`.

### Результат распознавания (`<id>.<model>.asr.jsonl`)

Одна строка — один `RecognitionResult` (раздел 4.4), полученный прогоном записи через модель в реальном темпе с теми же параметрами, что на телефоне. Так следование и проверку можно гонять на компьютере без модели и без звука, одинаково при каждом запуске.

### Отчёт

- Показатели раздела 5.3 в целом, по типам ошибок и по группам; доверительные интервалы бутстрепом по людям.
- Сравнение с прошлым отчётом: разница в процентных пунктах.
- Итог: прошло / не прошло пороги; выбранный режим выпуска (А–Г).
