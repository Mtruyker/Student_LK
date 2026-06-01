import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/secure_session_storage.dart';
import '../../shared/auth_role.dart';
import '../../shared/exceptions.dart';
import '../models/teacher_models.dart';
import 'teacher_repository.dart';

class SupabaseTeacherRepository implements TeacherRepository {
  SupabaseTeacherRepository({
    SessionStorage? sessionStorage,
  }) : _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final _client = Supabase.instance.client;
  final SessionStorage _sessionStorage;

  @override
  String get defaultTeacherEmail => '';

  @override
  String get defaultTeacherPassword => '';

  @override
  Future<bool> restoreSession() async {
    final session = _client.auth.currentSession;
    return session != null &&
        userHasRole(_client.auth.currentUser, AppUserRole.teacher);
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
          !userHasRole(response.user, AppUserRole.teacher)) {
        if (response.user != null) {
          await signOut();
        }
        throw const AppAuthException(
          'У вас нет прав доступа преподавателя.',
        );
      }

      await _refreshSessionForRole(
        AppUserRole.teacher,
        fallbackMessage: 'У вас нет прав доступа преподавателя.',
      );
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    } on AppAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'fullName': fullName,
          'role': 'teacher',
        },
      );

      if (response.user == null) {
        throw const AppAuthException(
          'Не удалось создать аккаунт преподавателя.',
        );
      }

      if (_client.auth.currentSession == null) {
        throw const AppAuthException(
          'Аккаунт создан. Подтвердите e-mail и войдите снова.',
        );
      }

      await _refreshSessionForRole(
        AppUserRole.teacher,
        fallbackMessage:
            'Аккаунт создан. Пожалуйста, войдите снова, чтобы обновить права доступа.',
      );
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    } on AppAuthException {
      rethrow;
    }
  }

  @override
  Future<TeacherDashboardData> fetchDashboard() async {
    final user = _client.auth.currentUser;
    if (user == null || !userHasRole(user, AppUserRole.teacher)) {
      throw const AppAuthException('Сессия истекла.');
    }

    try {
      final teacher = _asMap(
        await _client.from('teachers').select().eq('id', user.id).single(),
      );
      final List<dynamic> curatorStudents = await _client
          .from('students')
          .select('id')
          .eq('curator_teacher_id', user.id);

      final List<dynamic> lessonRows = await _client
          .from('schedule_lessons')
          .select(
            'weekday, time, subject, room, lesson_type, students(group_name)',
          )
          .eq('teacher_id', user.id)
          .order('weekday', ascending: true)
          .order('time', ascending: true);

      final groupedLessons = <String, _LessonAccumulator>{};
      for (final row in _asMapList(lessonRows)) {
        final groupName = _nestedString(row, 'students', 'group_name');
        final key = [
          row['weekday'],
          row['time'],
          row['subject'],
          row['room'],
          row['lesson_type'],
        ].join('|');

        final current = groupedLessons.putIfAbsent(
          key,
          () => _LessonAccumulator(
            weekday: (row['weekday'] as num?)?.toInt() ?? 0,
            time: (row['time'] ?? '').toString(),
            subject: (row['subject'] ?? '').toString(),
            room: (row['room'] ?? '').toString(),
            type: (row['lesson_type'] ?? '').toString(),
          ),
        );

        if (groupName.isNotEmpty && !current.groups.contains(groupName)) {
          current.groups.add(groupName);
        }
      }

      final List<dynamic> messageRows = await _client
          .from('curator_messages')
          .select(
            'id, message, status, created_at, teacher_reply, teacher_reply_at, students(full_name, group_name)',
          )
          .eq('curator_teacher_id', user.id)
          .order('created_at', ascending: false);

      return TeacherDashboardData(
        profile: TeacherProfile(
          fullName: (teacher['full_name'] ?? '').toString(),
          email: (teacher['email'] ?? '').toString(),
          isCurator: curatorStudents.isNotEmpty,
          curatorStudentsCount: curatorStudents.length,
        ),
        schedule: groupedLessons.values
            .map(
              (entry) => TeacherLesson(
                weekday: entry.weekday,
                time: entry.time,
                subject: entry.subject,
                room: entry.room,
                type: entry.type,
                groups: entry.groups,
              ),
            )
            .toList(),
        curatorMessages: _asMapList(messageRows)
            .map(
              (row) => CuratorMessage(
                id: (row['id'] ?? '').toString(),
                studentName: _nestedString(row, 'students', 'full_name'),
                group: _nestedString(row, 'students', 'group_name'),
                message: (row['message'] ?? '').toString(),
                status: (row['status'] ?? 'new').toString(),
                teacherReply: (row['teacher_reply'] ?? '').toString(),
                repliedAt: (row['teacher_reply_at'] ?? '').toString(),
                dateLabel: (row['created_at'] ?? '').toString(),
                createdAt: (row['created_at'] ?? '').toString(),
              ),
            )
            .toList(),
      );
    } catch (_) {
      throw const AppDataException('Ошибка загрузки данных преподавателя.');
    }
  }

  @override
  Future<TeacherDashboardData> startCuratorMessageWork({
    required String messageId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || !userHasRole(user, AppUserRole.teacher)) {
      throw const AppAuthException('Сессия истекла.');
    }

    try {
      await _client
          .from('curator_messages')
          .update(<String, dynamic>{'status': 'processing'})
          .eq('id', messageId)
          .eq('curator_teacher_id', user.id);

      return fetchDashboard();
    } catch (_) {
      throw const AppDataException('Не удалось взять сообщение в работу.');
    }
  }

  @override
  Future<TeacherDashboardData> replyToCuratorMessage({
    required String messageId,
    required String reply,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || !userHasRole(user, AppUserRole.teacher)) {
      throw const AppAuthException('Сессия истекла.');
    }

    final normalizedReply = reply.trim();
    if (normalizedReply.isEmpty) {
      throw const AppDataException('Введите ответ студенту.');
    }

    try {
      await _client
          .from('curator_messages')
          .update(<String, dynamic>{
            'status': 'answered',
            'teacher_reply': normalizedReply,
            'teacher_reply_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('curator_teacher_id', user.id);

      return fetchDashboard();
    } catch (_) {
      throw const AppDataException('Не удалось сохранить ответ студенту.');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
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

  String _nestedString(Map<String, dynamic> row, String key, String nestedKey) {
    final nested = row[key];
    if (nested is Map<String, dynamic>) {
      return (nested[nestedKey] ?? '').toString().trim();
    }
    if (nested is Map) {
      return (nested[nestedKey] ?? '').toString().trim();
    }
    if (nested is List && nested.isNotEmpty) {
      final first = nested.first;
      if (first is Map<String, dynamic>) {
        return (first[nestedKey] ?? '').toString().trim();
      }
      if (first is Map) {
        return (first[nestedKey] ?? '').toString().trim();
      }
    }
    return '';
  }

  Future<void> _refreshSessionForRole(
    AppUserRole role, {
    required String fallbackMessage,
  }) async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {
      // Ignore refresh failures and validate available claims below.
    }

    if (!userHasRole(_client.auth.currentUser, role)) {
      await signOut();
      throw AppAuthException(fallbackMessage);
    }
  }
}

class _LessonAccumulator {
  _LessonAccumulator({
    required this.weekday,
    required this.time,
    required this.subject,
    required this.room,
    required this.type,
  });

  final int weekday;
  final String time;
  final String subject;
  final String room;
  final String type;
  final List<String> groups = <String>[];
}
