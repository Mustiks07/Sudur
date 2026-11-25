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

  @override
  String get readPreparing => 'Preparing…';

  @override
  String get readReady => 'Start reading';

  @override
  String get readModeSupported => 'With support';

  @override
  String get readModeRecall => 'Try to recall';

  @override
  String get readModeTest => 'Test myself';

  @override
  String get readStart => 'Start';

  @override
  String get readHint => 'Hint';

  @override
  String get readPause => 'Pause';

  @override
  String get readResume => 'Continue';

  @override
  String get readFinish => 'Finish';

  @override
  String get readPaused => 'Paused';

  @override
  String get readMicDenied => 'Microphone access is needed';

  @override
  String get readWithoutMic => 'Without microphone';

  @override
  String get readModelMissing => 'The model is not downloaded';

  @override
  String get readDownload => 'Download';

  @override
  String get readWithoutVoice => 'Without voice';

  @override
  String get readDeviceTooSlow =>
      'The phone cannot check in time. Let\'s continue without checking';

  @override
  String get readFailed => 'Could not prepare reading';

  @override
  String get readUnlock => 'Open without penalty';

  @override
  String get readStrictAgain => 'Read this word again';

  @override
  String get readOfferHint => 'Show a hint?';

  @override
  String get readChecksNotice =>
      'Words are checked. Vowel marks and tajweed are not checked yet';

  @override
  String readTitle(int surah, int from, int to) {
    return 'Surah $surah, ayahs $from–$to';
  }

  @override
  String get readShowFirstWord => 'First word visible';

  @override
  String get readStrict => 'Strict mode';

  @override
  String get readTextView =>
      'Temporary text view: there is no page layout for this place yet';

  @override
  String get readSaving => 'Saving the result…';

  @override
  String get reviewTitle => 'Review';

  @override
  String get reviewClean => 'Read cleanly';

  @override
  String reviewIndependent(int count) {
    return 'On your own: $count';
  }

  @override
  String reviewWithHints(int count) {
    return 'With hints: $count';
  }

  @override
  String reviewErrors(int count) {
    return 'Mistakes: $count';
  }

  @override
  String reviewUnverified(int count) {
    return 'Could not check: $count';
  }

  @override
  String get reviewFilterAll => 'All';

  @override
  String get reviewFilterErrors => 'Mistakes';

  @override
  String get reviewFilterCorrections => 'Corrections';

  @override
  String get reviewFilterUnverified => 'Not heard';

  @override
  String get reviewKindOmission => 'word skipped';

  @override
  String get reviewKindSubstitution => 'another word';

  @override
  String get reviewKindInsertion => 'extra word';

  @override
  String get reviewKindJump => 'moved to a similar ayah';

  @override
  String get reviewKindRepetition => 'repetition';

  @override
  String get reviewKindHesitation => 'hesitation';

  @override
  String get reviewStatePreliminary => 'preliminary';

  @override
  String get reviewStateConfirmed => 'confirmed';

  @override
  String get reviewStateCorrected => 'corrected';

  @override
  String get reviewStateUnverified => 'could not check';

  @override
  String get reviewStateDisputed => 'disputed';

  @override
  String get reviewListenSelf => 'Listen to myself';

  @override
  String get reviewListenReciter => 'Listen to the reciter';

  @override
  String get reviewDispute => 'I disagree';

  @override
  String get reviewPractice => 'Practise this place';

  @override
  String get reviewNext => 'Next';

  @override
  String get reviewAudioSoon =>
      'Your recording and the reciter come in the next version';

  @override
  String get reviewNoEvents => 'No events';

  @override
  String get selfTitle => 'Self-check';

  @override
  String selfPrompt(int surah, int from, int to) {
    return 'Read surah $surah, ayahs $from–$to to yourself';
  }

  @override
  String get selfDone => 'Done';

  @override
  String get selfHowWasIt => 'How did it go?';

  @override
  String get selfRemembered => 'Remembered';

  @override
  String get selfDifficulty => 'With difficulty';

  @override
  String get selfForgot => 'Did not remember';

  @override
  String get exerciseTitle => 'Exercise';

  @override
  String exerciseProgress(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get exerciseClosed => 'The place is fixed';

  @override
  String get exerciseAgain => 'We will come back to it tomorrow';

  @override
  String get exerciseUnverifiedPairs =>
      'Similar places were found automatically and not checked by a specialist';

  @override
  String get exerciseHardPassage => 'Hard place';

  @override
  String get exerciseTransition => 'Transition between ayahs';

  @override
  String get exerciseStartInMiddle => 'Start from the middle';

  @override
  String get exerciseFadingHelp => 'Fewer hints';

  @override
  String get exerciseSimilar => 'Similar ayahs';

  @override
  String get exerciseReread => 'Read again';

  @override
  String get learnTitle => 'Learning';

  @override
  String get learnListen => 'Listen to the reciter';

  @override
  String get learnListenUnavailable =>
      'There are no reciter recordings in the app yet — their rights are not obtained yet';

  @override
  String get learnSkipListening => 'Skip listening';

  @override
  String get learnSupported => 'Read with the text';

  @override
  String get learnRecall => 'Try to recall';

  @override
  String get learnTest => 'Check yourself';

  @override
  String get learnJunction => 'Junction with the previous passage';

  @override
  String get learnCombined => 'Both passages in a row';

  @override
  String get learnLearned => 'Passage learned. We will repeat it tomorrow';

  @override
  String courseAvailable(int count) {
    return 'Lessons available: $count';
  }

  @override
  String courseStage(int stage) {
    return 'Stage $stage';
  }

  @override
  String get courseSoon => 'Lessons of this stage are being prepared';

  @override
  String get coursePaid => 'With subscription';

  @override
  String get courseTajweed => 'Tajweed reference';

  @override
  String get tajweedSoon => 'The reference comes with the course content';

  @override
  String get lessonRight => 'Right';

  @override
  String get lessonWrong =>
      'Not right — see the right answer in the explanation';

  @override
  String get lessonGotIt => 'Got it';

  @override
  String get lessonNotQuite => 'Not quite';

  @override
  String get lessonRepeatCompare => 'Repeat and compare';

  @override
  String get lessonAudioSoon =>
      'The sample sound comes with the course content';

  @override
  String get lessonPassed => 'Lesson passed';

  @override
  String get lessonFailed => 'Let\'s repeat the hard parts';

  @override
  String get lessonRepeat => 'Repeat';

  @override
  String lessonQuizScore(int percent) {
    return 'Mini-check: $percent%';
  }

  @override
  String lessonOption(int number) {
    return 'Option $number';
  }

  @override
  String get lessonBuild => 'Tap in order';

  @override
  String get lessonFindRule => 'Mark the words with the rule';
}
