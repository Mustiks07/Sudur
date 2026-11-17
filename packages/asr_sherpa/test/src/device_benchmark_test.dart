import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects small, tiny, slow partials, and self-check at thresholds', () {
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.3, tinySpeedRatio: 0.2),
      AsrDeviceDecision.small,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.4, tinySpeedRatio: 0.3),
      AsrDeviceDecision.tiny,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.4, tinySpeedRatio: 0.4),
      AsrDeviceDecision.smallWithSlowPartials,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.7, tinySpeedRatio: 0.7),
      AsrDeviceDecision.selfCheck,
    );
  });
}
