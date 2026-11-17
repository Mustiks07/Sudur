// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Sudur';

  @override
  String get today => 'Bugun';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get learnToRead => 'O‘qishni o‘rganaman';

  @override
  String get progress => 'Taraqqiyot';

  @override
  String get more => 'Yana';

  @override
  String get sectionComingSoon => 'Bu bo‘lim tayyorlanmoqda';

  @override
  String get prototypeTitle => 'Прототип · Пробую вспомнить · 78';

  @override
  String get prototypeNotice =>
      'Слова открываются по услышанному. Проверка ошибок не включена. Заголовки и басмала пока не показаны.';

  @override
  String get prototypeShare => 'Поделиться журналом';

  @override
  String get prototypeSmall => 'small';

  @override
  String get prototypeTiny => 'tiny';

  @override
  String get prototypeBenchmark => 'Тест телефона';

  @override
  String get prototypeReload => 'Загрузить файлы';

  @override
  String get prototypeFile => 'Подавать input.wav вместо микрофона';

  @override
  String get prototypeRecommendation => 'Рекомендация';

  @override
  String get prototypeSlow => 'small · частичные результаты раз в секунду';

  @override
  String get prototypeSelfCheck => 'Самопроверка без распознавания';

  @override
  String get prototypeInstall =>
      'Установите данные, модели и шрифты по docs/prototype.md';

  @override
  String get prototypeMicTitle => 'Доступ к микрофону';

  @override
  String get prototypeMicReason =>
      'Звук обрабатывается только на телефоне и не сохраняется. Разрешите микрофон, чтобы открывать слова по чтению. При отказе можно пользоваться самопроверкой.';

  @override
  String get prototypeCancel => 'Отмена';

  @override
  String get prototypeContinue => 'Продолжить';

  @override
  String get prototypeStart => 'Начать';

  @override
  String get prototypeStop => 'Завершить';

  @override
  String get prototypeFailed =>
      'Не удалось выполнить действие. Проверьте файлы и разрешение микрофона. Сессия остановлена.';

  @override
  String get prototypeLoading => 'Загрузка…';

  @override
  String get prototypeRunning => 'Слушаю';

  @override
  String get prototypeLost => 'Место потеряно: продолжите читать';

  @override
  String get prototypeStopping => 'Ожидание последних результатов…';

  @override
  String get prototypeInterrupted => 'Прервано. Начните новую сессию.';

  @override
  String get prototypeStopped => 'Сессия завершена';

  @override
  String get prototypeReady => 'Готово';
}
