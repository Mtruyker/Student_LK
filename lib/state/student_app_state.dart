import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../repositories/student_repository.dart';
import '../shared/exceptions.dart';
import '../shared/helpers.dart' as shared;

enum AppTab {
  dashboard,
  schedule,
  grades,
  profile,
}

extension AppTabX on AppTab {
  int get index {
    switch (this) {
      case AppTab.dashboard:
        return 0;
      case AppTab.schedule:
        return 1;
      case AppTab.grades:
        return 2;
      case AppTab.profile:
        return 3;
    }
  }

  static AppTab fromIndex(int index) {
    switch (index) {
      case 1:
        return AppTab.schedule;
      case 2:
        return AppTab.grades;
      case 3:
        return AppTab.profile;
      default:
        return AppTab.dashboard;
    }
  }
}

class StudentAppState extends ChangeNotifier {
  StudentAppState(this._repository)
      : _selectedWeekday = _initialScheduleWeekday(DateTime.now()) {
    _restoreSession();
    _loadThemeMode();
  }

  final StudentRepository _repository;

  StudentCabinetData? _cabinetData;
  AppTab _selectedTab = AppTab.dashboard;
  late int _selectedWeekday;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAuthenticating = false;
  bool _isInitializing = true;
  bool _isRefreshing = false;
  bool _isSubmittingCertificateRequest = false;
  bool _isSendingCuratorMessage = false;
  bool _isSendingPasswordReset = false;
  String? _authError;
  String? _authNotice;
  String? _loadError;

  String get demoEmail => _repository.demoEmail;
  String get demoPassword => _repository.demoPassword;
  bool get hasDemoCredentials =>
      demoEmail.isNotEmpty && demoPassword.isNotEmpty;

  bool get isAuthenticated => _cabinetData != null;
  bool get isAuthenticating => _isAuthenticating;
  bool get isInitializing => _isInitializing;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmittingCertificateRequest => _isSubmittingCertificateRequest;
  bool get isSendingCuratorMessage => _isSendingCuratorMessage;
  bool get isSendingPasswordReset => _isSendingPasswordReset;
  String? get authError => _authError;
  String? get authNotice => _authNotice;
  String? get loadError => _loadError;
  AppTab get selectedTab => _selectedTab;
  int get selectedWeekday => _selectedWeekday;
  ThemeMode get themeMode => _themeMode;

  StudentCabinetData get cabinetData {
    final data = _cabinetData;
    if (data == null) {
      throw StateError('Student cabinet data is not loaded.');
    }
    return data;
  }

  StudentProfile get profile => cabinetData.profile;
  List<Lesson> get schedule => cabinetData.schedule;
  List<GradeRecord> get grades => cabinetData.grades;
  List<StudentDocument> get documents => cabinetData.documents;
  List<StudentAnnouncement> get announcements => cabinetData.announcements;

  List<int> get supportedWeekdays => const <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ];

  List<Lesson> get selectedLessons => _lessonsForWeekday(_selectedWeekday);
  List<Lesson> get todayLessons => _lessonsForWeekday(DateTime.now().weekday);

  Lesson? get nextLesson {
    final now = DateTime.now();
    final lessonsToday = _lessonsForWeekday(now.weekday);

    for (final lesson in lessonsToday) {
      final lessonTime = _lessonStartDateTime(now, lesson.time);
      if (lessonTime == null) {
        continue;
      }

      if (lessonTime.isAfter(now)) {
        return lesson;
      }
    }

    return null;
  }

  double get averageGrade {
    if (grades.isEmpty) {
      return 0;
    }

    final total = grades.fold<int>(0, (sum, item) => sum + item.grade);
    return total / grades.length;
  }

  GradeRecord? get strongestSubject {
    if (grades.isEmpty) {
      return null;
    }

    return grades.reduce(
      (best, item) => item.progress > best.progress ? item : best,
    );
  }

  GradeRecord? get attentionSubject {
    if (grades.isEmpty) {
      return null;
    }

    return grades.reduce(
      (weakest, item) => item.progress < weakest.progress ? item : weakest,
    );
  }

  int get availableDocumentsCount {
    return documents.where((item) => item.status != 'Требует подпись').length;
  }

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
      if (!hasStoredSession) {
        return;
      }

      _cabinetData = await _repository.fetchCabinet();
      _selectedTab = AppTab.dashboard;
      _selectedWeekday = _initialScheduleWeekday(DateTime.now());
    } on AppAuthException {
      await _resetSession();
    } on AppDataException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Не удалось восстановить сессию.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      action: () => _repository.signIn(
        email: email,
        password: password,
      ),
      fallbackError: 'Не удалось выполнить вход. Повторите попытку.',
    );
  }

  Future<void> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    await _authenticate(
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

  Future<void> _authenticate({
    required Future<StudentCabinetData> Function() action,
    required String fallbackError,
  }) async {
    _authError = null;
    _authNotice = null;
    _loadError = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      _cabinetData = await action();
      _selectedTab = AppTab.dashboard;
      _selectedWeekday = _initialScheduleWeekday(DateTime.now());
    } on AppAuthException catch (error) {
      _authError = error.message;
    } on AppDataException catch (error) {
      _authError = error.message;
    } catch (_) {
      _authError = fallbackError;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
  }) async {
    if (_isSendingPasswordReset) {
      return false;
    }

    _authError = null;
    _authNotice = null;
    _loadError = null;
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

  Future<void> refreshCabinet() async {
    if (!isAuthenticated) {
      return;
    }

    _loadError = null;
    _isRefreshing = true;
    notifyListeners();

    try {
      _cabinetData = await _repository.fetchCabinet();
    } on AppAuthException catch (error) {
      await _resetSession();
      _authError = error.message;
    } on AppDataException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Не удалось обновить данные кабинета.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  }) async {
    if (!isAuthenticated || _isSubmittingCertificateRequest) {
      return false;
    }

    _authError = null;
    _loadError = null;
    _isSubmittingCertificateRequest = true;
    notifyListeners();

    try {
      _cabinetData = await _repository.requestCertificate(
        type: type,
        comment: comment,
      );
      return true;
    } on AppAuthException catch (error) {
      await _resetSession();
      _authError = error.message;
      return false;
    } on AppDataException catch (error) {
      _loadError = error.message;
      return false;
    } catch (_) {
      _loadError = 'Не удалось отправить запрос на справку.';
      return false;
    } finally {
      _isSubmittingCertificateRequest = false;
      notifyListeners();
    }
  }

  Future<bool> contactCurator({
    required String message,
  }) async {
    if (!isAuthenticated || _isSendingCuratorMessage) {
      return false;
    }

    _authError = null;
    _loadError = null;
    _isSendingCuratorMessage = true;
    notifyListeners();

    try {
      _cabinetData = await _repository.contactCurator(
        message: message,
      );
      return true;
    } on AppAuthException catch (error) {
      await _resetSession();
      _authError = error.message;
      return false;
    } on AppDataException catch (error) {
      _loadError = error.message;
      return false;
    } catch (_) {
      _loadError = 'Не удалось отправить сообщение куратору.';
      return false;
    } finally {
      _isSendingCuratorMessage = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _resetSession();
    _authError = null;
    _authNotice = null;
    _loadError = null;
    notifyListeners();
  }

  Future<void> _resetSession() async {
    await _repository.signOut();
    _cabinetData = null;
    _isSubmittingCertificateRequest = false;
    _isSendingCuratorMessage = false;
    _isSendingPasswordReset = false;
    _selectedTab = AppTab.dashboard;
    _selectedWeekday = _initialScheduleWeekday(DateTime.now());
  }

  void clearAuthFeedback() {
    if (_authError == null && _authNotice == null) {
      return;
    }

    _authError = null;
    _authNotice = null;
    notifyListeners();
  }

  void selectTab(AppTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    _selectedTab = tab;
    notifyListeners();
  }

  void selectTabIndex(int index) {
    selectTab(AppTabX.fromIndex(index));
  }

  void selectWeekday(int weekday) {
    if (_selectedWeekday == weekday) {
      return;
    }

    _selectedWeekday = weekday;
    notifyListeners();
  }

  String weekdayLabel(int weekday) => shared.weekdayLabel(weekday);

  Color gradeColor(int grade) {
    switch (grade) {
      case 5:
        return const Color(0xFF217A4B);
      case 4:
        return const Color(0xFF2A8C82);
      case 3:
        return const Color(0xFFE1A100);
      default:
        return const Color(0xFFC85C40);
    }
  }

  List<Lesson> _lessonsForWeekday(int weekday) {
    final lessons =
        schedule.where((lesson) => lesson.weekday == weekday).toList()
          ..sort((a, b) {
            final left = _lessonStartMinutes(a.time);
            final right = _lessonStartMinutes(b.time);
            if (left != null && right != null) {
              return left.compareTo(right);
            }
            if (left != null) {
              return -1;
            }
            if (right != null) {
              return 1;
            }
            return a.time.compareTo(b.time);
          });
    return lessons;
  }
}

DateTime? _lessonStartDateTime(DateTime day, String value) {
  final startMinutes = _lessonStartMinutes(value);
  if (startMinutes == null) {
    return null;
  }

  return DateTime(
    day.year,
    day.month,
    day.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );
}

int? _lessonStartMinutes(String value) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return (hour * 60) + minute;
}

int _initialScheduleWeekday(DateTime now) {
  if (now.weekday < DateTime.monday || now.weekday > DateTime.friday) {
    return DateTime.monday;
  }

  return now.weekday;
}
