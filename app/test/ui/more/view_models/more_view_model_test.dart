import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  test('loads and updates study settings through the repository', () async {
    final repository = FakeAppUserRepository();
    final viewModel = MoreViewModel(repository);
    await viewModel.initialize();

    await viewModel.updateStudySettings(
      dailyMinutes: 20,
      strictBehavior: true,
      showFirstWord: false,
      memorizationRepeats: 4,
    );
    await viewModel.updateLanguage(AppLanguage.en);

    expect(viewModel.settings?.profile.dailyMinutes, 20);
    expect(viewModel.settings?.profile.strictBehavior, isTrue);
    expect(viewModel.settings?.profile.language, AppLanguage.en);
    expect(viewModel.settings?.memorizationRepeats, 4);
    viewModel.dispose();
  });
}
