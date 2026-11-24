// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'Sudur';

  @override
  String get today => 'Бүгін';

  @override
  String get mushaf => 'Мусхаф';

  @override
  String get learnToRead => 'Оқуды үйренемін';

  @override
  String get progress => 'Ілгерілеу';

  @override
  String get more => 'Тағы';

  @override
  String get sectionComingSoon => 'Бұл бөлім әзірленіп жатыр';

  @override
  String get prototypeTitle => '78-сүре прототипі';

  @override
  String get prototypePreparing =>
      'Тексерілген модель, мұсхаф беттері мен қаріптер дайындалуда';

  @override
  String prototypeDownloadProgress(String resource, int percent) {
    return '$resource жүктелуде: $percent%';
  }

  @override
  String get prototypeRetry => 'Қайталау';

  @override
  String get prototypeError =>
      'Прототипті дайындау мүмкін болмады. Интернетті тексеріп, қайталаңыз.';

  @override
  String get prototypeModelSmall => 'Small моделі';

  @override
  String get prototypeModelTiny => 'Tiny моделі';

  @override
  String get prototypePhoneTest => 'Телефонды тексеру';

  @override
  String get prototypePhoneTesting => 'Тексерілуде…';

  @override
  String prototypePhoneResult(String ratio, int decodeMs) {
    return 'Жылдамдық: $ratio; тану: $decodeMs мс';
  }

  @override
  String get prototypeChooseWav => 'WAV таңдау';

  @override
  String get prototypeUseMicrophone => 'Микрофонды пайдалану';

  @override
  String prototypeWavSelected(String fileName) {
    return 'Өлшеу көзі: $fileName';
  }

  @override
  String get prototypeStart => 'Бастау';

  @override
  String get prototypePause => 'Кідірту';

  @override
  String get prototypeResume => 'Жалғастыру';

  @override
  String get prototypeStop => 'Аяқтау';

  @override
  String get prototypeHint => 'Көмек';

  @override
  String get prototypeShareLog => 'Журналды бөлісу';

  @override
  String get prototypeFinishReadingFirst => 'Алдымен оқуды аяқтаңыз';

  @override
  String get prototypeMockNotice =>
      'Дыбыс тек телефонда өңделеді және сақталмайды. «Бастау» түймесін басқаннан кейін Android микрофонға рұқсат сұрайды.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return '$surah-сүре, $ayah-аят. $text';
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
}
