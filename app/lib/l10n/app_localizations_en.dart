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
}
