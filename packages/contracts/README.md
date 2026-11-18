# contracts

Общие неизменяемые модели, события и интерфейсы между модулями. Менять только через запись решения и согласие владельца.

- **Владелец:** Астра
- **Задача:** —
- **ТЗ:** 4.4, 4.5

Правила: [`AGENTS.md`](../../AGENTS.md). Публичный интерфейс — только `lib/contracts.dart`; внутренности — в `lib/src/`.

## Что внутри

| Файл | Что | ТЗ |
|---|---|---|
| `word_key.dart` | `WordKey` — `сура:аят:слово` | 4.5 |
| `result.dart` | `Result` (`Ok` / `Error`) | 17.2 |
| `recognition.dart` | `SpeechRecognizer`, `RecognitionResult`, `RecognizerInfo` | 4.4 |
| `session_events.dart` | события сессии: `PositionUpdate`, `WordRevealed`, `PositionLost`, `CheckEvent` (с версиями), `SignalQuality` | 4.5 |
| `session_commands.dart` | команды экрана, режимы, поведение и виды подсказок | 4.5, 10.6; ADR 0005 |
| `session_audio.dart` | интерфейс аудиоисточника, открытие/кадры/закрытие отрезка | 4.3, 4.6; ADR 0005 |
| `alignment.dart` | путь выравнивания: `HeardWord`, `AlignmentStep`, `JumpCandidate` — выдаёт `follow`, принимает `check` | 10.4, 10.5; ADR 0003 |
| `search_key.dart` | `SearchKey` — технический ключ слова, не текст для показа | 10.1; ADR 0003 |
| `versions.dart` | `ReadingVersions` — версии модели, правил и текста | ПО-11; ADR 0003 |
