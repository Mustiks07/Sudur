import 'package:flutter/foundation.dart';

/// UI state and commands for the application's placeholder home screen.
final class HomeViewModel extends ChangeNotifier {
  /// Currently selected destination in the bottom navigation bar.
  int get selectedIndex => _selectedIndex;
  int _selectedIndex = 0;

  /// Selects a destination by its zero-based [index].
  void selectDestination(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
