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
