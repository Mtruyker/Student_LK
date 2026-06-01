import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_cabinet_flutter_app/shared/supabase_bootstrap.dart';

class SupabaseIntegrationTestConfig {
  const SupabaseIntegrationTestConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String studentEmail =
      String.fromEnvironment('TEST_STUDENT_EMAIL');
  static const String studentPassword =
      String.fromEnvironment('TEST_STUDENT_PASSWORD');
  static const String adminEmail = String.fromEnvironment('TEST_ADMIN_EMAIL');
  static const String adminPassword =
      String.fromEnvironment('TEST_ADMIN_PASSWORD');
  static const String teacherEmail =
      String.fromEnvironment('TEST_TEACHER_EMAIL');
  static const String teacherPassword =
      String.fromEnvironment('TEST_TEACHER_PASSWORD');

  static const bool hasSupabaseConfig =
      supabaseUrl != '' && supabaseAnonKey != '';

  static const bool canRunStudentLogin =
      hasSupabaseConfig && studentEmail != '' && studentPassword != '';

  static const bool canRunAdminLogin =
      hasSupabaseConfig && adminEmail != '' && adminPassword != '';

  static const bool canRunTeacherLogin =
      hasSupabaseConfig && teacherEmail != '' && teacherPassword != '';
}

Future<void> prepareSupabaseIntegrationTest() async {
  await ensureSupabaseInitialized();
  await Supabase.instance.client.auth.signOut();
}

Future<void> loginWithEmailAndPassword(
  WidgetTester tester, {
  required String email,
  required String password,
  required String submitButtonLabel,
}) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsAtLeastNWidgets(2));

  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, submitButtonLabel));
  await tester.pump();
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 300),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  expect(finder, findsWidgets);
}
