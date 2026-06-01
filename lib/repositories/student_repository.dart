import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/student_models.dart';
import '../services/secure_session_storage.dart';
import '../shared/api_client.dart';
import '../shared/app_environment.dart';
import '../shared/exceptions.dart';
import 'demo_student_repository.dart';
import 'supabase_student_repository.dart';

class ApiConfig {
  final String baseUrl;
  final String loginPath;
  final String registerPath;
  final String passwordResetPath;
  final String cabinetPath;
  final String certificateRequestPath;
  final String curatorContactPath;

  const ApiConfig({
    required this.baseUrl,
    required this.loginPath,
    required this.registerPath,
    required this.passwordResetPath,
    required this.cabinetPath,
    required this.certificateRequestPath,
    required this.curatorContactPath,
  });

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(
      baseUrl: AppEnvironment.apiBaseUrl,
      loginPath: String.fromEnvironment(
        'API_LOGIN_PATH',
        defaultValue: '/auth/login',
      ),
      registerPath: String.fromEnvironment(
        'API_REGISTER_PATH',
        defaultValue: '/auth/register',
      ),
      passwordResetPath: String.fromEnvironment(
        'API_PASSWORD_RESET_PATH',
        defaultValue: '/auth/reset-password',
      ),
      cabinetPath: String.fromEnvironment(
        'API_CABINET_PATH',
        defaultValue: '/student/cabinet',
      ),
      certificateRequestPath: String.fromEnvironment(
        'API_CERTIFICATE_REQUEST_PATH',
        defaultValue: '/student/certificate-request',
      ),
      curatorContactPath: String.fromEnvironment(
        'API_CURATOR_CONTACT_PATH',
        defaultValue: '/student/curator/contact',
      ),
    );
  }
}

abstract class StudentRepository {
  String get demoEmail;
  String get demoPassword;

  Future<bool> restoreSession();

  Future<ThemeMode?> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<StudentCabinetData> signIn({
    required String email,
    required String password,
  });

  Future<StudentCabinetData> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<StudentCabinetData> fetchCabinet();

  Future<StudentCabinetData> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  });

  Future<StudentCabinetData> contactCurator({
    required String message,
  });

  Future<void> signOut();
}

StudentRepository createStudentRepository({
  SessionStorage? sessionStorage,
}) {
  if (AppEnvironment.useSupabase) {
    return SupabaseStudentRepository();
  }

  if (AppEnvironment.enableLegacyApi) {
    final config = ApiConfig.fromEnvironment();
    if (!config.isConfigured) {
      throw StateError(
        'ENABLE_LEGACY_API is true, but API_BASE_URL is not configured.',
      );
    }

    return ApiStudentRepository(
      config: config,
      sessionStorage: sessionStorage,
    );
  }

  if (AppEnvironment.enableDemoMode) {
    return DemoStudentRepository();
  }

  throw StateError(
    'No backend is configured. Enable Supabase or explicitly enable legacy API/demo mode.',
  );
}

class ApiStudentRepository extends BaseApiClient implements StudentRepository {
  ApiStudentRepository({
    required ApiConfig config,
    http.Client? client,
    SessionStorage? sessionStorage,
  })  : _config = config,
        super(
          baseUrl: config.baseUrl,
          tokenStorageKey: 'student_access_token',
          client: client,
          sessionStorage: sessionStorage,
        );

  final ApiConfig _config;

  @override
  String get demoEmail => '';

  @override
  String get demoPassword => '';

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
  Future<StudentCabinetData> signIn({
    required String email,
    required String password,
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.loginPath),
        headers: jsonHeaders,
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppAuthException(
        extractMessage(payload, fallback: 'Не удалось выполнить вход.'),
      );
    }

    final token = extractToken(payload);
    if (token.isNotEmpty) {
      await setAccessToken(token);
    }

    final cabinetJson = _extractCabinetJson(payload);
    if (cabinetJson != null) {
      return StudentCabinetData.fromJson(cabinetJson);
    }

    return fetchCabinet();
  }

  @override
  Future<StudentCabinetData> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.registerPath),
        headers: jsonHeaders,
        body: jsonEncode(<String, String>{
          'fullName': fullName,
          'group': group,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppAuthException(
        extractMessage(payload, fallback: 'Не удалось создать аккаунт.'),
      );
    }

    final token = extractToken(payload);
    if (token.isNotEmpty) {
      await setAccessToken(token);
    }

    final cabinetJson = _extractCabinetJson(payload);
    if (cabinetJson != null) {
      return StudentCabinetData.fromJson(cabinetJson);
    }

    return fetchCabinet();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.passwordResetPath),
        headers: jsonHeaders,
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось отправить письмо для восстановления доступа.',
        ),
      );
    }
  }

  @override
  Future<StudentCabinetData> fetchCabinet() async {
    final response = await guardedRequest(
      () => client.get(
        buildUri(_config.cabinetPath),
        headers: authorizedHeaders(),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(payload, fallback: 'Не удалось загрузить кабинет.'),
      );
    }

    final cabinetJson = _extractCabinetJson(payload) ?? payload;
    return StudentCabinetData.fromJson(cabinetJson);
  }

  @override
  Future<StudentCabinetData> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.certificateRequestPath),
        headers: authorizedJsonHeaders(),
        body: jsonEncode(<String, String>{
          'type': type,
          'comment': comment,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось отправить запрос на справку.',
        ),
      );
    }

    final cabinetJson = _extractCabinetJson(payload);
    if (cabinetJson != null) {
      return StudentCabinetData.fromJson(cabinetJson);
    }

    return fetchCabinet();
  }

  @override
  Future<StudentCabinetData> contactCurator({
    required String message,
  }) async {
    final response = await guardedRequest(
      () => client.post(
        buildUri(_config.curatorContactPath),
        headers: authorizedJsonHeaders(),
        body: jsonEncode(<String, String>{
          'message': message,
        }),
      ),
    );

    final payload = decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataException(
        extractMessage(
          payload,
          fallback: 'Не удалось отправить сообщение куратору.',
        ),
      );
    }

    final cabinetJson = _extractCabinetJson(payload);
    if (cabinetJson != null) {
      return StudentCabinetData.fromJson(cabinetJson);
    }

    return fetchCabinet();
  }

  Map<String, dynamic>? _extractCabinetJson(Map<String, dynamic> json) {
    const keys = <String>[
      'cabinet',
      'data',
      'studentCabinet',
      'student_cabinet',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
      }
    }

    if (json.containsKey('profile') || json.containsKey('student')) {
      return json;
    }

    return null;
  }
}
