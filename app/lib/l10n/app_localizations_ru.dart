// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Sudur';

  @override
  String get today => 'Сегодня';

  @override
  String get mushaf => 'Мусхаф';

  @override
  String get learnToRead => 'Учусь читать';

  @override
  String get progress => 'Прогресс';

  @override
  String get more => 'Ещё';

  @override
  String get sectionComingSoon => 'Этот раздел готовится';

  @override
  String get prototypeTitle => 'Прототип суры 78';

  @override
  String get prototypePreparing =>
      'Готовим проверенную модель, страницы мусхафа и шрифты';

  @override
  String prototypeDownloadProgress(String resource, int percent) {
    return 'Загружается $resource: $percent%';
  }

  @override
  String get prototypeRetry => 'Повторить';

  @override
  String get prototypeError =>
      'Не удалось подготовить прототип. Проверьте интернет и повторите.';

  @override
  String get prototypeModelSmall => 'Модель small';

  @override
  String get prototypeModelTiny => 'Модель tiny';

  @override
  String get prototypePhoneTest => 'Тест телефона';

  @override
  String get prototypePhoneTesting => 'Идёт тест…';

  @override
  String prototypePhoneResult(String ratio, int decodeMs) {
    return 'Скорость: $ratio; распознавание: $decodeMs мс';
  }

  @override
  String get prototypeChooseWav => 'Выбрать WAV';

  @override
  String get prototypeUseMicrophone => 'Использовать микрофон';

  @override
  String prototypeWavSelected(String fileName) {
    return 'Источник замера: $fileName';
  }

  @override
  String get prototypeStart => 'Начать';

  @override
  String get prototypePause => 'Пауза';

  @override
  String get prototypeResume => 'Продолжить';

  @override
  String get prototypeStop => 'Завершить';

  @override
  String get prototypeHint => 'Подсказка';

  @override
  String get prototypeShareLog => 'Поделиться журналом';

  @override
  String get prototypeMockNotice =>
      'Звук обрабатывается только на телефоне и не сохраняется. После нажатия «Начать» Android запросит доступ к микрофону.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return 'Сура $surah, аят $ayah. $text';
  }
}
