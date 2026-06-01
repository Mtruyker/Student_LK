import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'repositories/student_repository.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'shared/supabase_bootstrap.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'state/student_app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await ensureSupabaseInitialized();
  await CacheService.instance.initialize();

  // Initialize connectivity service (no await needed)
  ConnectivityService.instance;

  runApp(const StudentCabinetApp());
}

class StudentCabinetApp extends StatelessWidget {
  const StudentCabinetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentAppState>(
      create: (_) => StudentAppState(createStudentRepository()),
      child: Consumer<StudentAppState>(
        builder: (context, appState, _) => MaterialApp(
          title: 'Личный кабинет',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(AppShellRole.student, Brightness.light),
          darkTheme: AppTheme.build(AppShellRole.student, Brightness.dark),
          themeMode: appState.themeMode,
          home: const _AppRoot(),
        ),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentAppState>(
      builder: (context, appState, _) {
        if (appState.isInitializing) {
          return const _StartupLoadingPage();
        }

        if (appState.isAuthenticated) {
          return const HomePage();
        }

        return const LoginPage();
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
