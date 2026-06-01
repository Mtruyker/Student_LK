import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/secure_session_storage.dart';
import '../../shared/api_client.dart';
import '../../shared/app_environment.dart';
import '../../shared/exceptions.dart';
import '../models/teacher_models.dart';
import 'supabase_teacher_repository.dart';

class TeacherApiConfig {
  final String baseUrl;
  final String registerPath;
  final String loginPath;
  final String dashboardPath;
  final String defaultTeacherEmail;
  final String defaultTeacherPassword;

  const TeacherApiConfig({
    required this.baseUrl,
    required this.registerPath,
    required this.loginPath,
    required this.dashboardPath,
    required this.defaultTeacherEmail,
    required this.defaultTeacherPassword,
  });

  factory TeacherApiConfig.fromEnvironment() {
    return const TeacherApiConfig(
      baseUrl: AppEnvironment.apiBaseUrl,
      registerPath: '/teacher/register',
      loginPath: '/teacher/login',
      dashboardPath: '/teacher/dashboard',
      defaultTeacherEmail: AppEnvironment.defaultTeacherEmail,
      defaultTeacherPassword: AppEnvironment.defaultTeacherPassword,
    );
  }
}

abstract class TeacherRepository {
  String get defaultTeacherEmail;
  String get defaultTeacherPassword;

  Future<bool> restoreSession();

  Future<ThemeMode?> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<TeacherDashboardData> fetchDashboard();

  Future<TeacherDashboardData> startCuratorMessageWork({
    required String messageId,
  });

  Future<TeacherDashboardData> replyToCuratorMessage({
    required String messageId,
    required String reply,
  });

  Future<void> signOut();
}

TeacherRepository createTeacherRepository({
  SessionStorage? sessionStorage,
}) {
  if (AppEnvironment.useSupabase) {
    return SupabaseTeacherRepository();
  }

  if (!AppEnvironment.enableLegacyApi) {
    throw StateError(
      'Teacher console requires USE_SUPABASE=true or ENABLE_LEGACY_API=true.',
    );
  }

  final config = TeacherApiConfig.fromEnvironment();
  if (config.baseUrl.trim().isEmpty) {
    throw StateError(
      'ENABLE_LEGACY_API is true, but API_BASE_URL is not configured.',
    );
  }

  return ApiTeacherRepository(
    config: config,
    sessionStorage: sessionStorage,
  );
}

class ApiTeacherRepository extends BaseApiClient implements TeacherRepository {
  ApiTeacherRepository({
    required TeacherApiConfig config,
    http.Client? client,
    SessionStorage? sessionStorage,
  })  : _config = config,
        super(
          baseUrl: config.baseUrl,
          tokenStorageKey: 'teacher_access_token',
          client: client,
          sessionStorage: sessionStorage,
        );

  final TeacherApiConfig _config;

  @override
  String get defaultTeacherEmail => _config.defaultTeacherEmail;

  @override
  String get defaultTeacherPassword => _config.defaultTeacherPassword;

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
          fallback: 'Не удалось выполнить вход преподавателя.',
        ),
      );
    }

    final token = extractToken(payload);
    if (token.isEmpty) {
      throw const AppAuthException(
        'Сервер не вернул token для teacher-сессии.',
      );
    }

    await setAccessToken(token);
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.registerPath),
        headers: jsonHeaders,
        body: jsonEncode(<String, dynamic>{
          'fullName': fullName,
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
          fallback: 'Не удалось зарегистрировать преподавателя.',
        ),
      );
    }

    final token = extractToken(payload);
    if (token.isEmpty) {
      throw const AppAuthException(
        'Сервер не вернул token для teacher-сессии.',
      );
    }

    await setAccessToken(token);
  }

  @override
  Future<TeacherDashboardData> fetchDashboard() async {
    final response = await guardedRequest(
      () => client.get(
        buildUri(_config.dashboardPath),
        headers: authorizedHeaders(),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось загрузить данные преподавателя.',
        ),
      );
    }

    return TeacherDashboardData.fromJson(payload);
  }

  @override
  Future<TeacherDashboardData> startCuratorMessageWork({
    required String messageId,
  }) {
    throw const AppDataException(
      'Обработка сообщений куратора доступна только в режиме Supabase.',
    );
  }

  @override
  Future<TeacherDashboardData> replyToCuratorMessage({
    required String messageId,
    required String reply,
  }) {
    throw const AppDataException(
      'Ответы студентам доступны только в режиме Supabase.',
    );
  }
}
