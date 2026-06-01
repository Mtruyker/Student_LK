import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/shared/exceptions.dart';
import 'package:student_cabinet_flutter_app/teacher/models/teacher_models.dart';
import 'package:student_cabinet_flutter_app/teacher/repositories/teacher_repository.dart';
import 'package:student_cabinet_flutter_app/teacher/state/teacher_app_state.dart';

void main() {
  group('TeacherAppState', () {
    test('replies to curator message and updates dashboard data', () async {
      final repository = _FakeTeacherRepository();
      final state = TeacherAppState(repository);

      await _settleAsyncState();
      await state.signIn(
        email: 'teacher@example.com',
        password: 'secret',
      );

      final result = await state.replyToCuratorMessage(
        messageId: 'message-1',
        reply: 'Please bring the application tomorrow.',
      );

      expect(result, isTrue);
      expect(repository.replyMessageId, 'message-1');
      expect(
        repository.replyText,
        'Please bring the application tomorrow.',
      );
      expect(state.actionNotice, isNotNull);
      expect(state.isUpdatingCuratorMessage, isFalse);
      expect(state.activeCuratorMessageId, isNull);
      expect(
        state.dashboard?.curatorMessages.single.teacherReply,
        'Please bring the application tomorrow.',
      );
      expect(
        state.dashboard?.curatorMessages.single.status,
        'answered',
      );
    });

    test('stores repository error when reply fails', () async {
      final repository = _FakeTeacherRepository(
        replyError: const AppDataException('Reply failed.'),
      );
      final state = TeacherAppState(repository);

      await _settleAsyncState();
      await state.signIn(
        email: 'teacher@example.com',
        password: 'secret',
      );

      final result = await state.replyToCuratorMessage(
        messageId: 'message-1',
        reply: 'Follow up later.',
      );

      expect(result, isFalse);
      expect(state.loadError, 'Reply failed.');
      expect(state.isUpdatingCuratorMessage, isFalse);
      expect(state.activeCuratorMessageId, isNull);
    });
  });
}

Future<void> _settleAsyncState() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeTeacherRepository implements TeacherRepository {
  _FakeTeacherRepository({
    this.replyError,
    TeacherDashboardData? initialDashboard,
  }) : _dashboard = initialDashboard ?? _sampleDashboard();

  final Exception? replyError;
  TeacherDashboardData _dashboard;
  String? replyMessageId;
  String? replyText;

  @override
  String get defaultTeacherEmail => '';

  @override
  String get defaultTeacherPassword => '';

  @override
  Future<bool> restoreSession() async => false;

  @override
  Future<ThemeMode?> getThemeMode() async => null;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {}

  @override
  Future<TeacherDashboardData> fetchDashboard() async => _dashboard;

  @override
  Future<TeacherDashboardData> startCuratorMessageWork({
    required String messageId,
  }) async {
    _dashboard = TeacherDashboardData(
      profile: _dashboard.profile,
      schedule: _dashboard.schedule,
      curatorMessages: _dashboard.curatorMessages
          .map(
            (message) => message.id == messageId
                ? CuratorMessage(
                    id: message.id,
                    studentName: message.studentName,
                    group: message.group,
                    message: message.message,
                    status: 'processing',
                    teacherReply: message.teacherReply,
                    repliedAt: message.repliedAt,
                    dateLabel: message.dateLabel,
                    createdAt: message.createdAt,
                  )
                : message,
          )
          .toList(growable: false),
    );

    return _dashboard;
  }

  @override
  Future<TeacherDashboardData> replyToCuratorMessage({
    required String messageId,
    required String reply,
  }) async {
    final error = replyError;
    if (error != null) {
      throw error;
    }

    replyMessageId = messageId;
    replyText = reply;
    _dashboard = TeacherDashboardData(
      profile: _dashboard.profile,
      schedule: _dashboard.schedule,
      curatorMessages: _dashboard.curatorMessages
          .map(
            (message) => message.id == messageId
                ? CuratorMessage(
                    id: message.id,
                    studentName: message.studentName,
                    group: message.group,
                    message: message.message,
                    status: 'answered',
                    teacherReply: reply,
                    repliedAt: '2026-04-11 10:30',
                    dateLabel: message.dateLabel,
                    createdAt: message.createdAt,
                  )
                : message,
          )
          .toList(growable: false),
    );

    return _dashboard;
  }

  @override
  Future<void> signOut() async {}
}

TeacherDashboardData _sampleDashboard() {
  return const TeacherDashboardData(
    profile: TeacherProfile(
      fullName: 'Teacher Name',
      email: 'teacher@example.com',
      isCurator: true,
      curatorStudentsCount: 12,
    ),
    schedule: <TeacherLesson>[
      TeacherLesson(
        weekday: DateTime.monday,
        time: '10:00',
        subject: 'Physics',
        room: '204',
        type: 'Lecture',
        groups: <String>['P-41'],
      ),
    ],
    curatorMessages: <CuratorMessage>[
      CuratorMessage(
        id: 'message-1',
        studentName: 'Student Name',
        group: 'P-41',
        message: 'Need help with certificate.',
        status: 'new',
        teacherReply: '',
        repliedAt: '',
        dateLabel: '2026-04-11',
        createdAt: '2026-04-11T09:00:00',
      ),
    ],
  );
}
