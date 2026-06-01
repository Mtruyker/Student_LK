import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'shared/supabase_bootstrap.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'teacher/pages/teacher_dashboard_page.dart';
import 'teacher/pages/teacher_login_page.dart';
import 'teacher/repositories/teacher_repository.dart';
import 'teacher/state/teacher_app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSupabaseInitialized();
  runApp(const TeacherConsoleApp());
}

class TeacherConsoleApp extends StatelessWidget {
  const TeacherConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherAppState>(
      create: (_) => TeacherAppState(createTeacherRepository()),
      child: Consumer<TeacherAppState>(
        builder: (context, appState, _) => MaterialApp(
          title: 'Консоль преподавателя',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AppShellRole.teacher, Brightness.light),
          darkTheme: AppTheme.build(AppShellRole.teacher, Brightness.dark),
          themeMode: appState.themeMode,
          home: const _TeacherRoot(),
        ),
      ),
    );

  }
}

class _TeacherRoot extends StatelessWidget {
  const _TeacherRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherAppState>(
      builder: (context, appState, _) {
        if (appState.isInitializing) {
          return const _StartupLoadingPage();
        }

        if (appState.isAuthenticated) {
          return const TeacherDashboardPage();
        }

        return const TeacherLoginPage();
      },
    );
  }
}

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
