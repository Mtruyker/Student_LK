import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/auth_shell.dart';
import '../../shared/widgets/auth_submit_button.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/password_field.dart';
import '../state/teacher_app_state.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _defaultsApplied = false;
  bool _isRegisterMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied) {
      return;
    }

    final appState = context.read<TeacherAppState>();
    _emailController.text = appState.defaultTeacherEmail;
    _passwordController.text = appState.defaultTeacherPassword;
    _defaultsApplied = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
    final appState = context.read<TeacherAppState>();
    if (_isRegisterMode) {
      await appState.signUp(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }

    await appState.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TeacherAppState>();
    final theme = Theme.of(context);
    final errorText = appState.authError ?? appState.loadError;

    return AuthShell(
      role: AppShellRole.teacher,
      kicker: _isRegisterMode ? 'Teacher onboarding' : 'Faculty workspace',
      title: 'Кабинет преподавателя',
      subtitle:
          'Расписание занятий, группы и сообщения кураторства собраны в одном удобном рабочем пространстве.',
      icon: Icons.cast_for_education_rounded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isRegisterMode ? 'Регистрация преподавателя' : 'Вход',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? 'Новый аккаунт получит роль teacher и создаст запись в таблице teachers.'
                    : 'Используйте преподавательский аккаунт, чтобы открыть рабочий кабинет.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (_isRegisterMode) ...<Widget>[
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'ФИО преподавателя',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (!_isRegisterMode) {
                      return null;
                    }
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Введите ФИО';
                    }
                    if (text.length < 5) {
                      return 'Слишком короткое имя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail преподавателя',
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
                  final text = value ?? '';
                  if (text.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (_isRegisterMode && text.length < 6) {
                    return 'Минимум 6 символов';
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
                label: _isRegisterMode
                    ? 'Зарегистрироваться'
                    : 'Открыть кабинет',
                isLoading: appState.isAuthenticating,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: appState.isAuthenticating
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                          });
                        },
                  child: Text(
                    _isRegisterMode
                        ? 'У меня уже есть аккаунт'
                        : 'Нет аккаунта? Регистрация',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
