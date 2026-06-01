import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/theme/app_colors.dart';
import '../shared/widgets/auth_shell.dart';
import '../shared/widgets/auth_submit_button.dart';
import '../shared/widgets/error_banner.dart';
import '../shared/widgets/password_field.dart';
import '../shared/widgets/status_banner.dart';
import '../state/student_app_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _defaultsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_defaultsApplied) {
      return;
    }

    final appState = context.read<StudentAppState>();
    _emailController.text = appState.demoEmail;
    _passwordController.text = appState.demoPassword;
    _defaultsApplied = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<StudentAppState>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _recoverPassword() async {
    final email = await _askRecoveryEmail(
      context,
      _emailController.text.trim(),
    );
    if (!mounted || email == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<StudentAppState>().sendPasswordResetEmail(email: email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<StudentAppState>();
    final errorText = appState.authError ?? appState.loadError;
    final noticeText = appState.authNotice;

    return AuthShell(
      role: AppShellRole.student,
      kicker: 'Campus OS',
      title: 'Личный кабинет студента',
      subtitle:
          'Расписание, успеваемость, документы и общение с куратором в одном спокойном и современном интерфейсе.',
      icon: Icons.school_rounded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Вход',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                appState.hasDemoCredentials
                    ? 'Для демо уже подставлены тестовые данные. Их можно заменить на реальные.'
                    : 'Введите данные аккаунта, чтобы открыть личный кабинет.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Введите e-mail';
                  }
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Проверьте формат e-mail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                onFieldSubmitted: (_) =>
                    appState.isAuthenticating ? null : _login(),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (text.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
              ),
              if (errorText != null) ...<Widget>[
                const SizedBox(height: 14),
                ErrorBanner(text: errorText),
              ],
              if (noticeText != null) ...<Widget>[
                const SizedBox(height: 14),
                StatusBanner(
                  text: noticeText,
                  tone: StatusBannerTone.success,
                ),
              ],
              const SizedBox(height: 20),
              AuthSubmitButton(
                label: 'Войти',
                isLoading: appState.isAuthenticating,
                onPressed: _login,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('Создать аккаунт'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: appState.isSendingPasswordReset
                          ? null
                          : _recoverPassword,
                      child: Text(
                        appState.isSendingPasswordReset
                            ? 'Отправляем...'
                            : 'Забыли пароль?',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _askRecoveryEmail(
  BuildContext context,
  String initialEmail,
) async {
  final controller = TextEditingController(text: initialEmail);
  String? validationError;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Восстановление доступа'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Укажите e-mail аккаунта. Мы отправим письмо со ссылкой для сброса пароля.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    errorText: validationError,
                  ),
                  onChanged: (_) {
                    if (validationError == null) {
                      return;
                    }
                    setState(() {
                      validationError = null;
                    });
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final email = controller.text.trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    setState(() {
                      validationError = 'Проверьте формат e-mail';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(email);
                },
                child: const Text('Отправить'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return result;
}
