import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  test('start and skip update the visible stable plan', () async {
    final repository = FakeAppUserRepository();
    final viewModel = TodayViewModel(repository, const E01Config());

    await viewModel.initialize();
    await viewModel.start();
    expect(viewModel.data?.inProgress, isTrue);

    await viewModel.skip('step-1');
    expect(viewModel.data?.steps, isEmpty);
    expect(viewModel.data?.condition.name, 'completed');
    viewModel.dispose();
  });
}
