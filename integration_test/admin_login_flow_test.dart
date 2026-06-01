import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:student_cabinet_flutter_app/admin/pages/admin_dashboard_page.dart';
import 'package:student_cabinet_flutter_app/main_admin.dart';

import 'support/supabase_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (SupabaseIntegrationTestConfig.canRunAdminLogin) {
      await prepareSupabaseIntegrationTest();
    }
  });

  testWidgets(
    'admin signs in through Supabase with a real admin role',
    (WidgetTester tester) async {
      await prepareSupabaseIntegrationTest();
      await tester.pumpWidget(const AdminConsoleApp());

      await waitForFinder(tester, find.byType(TextFormField));
      await loginWithEmailAndPassword(
        tester,
        email: SupabaseIntegrationTestConfig.adminEmail,
        password: SupabaseIntegrationTestConfig.adminPassword,
        submitButtonLabel: 'Открыть админ-панель',
      );

      await waitForFinder(tester, find.byType(AdminDashboardPage));
      expect(find.byType(AdminDashboardPage), findsOneWidget);
    },
    skip: !SupabaseIntegrationTestConfig.canRunAdminLogin,
  );
}
