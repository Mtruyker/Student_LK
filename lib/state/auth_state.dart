import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../repositories/student_repository.dart';
import '../shared/exceptions.dart';

/// Состояние аутентификации пользователя
class AuthState extends ChangeNotifier {
  AuthState(this._repository);

  final StudentRepository _repository;

  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _isInitializing = true;
  bool _isSendingPasswordReset = false;
  String? _authError;
  String? _authNotice;
  StudentProfile? _userProfile;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  bool get isInitializing => _isInitializing;
  bool get isSendingPasswordReset => _isSendingPasswordReset;
  String? get authError => _authError;
  String? get authNotice => _authNotice;
  StudentProfile? get userProfile => _userProfile;

  String get demoEmail => _repository.demoEmail;
  String get demoPassword => _repository.demoPassword;
  bool get hasDemoCredentials =>
      demoEmail.isNotEmpty && demoPassword.isNotEmpty;

  /// Инициализация состояния аутентификации
  Future<void> initialize() async {
    try {
      final hasStoredSession = await _repository.restoreSession();
      if (hasStoredSession) {
        // Получаем базовую информацию о пользователе
        final cabinetData = await _repository.fetchCabinet();
        _userProfile = cabinetData.profile;
        _isAuthenticated = true;
      }
    } on AppAuthException {
      await _resetSession();
    } catch (_) {
      // Игнорируем ошибки загрузки данных на этапе инициализации
      // Они будут обработаны в соответствующих состояниях
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Вход в систему
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      action: () => _repository.signIn(
        email: email,
        password: password,
      ),
      fallbackError: 'Не удалось выполнить вход. Повторите попытку.',
    );
  }

  /// Регистрация
  Future<bool> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    return _authenticate(
      action: () => _repository.signUp(
        fullName: fullName,
        group: group,
        email: email,
        password: password,
        phone: phone,
      ),
      fallbackError: 'Не удалось создать аккаунт. Повторите попытку.',
    );
  }

  /// Отправка письма для восстановления пароля
  Future<bool> sendPasswordResetEmail({
    required String email,
  }) async {
    if (_isSendingPasswordReset) {
      return false;
    }

    _authError = null;
    _authNotice = null;
    _isSendingPasswordReset = true;
    notifyListeners();

    try {
      await _repository.sendPasswordResetEmail(email: email);
      _authNotice =
          'Мы отправили письмо для восстановления доступа на $email. Проверьте почту и папку "Спам".';
      return true;
    } on AppAuthException catch (error) {
      _authError = error.message;
      return false;
    } on AppDataException catch (error) {
      _authError = error.message;
      return false;
    } catch (_) {
      _authError = 'Не удалось отправить письмо для восстановления доступа.';
      return false;
    } finally {
      _isSendingPasswordReset = false;
      notifyListeners();
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    await _resetSession();
    _authError = null;
    _authNotice = null;
    notifyListeners();
  }

  /// Очистка сообщений об ошибках и уведомлений
  void clearAuthFeedback() {
    if (_authError == null && _authNotice == null) {
      return;
    }

    _authError = null;
    _authNotice = null;
    notifyListeners();
  }

  /// Обновление профиля пользователя
  void updateUserProfile(StudentProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  /// Общий метод для аутентификации
  Future<bool> _authenticate({
    required Future<StudentCabinetData> Function() action,
    required String fallbackError,
  }) async {
    _authError = null;
    _authNotice = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      final cabinetData = await action();
      _userProfile = cabinetData.profile;
      _isAuthenticated = true;
      return true;
    } on AppAuthException catch (error) {
      _authError = error.message;
      return false;
    } on AppDataException catch (error) {
      _authError = error.message;
      return false;
    } catch (_) {
      _authError = fallbackError;
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Сброс сессии
  Future<void> _resetSession() async {
    await _repository.signOut();
    _isAuthenticated = false;
    _userProfile = null;
    _isSendingPasswordReset = false;
  }
}