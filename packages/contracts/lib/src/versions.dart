import 'package:meta/meta.dart';

/// Versions a result was produced with: recognition model, check rules and
/// content text (docs/tz ПО-11, 4.5). Stored with every check event and
/// attempt so results stay comparable when a model or rules change.
@immutable
final class ReadingVersions {
  /// Creates versions.
  const ReadingVersions({
    required this.modelId,
    required this.modelVersion,
    required this.rulesVersion,
    required this.textVersion,
  });

  /// Recognition model id, for example `abdou/quran-asr-small`.
  final String modelId;

  /// Version of the installed model package.
  final String modelVersion;

  /// Version of the check rules and thresholds.
  final String rulesVersion;

  /// Version of the content (canonical text) package.
  final String textVersion;

  /// JSON form for `check_event.versions` (docs/tz 12.1).
  Map<String, String> toJson() => {
        'model': '$modelId@$modelVersion',
        'rules': rulesVersion,
        'text': textVersion,
      };

  @override
  bool operator ==(Object other) =>
      other is ReadingVersions &&
      other.modelId == modelId &&
      other.modelVersion == modelVersion &&
      other.rulesVersion == rulesVersion &&
      other.textVersion == textVersion;

  @override
  int get hashCode =>
      Object.hash(modelId, modelVersion, rulesVersion, textVersion);
}
