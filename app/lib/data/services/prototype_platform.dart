import 'package:flutter/services.dart';

/// Android-only provisioning and explicit metadata sharing for the prototype.
class PrototypePlatform {
  static const _channel = MethodChannel('sudur/prototype');

  /// App-specific external directory populated by the owner using adb.
  Future<String> root() async {
    final path = await _channel.invokeMethod<String>('root');
    if (path == null) throw StateError('prototypeDirectoryUnavailable');
    return path;
  }

  /// Shares timing JSON only, after an explicit user action.
  Future<void> share(String json) => _channel.invokeMethod<void>('share', json);
}
