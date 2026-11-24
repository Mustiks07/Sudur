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

  @override
  String get prototypeTitle => 'Прототип суры 78';

  @override
  String get prototypePreparing =>
      'Готовим проверенную модель, страницы мусхафа и шрифты';

  @override
  String prototypeDownloadProgress(String resource, int percent) {
    return 'Загружается $resource: $percent%';
  }

  @override
  String get prototypeRetry => 'Повторить';

  @override
  String get prototypeError =>
      'Не удалось подготовить прототип. Проверьте интернет и повторите.';

  @override
  String get prototypeModelSmall => 'Модель small';

  @override
  String get prototypeModelTiny => 'Модель tiny';

  @override
  String get prototypePhoneTest => 'Тест телефона';

  @override
  String get prototypePhoneTesting => 'Идёт тест…';

  @override
  String prototypePhoneResult(String ratio, int decodeMs) {
    return 'Скорость: $ratio; распознавание: $decodeMs мс';
  }

  @override
  String get prototypeChooseWav => 'Выбрать WAV';

  @override
  String get prototypeUseMicrophone => 'Использовать микрофон';

  @override
  String prototypeWavSelected(String fileName) {
    return 'Источник замера: $fileName';
  }

  @override
  String get prototypeStart => 'Начать';

  @override
  String get prototypePause => 'Пауза';

  @override
  String get prototypeResume => 'Продолжить';

  @override
  String get prototypeStop => 'Завершить';

  @override
  String get prototypeHint => 'Подсказка';

  @override
  String get prototypeShareLog => 'Поделиться журналом';

  @override
  String get prototypeFinishReadingFirst => 'Сначала завершите чтение';

  @override
  String get prototypeMockNotice =>
      'Звук обрабатывается только на телефоне и не сохраняется. После нажатия «Начать» Android запросит доступ к микрофону.';

  @override
  String mushafAyahSemantics(int surah, int ayah, String text) {
    return 'Сура $surah, аят $ayah. $text';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get loadError =>
      'Не удалось загрузить данные. Повторите попытку или сообщите о проблеме.';

  @override
  String get networkError => 'Нет интернета. Остальное работает без него';

  @override
  String get startTitle => 'Старт';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get languageUzbek => 'O‘zbekcha';

  @override
  String get languageEnglish => 'English';

  @override
  String get choosePath => 'С чего начнём?';

  @override
  String get pathLearnReading => 'Хочу научиться читать';

  @override
  String get pathMemorize => 'Уже читаю, хочу учить наизусть';

  @override
  String get pathRestore => 'Хочу восстановить выученное';

  @override
  String get chooseFamiliarSurahs => 'Какие суры вы уже знаете?';

  @override
  String get searchSurah => 'Номер суры';

  @override
  String surahNumber(Object number) {
    return 'Сура $number';
  }

  @override
  String get skip => 'Пропустить';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get chooseDailyTime => 'Сколько времени в день?';

  @override
  String minutesCount(Object count) {
    return '$count минут';
  }

  @override
  String get customTime => 'Своё время';

  @override
  String get minutes => 'Минуты';

  @override
  String get cancel => 'Отмена';

  @override
  String get modelTitle =>
      'Чтобы проверять чтение без интернета, скачаем модель. Скачать сейчас по Wi-Fi?';

  @override
  String get downloadModel => 'Скачать';

  @override
  String get downloadLater => 'Позже';

  @override
  String get modelDownloading => 'Скачиваем и проверяем файлы…';

  @override
  String get chooseStartPoint => 'С какой суры начнём?';

  @override
  String get startFirstSurah => 'С первой суры';

  @override
  String get startShortSurahs => 'Короткие суры с конца Корана';

  @override
  String get knowLetters => 'Знаете ли вы арабские буквы?';

  @override
  String get lettersNo => 'Нет';

  @override
  String get lettersALittle => 'Немного';

  @override
  String todayAroundMinutes(Object minutes) {
    return 'Сегодня — около $minutes минут';
  }

  @override
  String get todayFirstDay => 'Начнём с одного небольшого занятия';

  @override
  String get todayNormal => 'План собран по вашим прошлым занятиям';

  @override
  String get todayReturning =>
      'С возвращением. Начнём с короткой проверки, и я составлю новый план';

  @override
  String get todayCompleted => 'На сегодня готово';

  @override
  String get todayFreeLimit =>
      'Бесплатная проверка на сегодня закончилась. Можно продолжить с самопроверкой';

  @override
  String get todayModelMissing =>
      'Скачайте модель, чтобы приложение проверяло чтение. Пока доступна самопроверка';

  @override
  String get stepDiagnostic => 'Короткая проверка';

  @override
  String get stepPassage => 'Отрывок';

  @override
  String stepSurah(Object number) {
    return 'Сура $number';
  }

  @override
  String get stepHardSpot => 'Трудное место';

  @override
  String get stepLesson => 'Урок чтения';

  @override
  String get stepSkill => 'Упражнение';

  @override
  String get reasonReturnDiagnosis => 'после перерыва';

  @override
  String get reasonYesterdayNew => 'вчера было новым';

  @override
  String get reasonYesterdayError => 'вчера была ошибка';

  @override
  String get reasonRecentDue => 'пора закрепить';

  @override
  String get reasonLongUnchecked => 'давно не проверяли';

  @override
  String get reasonNewMaterial => 'новое';

  @override
  String get reasonCourseLesson => 'следующий урок';

  @override
  String get reasonSkillDue => 'пора повторить навык';

  @override
  String get reasonUserAdded => 'добавлено вами';

  @override
  String get selfCheck => 'Самопроверка';

  @override
  String get startAction => 'Начать';

  @override
  String get skipTodayTitle => 'Пропустить этот шаг сегодня?';

  @override
  String get skipTodayBody => 'Он останется в плане следующих дней.';

  @override
  String get skipToday => 'Пропустить сегодня';

  @override
  String get dayDone => 'На сегодня готово. Можно ещё повторить';

  @override
  String get reviewMore => 'Ещё повторить';

  @override
  String get activities => 'Занятия';

  @override
  String get language => 'Язык';

  @override
  String get downloads => 'Загрузки';

  @override
  String get myData => 'Мои данные';

  @override
  String get subscription => 'Подписка';

  @override
  String get reminders => 'Напоминания';

  @override
  String get improveChecking => 'Помочь улучшить проверку';

  @override
  String get reportProblem => 'Сообщить о проблеме';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get sourcesLicenses => 'Источники и лицензии';

  @override
  String get dailyTime => 'Время на день';

  @override
  String get strictMode => 'Строго останавливаться при ошибке';

  @override
  String get showFirstWord => 'Показывать первое слово';

  @override
  String get memorizationRepeats => 'Повторов при заучивании';

  @override
  String get save => 'Сохранить';

  @override
  String get noModels => 'Модель ещё не загружена';

  @override
  String get speechModel => 'Модель проверки чтения';

  @override
  String megabytes(Object value) {
    return '$value МБ';
  }

  @override
  String get deleteAction => 'Удалить';

  @override
  String get close => 'Закрыть';

  @override
  String get exportData => 'Выгрузить данные';

  @override
  String get importData => 'Загрузить данные';

  @override
  String get deleteAllData => 'Удалить всё';

  @override
  String get deleteAllDataWarning =>
      'Будут удалены профиль, занятия, настройки и сохранённые записи. Это действие нельзя отменить.';
}
