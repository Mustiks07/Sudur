import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/config/prototype_real_session.dart';
import 'package:sudur/ui/read/view_models/read_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';
import '../../reading/test_helpers.dart';
import '../read_test_helpers.dart';

void main() {
  late FakeReadingRepository reading;
  late FakeAppUserRepository user;
  late ManualPrototypeSessionFactory sessions;
  late ReadViewModel viewModel;

  setUp(() async {
    reading = FakeReadingRepository();
    user = FakeAppUserRepository();
    sessions = ManualPrototypeSessionFactory();
    viewModel = ReadViewModel(
      reading: reading,
      user: user,
      sessionFactory: sessions,
    );
    await viewModel.open(from: w1, to: w3, stepId: 'step-1');
  });

  tearDown(() => viewModel.dispose());

  test(
    'recall hides all but the first word; support shows all (ЭЧ-01, 13)',
    () {
      expect(viewModel.state, ReadState.ready);
      expect(viewModel.wordStates[w1], MushafWordState.normal);
      expect(viewModel.wordStates[w2], MushafWordState.hidden);

      viewModel.setMode(ReadMode.supported);
      expect(viewModel.wordStates.values.toSet(), {MushafWordState.normal});

      viewModel
        ..setMode(ReadMode.test)
        ..setShowFirstWord(value: false);
      expect(viewModel.wordStates[w1], MushafWordState.hidden);
    },
  );

  test('no model: modelMissing, then download prepares again', () async {
    reading.voice = false;
    await viewModel.open(from: w1, to: w3);
    expect(viewModel.state, ReadState.error);
    expect(viewModel.error, ReadError.modelMissing);

    await viewModel.downloadModel();
    expect(reading.downloads, 1);
    expect(viewModel.state, ReadState.ready);
  });

  test('start sends the mode and behavior; heard words appear', () async {
    viewModel.setStrict(value: true);
    await viewModel.start();
    final start = sessions.session.commands.whereType<StartSession>().single;
    expect(start.mode, SessionMode.recall);
    expect(start.behavior, SessionBehavior.strict);
    expect(viewModel.state, ReadState.listening);

    sessions.session.emit(revealed(w2));
    expect(viewModel.wordStates[w2], MushafWordState.correct);
  });

  test('in “test myself” nothing appears until the end', () async {
    viewModel.setMode(ReadMode.test);
    await viewModel.start();
    sessions.session
      ..emit(revealed(w2))
      ..emit(check('c', w3));
    expect(viewModel.wordStates[w2], MushafWordState.hidden);
    expect(viewModel.wordStates[w3], MushafWordState.hidden);
  });

  test('the hint ladder goes letter, word, next ayah, ayah (ЭЧ-04)', () async {
    await viewModel.start();
    for (var i = 0; i < 5; i++) {
      await viewModel.hint();
    }
    expect(
      sessions.session.commands.whereType<RequestHint>().map((h) => h.kind),
      [
        HintKind.firstLetter,
        HintKind.word,
        HintKind.nextAyahStart,
        HintKind.wholeAyah,
        HintKind.wholeAyah,
      ],
    );
    sessions.session.emit(revealed(w2));
    await viewModel.hint();
    expect(
      sessions.session.commands.whereType<RequestHint>().last.kind,
      HintKind.firstLetter,
      reason: 'the ladder starts again after a word opened',
    );
  });

  test(
    'a word that does not open is offered without penalty (ЭЧ-12)',
    () async {
      await viewModel.start();
      sessions.session
        ..emit(ok)
        ..emit(at(w2))
        ..emit(at(w2));
      expect(viewModel.stuckWord, isNull);
      sessions.session.emit(at(w2));
      expect(viewModel.stuckWord, w2);

      viewModel.unlockStuckWord();
      expect(viewModel.wordStates[w2], MushafWordState.notHeard);
      expect(viewModel.stuckWord, isNull);
    },
  );

  test('with a poor signal no unlock is offered', () async {
    await viewModel.start();
    sessions.session.emit(
      const SignalQuality(
        sessionId: 's',
        atMs: 1,
        level: SignalQualityLevel.noisy,
      ),
    );
    for (var i = 0; i < 4; i++) {
      sessions.session.emit(at(w2));
    }
    expect(viewModel.stuckWord, isNull);
    expect(viewModel.sound, SoundIndicator.poor);
  });

  test('strict: read again, then a hint is offered (ЭЧ-05)', () async {
    viewModel.setStrict(value: true);
    await viewModel.start();
    sessions.session.emit(check('a', w2));
    expect(viewModel.strictWord, w2);
    expect(viewModel.offerHint, isFalse);
    sessions.session.emit(check('b', w2));
    expect(viewModel.offerHint, isTrue);

    sessions.session.emit(revealed(w2));
    expect(viewModel.strictWord, isNull);
    expect(viewModel.offerHint, isFalse);
  });

  test(
    'finish writes the attempt with checks, hints and unlocked words',
    () async {
      await viewModel.start();
      await viewModel.hint();
      sessions.session
        ..emit(ok)
        ..emit(check('c1', w2))
        ..emit(
          const CheckStateChanged(
            sessionId: 's',
            atMs: 20,
            eventId: 'c1',
            from: CheckState.preliminary,
            to: CheckState.confirmed,
            reason: 'context',
          ),
        )
        ..emit(at(w3))
        ..emit(at(w3))
        ..emit(at(w3));
      viewModel.unlockStuckWord();

      final finishing = viewModel.finish();
      expect(viewModel.state, ReadState.finishing);
      expect(sessions.session.stops, 1);
      sessions.session.emit(finishedEvent());
      await finishing;

      expect(viewModel.state, ReadState.finished);
      final result = user.readings.single;
      expect(result.stepId, 'step-1');
      expect(result.mode, SessionMode.recall);
      expect(result.hints, {HintKind.firstLetter: 1});
      expect(result.checks.single.state, CheckState.confirmed);
      expect(result.checks.single.heardText, 'heard-test');
      expect(result.unlocked, {w3});
      expect(viewModel.wordStates[w3], MushafWordState.notHeard);
    },
  );

  test('microphone denied is shown as micDenied', () async {
    await viewModel.start();
    sessions.session.emitFailure(
      const PrototypeRealSessionException('micDenied', 'denied'),
    );
    expect(viewModel.state, ReadState.error);
    expect(viewModel.error, ReadError.micDenied);
  });
}
