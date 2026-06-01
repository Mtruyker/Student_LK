import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/secure_session_storage.dart';
import '../../shared/auth_role.dart';
import '../../shared/exceptions.dart';
import '../models/admin_models.dart';
import 'admin_repository.dart';

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({
    SessionStorage? sessionStorage,
  }) : _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final _client = Supabase.instance.client;
  final SessionStorage _sessionStorage;

  @override
  String get baseUrl => '';

  @override
  String get defaultAdminEmail => '';

  @override
  String get defaultAdminPassword => '';

  @override
  Future<bool> restoreSession() async {
    final session = _client.auth.currentSession;
    return session != null &&
        userHasRole(_client.auth.currentUser, AppUserRole.admin);
  }

  @override
  Future<ThemeMode?> getThemeMode() async {
    final value = await _sessionStorage.read('theme_mode');
    if (value == null) return null;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _sessionStorage.write('theme_mode', mode.name);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null ||
          !userHasRole(response.user, AppUserRole.admin)) {
        if (response.user != null) {
          await signOut();
        }
        throw const AppAuthException(
          'У вас нет прав доступа администратора.',
        );
      }
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    } on AppAuthException {
      rethrow;
    }
  }

  @override
  Future<List<AdminStudentSummary>> fetchStudents() async {
    try {
      final List<dynamic> data = await _client
          .from('students')
          .select('id, full_name, group_name, email, student_identifier')
          .order('full_name');

      return _asMapList(data)
          .map(AdminStudentSummary.fromJson)
          .toList(growable: false);
    } catch (_) {
      throw const AppDataException('Ошибка загрузки списка студентов.');
    }
  }

  @override
  Future<AdminStudentDetails> fetchStudent(String id) async {
    try {
      final profile =
          await _client.from('students').select().eq('id', id).single();
      final List<dynamic> schedule = await _client
          .from('schedule_lessons')
          .select()
          .eq('student_id', id)
          .order('weekday', ascending: true)
          .order('time', ascending: true);
      final List<dynamic> documents = await _client
          .from('documents')
          .select()
          .eq('student_id', id)
          .order('created_at', ascending: false);
      final List<dynamic> certificateRequests = await _client
          .from('certificate_requests')
          .select()
          .eq('student_id', id)
          .order('created_at', ascending: false);

      return AdminStudentDetails(
        id: id,
        profile: AdminStudentProfile.fromJson(_asMap(profile)),
        schedule: _asMapList(schedule).map(AdminLesson.fromJson).toList(),
        documents:
            _asMapList(documents).map(AdminStudentDocument.fromJson).toList(),
        certificateRequests: _asMapList(certificateRequests)
            .map(AdminCertificateRequest.fromJson)
            .toList(),
      );
    } catch (_) {
      throw const AppDataException('Ошибка загрузки данных студента.');
    }
  }

  @override
  Future<AdminStudentDetails> updateProfile({
    required String studentId,
    required AdminStudentProfile profile,
  }) async {
    try {
      final curatorTeacherId = await _resolveCuratorTeacherId(profile.curator);
      await _client.from('students').update(<String, dynamic>{
        'full_name': profile.fullName,
        'first_name': _firstNameFromFullName(profile.fullName),
        'group_name': profile.group,
        'phone': profile.phone,
        'curator': profile.curator,
        'curator_teacher_id': curatorTeacherId,
        'attendance': profile.attendance,
        'completed_assignments': profile.completedAssignments,
        'total_assignments': profile.totalAssignments,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', studentId);

      return fetchStudent(studentId);
    } on AppDataException {
      rethrow;
    } catch (_) {
      throw const AppDataException('Ошибка обновления профиля.');
    }
  }

  @override
  Future<AdminStudentDetails> updateSchedule({
    required String studentId,
    required List<AdminLesson> schedule,
  }) async {
    try {
      await _client
          .from('schedule_lessons')
          .delete()
          .eq('student_id', studentId);

      if (schedule.isNotEmpty) {
        final teacherIdsByName = <String, String?>{};
        for (final lesson in schedule) {
          final teacherName = lesson.teacher.trim();
          if (teacherName.isEmpty ||
              teacherIdsByName.containsKey(teacherName)) {
            continue;
          }

          teacherIdsByName[teacherName] = await _resolveTeacherIdByName(
            teacherName,
          );
        }

        await _client.from('schedule_lessons').insert(
              schedule
                  .map(
                    (lesson) => <String, dynamic>{
                      'student_id': studentId,
                      'teacher_id': teacherIdsByName[lesson.teacher.trim()],
                      'weekday': lesson.weekday,
                      'time': lesson.time,
                      'subject': lesson.subject,
                      'room': lesson.room,
                      'teacher': lesson.teacher,
                      'lesson_type': lesson.type,
                    },
                  )
                  .toList(growable: false),
            );
      }

      return fetchStudent(studentId);
    } catch (_) {
      throw const AppDataException('Ошибка обновления расписания.');
    }
  }

  @override
  Future<AdminStudentDetails> saveDocument({
    required String studentId,
    String? documentId,
    required String title,
    required String status,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedStatus = status.trim();
    if (normalizedTitle.isEmpty || normalizedStatus.isEmpty) {
      throw const AppDataException(
        'У документа должны быть заполнены название и статус.',
      );
    }

    try {
      final payload = <String, dynamic>{
        'student_id': studentId,
        'title': normalizedTitle,
        'status': normalizedStatus,
        'updated_at_label': _formatTimestampLabel(DateTime.now()),
      };

      final normalizedDocumentId = documentId?.trim() ?? '';
      if (normalizedDocumentId.isEmpty) {
        await _client.from('documents').insert(payload);
      } else {
        await _client
            .from('documents')
            .update(payload)
            .eq('id', normalizedDocumentId);
      }

      return fetchStudent(studentId);
    } catch (_) {
      throw const AppDataException('Ошибка сохранения документа.');
    }
  }

  @override
  Future<AdminStudentDetails> updateCertificateRequestStatus({
    required String studentId,
    required String requestId,
    required String status,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus.isEmpty) {
      throw const AppDataException('Статус запроса не указан.');
    }

    try {
      final request = _asMap(
        await _client
            .from('certificate_requests')
            .select()
            .eq('id', requestId)
            .eq('student_id', studentId)
            .single(),
      );

      await _client.from('certificate_requests').update(
          <String, dynamic>{'status': normalizedStatus}).eq('id', requestId);

      final documentTitle = '${(request['type'] ?? 'Справка').toString()}.pdf';
      final documentStatus = _documentStatusFromRequestStatus(normalizedStatus);
      final updatedAtLabel = _formatTimestampLabel(DateTime.now());

      final List<dynamic> existingDocuments = await _client
          .from('documents')
          .select('id')
          .eq('student_id', studentId)
          .eq('title', documentTitle)
          .limit(1);

      if (existingDocuments.isEmpty) {
        await _client.from('documents').insert(<String, dynamic>{
          'student_id': studentId,
          'title': documentTitle,
          'status': documentStatus,
          'updated_at_label': updatedAtLabel,
        });
      } else {
        final existingDocumentId =
            (_asMap(existingDocuments.first)['id'] ?? '').toString();
        if (existingDocumentId.isNotEmpty) {
          await _client.from('documents').update(<String, dynamic>{
            'status': documentStatus,
            'updated_at_label': updatedAtLabel,
          }).eq('id', existingDocumentId);
        }
      }

      return fetchStudent(studentId);
    } catch (_) {
      throw const AppDataException('Ошибка обновления статуса запроса.');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String?> _resolveTeacherIdByName(String fullName) async {
    final normalized = fullName.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final List<dynamic> data = await _client
        .from('teachers')
        .select('id')
        .eq('full_name', normalized)
        .limit(1);
    if (data.isEmpty) {
      return null;
    }

    return (_asMap(data.first)['id'])?.toString();
  }

  Future<String?> _resolveCuratorTeacherId(String curatorName) async {
    final normalized = curatorName.trim();
    if (normalized.isEmpty || normalized == 'Не назначен') {
      return null;
    }

    final teacherId = await _resolveTeacherIdByName(normalized);
    if (teacherId == null) {
      throw const AppDataException(
        'Куратор должен совпадать с ФИО существующего преподавателя.',
      );
    }

    return teacherId;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  String _firstNameFromFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '';
    }
    return parts.first;
  }

  String _documentStatusFromRequestStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'ready':
        return 'Готов';
      case 'processing':
      case 'in_progress':
        return 'В работе';
      default:
        return 'Запрошен';
    }
  }

  String _formatTimestampLabel(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Обновлено $day.$month.$year $hour:$minute';
  }
}
