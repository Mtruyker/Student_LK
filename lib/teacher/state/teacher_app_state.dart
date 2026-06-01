import 'package:flutter/material.dart';

import '../models/teacher_models.dart';
import '../repositories/teacher_repository.dart';
import '../../shared/exceptions.dart';
import '../../shared/helpers.dart' as shared;

class TeacherAppState extends ChangeNotifier {
  TeacherAppState(this._repository) {
    _restoreSession();
    _loadThemeMode();
  }

  final TeacherRepository _repository;

  bool _hasSession = false;
  bool _isInitializing = true;
  bool _isAuthenticating = false;
  bool _isLoadingDashboard = false;
  bool _isUpdatingCuratorMessage = false;
  ThemeMode _themeMode = ThemeMode.system;
  String? _activeCuratorMessageId;
  String? _authError;
  String? _loadError;
  String? _actionNotice;
  TeacherDashboardData? _dashboard;

  String get defaultTeacherEmail => _repository.defaultTeacherEmail;
  String get defaultTeacherPassword => _repository.defaultTeacherPassword;

  bool get isAuthenticated => _hasSession;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticating => _isAuthenticating;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isUpdatingCuratorMessage => _isUpdatingCuratorMessage;
  String? get authError => _authError;
  String? get loadError => _loadError;
  String? get actionNotice => _actionNotice;
  TeacherDashboardData? get dashboard => _dashboard;
  String? get activeCuratorMessageId => _activeCuratorMessageId;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final mode = await _repository.getThemeMode();
    if (mode != null && _themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(mode);
  }

  Future<void> _restoreSession() async {
    try {
      final hasStoredSession = await _repository.restoreSession();
      _hasSession = hasStoredSession;
      if (hasStoredSession) {
        await refreshDashboard();
      }
    } catch (_) {
      await _clearSession();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _authError = null;
    _loadError = null;
    _actionNotice = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      _hasSession = true;
      await refreshDashboard();
    } on AppAuthException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } on AppDataException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } catch (_) {
      _authError = 'Не удалось выполнить вход преподавателя.';
      _hasSession = false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _authError = null;
    _loadError = null;
    _actionNotice = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      _hasSession = true;
      await refreshDashboard();
    } on AppAuthException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } on AppDataException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } catch (_) {
      _authError = 'Не удалось зарегистрировать преподавателя.';
      _hasSession = false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    if (!_hasSession) {
      return;
    }

    _loadError = null;
    _actionNotice = null;
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      _dashboard = await _repository.fetchDashboard();
    } on AppAuthException catch (error) {
      _loadError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Не удалось загрузить данные преподавателя.';
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<bool> startCuratorMessageWork(String messageId) async {
    if (!_hasSession || _isUpdatingCuratorMessage) {
      return false;
    }

    _loadError = null;
    _actionNotice = null;
    _isUpdatingCuratorMessage = true;
    _activeCuratorMessageId = messageId;
    notifyListeners();

    try {
      _dashboard = await _repository.startCuratorMessageWork(
        messageId: messageId,
      );
      _actionNotice = 'Сообщение переведено в работу.';
      return true;
    } on AppAuthException catch (error) {
      _loadError = error.message;
      await _clearSession();
      return false;
    } on AppDataException catch (error) {
      _loadError = error.message;
      return false;
    } catch (_) {
      _loadError = 'Не удалось обновить статус сообщения.';
      return false;
    } finally {
      _isUpdatingCuratorMessage = false;
      _activeCuratorMessageId = null;
      notifyListeners();
    }
  }

  Future<bool> replyToCuratorMessage({
    required String messageId,
    required String reply,
  }) async {
    if (!_hasSession || _isUpdatingCuratorMessage) {
      return false;
    }

    _loadError = null;
    _actionNotice = null;
    _isUpdatingCuratorMessage = true;
    _activeCuratorMessageId = messageId;
    notifyListeners();

    try {
      _dashboard = await _repository.replyToCuratorMessage(
        messageId: messageId,
        reply: reply,
      );
      _actionNotice = 'Ответ сохранен. Студент увидит его в кабинете.';
      return true;
    } on AppAuthException catch (error) {
      _loadError = error.message;
      await _clearSession();
      return false;
    } on AppDataException catch (error) {
      _loadError = error.message;
      return false;
    } catch (_) {
      _loadError = 'Не удалось сохранить ответ студенту.';
      return false;
    } finally {
      _isUpdatingCuratorMessage = false;
      _activeCuratorMessageId = null;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _clearSession();
    _isAuthenticating = false;
    _isLoadingDashboard = false;
    _isUpdatingCuratorMessage = false;
    _activeCuratorMessageId = null;
    _authError = null;
    _loadError = null;
    _actionNotice = null;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _repository.signOut();
    _hasSession = false;
    _dashboard = null;
    _isUpdatingCuratorMessage = false;
    _activeCuratorMessageId = null;
  }

  bool isUpdatingMessage(String messageId) {
    return _isUpdatingCuratorMessage && _activeCuratorMessageId == messageId;
  }

  void clearActionNotice() {
    if (_actionNotice == null) {
      return;
    }
    _actionNotice = null;
    notifyListeners();
  }

  String weekdayLabel(int weekday) => shared.weekdayLabel(weekday);
}
