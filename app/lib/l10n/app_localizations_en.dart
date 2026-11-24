// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sudur';

  @override
  String get today => 'Today';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get learnToRead => 'Learn to read';

  @override
  String get progress => 'Progress';

  @override
  String get more => 'More';

  @override
  String get sectionComingSoon => 'This section is being prepared';

  @override
  String get prototypeTitle => 'Surah 78 prototype';

  @override
  String get prototypePreparing =>
      'Preparing the verified model, Mushaf pages, and fonts';

  @override
  String prototypeDownloadProgress(String resource, int percent) {
    return 'Downloading $resource: $percent%';
  }

  @override
  String get prototypeRetry => 'Try again';

  @override
  String get prototypeError =>
      'The prototype could not be prepared. Check the connection and try again.';

  @override
  String get prototypeModelSmall => 'Small model';

  @override
  String get prototypeModelTiny => 'Tiny model';

  @override
  String get prototypePhoneTest => 'Phone test';

  @override
  String get prototypePhoneTesting => 'Testing…';

  @override
  String prototypePhoneResult(String ratio, int decodeMs) {
    return 'Speed ratio: $ratio; decode: $decodeMs ms';
  }

  @override
  String get prototypeChooseWav => 'Choose WAV';

  @override
  String get prototypeUseMicrophone => 'Use microphone';

  @override
  String prototypeWavSelected(String fileName) {
    return 'Measurement input: $fileName';
  }

  @override
  String get prototypeStart => 'Start';

  @override
  String get prototypePause => 'Pause';

  @override
  String get prototypeResume => 'Resume';

  @override
  String get prototypeStop => 'Stop';

  @override
  String get prototypeHint => 'Hint';

  @override
  String get prototypeShareLog => 'Share log';

  @override
  String get prototypeFinishReadingFirst => 'Finish reading first';

  @override
  String get prototypeMockNotice =>
      'Audio is processed only on this phone and is not saved. Android will request microphone access after you tap Start.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return 'Surah $surah, ayah $ayah. $text';
  }

  @override
  String get retry => '[Нужен перевод]';

  @override
  String get loadError => '[Нужен перевод]';

  @override
  String get networkError => '[Нужен перевод]';

  @override
  String get startTitle => '[Нужен перевод]';

  @override
  String get chooseLanguage => '[Нужен перевод]';

  @override
  String get languageRussian => '[Нужен перевод]';

  @override
  String get languageKazakh => '[Нужен перевод]';

  @override
  String get languageUzbek => '[Нужен перевод]';

  @override
  String get languageEnglish => '[Нужен перевод]';

  @override
  String get choosePath => '[Нужен перевод]';

  @override
  String get pathLearnReading => '[Нужен перевод]';

  @override
  String get pathMemorize => '[Нужен перевод]';

  @override
  String get pathRestore => '[Нужен перевод]';

  @override
  String get chooseFamiliarSurahs => '[Нужен перевод]';

  @override
  String get searchSurah => '[Нужен перевод]';

  @override
  String surahNumber(Object number) {
    return '[Нужен перевод] $number';
  }

  @override
  String get skip => '[Нужен перевод]';

  @override
  String get continueAction => '[Нужен перевод]';

  @override
  String get chooseDailyTime => '[Нужен перевод]';

  @override
  String minutesCount(Object count) {
    return '[Нужен перевод] $count';
  }

  @override
  String get customTime => '[Нужен перевод]';

  @override
  String get minutes => '[Нужен перевод]';

  @override
  String get cancel => '[Нужен перевод]';

  @override
  String get modelTitle => '[Нужен перевод]';

  @override
  String get downloadModel => '[Нужен перевод]';

  @override
  String get downloadLater => '[Нужен перевод]';

  @override
  String get modelDownloading => '[Нужен перевод]';

  @override
  String get chooseStartPoint => '[Нужен перевод]';

  @override
  String get startFirstSurah => '[Нужен перевод]';

  @override
  String get startShortSurahs => '[Нужен перевод]';

  @override
  String get knowLetters => '[Нужен перевод]';

  @override
  String get lettersNo => '[Нужен перевод]';

  @override
  String get lettersALittle => '[Нужен перевод]';

  @override
  String todayAroundMinutes(Object minutes) {
    return '[Нужен перевод] $minutes';
  }

  @override
  String get todayFirstDay => '[Нужен перевод]';

  @override
  String get todayNormal => '[Нужен перевод]';

  @override
  String get todayReturning => '[Нужен перевод]';

  @override
  String get todayCompleted => '[Нужен перевод]';

  @override
  String get todayFreeLimit => '[Нужен перевод]';

  @override
  String get todayModelMissing => '[Нужен перевод]';

  @override
  String get stepDiagnostic => '[Нужен перевод]';

  @override
  String get stepPassage => '[Нужен перевод]';

  @override
  String stepSurah(Object number) {
    return '[Нужен перевод] $number';
  }

  @override
  String get stepHardSpot => '[Нужен перевод]';

  @override
  String get stepLesson => '[Нужен перевод]';

  @override
  String get stepSkill => '[Нужен перевод]';

  @override
  String get reasonReturnDiagnosis => '[Нужен перевод]';

  @override
  String get reasonYesterdayNew => '[Нужен перевод]';

  @override
  String get reasonYesterdayError => '[Нужен перевод]';

  @override
  String get reasonRecentDue => '[Нужен перевод]';

  @override
  String get reasonLongUnchecked => '[Нужен перевод]';

  @override
  String get reasonNewMaterial => '[Нужен перевод]';

  @override
  String get reasonCourseLesson => '[Нужен перевод]';

  @override
  String get reasonSkillDue => '[Нужен перевод]';

  @override
  String get reasonUserAdded => '[Нужен перевод]';

  @override
  String get selfCheck => '[Нужен перевод]';

  @override
  String get startAction => '[Нужен перевод]';

  @override
  String get skipTodayTitle => '[Нужен перевод]';

  @override
  String get skipTodayBody => '[Нужен перевод]';

  @override
  String get skipToday => '[Нужен перевод]';

  @override
  String get dayDone => '[Нужен перевод]';

  @override
  String get reviewMore => '[Нужен перевод]';

  @override
  String get activities => '[Нужен перевод]';

  @override
  String get language => '[Нужен перевод]';

  @override
  String get downloads => '[Нужен перевод]';

  @override
  String get myData => '[Нужен перевод]';

  @override
  String get subscription => '[Нужен перевод]';

  @override
  String get reminders => '[Нужен перевод]';

  @override
  String get improveChecking => '[Нужен перевод]';

  @override
  String get reportProblem => '[Нужен перевод]';

  @override
  String get comingSoon => '[Нужен перевод]';

  @override
  String get aboutApp => '[Нужен перевод]';

  @override
  String get sourcesLicenses => '[Нужен перевод]';

  @override
  String get dailyTime => '[Нужен перевод]';

  @override
  String get strictMode => '[Нужен перевод]';

  @override
  String get showFirstWord => '[Нужен перевод]';

  @override
  String get memorizationRepeats => '[Нужен перевод]';

  @override
  String get save => '[Нужен перевод]';

  @override
  String get noModels => '[Нужен перевод]';

  @override
  String get speechModel => '[Нужен перевод]';

  @override
  String megabytes(Object value) {
    return '[Нужен перевод] $value';
  }

  @override
  String get deleteAction => '[Нужен перевод]';

  @override
  String get close => '[Нужен перевод]';

  @override
  String get exportData => '[Нужен перевод]';

  @override
  String get importData => '[Нужен перевод]';

  @override
  String get deleteAllData => '[Нужен перевод]';

  @override
  String get deleteAllDataWarning => '[Нужен перевод]';

  @override
  String get back => 'Back';

  @override
  String get readingDone => 'Done';

  @override
  String get readingRangeUnavailable =>
      'This passage cannot be opened yet: the prototype has only pages 582–583. Reading the whole Quran comes in the next version.';

  @override
  String get stepComingSoon =>
      'This step comes in the next version of the app.';

  @override
  String todaySummary(int count) {
    return 'Steps done: $count';
  }
}
