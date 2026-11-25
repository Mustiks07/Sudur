import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sudur'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @mushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @learnToRead.
  ///
  /// In en, this message translates to:
  /// **'Learn to read'**
  String get learnToRead;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @sectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section is being prepared'**
  String get sectionComingSoon;

  /// No description provided for @prototypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah 78 prototype'**
  String get prototypeTitle;

  /// No description provided for @prototypePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the verified model, Mushaf pages, and fonts'**
  String get prototypePreparing;

  /// No description provided for @prototypeDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {resource}: {percent}%'**
  String prototypeDownloadProgress(String resource, int percent);

  /// No description provided for @prototypeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get prototypeRetry;

  /// No description provided for @prototypeError.
  ///
  /// In en, this message translates to:
  /// **'The prototype could not be prepared. Check the connection and try again.'**
  String get prototypeError;

  /// No description provided for @prototypeModelSmall.
  ///
  /// In en, this message translates to:
  /// **'Small model'**
  String get prototypeModelSmall;

  /// No description provided for @prototypeModelTiny.
  ///
  /// In en, this message translates to:
  /// **'Tiny model'**
  String get prototypeModelTiny;

  /// No description provided for @prototypePhoneTest.
  ///
  /// In en, this message translates to:
  /// **'Phone test'**
  String get prototypePhoneTest;

  /// No description provided for @prototypePhoneTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get prototypePhoneTesting;

  /// No description provided for @prototypePhoneResult.
  ///
  /// In en, this message translates to:
  /// **'Speed ratio: {ratio}; decode: {decodeMs} ms'**
  String prototypePhoneResult(String ratio, int decodeMs);

  /// No description provided for @prototypeChooseWav.
  ///
  /// In en, this message translates to:
  /// **'Choose WAV'**
  String get prototypeChooseWav;

  /// No description provided for @prototypeUseMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Use microphone'**
  String get prototypeUseMicrophone;

  /// No description provided for @prototypeWavSelected.
  ///
  /// In en, this message translates to:
  /// **'Measurement input: {fileName}'**
  String prototypeWavSelected(String fileName);

  /// No description provided for @prototypeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get prototypeStart;

  /// No description provided for @prototypePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get prototypePause;

  /// No description provided for @prototypeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get prototypeResume;

  /// No description provided for @prototypeStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get prototypeStop;

  /// No description provided for @prototypeHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get prototypeHint;

  /// No description provided for @prototypeShareLog.
  ///
  /// In en, this message translates to:
  /// **'Share log'**
  String get prototypeShareLog;

  /// No description provided for @prototypeFinishReadingFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish reading first'**
  String get prototypeFinishReadingFirst;

  /// No description provided for @prototypeMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Audio is processed only on this phone and is not saved. Android will request microphone access after you tap Start.'**
  String get prototypeMockNotice;

  /// No description provided for @mushafAyahSemantics.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayah {ayah}. {text}'**
  String mushafAyahSemantics(int surah, int ayah, String text);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get loadError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get networkError;

  /// No description provided for @startTitle.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get startTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get chooseLanguage;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get languageRussian;

  /// No description provided for @languageKazakh.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get languageKazakh;

  /// No description provided for @languageUzbek.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get languageUzbek;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get languageEnglish;

  /// No description provided for @choosePath.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get choosePath;

  /// No description provided for @pathLearnReading.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get pathLearnReading;

  /// No description provided for @pathMemorize.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get pathMemorize;

  /// No description provided for @pathRestore.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get pathRestore;

  /// No description provided for @chooseFamiliarSurahs.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get chooseFamiliarSurahs;

  /// No description provided for @searchSurah.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get searchSurah;

  /// No description provided for @surahNumber.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод] {number}'**
  String surahNumber(Object number);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get skip;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get continueAction;

  /// No description provided for @chooseDailyTime.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get chooseDailyTime;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод] {count}'**
  String minutesCount(Object count);

  /// No description provided for @customTime.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get customTime;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get minutes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get cancel;

  /// No description provided for @modelTitle.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get modelTitle;

  /// No description provided for @downloadModel.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get downloadModel;

  /// No description provided for @downloadLater.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get downloadLater;

  /// No description provided for @modelDownloading.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get modelDownloading;

  /// No description provided for @chooseStartPoint.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get chooseStartPoint;

  /// No description provided for @startFirstSurah.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get startFirstSurah;

  /// No description provided for @startShortSurahs.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get startShortSurahs;

  /// No description provided for @knowLetters.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get knowLetters;

  /// No description provided for @lettersNo.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get lettersNo;

  /// No description provided for @lettersALittle.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get lettersALittle;

  /// No description provided for @todayAroundMinutes.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод] {minutes}'**
  String todayAroundMinutes(Object minutes);

  /// No description provided for @todayFirstDay.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayFirstDay;

  /// No description provided for @todayNormal.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayNormal;

  /// No description provided for @todayReturning.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayReturning;

  /// No description provided for @todayCompleted.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayCompleted;

  /// No description provided for @todayFreeLimit.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayFreeLimit;

  /// No description provided for @todayModelMissing.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get todayModelMissing;

  /// No description provided for @stepDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get stepDiagnostic;

  /// No description provided for @stepPassage.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get stepPassage;

  /// No description provided for @stepSurah.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод] {number}'**
  String stepSurah(Object number);

  /// No description provided for @stepHardSpot.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get stepHardSpot;

  /// No description provided for @stepLesson.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get stepLesson;

  /// No description provided for @stepSkill.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get stepSkill;

  /// No description provided for @reasonReturnDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonReturnDiagnosis;

  /// No description provided for @reasonYesterdayNew.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonYesterdayNew;

  /// No description provided for @reasonYesterdayError.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonYesterdayError;

  /// No description provided for @reasonRecentDue.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonRecentDue;

  /// No description provided for @reasonLongUnchecked.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonLongUnchecked;

  /// No description provided for @reasonNewMaterial.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonNewMaterial;

  /// No description provided for @reasonCourseLesson.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonCourseLesson;

  /// No description provided for @reasonSkillDue.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonSkillDue;

  /// No description provided for @reasonUserAdded.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reasonUserAdded;

  /// No description provided for @selfCheck.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get selfCheck;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get startAction;

  /// No description provided for @skipTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get skipTodayTitle;

  /// No description provided for @skipTodayBody.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get skipTodayBody;

  /// No description provided for @skipToday.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get skipToday;

  /// No description provided for @dayDone.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get dayDone;

  /// No description provided for @reviewMore.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reviewMore;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get activities;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get language;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get downloads;

  /// No description provided for @myData.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get myData;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get subscription;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reminders;

  /// No description provided for @improveChecking.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get improveChecking;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get reportProblem;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get comingSoon;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get aboutApp;

  /// No description provided for @sourcesLicenses.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get sourcesLicenses;

  /// No description provided for @dailyTime.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get dailyTime;

  /// No description provided for @strictMode.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get strictMode;

  /// No description provided for @showFirstWord.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get showFirstWord;

  /// No description provided for @memorizationRepeats.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get memorizationRepeats;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get save;

  /// No description provided for @noModels.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get noModels;

  /// No description provided for @speechModel.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get speechModel;

  /// No description provided for @megabytes.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод] {value}'**
  String megabytes(Object value);

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get deleteAction;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get close;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get importData;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'[Нужен перевод]'**
  String get deleteAllDataWarning;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @readingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readingDone;

  /// No description provided for @readingRangeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This passage cannot be opened yet: the prototype has only pages 582–583. Reading the whole Quran comes in the next version.'**
  String get readingRangeUnavailable;

  /// No description provided for @stepComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This step comes in the next version of the app.'**
  String get stepComingSoon;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Steps done: {count}'**
  String todaySummary(int count);

  /// No description provided for @readPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get readPreparing;

  /// No description provided for @readReady.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get readReady;

  /// No description provided for @readModeSupported.
  ///
  /// In en, this message translates to:
  /// **'With support'**
  String get readModeSupported;

  /// No description provided for @readModeRecall.
  ///
  /// In en, this message translates to:
  /// **'Try to recall'**
  String get readModeRecall;

  /// No description provided for @readModeTest.
  ///
  /// In en, this message translates to:
  /// **'Test myself'**
  String get readModeTest;

  /// No description provided for @readStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get readStart;

  /// No description provided for @readHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get readHint;

  /// No description provided for @readPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get readPause;

  /// No description provided for @readResume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get readResume;

  /// No description provided for @readFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get readFinish;

  /// No description provided for @readPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get readPaused;

  /// No description provided for @readMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed'**
  String get readMicDenied;

  /// No description provided for @readWithoutMic.
  ///
  /// In en, this message translates to:
  /// **'Without microphone'**
  String get readWithoutMic;

  /// No description provided for @readModelMissing.
  ///
  /// In en, this message translates to:
  /// **'The model is not downloaded'**
  String get readModelMissing;

  /// No description provided for @readDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get readDownload;

  /// No description provided for @readWithoutVoice.
  ///
  /// In en, this message translates to:
  /// **'Without voice'**
  String get readWithoutVoice;

  /// No description provided for @readDeviceTooSlow.
  ///
  /// In en, this message translates to:
  /// **'The phone cannot check in time. Let\'s continue without checking'**
  String get readDeviceTooSlow;

  /// No description provided for @readFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare reading'**
  String get readFailed;

  /// No description provided for @readUnlock.
  ///
  /// In en, this message translates to:
  /// **'Open without penalty'**
  String get readUnlock;

  /// No description provided for @readStrictAgain.
  ///
  /// In en, this message translates to:
  /// **'Read this word again'**
  String get readStrictAgain;

  /// No description provided for @readOfferHint.
  ///
  /// In en, this message translates to:
  /// **'Show a hint?'**
  String get readOfferHint;

  /// No description provided for @readChecksNotice.
  ///
  /// In en, this message translates to:
  /// **'Words are checked. Vowel marks and tajweed are not checked yet'**
  String get readChecksNotice;

  /// No description provided for @readTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayahs {from}–{to}'**
  String readTitle(int surah, int from, int to);

  /// No description provided for @readShowFirstWord.
  ///
  /// In en, this message translates to:
  /// **'First word visible'**
  String get readShowFirstWord;

  /// No description provided for @readStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict mode'**
  String get readStrict;

  /// No description provided for @readTextView.
  ///
  /// In en, this message translates to:
  /// **'Temporary text view: there is no page layout for this place yet'**
  String get readTextView;

  /// No description provided for @readSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving the result…'**
  String get readSaving;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @reviewClean.
  ///
  /// In en, this message translates to:
  /// **'Read cleanly'**
  String get reviewClean;

  /// No description provided for @reviewIndependent.
  ///
  /// In en, this message translates to:
  /// **'On your own: {count}'**
  String reviewIndependent(int count);

  /// No description provided for @reviewWithHints.
  ///
  /// In en, this message translates to:
  /// **'With hints: {count}'**
  String reviewWithHints(int count);

  /// No description provided for @reviewErrors.
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {count}'**
  String reviewErrors(int count);

  /// No description provided for @reviewUnverified.
  ///
  /// In en, this message translates to:
  /// **'Could not check: {count}'**
  String reviewUnverified(int count);

  /// No description provided for @reviewFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewFilterAll;

  /// No description provided for @reviewFilterErrors.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get reviewFilterErrors;

  /// No description provided for @reviewFilterCorrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get reviewFilterCorrections;

  /// No description provided for @reviewFilterUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not heard'**
  String get reviewFilterUnverified;

  /// No description provided for @reviewKindOmission.
  ///
  /// In en, this message translates to:
  /// **'word skipped'**
  String get reviewKindOmission;

  /// No description provided for @reviewKindSubstitution.
  ///
  /// In en, this message translates to:
  /// **'another word'**
  String get reviewKindSubstitution;

  /// No description provided for @reviewKindInsertion.
  ///
  /// In en, this message translates to:
  /// **'extra word'**
  String get reviewKindInsertion;

  /// No description provided for @reviewKindJump.
  ///
  /// In en, this message translates to:
  /// **'moved to a similar ayah'**
  String get reviewKindJump;

  /// No description provided for @reviewKindRepetition.
  ///
  /// In en, this message translates to:
  /// **'repetition'**
  String get reviewKindRepetition;

  /// No description provided for @reviewKindHesitation.
  ///
  /// In en, this message translates to:
  /// **'hesitation'**
  String get reviewKindHesitation;

  /// No description provided for @reviewStatePreliminary.
  ///
  /// In en, this message translates to:
  /// **'preliminary'**
  String get reviewStatePreliminary;

  /// No description provided for @reviewStateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'confirmed'**
  String get reviewStateConfirmed;

  /// No description provided for @reviewStateCorrected.
  ///
  /// In en, this message translates to:
  /// **'corrected'**
  String get reviewStateCorrected;

  /// No description provided for @reviewStateUnverified.
  ///
  /// In en, this message translates to:
  /// **'could not check'**
  String get reviewStateUnverified;

  /// No description provided for @reviewStateDisputed.
  ///
  /// In en, this message translates to:
  /// **'disputed'**
  String get reviewStateDisputed;

  /// No description provided for @reviewListenSelf.
  ///
  /// In en, this message translates to:
  /// **'Listen to myself'**
  String get reviewListenSelf;

  /// No description provided for @reviewListenReciter.
  ///
  /// In en, this message translates to:
  /// **'Listen to the reciter'**
  String get reviewListenReciter;

  /// No description provided for @reviewDispute.
  ///
  /// In en, this message translates to:
  /// **'I disagree'**
  String get reviewDispute;

  /// No description provided for @reviewPractice.
  ///
  /// In en, this message translates to:
  /// **'Practise this place'**
  String get reviewPractice;

  /// No description provided for @reviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reviewNext;

  /// No description provided for @reviewAudioSoon.
  ///
  /// In en, this message translates to:
  /// **'Your recording and the reciter come in the next version'**
  String get reviewAudioSoon;

  /// No description provided for @reviewNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get reviewNoEvents;

  /// No description provided for @selfTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-check'**
  String get selfTitle;

  /// No description provided for @selfPrompt.
  ///
  /// In en, this message translates to:
  /// **'Read surah {surah}, ayahs {from}–{to} to yourself'**
  String selfPrompt(int surah, int from, int to);

  /// No description provided for @selfDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selfDone;

  /// No description provided for @selfHowWasIt.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get selfHowWasIt;

  /// No description provided for @selfRemembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get selfRemembered;

  /// No description provided for @selfDifficulty.
  ///
  /// In en, this message translates to:
  /// **'With difficulty'**
  String get selfDifficulty;

  /// No description provided for @selfForgot.
  ///
  /// In en, this message translates to:
  /// **'Did not remember'**
  String get selfForgot;

  /// No description provided for @exerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseTitle;

  /// No description provided for @exerciseProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String exerciseProgress(int step, int total);

  /// No description provided for @exerciseClosed.
  ///
  /// In en, this message translates to:
  /// **'The place is fixed'**
  String get exerciseClosed;

  /// No description provided for @exerciseAgain.
  ///
  /// In en, this message translates to:
  /// **'We will come back to it tomorrow'**
  String get exerciseAgain;

  /// No description provided for @exerciseUnverifiedPairs.
  ///
  /// In en, this message translates to:
  /// **'Similar places were found automatically and not checked by a specialist'**
  String get exerciseUnverifiedPairs;

  /// No description provided for @exerciseHardPassage.
  ///
  /// In en, this message translates to:
  /// **'Hard place'**
  String get exerciseHardPassage;

  /// No description provided for @exerciseTransition.
  ///
  /// In en, this message translates to:
  /// **'Transition between ayahs'**
  String get exerciseTransition;

  /// No description provided for @exerciseStartInMiddle.
  ///
  /// In en, this message translates to:
  /// **'Start from the middle'**
  String get exerciseStartInMiddle;

  /// No description provided for @exerciseFadingHelp.
  ///
  /// In en, this message translates to:
  /// **'Fewer hints'**
  String get exerciseFadingHelp;

  /// No description provided for @exerciseSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar ayahs'**
  String get exerciseSimilar;

  /// No description provided for @exerciseReread.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get exerciseReread;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
