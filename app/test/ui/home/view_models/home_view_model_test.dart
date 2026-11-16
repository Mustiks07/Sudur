import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';

void main() {
  test('selectDestination updates the selected index and notifies', () {
    var notificationCount = 0;
    final viewModel = HomeViewModel()
      ..addListener(() => notificationCount += 1)
      ..selectDestination(3);

    expect(viewModel.selectedIndex, 3);
    expect(notificationCount, 1);
  });

  test('selectDestination does not notify for the selected destination', () {
    var notificationCount = 0;
    final viewModel = HomeViewModel()
      ..addListener(() => notificationCount += 1)
      ..selectDestination(0);

    expect(viewModel.selectedIndex, 0);
    expect(notificationCount, 0);
  });
}
