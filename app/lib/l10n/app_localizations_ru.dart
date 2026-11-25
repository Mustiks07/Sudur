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

  @override
  String get back => 'Назад';

  @override
  String get readingDone => 'Готово';

  @override
  String get readingRangeUnavailable =>
      'Этот отрывок пока нельзя открыть: в прототипе есть только страницы 582–583. Экран чтения для всего Корана появится в следующей версии.';

  @override
  String get stepComingSoon =>
      'Этот шаг появится в следующей версии приложения.';

  @override
  String todaySummary(int count) {
    return 'Сделано шагов: $count';
  }

  @override
  String get readPreparing => 'Готовлю…';

  @override
  String get readReady => 'Начинайте читать';

  @override
  String get readModeSupported => 'С поддержкой';

  @override
  String get readModeRecall => 'Пробую вспомнить';

  @override
  String get readModeTest => 'Проверяю себя';

  @override
  String get readStart => 'Начать';

  @override
  String get readHint => 'Подсказка';

  @override
  String get readPause => 'Пауза';

  @override
  String get readResume => 'Продолжить';

  @override
  String get readFinish => 'Закончить';

  @override
  String get readPaused => 'Пауза';

  @override
  String get readMicDenied => 'Нужен доступ к микрофону';

  @override
  String get readWithoutMic => 'Без микрофона';

  @override
  String get readModelMissing => 'Модель не скачана';

  @override
  String get readDownload => 'Скачать';

  @override
  String get readWithoutVoice => 'Без голоса';

  @override
  String get readDeviceTooSlow =>
      'Телефон не успевает проверять. Продолжим без проверки';

  @override
  String get readFailed => 'Не удалось подготовить чтение';

  @override
  String get readUnlock => 'Открыть без штрафа';

  @override
  String get readStrictAgain => 'Прочитайте это слово ещё раз';

  @override
  String get readOfferHint => 'Подсказать?';

  @override
  String get readChecksNotice =>
      'Проверяются слова. Огласовки и таджвид пока не проверяются';

  @override
  String readTitle(int surah, int from, int to) {
    return 'Сура $surah, аяты $from–$to';
  }

  @override
  String get readShowFirstWord => 'Первое слово видно';

  @override
  String get readStrict => 'Строгий режим';

  @override
  String get readTextView =>
      'Временный текстовый вид: разметки страниц для этого места пока нет';

  @override
  String get readSaving => 'Сохраняю результат…';

  @override
  String get reviewTitle => 'Разбор';

  @override
  String get reviewClean => 'Прочитано чисто';

  @override
  String reviewIndependent(int count) {
    return 'Самостоятельно: $count';
  }

  @override
  String reviewWithHints(int count) {
    return 'С подсказками: $count';
  }

  @override
  String reviewErrors(int count) {
    return 'Ошибок: $count';
  }

  @override
  String reviewUnverified(int count) {
    return 'Не удалось проверить: $count';
  }

  @override
  String get reviewFilterAll => 'Все';

  @override
  String get reviewFilterErrors => 'Ошибки';

  @override
  String get reviewFilterCorrections => 'Исправления';

  @override
  String get reviewFilterUnverified => 'Не расслышал';

  @override
  String get reviewKindOmission => 'пропущено слово';

  @override
  String get reviewKindSubstitution => 'другое слово';

  @override
  String get reviewKindInsertion => 'лишнее слово';

  @override
  String get reviewKindJump => 'перешли на похожий аят';

  @override
  String get reviewKindRepetition => 'повтор';

  @override
  String get reviewKindHesitation => 'запинка';

  @override
  String get reviewStatePreliminary => 'предварительно';

  @override
  String get reviewStateConfirmed => 'подтверждено';

  @override
  String get reviewStateCorrected => 'исправлено';

  @override
  String get reviewStateUnverified => 'не удалось проверить';

  @override
  String get reviewStateDisputed => 'оспорено';

  @override
  String get reviewListenSelf => 'Послушать себя';

  @override
  String get reviewListenReciter => 'Послушать чтеца';

  @override
  String get reviewDispute => 'Не согласен';

  @override
  String get reviewPractice => 'Потренировать это место';

  @override
  String get reviewNext => 'Дальше';

  @override
  String get reviewAudioSoon =>
      'Своя запись и чтец появятся в следующей версии';

  @override
  String get reviewNoEvents => 'Событий нет';

  @override
  String get selfTitle => 'Самопроверка';

  @override
  String selfPrompt(int surah, int from, int to) {
    return 'Прочитайте про себя суру $surah, аяты $from–$to';
  }

  @override
  String get selfDone => 'Готово';

  @override
  String get selfHowWasIt => 'Как получилось?';

  @override
  String get selfRemembered => 'Вспомнил';

  @override
  String get selfDifficulty => 'С трудом';

  @override
  String get selfForgot => 'Не вспомнил';

  @override
  String get exerciseTitle => 'Упражнение';

  @override
  String exerciseProgress(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String get exerciseClosed => 'Место закреплено';

  @override
  String get exerciseAgain => 'Вернёмся к нему завтра';

  @override
  String get exerciseUnverifiedPairs =>
      'Похожие места подобраны автоматически и не проверены специалистом';

  @override
  String get exerciseHardPassage => 'Трудное место';

  @override
  String get exerciseTransition => 'Переход между аятами';

  @override
  String get exerciseStartInMiddle => 'Начало с середины';

  @override
  String get exerciseFadingHelp => 'Меньше подсказок';

  @override
  String get exerciseSimilar => 'Похожие аяты';

  @override
  String get exerciseReread => 'Прочитать ещё раз';
}
