import 'package:content/src/config_schema.dart';
import 'package:content/src/manifest.dart';
import 'package:content/src/manifest_verifier.dart';
import 'package:content/src/package_version.dart';
import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// All parameters of the `config` package by section (docs/tz 8.8, 12.4).
@immutable
final class AppConfig {
  /// Creates the parameters.
  const AppConfig({
    required this.audio,
    required this.recognition,
    required this.plan,
    required this.other,
  });

  /// The built-in values, used until a signed config is accepted.
  static const AppConfig defaults = AppConfig(
    audio: AudioConfig.defaults,
    recognition: RecognitionConfig.defaults,
    plan: PlanConfig.defaults,
    other: OtherConfig.defaults,
  );

  /// Sound (`audio_capture`).
  final AudioConfig audio;

  /// Recognition not tied to a model (`asr_sherpa`).
  final RecognitionConfig recognition;

  /// Plan (`planner`).
  final PlanConfig plan;

  /// Everything else.
  final OtherConfig other;
}

/// A config file whose signature and values are checked.
@immutable
final class VerifiedConfig {
  /// Creates it.
  const VerifiedConfig({
    required this.config,
    required this.version,
    required this.issuedAt,
    required this.signature,
    required this.source,
  });

  /// The parameters.
  final AppConfig config;

  /// Version of this config.
  final PackageVersion version;

  /// When it was issued.
  final DateTime issuedAt;

  /// The checked signature.
  final ManifestSignature signature;

  /// The file as received, to store as the last verified copy.
  final String source;
}

/// Format of config files this app reads.
const int supportedConfigVersion = 1;

/// Why a config file is refused: the document problem and, for values,
/// which value.
final class ConfigException implements Exception {
  /// Creates the error.
  const ConfigException(this.problem, this.message);

  /// Kind of problem; `malformed` also covers values out of bounds.
  final ManifestProblem problem;

  /// Which field and why.
  final String message;

  @override
  String toString() => 'Config ${problem.name}: $message';
}

const Set<String> _topLevel = {
  'configVersion',
  'version',
  'issuedAt',
  'signature',
  ...{'audio', 'recognition', 'plan', 'other'},
};

/// Checks a `config` file (docs/tz 12.3: signed like the manifest) and
/// reads it. Unknown sections or parameters and values out of bounds are
/// refused with the name of the value; a missing parameter keeps its
/// built-in value. [notBefore] refuses a copy older than the stored one.
Future<Result<VerifiedConfig>> verifyConfig(
  String source,
  TrustedKeys keys, {
  DateTime? notBefore,
}) async {
  Result<VerifiedConfig> fail(ManifestProblem p, String message) =>
      Result.error(ConfigException(p, message));

  final Map<String, Object?> json;
  final ManifestSignature signature;
  switch (await verifySignedJson(source, keys)) {
    case Ok(value: (final document, final sig)):
      json = document;
      signature = sig;
    case Error(error: final ManifestException e):
      return fail(e.problem, e.message);
    case Error(:final error):
      return fail(ManifestProblem.malformed, '$error');
  }
  switch (json['configVersion']) {
    case final int v when v == supportedConfigVersion:
      break;
    case final int v when v > supportedConfigVersion:
      return fail(ManifestProblem.unsupportedVersion, 'configVersion $v');
    default:
      return fail(ManifestProblem.malformed, 'configVersion');
  }
  for (final k in json.keys) {
    if (!_topLevel.contains(k)) {
      return fail(ManifestProblem.malformed, 'unknown field "$k"');
    }
  }
  final DateTime issuedAt;
  final PackageVersion? version;
  try {
    issuedAt = parseUtcTime(json['issuedAt'], 'issuedAt');
    version = switch (json['version']) {
      final String v => PackageVersion.tryParse(v),
      _ => null,
    };
  } on FormatException catch (e) {
    return fail(ManifestProblem.malformed, e.message);
  }
  if (version == null) {
    return fail(ManifestProblem.malformed, 'version must be x.y.z');
  }
  if (notBefore != null && issuedAt.isBefore(notBefore)) {
    return fail(ManifestProblem.outdated, 'issued $issuedAt');
  }
  return switch (parseConfigValues(json)) {
    Ok(:final value) => Result.ok(
        VerifiedConfig(
          config: value,
          version: version,
          issuedAt: issuedAt,
          signature: signature,
          source: source,
        ),
      ),
    Error(:final error) => Result.error(error),
  };
}

/// Checks the sections of a config document against [configSchema] and
/// builds the parameters; missing parameters keep their built-in values.
Result<AppConfig> parseConfigValues(Map<String, Object?> json) {
  final checked = <String, Map<String, Object>>{};
  for (final MapEntry(key: section, value: specs) in configSchema.entries) {
    final values = <String, Object>{
      for (final s in specs) s.name: s.defaultValue,
    };
    final given = json[section];
    if (given != null) {
      if (given is! Map<String, Object?>) {
        return _bad('$section must be an object');
      }
      final names = {for (final s in specs) s.name: s};
      for (final MapEntry(:key, :value) in given.entries) {
        final spec = names[key];
        if (spec == null) return _bad('unknown parameter $section.$key');
        final problem = _check(spec, value);
        if (problem != null) return _bad('$section.$key $problem');
        values[key] = value!; // _check refuses null.
      }
    }
    checked[section] = values;
  }
  // Rules between values.
  final plan = checked['plan']!; // Every schema section is filled above.
  final shares = ['newShare', 'recentShare', 'oldShare'].fold<double>(
    0,
    (sum, k) => sum + (plan[k]! as num).toDouble(), // Filled above.
  );
  if ((shares - 1).abs() > _shareTolerance) {
    return _bad('plan shares must add up to 1, not $shares');
  }
  final audio = checked['audio']!; // Filled above.
  if ((audio['quietDbfs']! as num) >= (audio['noisyDbfs']! as num)) {
    return _bad('audio.quietDbfs must be below audio.noisyDbfs');
  }
  final recognition = checked['recognition']!; // Filled above.
  if ((recognition['deviceTestSmallMax']! as num) >
      (recognition['deviceTestTinyMax']! as num)) {
    return _bad('deviceTestSmallMax must not exceed deviceTestTinyMax');
  }
  return Result.ok(
    AppConfig(
      audio: AudioConfig.fromValues(audio),
      recognition: RecognitionConfig.fromValues(recognition),
      plan: PlanConfig.fromValues(plan),
      other: OtherConfig.fromValues(checked['other']!), // Filled above.
    ),
  );
}

/// Rounding slack when the plan shares are added up.
const double _shareTolerance = 1e-9;

Result<AppConfig> _bad(String message) =>
    Result.error(ConfigException(ManifestProblem.malformed, message));

String? _check(ParamSpec spec, Object? value) {
  bool inBounds(num x) =>
      (spec.min == null || x >= spec.min!) && // Checked for null first.
      (spec.max == null || x <= spec.max!); // Checked for null first.
  final bounds = '${spec.min}..${spec.max}';
  bool ascending(List<num> xs) {
    for (var i = 1; i < xs.length; i++) {
      if (xs[i] <= xs[i - 1]) return false;
    }
    return true;
  }

  switch (spec.kind) {
    case ParamKind.integer:
      if (value is! int) return 'must be a whole number';
      if (!inBounds(value)) return 'must be in $bounds';
    case ParamKind.number:
      if (value is! num) return 'must be a number';
      if (!inBounds(value)) return 'must be in $bounds';
    case ParamKind.boolean:
      if (value is! bool) return 'must be true or false';
    case ParamKind.integerList:
      if (value is! List<Object?> ||
          value.isEmpty ||
          !value.every((x) => x is int)) {
        return 'must be a non-empty list of whole numbers';
      }
      final xs = value.cast<int>();
      if (!xs.every(inBounds)) return 'values must be in $bounds';
      if (!ascending(xs)) return 'must be ascending';
    case ParamKind.numberTriple:
      if (value is! List<Object?> ||
          value.length != 3 ||
          !value.every((x) => x is num)) {
        return 'must be three numbers';
      }
      final xs = value.cast<num>();
      if (!xs.every(inBounds)) return 'values must be in $bounds';
      if (!ascending(xs)) return 'must be ascending';
    case ParamKind.range:
      if (value case {'min': final int lo, 'max': final int hi}
          when value.length == 2) {
        if (!inBounds(lo) || !inBounds(hi)) return 'must be in $bounds';
        if (lo > hi) return 'min must not exceed max';
      } else {
        return 'must be {"min": a, "max": b}';
      }
  }
  return null;
}

/// Where the app keeps the last verified config file.
///
/// Like every service it reports failures as `Result.error` instead of
/// throwing; the loader keeps working when the store does not.
abstract interface class ConfigStore {
  /// The stored file, or `null` if there is none.
  Future<Result<String?>> read();

  /// Replaces the stored file.
  Future<Result<void>> write(String source);
}

/// Where the parameters in use came from.
enum ConfigSource {
  /// Built into the app.
  builtIn,

  /// The last verified copy.
  stored,

  /// The file just received.
  received,
}

/// The parameters in use and, if a file was refused, why.
@immutable
final class ConfigState {
  /// Creates the state.
  const ConfigState(
    this.config,
    this.source, {
    this.verified,
    this.refused,
    this.storeError,
  });

  /// Parameters to use.
  final AppConfig config;

  /// Where they came from.
  final ConfigSource source;

  /// The verified file behind them, unless built in.
  final VerifiedConfig? verified;

  /// Why the last file was not taken, if it was not.
  final ConfigException? refused;

  /// The store could not be read or written; the parameters above are
  /// still usable (built-in values, or the received file kept in memory
  /// only — the app may retry storing it).
  final Exception? storeError;
}

/// Keeps the parameters: a new signed file replaces the stored copy only
/// when it is valid; otherwise the stored copy stays, and without one the
/// built-in values (docs/tz 8.8).
final class ConfigLoader {
  /// Creates the loader.
  ConfigLoader({required TrustedKeys keys, required ConfigStore store})
      : _keys = keys,
        _store = store;

  final TrustedKeys _keys;
  final ConfigStore _store;

  /// At start: the stored copy, checked again, or the built-in values —
  /// also when the store cannot be read.
  Future<ConfigState> current() async {
    final String? stored;
    switch (await _store.read()) {
      case Ok(:final value):
        stored = value;
      case Error(:final error):
        return ConfigState(
          AppConfig.defaults,
          ConfigSource.builtIn,
          storeError: error,
        );
    }
    if (stored == null) {
      return const ConfigState(AppConfig.defaults, ConfigSource.builtIn);
    }
    return switch (await verifyConfig(stored, _keys)) {
      Ok(:final value) =>
        ConfigState(value.config, ConfigSource.stored, verified: value),
      Error(:final error) => ConfigState(
          AppConfig.defaults,
          ConfigSource.builtIn,
          refused: _asConfigError(error),
        ),
    };
  }

  /// A config file from an installed `config` package: taken and stored if
  /// valid and not older than the stored copy; otherwise the parameters in
  /// use stay. If storing fails, the valid file is still used for this run
  /// and [ConfigState.storeError] says so; after a restart the previous
  /// stored copy (or the built-in values) applies until it is stored.
  Future<ConfigState> accept(String source) async {
    final now = await current();
    final result = await verifyConfig(
      source,
      _keys,
      notBefore: now.verified?.issuedAt,
    );
    switch (result) {
      case Ok(:final value):
        final stored = await _store.write(source);
        return ConfigState(
          value.config,
          ConfigSource.received,
          verified: value,
          storeError: switch (stored) {
            Ok() => null,
            Error(:final error) => error,
          },
        );
      case Error(:final error):
        return ConfigState(
          now.config,
          now.source,
          verified: now.verified,
          refused: _asConfigError(error),
          storeError: now.storeError,
        );
    }
  }
}

ConfigException _asConfigError(Exception e) => switch (e) {
      final ConfigException c => c,
      _ => ConfigException(ManifestProblem.malformed, '$e'),
    };
