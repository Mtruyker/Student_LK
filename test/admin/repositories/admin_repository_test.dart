import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:student_cabinet_flutter_app/admin/repositories/admin_repository.dart';
import 'package:student_cabinet_flutter_app/services/secure_session_storage.dart';

void main() {
  group('ApiAdminRepository', () {
    test('persists token after sign in', () async {
      final storage = _MemorySessionStorage();
      final repository = ApiAdminRepository(
        config: const AdminApiConfig(
          baseUrl: 'http://example.com',
          loginPath: '/admin/login',
          studentsPath: '/admin/students',
          defaultAdminEmail: 'admin@example.com',
          defaultAdminPassword: 'admin123',
        ),
        client: MockClient((http.Request request) async {
          expect(request.url.toString(), 'http://example.com/admin/login');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'token': 'admin-token',
              'role': 'admin',
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }),
        sessionStorage: storage,
      );

      await repository.signIn(
        email: 'admin@example.com',
        password: 'admin123',
      );

      expect(await storage.read('admin_access_token'), 'admin-token');
    });

    test('uses restored token for authorized requests', () async {
      final storage = _MemorySessionStorage();
      await storage.write('admin_access_token', 'restored-token');

      final repository = ApiAdminRepository(
        config: const AdminApiConfig(
          baseUrl: 'http://example.com',
          loginPath: '/admin/login',
          studentsPath: '/admin/students',
          defaultAdminEmail: 'admin@example.com',
          defaultAdminPassword: 'admin123',
        ),
        client: MockClient((http.Request request) async {
          expect(
            request.headers['Authorization'],
            'Bearer restored-token',
          );
          return http.Response(
            jsonEncode(<String, dynamic>{
              'students': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': '1',
                  'fullName': 'Test Student',
                  'group': 'P-21',
                  'email': 'test@example.com',
                  'studentId': 'STU1',
                },
              ],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }),
        sessionStorage: storage,
      );

      final restored = await repository.restoreSession();
      final students = await repository.fetchStudents();

      expect(restored, isTrue);
      expect(students, hasLength(1));
      expect(students.first.fullName, 'Test Student');
    });
  });
}

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}
