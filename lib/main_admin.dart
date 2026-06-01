import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/pages/admin_dashboard_page.dart';
import 'admin/pages/admin_login_page.dart';
import 'admin/repositories/admin_repository.dart';
import 'admin/state/admin_app_state.dart';
import 'shared/supabase_bootstrap.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSupabaseInitialized();
  runApp(const AdminConsoleApp());
}

class AdminConsoleApp extends StatelessWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminAppState>(
      create: (_) => AdminAppState(createAdminRepository()),
      child: Consumer<AdminAppState>(
        builder: (context, appState, _) => MaterialApp(
          title: 'Админ-панель',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AppShellRole.admin, Brightness.light),
          darkTheme: AppTheme.build(AppShellRole.admin, Brightness.dark),
          themeMode: appState.themeMode,
          home: const _AdminRoot(),
        ),
      ),
    );
  }
}

class _AdminRoot extends StatelessWidget {
  const _AdminRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAppState>(
      builder: (context, appState, _) {
        if (appState.isInitializing) {
          return const _StartupLoadingPage();
        }

        if (appState.isAuthenticated) {
          return const AdminDashboardPage();
        }

        return const AdminLoginPage();
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
