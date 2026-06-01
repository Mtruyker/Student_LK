import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:student_cabinet_flutter_app/pages/login_page.dart';
import 'package:student_cabinet_flutter_app/repositories/demo_student_repository.dart';
import 'package:student_cabinet_flutter_app/shared/theme/app_colors.dart';
import 'package:student_cabinet_flutter_app/shared/theme/app_theme.dart';
import 'package:student_cabinet_flutter_app/state/student_app_state.dart';

void main() {
  testWidgets('shows login screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<StudentAppState>(
        create: (_) => StudentAppState(DemoStudentRepository()),
        child: MaterialApp(
          theme: AppTheme.build(AppShellRole.student),
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
