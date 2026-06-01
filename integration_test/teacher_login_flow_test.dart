import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:student_cabinet_flutter_app/main_teacher.dart';
import 'package:student_cabinet_flutter_app/teacher/pages/teacher_dashboard_page.dart';

import 'support/supabase_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (SupabaseIntegrationTestConfig.canRunTeacherLogin) {
      await prepareSupabaseIntegrationTest();
    }
  });

  testWidgets(
    'teacher signs in through Supabase with a real teacher role',
    (WidgetTester tester) async {
      await prepareSupabaseIntegrationTest();
      await tester.pumpWidget(const TeacherConsoleApp());

      await waitForFinder(tester, find.byType(TextFormField));
      await loginWithEmailAndPassword(
        tester,
        email: SupabaseIntegrationTestConfig.teacherEmail,
        password: SupabaseIntegrationTestConfig.teacherPassword,
        submitButtonLabel: 'Открыть кабинет',
      );

      await waitForFinder(tester, find.byType(TeacherDashboardPage));
      expect(find.byType(TeacherDashboardPage), findsOneWidget);
    },
    skip: !SupabaseIntegrationTestConfig.canRunTeacherLogin,
  );
}
