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
  String get prototypeTitle => '78-sura prototipi';

  @override
  String get prototypePreparing =>
      'Tekshirilgan model, mushaf sahifalari va shriftlar tayyorlanmoqda';

  @override
  String prototypeDownloadProgress(String resource, int percent) {
    return '$resource yuklanmoqda: $percent%';
  }

  @override
  String get prototypeRetry => 'Qayta urinish';

  @override
  String get prototypeError =>
      'Prototipni tayyorlab bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get prototypeModelSmall => 'Small modeli';

  @override
  String get prototypeModelTiny => 'Tiny modeli';

  @override
  String get prototypePhoneTest => 'Telefon testi';

  @override
  String get prototypePhoneTesting => 'Sinov ketmoqda…';

  @override
  String prototypePhoneResult(String ratio, int decodeMs) {
    return 'Tezlik: $ratio; tanish: $decodeMs ms';
  }

  @override
  String get prototypeChooseWav => 'WAV tanlash';

  @override
  String get prototypeUseMicrophone => 'Mikrofondan foydalanish';

  @override
  String prototypeWavSelected(String fileName) {
    return 'O‘lchov manbasi: $fileName';
  }

  @override
  String get prototypeStart => 'Boshlash';

  @override
  String get prototypePause => 'Pauza';

  @override
  String get prototypeResume => 'Davom etish';

  @override
  String get prototypeStop => 'Tugatish';

  @override
  String get prototypeHint => 'Yordam';

  @override
  String get prototypeShareLog => 'Jurnalni ulashish';

  @override
  String get prototypeFinishReadingFirst => 'Avval o‘qishni yakunlang';

  @override
  String get prototypeMockNotice =>
      'Audio faqat telefonda qayta ishlanadi va saqlanmaydi. «Boshlash» tugmasidan keyin Android mikrofonga ruxsat so‘raydi.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return '$surah-sura, $ayah-oyat. $text';
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
  String get back => '[Нужен перевод]';

  @override
  String get readingDone => '[Нужен перевод]';

  @override
  String get readingRangeUnavailable => '[Нужен перевод]';

  @override
  String get stepComingSoon => '[Нужен перевод]';

  @override
  String todaySummary(int count) {
    return '[Нужен перевод] $count';
  }

  @override
  String get readPreparing => '[Нужен перевод]';

  @override
  String get readReady => '[Нужен перевод]';

  @override
  String get readModeSupported => '[Нужен перевод]';

  @override
  String get readModeRecall => '[Нужен перевод]';

  @override
  String get readModeTest => '[Нужен перевод]';

  @override
  String get readStart => '[Нужен перевод]';

  @override
  String get readHint => '[Нужен перевод]';

  @override
  String get readPause => '[Нужен перевод]';

  @override
  String get readResume => '[Нужен перевод]';

  @override
  String get readFinish => '[Нужен перевод]';

  @override
  String get readPaused => '[Нужен перевод]';

  @override
  String get readMicDenied => '[Нужен перевод]';

  @override
  String get readWithoutMic => '[Нужен перевод]';

  @override
  String get readModelMissing => '[Нужен перевод]';

  @override
  String get readDownload => '[Нужен перевод]';

  @override
  String get readWithoutVoice => '[Нужен перевод]';

  @override
  String get readDeviceTooSlow => '[Нужен перевод]';

  @override
  String get readFailed => '[Нужен перевод]';

  @override
  String get readUnlock => '[Нужен перевод]';

  @override
  String get readStrictAgain => '[Нужен перевод]';

  @override
  String get readOfferHint => '[Нужен перевод]';

  @override
  String get readChecksNotice => '[Нужен перевод]';

  @override
  String readTitle(int surah, int from, int to) {
    return '[Нужен перевод] $surah $from $to';
  }

  @override
  String get readShowFirstWord => '[Нужен перевод]';

  @override
  String get readStrict => '[Нужен перевод]';

  @override
  String get readTextView => '[Нужен перевод]';

  @override
  String get readSaving => '[Нужен перевод]';

  @override
  String get reviewTitle => '[Нужен перевод]';

  @override
  String get reviewClean => '[Нужен перевод]';

  @override
  String reviewIndependent(int count) {
    return '[Нужен перевод] $count';
  }

  @override
  String reviewWithHints(int count) {
    return '[Нужен перевод] $count';
  }

  @override
  String reviewErrors(int count) {
    return '[Нужен перевод] $count';
  }

  @override
  String reviewUnverified(int count) {
    return '[Нужен перевод] $count';
  }

  @override
  String get reviewFilterAll => '[Нужен перевод]';

  @override
  String get reviewFilterErrors => '[Нужен перевод]';

  @override
  String get reviewFilterCorrections => '[Нужен перевод]';

  @override
  String get reviewFilterUnverified => '[Нужен перевод]';

  @override
  String get reviewKindOmission => '[Нужен перевод]';

  @override
  String get reviewKindSubstitution => '[Нужен перевод]';

  @override
  String get reviewKindInsertion => '[Нужен перевод]';

  @override
  String get reviewKindJump => '[Нужен перевод]';

  @override
  String get reviewKindRepetition => '[Нужен перевод]';

  @override
  String get reviewKindHesitation => '[Нужен перевод]';

  @override
  String get reviewStatePreliminary => '[Нужен перевод]';

  @override
  String get reviewStateConfirmed => '[Нужен перевод]';

  @override
  String get reviewStateCorrected => '[Нужен перевод]';

  @override
  String get reviewStateUnverified => '[Нужен перевод]';

  @override
  String get reviewStateDisputed => '[Нужен перевод]';

  @override
  String get reviewListenSelf => '[Нужен перевод]';

  @override
  String get reviewListenReciter => '[Нужен перевод]';

  @override
  String get reviewDispute => '[Нужен перевод]';

  @override
  String get reviewPractice => '[Нужен перевод]';

  @override
  String get reviewNext => '[Нужен перевод]';

  @override
  String get reviewAudioSoon => '[Нужен перевод]';

  @override
  String get reviewNoEvents => '[Нужен перевод]';

  @override
  String get selfTitle => '[Нужен перевод]';

  @override
  String selfPrompt(int surah, int from, int to) {
    return '[Нужен перевод] $surah $from $to';
  }

  @override
  String get selfDone => '[Нужен перевод]';

  @override
  String get selfHowWasIt => '[Нужен перевод]';

  @override
  String get selfRemembered => '[Нужен перевод]';

  @override
  String get selfDifficulty => '[Нужен перевод]';

  @override
  String get selfForgot => '[Нужен перевод]';
}
