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
}
