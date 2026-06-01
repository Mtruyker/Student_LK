import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/secure_session_storage.dart';
import '../../shared/api_client.dart';
import '../../shared/app_environment.dart';
import '../../shared/exceptions.dart';
import '../models/admin_models.dart';
import 'supabase_admin_repository.dart';

class AdminApiConfig {
  final String baseUrl;
  final String loginPath;
  final String studentsPath;
  final String defaultAdminEmail;
  final String defaultAdminPassword;

  const AdminApiConfig({
    required this.baseUrl,
    required this.loginPath,
    required this.studentsPath,
    required this.defaultAdminEmail,
    required this.defaultAdminPassword,
  });

  factory AdminApiConfig.fromEnvironment() {
    return const AdminApiConfig(
      baseUrl: AppEnvironment.apiBaseUrl,
      loginPath: '/admin/login',
      studentsPath: '/admin/students',
      defaultAdminEmail: AppEnvironment.defaultAdminEmail,
      defaultAdminPassword: AppEnvironment.defaultAdminPassword,
    );
  }
}

abstract class AdminRepository {
  String get baseUrl;
  String get defaultAdminEmail;
  String get defaultAdminPassword;

  Future<bool> restoreSession();

  Future<ThemeMode?> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<List<AdminStudentSummary>> fetchStudents();

  Future<AdminStudentDetails> fetchStudent(String id);

  Future<AdminStudentDetails> updateProfile({
    required String studentId,
    required AdminStudentProfile profile,
  });

  Future<AdminStudentDetails> updateSchedule({
    required String studentId,
    required List<AdminLesson> schedule,
  });

  Future<AdminStudentDetails> saveDocument({
    required String studentId,
    String? documentId,
    required String title,
    required String status,
  });

  Future<AdminStudentDetails> updateCertificateRequestStatus({
    required String studentId,
    required String requestId,
    required String status,
  });

  Future<void> signOut();
}

AdminRepository createAdminRepository({
  SessionStorage? sessionStorage,
}) {
  if (AppEnvironment.useSupabase) {
    return SupabaseAdminRepository();
  }

  if (!AppEnvironment.enableLegacyApi) {
    throw StateError(
      'Admin console requires USE_SUPABASE=true or ENABLE_LEGACY_API=true.',
    );
  }

  final config = AdminApiConfig.fromEnvironment();
  if (config.baseUrl.trim().isEmpty) {
    throw StateError(
      'ENABLE_LEGACY_API is true, but API_BASE_URL is not configured.',
    );
  }

  return ApiAdminRepository(
    config: config,
    sessionStorage: sessionStorage,
  );
}

class ApiAdminRepository extends BaseApiClient implements AdminRepository {
  ApiAdminRepository({
    required AdminApiConfig config,
    http.Client? client,
    SessionStorage? sessionStorage,
  })  : _config = config,
        super(
          baseUrl: config.baseUrl,
          tokenStorageKey: 'admin_access_token',
          client: client,
          sessionStorage: sessionStorage,
        );

  final AdminApiConfig _config;

  @override
  String get defaultAdminEmail => _config.defaultAdminEmail;

  @override
  String get defaultAdminPassword => _config.defaultAdminPassword;

  @override
  String get baseUrl => _config.baseUrl;

  @override
  Future<ThemeMode?> getThemeMode() async {
    final value = await sessionStorage.read('theme_mode');
    if (value == null) return null;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await sessionStorage.write('theme_mode', mode.name);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.loginPath),
        headers: jsonHeaders,
        body: jsonEncode(<String, dynamic>{
          'email': email,
          'password': password,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppAuthException(
        extractMessage(
          payload,
          fallback: 'Не удалось выполнить вход администратора.',
        ),
      );
    }

    final token = extractToken(payload);
    if (token.isEmpty) {
      throw const AppAuthException(
        'Сервер не вернул token для admin-сессии.',
      );
    }
    await setAccessToken(token);
  }

  @override
  Future<List<AdminStudentSummary>> fetchStudents() async {
    final response = await guardedRequest(
      () => client.get(
        buildUri(_config.studentsPath),
        headers: authorizedHeaders(),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось загрузить список студентов.',
        ),
      );
    }

    final raw = payload['students'];
    if (raw is! List) {
      return const <AdminStudentSummary>[];
    }

    return raw
        .whereType<Map>()
        .map((item) =>
            AdminStudentSummary.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<AdminStudentDetails> fetchStudent(String id) async {
    final response = await guardedRequest(
      () => client.get(
        buildUri('${_config.studentsPath}/$id'),
        headers: authorizedHeaders(),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось загрузить профиль студента.',
        ),
      );
    }

    return AdminStudentDetails.fromJson(payload);
  }

  @override
  Future<AdminStudentDetails> updateProfile({
    required String studentId,
    required AdminStudentProfile profile,
  }) async {
    final response = await guardedRequest(
      () => client.put(
        buildUri('${_config.studentsPath}/$studentId/profile'),
        headers: authorizedJsonHeaders(),
        body: jsonEncode(profile.toUpdateJson()),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось сохранить профиль студента.',
        ),
      );
    }

    return AdminStudentDetails.fromJson(payload);
  }

  @override
  Future<AdminStudentDetails> updateSchedule({
    required String studentId,
    required List<AdminLesson> schedule,
  }) async {
    final response = await guardedRequest(
      () => client.put(
        buildUri('${_config.studentsPath}/$studentId/schedule'),
        headers: authorizedJsonHeaders(),
        body: jsonEncode(
          <String, dynamic>{
            'schedule': schedule.map((lesson) => lesson.toJson()).toList(),
          },
        ),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось сохранить расписание студента.',
        ),
      );
    }

    return AdminStudentDetails.fromJson(payload);
  }

  @override
  Future<AdminStudentDetails> saveDocument({
    required String studentId,
    String? documentId,
    required String title,
    required String status,
  }) {
    throw const AppDataException(
      'Управление документами доступно только в режиме Supabase.',
    );
  }

  @override
  Future<AdminStudentDetails> updateCertificateRequestStatus({
    required String studentId,
    required String requestId,
    required String status,
  }) {
    throw const AppDataException(
      'Обработка запросов на справки доступна только в режиме Supabase.',
    );
  }
}
