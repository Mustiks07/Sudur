import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// UI state fields are deliberately public for ListenableBuilder consumers.
// ignore_for_file: public_member_api_docs, unnecessary_type_name_in_constructor

/// State and commands for the stable daily plan.
final class TodayViewModel extends ChangeNotifier {
  /// Creates the ViewModel.
  TodayViewModel(this._repository, this._config);

  final AppUserRepository _repository;
  final E01Config _config;
  Timer? _skeletonTimer;

  TodayDashboardData? data;
  bool loading = false;
  bool showSkeleton = false;
  String? error;

  Future<void> initialize() => reload();

  /// Loads the plan; storage guarantees it stays unchanged for the date.
  Future<void> reload() async {
    loading = true;
    error = null;
    notifyListeners();
    _skeletonTimer = Timer(_config.skeletonDelay, () {
      showSkeleton = true;
      notifyListeners();
    });
    _accept(await _repository.loadToday());
    _skeletonTimer?.cancel();
    loading = false;
    showSkeleton = false;
    notifyListeners();
  }

  Future<void> start() async {
    final current = data;
    if (current == null || current.steps.isEmpty) return;
    await startAt(current.steps.first.id);
  }

  /// Starts the selected visible step.
  Future<void> startAt(String stepId) async {
    _accept(await _repository.startToday(stepId));
    notifyListeners();
  }

  Future<void> skip(String stepId) async {
    _accept(await _repository.skipTodayStep(stepId));
    notifyListeners();
  }

  void _accept(Result<TodayDashboardData> result) {
    switch (result) {
      case Ok(:final value):
        data = value;
        error = null;
      case Error(:final error):
        this.error = error.toString();
    }
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }
}
