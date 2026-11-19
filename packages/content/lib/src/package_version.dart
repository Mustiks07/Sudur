import 'package:meta/meta.dart';

/// A version `major.minor.patch` of a package or of the app (docs/tz 12.3).
@immutable
final class PackageVersion implements Comparable<PackageVersion> {
  /// Creates a version.
  const PackageVersion(this.major, this.minor, this.patch);

  /// Parses `major.minor.patch`; `null` if [text] is anything else.
  static PackageVersion? tryParse(String text) {
    if (!_pattern.hasMatch(text)) return null;
    final parts = text.split('.').map(int.parse).toList();
    return PackageVersion(parts[0], parts[1], parts[2]);
  }

  static final RegExp _pattern =
      RegExp(r'^(0|[1-9]\d{0,8})(\.(0|[1-9]\d{0,8})){2}$');

  /// Major number.
  final int major;

  /// Minor number.
  final int minor;

  /// Patch number.
  final int patch;

  @override
  int compareTo(PackageVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  /// Whether this is newer than [other].
  bool operator >(PackageVersion other) => compareTo(other) > 0;

  /// Whether this is older than [other].
  bool operator <(PackageVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is PackageVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
