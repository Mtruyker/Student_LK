import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../repositories/admin_repository.dart';
import '../../shared/exceptions.dart';

class AdminAppState extends ChangeNotifier {
  AdminAppState(this._repository) {
    _restoreSession();
    _loadThemeMode();
  }

  final AdminRepository _repository;

  bool _isAuthenticating = false;
  bool _isInitializing = true;
  bool _isLoadingStudents = false;
  bool _isLoadingStudentDetails = false;
  bool _isSavingProfile = false;
  bool _isSavingSchedule = false;
  bool _isSavingDocuments = false;
  bool _isBulkImporting = false;
  ThemeMode _themeMode = ThemeMode.system;
  String? _authError;
  String? _loadError;
  String? _saveError;
  String? _bulkImportError;

  List<AdminStudentSummary> _students = const <AdminStudentSummary>[];
  String? _selectedStudentId;
  AdminStudentDetails? _selectedStudent;

  String get apiBaseUrl => _repository.baseUrl;
  String get defaultAdminEmail => _repository.defaultAdminEmail;
  String get defaultAdminPassword => _repository.defaultAdminPassword;

  bool get isAuthenticated => _hasSession;
  bool get isAuthenticating => _isAuthenticating;
  bool get isInitializing => _isInitializing;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingStudentDetails => _isLoadingStudentDetails;
  bool get isSavingProfile => _isSavingProfile;
  bool get isSavingSchedule => _isSavingSchedule;
  bool get isSavingDocuments => _isSavingDocuments;
  bool get isBulkImporting => _isBulkImporting;
  String? get authError => _authError;
  String? get loadError => _loadError;
  String? get saveError => _saveError;
  String? get bulkImportError => _bulkImportError;
  List<AdminStudentSummary> get students => _students;
  String? get selectedStudentId => _selectedStudentId;
  AdminStudentDetails? get selectedStudent => _selectedStudent;
  ThemeMode get themeMode => _themeMode;

  bool _hasSession = false;

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
        await refreshStudents(selectFirstIfNeeded: true);
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
    _saveError = null;
    _bulkImportError = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      _hasSession = true;
      await refreshStudents(selectFirstIfNeeded: true);
    } on AppAuthException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } on AppDataException catch (error) {
      _authError = error.message;
      _hasSession = false;
    } catch (_) {
      _authError = 'Не удалось выполнить вход администратора.';
      _hasSession = false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _clearSession();
    _authError = null;
    _loadError = null;
    _saveError = null;
    _bulkImportError = null;
    notifyListeners();
  }

  Future<void> refreshStudents({
    bool selectFirstIfNeeded = false,
  }) async {
    if (!_hasSession) {
      return;
    }

    _loadError = null;
    _isLoadingStudents = true;
    notifyListeners();

    try {
      final loaded = await _repository.fetchStudents();
      _students = loaded;

      if (_students.isEmpty) {
        _selectedStudentId = null;
        _selectedStudent = null;
      } else if (_selectedStudentId == null && selectFirstIfNeeded) {
        await selectStudent(_students.first.id);
      } else if (_selectedStudentId != null) {
        final stillExists =
            _students.any((item) => item.id == _selectedStudentId);
        if (!stillExists) {
          _selectedStudentId = _students.first.id;
          await selectStudent(_selectedStudentId!);
        }
      }
    } on AppAuthException catch (error) {
      _loadError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Не удалось загрузить список студентов.';
    } finally {
      _isLoadingStudents = false;
      notifyListeners();
    }
  }

  Future<void> selectStudent(String studentId) async {
    if (!_hasSession) {
      return;
    }

    _selectedStudentId = studentId;
    _loadError = null;
    _isLoadingStudentDetails = true;
    notifyListeners();

    try {
      _selectedStudent = await _repository.fetchStudent(studentId);
    } on AppAuthException catch (error) {
      _loadError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Не удалось загрузить данные студента.';
    } finally {
      _isLoadingStudentDetails = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(AdminStudentProfile profile) async {
    final studentId = _selectedStudentId;
    if (!_hasSession || studentId == null) {
      return;
    }

    _saveError = null;
    _isSavingProfile = true;
    notifyListeners();

    try {
      final updated = await _repository.updateProfile(
        studentId: studentId,
        profile: profile,
      );
      _selectedStudent = updated;
      await refreshStudents();
    } on AppAuthException catch (error) {
      _saveError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _saveError = error.message;
    } catch (_) {
      _saveError = 'Не удалось сохранить профиль студента.';
    } finally {
      _isSavingProfile = false;
      notifyListeners();
    }
  }

  Future<void> saveSchedule(List<AdminLesson> schedule) async {
    final studentId = _selectedStudentId;
    if (!_hasSession || studentId == null) {
      return;
    }

    _saveError = null;
    _isSavingSchedule = true;
    notifyListeners();

    try {
      final updated = await _repository.updateSchedule(
        studentId: studentId,
        schedule: schedule,
      );
      _selectedStudent = updated;
    } on AppAuthException catch (error) {
      _saveError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _saveError = error.message;
    } catch (_) {
      _saveError = 'Не удалось сохранить расписание студента.';
    } finally {
      _isSavingSchedule = false;
      notifyListeners();
    }
  }

  Future<void> saveDocument({
    String? documentId,
    required String title,
    required String status,
  }) async {
    final studentId = _selectedStudentId;
    if (!_hasSession || studentId == null) {
      return;
    }

    _saveError = null;
    _isSavingDocuments = true;
    notifyListeners();

    try {
      final updated = await _repository.saveDocument(
        studentId: studentId,
        documentId: documentId,
        title: title,
        status: status,
      );
      _selectedStudent = updated;
    } on AppAuthException catch (error) {
      _saveError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _saveError = error.message;
    } catch (_) {
      _saveError = 'Не удалось сохранить документ.';
    } finally {
      _isSavingDocuments = false;
      notifyListeners();
    }
  }

  Future<void> updateCertificateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final studentId = _selectedStudentId;
    if (!_hasSession || studentId == null) {
      return;
    }

    _saveError = null;
    _isSavingDocuments = true;
    notifyListeners();

    try {
      final updated = await _repository.updateCertificateRequestStatus(
        studentId: studentId,
        requestId: requestId,
        status: status,
      );
      _selectedStudent = updated;
    } on AppAuthException catch (error) {
      _saveError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _saveError = error.message;
    } catch (_) {
      _saveError = 'Не удалось обновить статус запроса.';
    } finally {
      _isSavingDocuments = false;
      notifyListeners();
    }
  }

  Future<BulkScheduleImportResult> applySchedulesToAllStudents(
    Map<String, List<AdminLesson>> schedulesByNormalizedGroup,
  ) async {
    if (!_hasSession) {
      const result = BulkScheduleImportResult(
        totalStudents: 0,
        matchedStudents: 0,
        updatedStudents: 0,
        skippedStudents: 0,
        failedStudents: <String>[],
      );
      _bulkImportError = 'Сессия администратора истекла. Войдите снова.';
      notifyListeners();
      return result;
    }

    _bulkImportError = null;
    _isBulkImporting = true;
    notifyListeners();

    final failedStudents = <String>[];
    var total = 0;
    var matched = 0;
    var updated = 0;
    var skipped = 0;
    var refreshSelected = false;

    try {
      if (_students.isEmpty) {
        _students = await _repository.fetchStudents();
      }

      total = _students.length;
      for (final student in _students) {
        final normalizedGroup = _normalizeGroup(student.group);
        final schedule = schedulesByNormalizedGroup[normalizedGroup];
        if (schedule == null || schedule.isEmpty) {
          skipped += 1;
          continue;
        }

        matched += 1;
        try {
          await _repository.updateSchedule(
            studentId: student.id,
            schedule: schedule,
          );
          updated += 1;
          if (student.id == _selectedStudentId) {
            refreshSelected = true;
          }
        } on AppAuthException catch (error) {
          _bulkImportError = error.message;
          await _clearSession();
          failedStudents.add('${student.fullName} (${student.group})');
          break;
        } on AppDataException catch (error) {
          failedStudents.add(
            '${student.fullName} (${student.group}): ${error.message}',
          );
        } catch (_) {
          failedStudents.add(
            '${student.fullName} (${student.group}): неизвестная ошибка',
          );
        }
      }

      if (refreshSelected && _selectedStudentId != null && _hasSession) {
        try {
          _selectedStudent =
              await _repository.fetchStudent(_selectedStudentId!);
        } catch (_) {
          // Ignore refresh errors, summary result still useful.
        }
      }
    } on AppAuthException catch (error) {
      _bulkImportError = error.message;
      await _clearSession();
    } on AppDataException catch (error) {
      _bulkImportError = error.message;
    } catch (_) {
      _bulkImportError = 'Не удалось применить расписание для всех студентов.';
    } finally {
      _isBulkImporting = false;
      notifyListeners();
    }

    return BulkScheduleImportResult(
      totalStudents: total,
      matchedStudents: matched,
      updatedStudents: updated,
      skippedStudents: skipped,
      failedStudents: failedStudents,
    );
  }

  static String _normalizeGroup(String value) {
    final lowered = value.toLowerCase().trim();
    return lowered.replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
  }

  bool get hasSession => _hasSession;

  Future<void> _clearSession() async {
    await _repository.signOut();
    _hasSession = false;
    _students = const <AdminStudentSummary>[];
    _selectedStudentId = null;
    _selectedStudent = null;
    _isSavingDocuments = false;
  }
}

class BulkScheduleImportResult {
  const BulkScheduleImportResult({
    required this.totalStudents,
    required this.matchedStudents,
    required this.updatedStudents,
    required this.skippedStudents,
    required this.failedStudents,
  });

  final int totalStudents;
  final int matchedStudents;
  final int updatedStudents;
  final int skippedStudents;
  final List<String> failedStudents;

  int get failedCount => failedStudents.length;
}
