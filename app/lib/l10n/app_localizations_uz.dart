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
  String get prototypeMockNotice =>
      'Audio faqat telefonda qayta ishlanadi va saqlanmaydi. «Boshlash» tugmasidan keyin Android mikrofonga ruxsat so‘raydi.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return '$surah-sura, $ayah-oyat. $text';
  }
}
