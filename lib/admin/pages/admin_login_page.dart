import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/auth_shell.dart';
import '../../shared/widgets/auth_submit_button.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/password_field.dart';
import '../state/admin_app_state.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _defaultsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied) {
      return;
    }

    final appState = context.read<AdminAppState>();
    _emailController.text = appState.defaultAdminEmail;
    _passwordController.text = appState.defaultAdminPassword;
    _defaultsApplied = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<AdminAppState>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AdminAppState>();
    final theme = Theme.of(context);
    final errorText = appState.authError ?? appState.loadError;

    return AuthShell(
      role: AppShellRole.admin,
      kicker: 'Control Center',
      title: 'Админ-панель',
      subtitle:
          'Управление студентами, данными профиля и расписанием в одном рабочем интерфейсе без визуального шума.',
      icon: Icons.space_dashboard_rounded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Вход администратора',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Используйте аккаунт, которому назначена роль admin в Supabase Auth.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail администратора',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Введите e-mail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                onFieldSubmitted: (_) =>
                    appState.isAuthenticating ? null : _submit(),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),
              if (errorText != null) ...<Widget>[
                const SizedBox(height: 14),
                ErrorBanner(text: errorText),
              ],
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Открыть админ-панель',
                isLoading: appState.isAuthenticating,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
