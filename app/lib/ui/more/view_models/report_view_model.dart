import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// The class names keep the view model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// «Сообщить о проблеме» (docs/tz 13.14, Б-02).
final class ReportViewModel extends ChangeNotifier {
  /// Creates the view model.
  ReportViewModel(this._repository);

  final AppUserRepository _repository;

  /// Whether the diagnostics file is attached.
  bool get withDiagnostics => _withDiagnostics;
  var _withDiagnostics = true;

  /// Whether the last sending failed.
  bool get failed => _failed;
  var _failed = false;

  /// Turns the diagnostics on or off.
  void setWithDiagnostics({required bool value}) {
    _withDiagnostics = value;
    notifyListeners();
  }

  /// Opens the share sheet with the report.
  Future<void> send() async {
    final sent = await _repository.reportProblem(
      withDiagnostics: _withDiagnostics,
    );
    _failed = sent is Error<void>;
    notifyListeners();
  }
}
