import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:student_cabinet_flutter_app/main.dart';
import 'package:student_cabinet_flutter_app/pages/home_page.dart';

import 'support/supabase_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (SupabaseIntegrationTestConfig.canRunStudentLogin) {
      await prepareSupabaseIntegrationTest();
    }
  });

  testWidgets(
    'student signs in through Supabase with a real student role',
    (WidgetTester tester) async {
      await prepareSupabaseIntegrationTest();
      await tester.pumpWidget(const StudentCabinetApp());

      await waitForFinder(tester, find.byType(TextFormField));
      await loginWithEmailAndPassword(
        tester,
        email: SupabaseIntegrationTestConfig.studentEmail,
        password: SupabaseIntegrationTestConfig.studentPassword,
        submitButtonLabel: 'Войти',
      );

      await waitForFinder(tester, find.byType(HomePage));
      expect(find.byType(HomePage), findsOneWidget);
    },
    skip: !SupabaseIntegrationTestConfig.canRunStudentLogin,
  );
}
