/// Microphone capture, ring buffer, VAD and signal quality.
///
/// Spec: docs/tz sections 2.5, 10.2.
library;

export 'package:contracts/contracts.dart'
    show SignalQuality, SignalQualityLevel;

export 'src/audio_capture_config.dart';
export 'src/audio_capture_event.dart';
export 'src/audio_capture_exception.dart';
export 'src/audio_capture_service.dart';
export 'src/audio_snippet.dart';
