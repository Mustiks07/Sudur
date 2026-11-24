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
  String get prototypeStrict => '[Нужен перевод]';

  @override
  String get checkOmission => '[Нужен перевод]';

  @override
  String get checkSubstitution => '[Нужен перевод]';

  @override
  String get checkInsertion => '[Нужен перевод]';

  @override
  String get checkJump => '[Нужен перевод]';

  @override
  String get checkRepetition => '[Нужен перевод]';

  @override
  String get checkHesitation => '[Нужен перевод]';

  @override
  String get checkPreliminary => '[Нужен перевод]';

  @override
  String get checkConfirmed => '[Нужен перевод]';

  @override
  String get checkCorrected => '[Нужен перевод]';

  @override
  String get checkUnverified => '[Нужен перевод]';

  @override
  String get checkDisputed => '[Нужен перевод]';

  @override
  String prototypeCheckTexts(String expected, String heard) {
    return '[Нужен перевод] $expected $heard';
  }
}
