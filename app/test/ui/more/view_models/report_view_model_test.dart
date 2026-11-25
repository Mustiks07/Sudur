import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/ui/more/view_models/report_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  test('the report goes with or without diagnostics', () async {
    final user = FakeAppUserRepository();
    final viewModel = ReportViewModel(user);
    expect(viewModel.withDiagnostics, isTrue);
    await viewModel.send();
    viewModel.setWithDiagnostics(value: false);
    await viewModel.send();
    expect(user.reports, [true, false]);
    expect(viewModel.failed, isFalse);
  });
}
