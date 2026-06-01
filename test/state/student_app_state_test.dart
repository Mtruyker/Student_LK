import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/models/student_models.dart';
import 'package:student_cabinet_flutter_app/repositories/student_repository.dart';
import 'package:student_cabinet_flutter_app/shared/exceptions.dart';
import 'package:student_cabinet_flutter_app/state/student_app_state.dart';

void main() {
  group('StudentAppState', () {
    test('sends password reset email and exposes success notice', () async {
      final repository = _FakeStudentRepository();
      final state = StudentAppState(repository);

      await _settleAsyncState();

      final result = await state.sendPasswordResetEmail(
        email: 'student@example.com',
      );

      expect(result, isTrue);
      expect(repository.passwordResetEmails, <String>['student@example.com']);
      expect(state.authError, isNull);
      expect(state.authNotice, contains('student@example.com'));
      expect(state.isSendingPasswordReset, isFalse);
    });

    test('surfaces password reset failures through authError', () async {
      final repository = _FakeStudentRepository(
        passwordResetError: const AppDataException('Reset failed.'),
      );
      final state = StudentAppState(repository);

      await _settleAsyncState();

      final result = await state.sendPasswordResetEmail(
        email: 'student@example.com',
      );

      expect(result, isFalse);
      expect(state.authError, 'Reset failed.');
      expect(state.authNotice, isNull);
      expect(state.isSendingPasswordReset, isFalse);
    });
  });
}

Future<void> _settleAsyncState() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({
    this.passwordResetError,
    StudentCabinetData? cabinetData,
  }) : _cabinetData = cabinetData ?? _sampleCabinetData();

  final Exception? passwordResetError;
  final StudentCabinetData _cabinetData;
  final List<String> passwordResetEmails = <String>[];

  @override
  String get demoEmail => '';

  @override
  String get demoPassword => '';

  @override
  Future<bool> restoreSession() async => false;

  @override
  Future<ThemeMode?> getThemeMode() async => null;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  Future<StudentCabinetData> signIn({
    required String email,
    required String password,
  }) async {
    return _cabinetData;
  }

  @override
  Future<StudentCabinetData> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    return _cabinetData;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final error = passwordResetError;
    if (error != null) {
      throw error;
    }

    passwordResetEmails.add(email);
  }

  @override
  Future<StudentCabinetData> fetchCabinet() async => _cabinetData;

  @override
  Future<StudentCabinetData> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  }) async {
    return _cabinetData;
  }

  @override
  Future<StudentCabinetData> contactCurator({
    required String message,
  }) async {
    return _cabinetData;
  }

  @override
  Future<void> signOut() async {}
}

StudentCabinetData _sampleCabinetData() {
  return const StudentCabinetData(
    profile: StudentProfile(
      fullName: 'Test Student',
      firstName: 'Test',
      group: 'P-41',
      studentId: 'ST-01',
      email: 'student@example.com',
      phone: '+70000000000',
      curator: 'Curator Name',
      attendance: 0.92,
      completedAssignments: 18,
      totalAssignments: 20,
    ),
    schedule: <Lesson>[
      Lesson(
        weekday: DateTime.monday,
        time: '09:00',
        subject: 'Math',
        room: '101',
        teacher: 'Teacher Name',
        type: 'Lecture',
      ),
    ],
    grades: <GradeRecord>[
      GradeRecord(
        subject: 'Math',
        grade: 5,
        progress: 0.95,
        completedTasks: 19,
        totalTasks: 20,
        teacher: 'Teacher Name',
      ),
    ],
    documents: <StudentDocument>[
      StudentDocument(
        id: 'doc-1',
        title: 'Certificate',
        status: 'Ready',
        updatedAt: '2026-04-11',
      ),
    ],
    announcements: <StudentAnnouncement>[
      StudentAnnouncement(
        title: 'Announcement',
        description: 'Description',
        dateLabel: '2026-04-11',
      ),
    ],
  );
}
