import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_models.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/secure_session_storage.dart';
import '../shared/app_environment.dart';
import '../shared/auth_role.dart';
import '../shared/error_handler.dart';
import '../shared/exceptions.dart';
import 'student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  SupabaseStudentRepository({
    SessionStorage? sessionStorage,
  }) : _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final _client = Supabase.instance.client;
  final SessionStorage _sessionStorage;

  @override
  String get demoEmail => '';

  @override
  String get demoPassword => '';

  @override
  Future<bool> restoreSession() async {
    final session = _client.auth.currentSession;
    return session != null && _isStudentUser(_client.auth.currentUser);
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
  Future<StudentCabinetData> signIn({
    required String email,
    required String password,
  }) async {
    return ErrorHandler.instance.executeWithRetry(
      () async {
        try {
          final response = await _client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (response.user == null || !_isStudentUser(response.user)) {
            if (response.user != null) {
              await signOut();
            }
            throw const AppAuthException(
              'Этот аккаунт не является студенческим. Используйте приложение для нужной роли.',
            );
          }

          await _refreshSessionForRole(
            AppUserRole.student,
            fallbackMessage:
                'Этот аккаунт не является студенческим. Используйте приложение для нужной роли.',
          );

          return fetchCabinet();
        } on AuthException catch (e) {
          throw AppAuthException(e.message);
        } on AppAuthException {
          rethrow;
        } catch (error) {
          throw AppAuthException('Произошла ошибка при входе: ${error.toString()}');
        }
      },
      operationName: 'Student sign in',
      shouldRetry: (error) => error is! AppAuthException, // Don't retry auth errors
    );
  }

  @override
  Future<StudentCabinetData> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'fullName': fullName,
          'group': group,
          'phone': phone,
          'role': 'student',
        },
      );

      if (response.user == null) {
        throw const AppAuthException('Не удалось создать аккаунт.');
      }

      if (_client.auth.currentSession == null) {
        throw const AppAuthException(
          'Аккаунт создан. Подтвердите e-mail и войдите снова.',
        );
      }

      await _refreshSessionForRole(
        AppUserRole.student,
        fallbackMessage:
            'Аккаунт создан. Пожалуйста, войдите снова, чтобы обновить права доступа.',
      );

      return fetchCabinet();
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    } on AppAuthException {
      rethrow;
    } catch (_) {
      throw const AppAuthException('Произошла ошибка при регистрации.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppEnvironment.optionalPasswordResetRedirectUrl,
      );
    } on AuthException catch (e) {
      throw AppDataException(e.message);
    } catch (_) {
      throw const AppDataException(
        'Не удалось отправить письмо для восстановления доступа.',
      );
    }
  }

  @override
  Future<StudentCabinetData> fetchCabinet() async {
    final user = _client.auth.currentUser;
    if (user == null || !_isStudentUser(user)) {
      throw const AppAuthException(
          'Сессия истекла. Пожалуйста, войдите снова.');
    }

    final studentId = user.id;
    final isConnected = ConnectivityService.instance.isConnected;

    // If offline, try to return cached data
    if (!isConnected) {
      final cachedData = await CacheService.instance.getCachedStudentData(studentId);
      if (cachedData != null) {
        debugPrint('Returning cached data for offline mode');
        return cachedData;
      } else {
        throw const AppNetworkException(
          'Нет подключения к интернету и отсутствуют сохраненные данные.',
        );
      }
    }

    // Online mode - fetch from server with caching
    return ErrorHandler.instance.executeWithRetry(
      () async {
        try {
          final profileData =
              await _client.from('students').select().eq('id', user.id).single();

          final List<dynamic> scheduleData = await _client
              .from('schedule_lessons')
              .select()
              .eq('student_id', user.id)
              .order('weekday', ascending: true)
              .order('time', ascending: true);

          final List<dynamic> gradesData = await _client
              .from('grades')
              .select()
              .eq('student_id', user.id)
              .order('created_at', ascending: false);

          final List<dynamic> documentsData = await _client
              .from('documents')
              .select()
              .eq('student_id', user.id)
              .order('created_at', ascending: false);

          final List<dynamic> announcementsData = await _client
              .from('announcements')
              .select()
              .eq('student_id', user.id)
              .order('created_at', ascending: false);

          final List<dynamic> curatorMessagesData = await _client
              .from('curator_messages')
              .select('teacher_reply, teacher_reply_at, created_at')
              .eq('student_id', user.id)
              .order('teacher_reply_at', ascending: false)
              .order('created_at', ascending: false);

          final announcementItems = _asMapList(announcementsData)
              .map(StudentAnnouncement.fromJson)
              .toList(growable: true);
          announcementItems.insertAll(
            0,
            _asMapList(curatorMessagesData)
                .where((row) =>
                    (row['teacher_reply'] ?? '').toString().trim().isNotEmpty)
                .map(
                  (row) => StudentAnnouncement(
                    title: 'Ответ куратора',
                    description: (row['teacher_reply'] ?? '').toString(),
                    dateLabel: (row['teacher_reply_at'] ?? row['created_at'] ?? '')
                        .toString(),
                  ),
                ),
          );

          final studentData = StudentCabinetData(
            profile: StudentProfile.fromJson(_asMap(profileData)),
            schedule: _asMapList(scheduleData).map(Lesson.fromJson).toList(),
            grades: _asMapList(gradesData).map(GradeRecord.fromJson).toList(),
            documents:
                _asMapList(documentsData).map(StudentDocument.fromJson).toList(),
            announcements: announcementItems,
          );

          // Cache the fresh data
          try {
            await CacheService.instance.cacheStudentData(studentId, studentData);
            debugPrint('Cached fresh student data');
          } catch (cacheError) {
            debugPrint('Failed to cache student data: $cacheError');
            // Don't fail the request if caching fails
          }

          return studentData;
        } catch (error) {
          debugPrint('Supabase fetchCabinet error: $error');

          // If network request fails, try to return cached data as fallback
          final cachedData = await CacheService.instance.getCachedStudentData(studentId);
          if (cachedData != null) {
            debugPrint('Network failed, returning cached data as fallback');
            return cachedData;
          }

          throw const AppDataException('Не удалось загрузить данные кабинета.');
        }
      },
      operationName: 'Fetch student cabinet data',
    );
  }

  @override
  Future<StudentCabinetData> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || !_isStudentUser(user)) {
      throw const AppAuthException('Не авторизован.');
    }

    try {
      await _client.from('certificate_requests').insert(<String, dynamic>{
        'student_id': user.id,
        'type': type,
        'comment': comment,
      });

      await _client.from('documents').insert(<String, dynamic>{
        'student_id': user.id,
        'title': '$type.pdf',
        'status': 'Запрошен',
        'updated_at_label': 'Только что',
      });

      await _client.from('announcements').insert(<String, dynamic>{
        'student_id': user.id,
        'title': 'Запрос справки',
        'description': 'Ваш запрос на "$type" принят в обработку.',
        'date_label': 'сейчас',
      });

      return fetchCabinet();
    } catch (_) {
      throw const AppDataException(
        'Не удалось отправить запрос на справку.',
      );
    }
  }

  @override
  Future<StudentCabinetData> contactCurator({
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || !_isStudentUser(user)) {
      throw const AppAuthException('Не авторизован.');
    }

    try {
      final studentProfile = _asMap(
        await _client
            .from('students')
            .select('curator, curator_teacher_id')
            .eq('id', user.id)
            .single(),
      );
      final curatorName = (studentProfile['curator'] ?? '').toString().trim();
      final curatorTeacherId =
          (studentProfile['curator_teacher_id'] ?? '').toString().trim();
      if (curatorName.isEmpty || curatorTeacherId.isEmpty) {
        throw const AppDataException('У студента не указан куратор.');
      }
      await _client.from('curator_messages').insert(<String, dynamic>{
        'student_id': user.id,
        'curator_teacher_id': curatorTeacherId,
        'message': message,
      });

      await _client.from('announcements').insert(<String, dynamic>{
        'student_id': user.id,
        'title': 'Сообщение куратору',
        'description': 'Ваше сообщение отправлено.',
        'date_label': 'сейчас',
      });

      return fetchCabinet();
    } on AppDataException {
      rethrow;
    } catch (_) {
      throw const AppDataException(
        'Не удалось отправить сообщение куратору.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool _isStudentUser(User? user) {
    return userHasRole(user, AppUserRole.student);
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
}
