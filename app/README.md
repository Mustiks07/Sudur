# Sudur app

Flutter-приложение Sudur. Архитектура следует официальному руководству Flutter:
экраны и `ChangeNotifier`-модели находятся в `lib/ui`, хранилища — в
`lib/data/repositories`, навигация — в `lib/routing`, сборка зависимостей — в
`lib/config`.

## Варианты сборки

- `lib/main_dev.dart` — разработка;
- `lib/main_beta.dart` — закрытое тестирование;
- `lib/main_prod.dart` — магазины.

## Запуск и проверка

```sh
fvm flutter run --target lib/main_dev.dart
fvm flutter test
```
