import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'config.dart';
import 'demo_student_store.dart';

class StudentConflictException implements Exception {
  final String message;

  const StudentConflictException(this.message);
}

class TeacherConflictException implements Exception {
  final String message;

  const TeacherConflictException(this.message);
}

class StudentAuthRecord {
  final String id;
  final String email;
  final String studentIdentifier;

  const StudentAuthRecord({
    required this.id,
    required this.email,
    required this.studentIdentifier,
  });
}

class TeacherAuthRecord {
  final String id;
  final String email;
  final String fullName;

  const TeacherAuthRecord({
    required this.id,
    required this.email,
    required this.fullName,
  });
}

class PostgresStudentStore {
  PostgresStudentStore._(
    this._connection,
    this._config,
  );

  Connection _connection;
  final ServerConfig _config;
  Future<void>? _reconnectInProgress;

  static Future<PostgresStudentStore> connect(ServerConfig config) async {
    final connection = await Connection.openFromUrl(config.databaseUrl);
    final store = PostgresStudentStore._(connection, config);
    await store._initialize();
    return store;
  }

  Future<void> close() async {
    await _connection.close();
  }

  Future<bool> ping() async {
    final result = await _runWithReconnect(
      (connection) => connection.execute('SELECT 1'),
    );
    return result.isNotEmpty && result.first.first == 1;
  }

  Future<StudentAuthRecord?> authenticate({
    required String email,
    required String password,
  }) async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            id::text AS id,
            email,
            student_identifier
          FROM students
          WHERE lower(email) = lower(@email)
            AND password_hash = crypt(@password, password_hash)
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      ),
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first.toColumnMap();
    return StudentAuthRecord(
      id: row['id']!.toString(),
      email: row['email']!.toString(),
      studentIdentifier: row['student_identifier']!.toString(),
    );
  }

  Future<StudentAuthRecord> registerStudent({
    required String fullName,
    required String groupName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedFullName = fullName.trim();
    final normalizedGroup = groupName.trim();
    final normalizedPhone = phone.trim();

    final exists = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT 1
          FROM students
          WHERE lower(email) = lower(@email)
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{'email': normalizedEmail},
      ),
    );

    if (exists.isNotEmpty) {
      throw const StudentConflictException(
        'Пользователь с таким e-mail уже зарегистрирован.',
      );
    }

    final studentIdentifier = _generateStudentIdentifier();
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          INSERT INTO students (
            email,
            password_hash,
            full_name,
            first_name,
            group_name,
            student_identifier,
            phone,
            curator,
            attendance,
            completed_assignments,
            total_assignments,
            schedule,
            grades,
            documents,
            announcements
          ) VALUES (
            @email,
            crypt(@password, gen_salt('bf')),
            @full_name,
            @first_name,
            @group_name,
            @student_identifier,
            @phone,
            @curator,
            0,
            0,
            0,
            CAST(@schedule AS jsonb),
            CAST(@grades AS jsonb),
            CAST(@documents AS jsonb),
            CAST(@announcements AS jsonb)
          )
          RETURNING id::text AS id, email, student_identifier
          ''',
        ),
        parameters: <String, dynamic>{
          'email': normalizedEmail,
          'password': password,
          'full_name': normalizedFullName,
          'first_name': _extractFirstName(normalizedFullName),
          'group_name': normalizedGroup,
          'student_identifier': studentIdentifier,
          'phone': normalizedPhone,
          'curator': 'Куратор будет назначен',
          'schedule': jsonEncode(_defaultSchedule()),
          'grades': jsonEncode(<Map<String, dynamic>>[]),
          'documents': jsonEncode(_defaultDocuments()),
          'announcements': jsonEncode(_defaultAnnouncements()),
        },
      ),
    );

    final row = result.first.toColumnMap();
    return StudentAuthRecord(
      id: row['id']!.toString(),
      email: row['email']!.toString(),
      studentIdentifier: row['student_identifier']!.toString(),
    );
  }

  Future<TeacherAuthRecord?> authenticateTeacher({
    required String email,
    required String password,
  }) async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            id::text AS id,
            email,
            full_name
          FROM teachers
          WHERE lower(email) = lower(@email)
            AND email IS NOT NULL
            AND password_hash IS NOT NULL
            AND password_hash = crypt(@password, password_hash)
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      ),
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first.toColumnMap();
    return TeacherAuthRecord(
      id: row['id']!.toString(),
      email: row['email']!.toString(),
      fullName: row['full_name']!.toString(),
    );
  }

  Future<TeacherAuthRecord> registerTeacher({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedFullName = fullName.trim();
    try {
      return await _runTxWithReconnect((session) async {
        final emailRows = await session.execute(
          Sql.named(
            '''
            SELECT id::text AS id
            FROM teachers
            WHERE lower(email) = lower(@email)
            LIMIT 1
            ''',
          ),
          parameters: <String, dynamic>{'email': normalizedEmail},
        );
        if (emailRows.isNotEmpty) {
          throw const TeacherConflictException(
            'Пользователь с таким e-mail уже зарегистрирован.',
          );
        }

        final nameRows = await session.execute(
          Sql.named(
            '''
            SELECT
              id::text AS id,
              email,
              full_name
            FROM teachers
            WHERE lower(full_name) = lower(@full_name)
            ORDER BY created_at ASC
            LIMIT 1
            ''',
          ),
          parameters: <String, dynamic>{'full_name': normalizedFullName},
        );

        if (nameRows.isNotEmpty) {
          final existing = nameRows.first.toColumnMap();
          final existingEmail = existing['email']?.toString().trim() ?? '';
          if (existingEmail.isNotEmpty &&
              !_equalsIgnoreCase(existingEmail, normalizedEmail)) {
            throw const TeacherConflictException(
              'Преподаватель с таким ФИО уже зарегистрирован.',
            );
          }

          final updated = await session.execute(
            Sql.named(
              '''
              UPDATE teachers
              SET
                email = @email,
                password_hash = crypt(@password, gen_salt('bf')),
                full_name = @full_name,
                updated_at = NOW()
              WHERE id::text = @id
              RETURNING id::text AS id, email, full_name
              ''',
            ),
            parameters: <String, dynamic>{
              'id': existing['id']?.toString() ?? '',
              'email': normalizedEmail,
              'password': password,
              'full_name': normalizedFullName,
            },
          );
          final row = updated.first.toColumnMap();
          return TeacherAuthRecord(
            id: row['id']!.toString(),
            email: row['email']!.toString(),
            fullName: row['full_name']!.toString(),
          );
        }

        final inserted = await session.execute(
          Sql.named(
            '''
            INSERT INTO teachers (
              email,
              password_hash,
              full_name
            ) VALUES (
              @email,
              crypt(@password, gen_salt('bf')),
              @full_name
            )
            RETURNING id::text AS id, email, full_name
            ''',
          ),
          parameters: <String, dynamic>{
            'email': normalizedEmail,
            'password': password,
            'full_name': normalizedFullName,
          },
        );

        final row = inserted.first.toColumnMap();
        return TeacherAuthRecord(
          id: row['id']!.toString(),
          email: row['email']!.toString(),
          fullName: row['full_name']!.toString(),
        );
      });
    } on TeacherConflictException {
      rethrow;
    } catch (error) {
      if (_isTeacherUniqueViolation(error)) {
        throw const TeacherConflictException(
          'Пользователь с таким e-mail уже зарегистрирован.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCabinetById(String id) async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            id::text AS id,
            full_name,
            first_name,
            group_name,
            student_identifier,
            email,
            phone,
            curator,
            attendance,
            completed_assignments,
            total_assignments,
            schedule::text AS schedule,
            grades::text AS grades,
            documents::text AS documents,
            announcements::text AS announcements
          FROM students
          WHERE id::text = @id
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{'id': id},
      ),
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first.toColumnMap();
    final schedule = await _loadStudentSchedule(
      id,
      legacyScheduleJson: row['schedule']?.toString(),
    );
    return <String, dynamic>{
      'profile': <String, dynamic>{
        'fullName': row['full_name'],
        'firstName': row['first_name'],
        'group': row['group_name'],
        'studentId': row['student_identifier'],
        'email': row['email'],
        'phone': row['phone'],
        'curator': row['curator'],
        'attendance': row['attendance'],
        'completedAssignments': row['completed_assignments'],
        'totalAssignments': row['total_assignments'],
      },
      'schedule': schedule,
      'grades': _decodeJsonList(row['grades']?.toString()),
      'documents': _decodeJsonList(row['documents']?.toString()),
      'announcements': _decodeJsonList(row['announcements']?.toString()),
    };
  }

  Future<List<Map<String, dynamic>>> listStudentsForAdmin() async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        '''
        SELECT
          id::text AS id,
          full_name,
          group_name,
          email,
          student_identifier
        FROM students
        ORDER BY full_name ASC, created_at ASC
        ''',
      ),
    );

    return result
        .map(
          (row) => <String, dynamic>{
            'id': row[0]?.toString() ?? '',
            'fullName': row[1]?.toString() ?? '',
            'group': row[2]?.toString() ?? '',
            'email': row[3]?.toString() ?? '',
            'studentId': row[4]?.toString() ?? '',
          },
        )
        .toList();
  }

  Future<bool> updateStudentProfile({
    required String id,
    required String fullName,
    required String groupName,
    required String email,
    required String phone,
    required String curator,
    required double attendance,
    required int completedAssignments,
    required int totalAssignments,
  }) async {
    final normalizedAttendance = attendance > 1 ? attendance / 100 : attendance;
    final clampedAttendance = normalizedAttendance.clamp(0.0, 1.0);

    try {
      final result = await _runWithReconnect(
        (connection) => connection.execute(
          Sql.named(
            '''
            UPDATE students
            SET
              full_name = @full_name,
              first_name = @first_name,
              group_name = @group_name,
              email = @email,
              phone = @phone,
              curator = @curator,
              attendance = @attendance,
              completed_assignments = @completed_assignments,
              total_assignments = @total_assignments,
              updated_at = NOW()
            WHERE id::text = @id
            RETURNING id::text
            ''',
          ),
          parameters: <String, dynamic>{
            'id': id,
            'full_name': fullName.trim(),
            'first_name': _extractFirstName(fullName.trim()),
            'group_name': groupName.trim(),
            'email': email.trim().toLowerCase(),
            'phone': phone.trim(),
            'curator': curator.trim(),
            'attendance': clampedAttendance,
            'completed_assignments':
                completedAssignments < 0 ? 0 : completedAssignments,
            'total_assignments': totalAssignments < 0 ? 0 : totalAssignments,
          },
        ),
      );

      return result.isNotEmpty;
    } catch (error) {
      if (_isUniqueViolation(error)) {
        throw const StudentConflictException(
          'Пользователь с таким e-mail уже зарегистрирован.',
        );
      }
      rethrow;
    }
  }

  Future<bool> replaceStudentSchedule({
    required String id,
    required List<Map<String, dynamic>> schedule,
  }) async {
    final normalized = _normalizeSchedulePayload(schedule);
    return _runTxWithReconnect(
      (session) => _replaceStudentScheduleInSession(
        session,
        studentId: id,
        schedule: normalized,
      ),
    );
  }

  Future<Map<String, dynamic>?> createCertificateRequest({
    required String id,
    required String certificateType,
    String comment = '',
  }) async {
    final cabinet = await getCabinetById(id);
    if (cabinet == null) {
      return null;
    }

    final normalizedType = certificateType.trim().isEmpty
        ? 'Справка об обучении'
        : certificateType.trim();
    final normalizedComment = comment.trim();

    final documents = _cloneList(cabinet['documents']);
    final announcements = _cloneList(cabinet['announcements']);
    final now = DateTime.now();
    final dateLabel = _dateLabel(now);

    documents.insert(
      0,
      <String, dynamic>{
        'title': '$normalizedType.pdf',
        'status': 'Запрошен',
        'updatedAt': 'Заявка отправлена $dateLabel',
      },
    );

    final descriptionBuffer = StringBuffer(
      'Запрос на "$normalizedType" отправлен в учебную часть.',
    );
    if (normalizedComment.isNotEmpty) {
      descriptionBuffer.write(' Комментарий: $normalizedComment');
    }

    announcements.insert(
      0,
      <String, dynamic>{
        'title': 'Запрос справки принят',
        'description': descriptionBuffer.toString(),
        'dateLabel': 'сейчас',
      },
    );

    final updated = await _updateDocumentsAndAnnouncements(
      id: id,
      documents: documents,
      announcements: announcements,
    );
    if (!updated) {
      return null;
    }

    return getCabinetById(id);
  }

  Future<Map<String, dynamic>?> sendMessageToCurator({
    required String id,
    required String message,
  }) async {
    final cabinet = await getCabinetById(id);
    if (cabinet == null) {
      return null;
    }

    final normalizedMessage = message.trim();
    final profile = cabinet['profile'] as Map<String, dynamic>? ?? const {};
    final studentName = profile['fullName']?.toString().trim() ?? '';
    final groupName = profile['group']?.toString().trim() ?? '';
    final curatorName = profile['curator']?.toString().trim() ?? '';
    final curatorTeacherId = await _findTeacherIdByName(curatorName);

    await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          INSERT INTO curator_messages (
            student_id,
            student_name,
            group_name,
            curator_teacher_id,
            curator_name,
            message
          ) VALUES (
            CAST(@student_id AS uuid),
            @student_name,
            @group_name,
            CAST(@curator_teacher_id AS uuid),
            @curator_name,
            @message
          )
          ''',
        ),
        parameters: <String, dynamic>{
          'student_id': id,
          'student_name': studentName,
          'group_name': groupName,
          'curator_teacher_id': curatorTeacherId,
          'curator_name': curatorName,
          'message': normalizedMessage,
        },
      ),
    );

    final announcements = _cloneList(cabinet['announcements']);

    announcements.insert(
      0,
      <String, dynamic>{
        'title': 'Сообщение куратору отправлено',
        'description':
            'Ваше обращение передано куратору: "$normalizedMessage".',
        'dateLabel': 'сейчас',
      },
    );

    final updated = await _updateDocumentsAndAnnouncements(
      id: id,
      documents: _cloneList(cabinet['documents']),
      announcements: announcements,
    );
    if (!updated) {
      return null;
    }

    return getCabinetById(id);
  }

  Future<Map<String, dynamic>> getTeacherDashboard({
    required String teacherId,
  }) async {
    final teacher = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            id::text AS id,
            full_name,
            email
          FROM teachers
          WHERE id::text = @id
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'id': teacherId,
        },
      ),
    );
    if (teacher.isEmpty) {
      throw StateError('Teacher not found.');
    }
    final teacherRow = teacher.first.toColumnMap();
    final normalizedTeacherName =
        teacherRow['full_name']?.toString().trim() ?? '';
    final teacherEmail = teacherRow['email']?.toString().trim() ?? '';
    final normalizedTeacherId = teacherRow['id']?.toString() ?? teacherId;

    final scheduleSource = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            students.group_name,
            schedule_lessons.weekday,
            schedule_lessons.start_time,
            schedule_lessons.end_time,
            schedule_lessons.room,
            schedule_lessons.lesson_type,
            subjects.name AS subject_name
          FROM schedule_lessons
          INNER JOIN students ON students.id = schedule_lessons.student_id
          INNER JOIN subjects ON subjects.id = schedule_lessons.subject_id
          WHERE schedule_lessons.teacher_id::text = @teacher_id
          ORDER BY
            schedule_lessons.weekday ASC,
            schedule_lessons.start_time ASC,
            schedule_lessons.end_time ASC,
            subjects.name ASC
          ''',
        ),
        parameters: <String, dynamic>{
          'teacher_id': normalizedTeacherId,
        },
      ),
    );

    final lessonsByKey = <String, Map<String, dynamic>>{};
    for (final row in scheduleSource) {
      final columns = row.toColumnMap();
      final groupName = columns['group_name']?.toString().trim() ?? '';
      final weekday = _toInt(columns['weekday']);
      final startTime = _asTime(columns['start_time']);
      final endTime = _asTime(columns['end_time']);
      final subject = columns['subject_name']?.toString().trim() ?? '';
      final room = columns['room']?.toString().trim() ?? '';
      final type = columns['lesson_type']?.toString().trim() ?? '';

      if (groupName.isEmpty ||
          weekday == null ||
          weekday < 1 ||
          weekday > 7 ||
          startTime == null ||
          endTime == null ||
          subject.isEmpty ||
          room.isEmpty ||
          type.isEmpty) {
        continue;
      }

      final time = _formatLessonTime(startTime, endTime);
      final key = '$weekday|$time|$subject|$room|$type';
      final entry = lessonsByKey.putIfAbsent(
        key,
        () => <String, dynamic>{
          'weekday': weekday,
          'time': time,
          'subject': subject,
          'room': room,
          'teacher': normalizedTeacherName,
          'type': type,
          'groups': <String>[],
        },
      );
      final groups = entry['groups'] as List<String>;
      if (!groups.contains(groupName)) {
        groups.add(groupName);
        groups.sort();
      }
    }

    final lessons = lessonsByKey.values.toList()
      ..sort((left, right) {
        final weekdayDiff =
            (left['weekday'] as int) - (right['weekday'] as int);
        if (weekdayDiff != 0) {
          return weekdayDiff;
        }
        final timeDiff =
            (left['time'] as String).compareTo(right['time'] as String);
        if (timeDiff != 0) {
          return timeDiff;
        }
        return (left['subject'] as String)
            .compareTo(right['subject'] as String);
      });

    final curatorCountResult = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT COUNT(*)::int AS count
          FROM students
          WHERE lower(curator) = lower(@curator_name)
          ''',
        ),
        parameters: <String, dynamic>{
          'curator_name': normalizedTeacherName,
        },
      ),
    );
    final curatorStudentsCount = _toInt(curatorCountResult.first.first) ?? 0;

    final messagesResult = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            id::text AS id,
            student_name,
            group_name,
            message,
            created_at
          FROM curator_messages
          WHERE
            curator_teacher_id::text = @teacher_id OR
            (
              curator_teacher_id IS NULL AND
              lower(curator_name) = lower(@curator_name)
            )
          ORDER BY created_at DESC
          LIMIT 200
          ''',
        ),
        parameters: <String, dynamic>{
          'teacher_id': normalizedTeacherId,
          'curator_name': normalizedTeacherName,
        },
      ),
    );

    final messages = messagesResult.map((row) {
      final columns = row.toColumnMap();
      final createdAt = columns['created_at'];
      return <String, dynamic>{
        'id': columns['id']?.toString() ?? '',
        'studentName': columns['student_name']?.toString() ?? '',
        'group': columns['group_name']?.toString() ?? '',
        'message': columns['message']?.toString() ?? '',
        'createdAt': createdAt?.toString() ?? '',
        'dateLabel': _dateLabelFromDb(createdAt),
      };
    }).toList();

    return <String, dynamic>{
      'profile': <String, dynamic>{
        'id': normalizedTeacherId,
        'fullName': normalizedTeacherName,
        'email': teacherEmail,
        'isCurator': curatorStudentsCount > 0,
        'curatorStudentsCount': curatorStudentsCount,
      },
      'schedule': lessons,
      'curatorMessages': messages,
    };
  }

  Future<bool> _updateDocumentsAndAnnouncements({
    required String id,
    required List<Map<String, dynamic>> documents,
    required List<Map<String, dynamic>> announcements,
  }) async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          UPDATE students
          SET
            documents = CAST(@documents AS jsonb),
            announcements = CAST(@announcements AS jsonb),
            updated_at = NOW()
          WHERE id::text = @id
          RETURNING id::text
          ''',
        ),
        parameters: <String, dynamic>{
          'id': id,
          'documents': jsonEncode(documents),
          'announcements': jsonEncode(announcements),
        },
      ),
    );

    return result.isNotEmpty;
  }

  List<Map<String, dynamic>> _cloneList(Object? value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map((item) => <String, dynamic>{...item})
        .toList();
  }

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _dateLabelFromDb(Object? value) {
    if (value is DateTime) {
      return _dateLabel(value.toLocal());
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return _dateLabel(parsed.toLocal());
    }

    return '';
  }

  bool _equalsIgnoreCase(String left, String right) {
    return left.toLowerCase() == right.toLowerCase();
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  Future<String?> _findTeacherIdByName(String fullName) async {
    final normalizedName = fullName.trim();
    if (normalizedName.isEmpty) {
      return null;
    }

    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT id::text AS id
          FROM teachers
          WHERE lower(full_name) = lower(@full_name)
          ORDER BY created_at ASC
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'full_name': normalizedName,
        },
      ),
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first.first?.toString();
  }

  Future<List<Map<String, dynamic>>> _loadStudentSchedule(
    String studentId, {
    String? legacyScheduleJson,
  }) async {
    final result = await _runWithReconnect(
      (connection) => connection.execute(
        Sql.named(
          '''
          SELECT
            schedule_lessons.weekday,
            schedule_lessons.start_time,
            schedule_lessons.end_time,
            schedule_lessons.room,
            schedule_lessons.lesson_type,
            subjects.id::text AS subject_id,
            subjects.name AS subject_name,
            teachers.id::text AS teacher_id,
            teachers.full_name AS teacher_name
          FROM schedule_lessons
          INNER JOIN subjects ON subjects.id = schedule_lessons.subject_id
          LEFT JOIN teachers ON teachers.id = schedule_lessons.teacher_id
          WHERE schedule_lessons.student_id::text = @student_id
          ORDER BY
            schedule_lessons.weekday ASC,
            schedule_lessons.start_time ASC,
            schedule_lessons.end_time ASC,
            subjects.name ASC
          ''',
        ),
        parameters: <String, dynamic>{
          'student_id': studentId,
        },
      ),
    );

    if (result.isEmpty) {
      return _decodeJsonList(legacyScheduleJson);
    }

    return result.map((row) {
      final columns = row.toColumnMap();
      final startTime = _asTime(columns['start_time']);
      final endTime = _asTime(columns['end_time']);
      final teacherName = columns['teacher_name']?.toString().trim() ?? '';
      return <String, dynamic>{
        'weekday': _toInt(columns['weekday']) ?? DateTime.monday,
        'time': startTime == null || endTime == null
            ? ''
            : _formatLessonTime(startTime, endTime),
        'subject': columns['subject_name']?.toString().trim() ?? '',
        'subjectId': columns['subject_id']?.toString() ?? '',
        'room': columns['room']?.toString().trim() ?? '',
        'teacher': teacherName.isEmpty ? 'Не указан' : teacherName,
        'teacherId': columns['teacher_id']?.toString() ?? '',
        'type': columns['lesson_type']?.toString().trim() ?? '',
      };
    }).toList(growable: false);
  }

  List<_ScheduleLessonInput> _normalizeSchedulePayload(
    List<Map<String, dynamic>> schedule, {
    bool skipInvalid = false,
  }) {
    final normalized = <_ScheduleLessonInput>[];
    for (final lesson in schedule) {
      final weekday = _toInt(lesson['weekday']);
      final time = lesson['time']?.toString().trim() ?? '';
      final subject = lesson['subject']?.toString().trim() ?? '';
      final room = lesson['room']?.toString().trim() ?? '';
      final teacherValue = lesson['teacher']?.toString().trim() ?? '';
      final type = lesson['type']?.toString().trim() ?? '';
      final teacher = teacherValue.isEmpty ? 'Не указан' : teacherValue;
      final timeRange = _parseLessonTime(time);

      final isValid = weekday != null &&
          weekday >= 1 &&
          weekday <= 7 &&
          timeRange != null &&
          subject.isNotEmpty &&
          room.isNotEmpty &&
          type.isNotEmpty;
      if (!isValid) {
        if (skipInvalid) {
          continue;
        }
        throw const FormatException('Invalid schedule lesson payload.');
      }

      normalized.add(
        _ScheduleLessonInput(
          weekday: weekday,
          startTime: timeRange.startTime,
          endTime: timeRange.endTime,
          subject: subject,
          room: room,
          teacher: teacher,
          type: type,
        ),
      );
    }

    return normalized;
  }

  Future<bool> _replaceStudentScheduleInSession(
    Session session, {
    required String studentId,
    required List<_ScheduleLessonInput> schedule,
  }) async {
    final legacyScheduleJson = jsonEncode(
      schedule.map((lesson) => lesson.toLegacyJson()).toList(growable: false),
    );
    final updatedStudent = await session.execute(
      Sql.named(
        '''
        UPDATE students
        SET
          schedule = CAST(@schedule AS jsonb),
          updated_at = NOW()
        WHERE id::text = @id
        RETURNING id::text
        ''',
      ),
      parameters: <String, dynamic>{
        'id': studentId,
        'schedule': legacyScheduleJson,
      },
    );
    if (updatedStudent.isEmpty) {
      return false;
    }

    await session.execute(
      Sql.named(
        '''
        DELETE FROM schedule_lessons
        WHERE student_id::text = @student_id
        ''',
      ),
      parameters: <String, dynamic>{
        'student_id': studentId,
      },
    );

    final subjectCache = <String, String>{};
    final teacherCache = <String, String?>{};
    final teacherSubjectCache = <String>{};

    for (final lesson in schedule) {
      final subjectId = await _ensureSubject(
        session,
        lesson.subject,
        cache: subjectCache,
      );
      final teacherId = await _ensureTeacher(
        session,
        lesson.teacher,
        cache: teacherCache,
      );
      if (teacherId != null) {
        await _ensureTeacherSubjectLink(
          session,
          teacherId: teacherId,
          subjectId: subjectId,
          cache: teacherSubjectCache,
        );
      }

      await session.execute(
        Sql.named(
          '''
          INSERT INTO schedule_lessons (
            student_id,
            weekday,
            start_time,
            end_time,
            room,
            lesson_type,
            subject_id,
            teacher_id
          ) VALUES (
            CAST(@student_id AS uuid),
            @weekday,
            @start_time,
            @end_time,
            @room,
            @lesson_type,
            CAST(@subject_id AS uuid),
            CAST(@teacher_id AS uuid)
          )
          ''',
        ),
        parameters: <String, dynamic>{
          'student_id': studentId,
          'weekday': lesson.weekday,
          'start_time': TypedValue(Type.time, lesson.startTime),
          'end_time': TypedValue(Type.time, lesson.endTime),
          'room': lesson.room,
          'lesson_type': lesson.type,
          'subject_id': subjectId,
          'teacher_id': teacherId,
        },
      );
    }

    return true;
  }

  Future<String> _ensureSubject(
    Session session,
    String name, {
    Map<String, String>? cache,
  }) async {
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cacheKey = normalizedName.toLowerCase();
    final cached = cache?[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final existing = await session.execute(
      Sql.named(
        '''
        SELECT id::text AS id
        FROM subjects
        WHERE lower(name) = lower(@name)
        ORDER BY created_at ASC
        LIMIT 1
        ''',
      ),
      parameters: <String, dynamic>{'name': normalizedName},
    );
    if (existing.isNotEmpty) {
      final subjectId = existing.first.first?.toString() ?? '';
      if (subjectId.isNotEmpty) {
        cache?[cacheKey] = subjectId;
        return subjectId;
      }
    }

    try {
      final inserted = await session.execute(
        Sql.named(
          '''
          INSERT INTO subjects (name)
          VALUES (@name)
          RETURNING id::text AS id
          ''',
        ),
        parameters: <String, dynamic>{'name': normalizedName},
      );
      final subjectId = inserted.first.first?.toString() ?? '';
      cache?[cacheKey] = subjectId;
      return subjectId;
    } catch (error) {
      if (!_isSubjectUniqueViolation(error)) {
        rethrow;
      }
      final retried = await session.execute(
        Sql.named(
          '''
          SELECT id::text AS id
          FROM subjects
          WHERE lower(name) = lower(@name)
          ORDER BY created_at ASC
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{'name': normalizedName},
      );
      final subjectId = retried.first.first?.toString() ?? '';
      cache?[cacheKey] = subjectId;
      return subjectId;
    }
  }

  Future<String?> _ensureTeacher(
    Session session,
    String fullName, {
    Map<String, String?>? cache,
  }) async {
    final normalizedName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cacheKey = normalizedName.toLowerCase();
    if (cache != null && cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }

    if (normalizedName.isEmpty || _isPlaceholderTeacherName(normalizedName)) {
      cache?[cacheKey] = null;
      return null;
    }

    final existing = await session.execute(
      Sql.named(
        '''
        SELECT id::text AS id
        FROM teachers
        WHERE lower(full_name) = lower(@full_name)
        ORDER BY created_at ASC
        LIMIT 1
        ''',
      ),
      parameters: <String, dynamic>{'full_name': normalizedName},
    );
    if (existing.isNotEmpty) {
      final teacherId = existing.first.first?.toString();
      cache?[cacheKey] = teacherId;
      return teacherId;
    }

    final inserted = await session.execute(
      Sql.named(
        '''
        INSERT INTO teachers (
          full_name,
          updated_at
        ) VALUES (
          @full_name,
          NOW()
        )
        RETURNING id::text AS id
        ''',
      ),
      parameters: <String, dynamic>{'full_name': normalizedName},
    );
    final teacherId = inserted.first.first?.toString();
    cache?[cacheKey] = teacherId;
    return teacherId;
  }

  Future<void> _ensureTeacherSubjectLink(
    Session session, {
    required String teacherId,
    required String subjectId,
    Set<String>? cache,
  }) async {
    final cacheKey = '$teacherId|$subjectId';
    if (cache != null && cache.contains(cacheKey)) {
      return;
    }

    await session.execute(
      Sql.named(
        '''
        INSERT INTO teacher_subjects (
          teacher_id,
          subject_id
        ) VALUES (
          CAST(@teacher_id AS uuid),
          CAST(@subject_id AS uuid)
        )
        ON CONFLICT DO NOTHING
        ''',
      ),
      parameters: <String, dynamic>{
        'teacher_id': teacherId,
        'subject_id': subjectId,
      },
    );
    cache?.add(cacheKey);
  }

  Future<void> _migrateLegacyStudentSchedules() async {
    final students = await _runWithReconnect(
      (connection) => connection.execute(
        '''
        SELECT
          id::text AS id,
          schedule::text AS schedule
        FROM students
        WHERE schedule <> '[]'::jsonb
        ORDER BY created_at ASC
        ''',
      ),
    );

    for (final row in students) {
      final studentId = row[0]?.toString() ?? '';
      final legacySchedule = _decodeJsonList(row[1]?.toString());
      if (studentId.isEmpty || legacySchedule.isEmpty) {
        continue;
      }

      final existingLessons = await _runWithReconnect(
        (connection) => connection.execute(
          Sql.named(
            '''
            SELECT 1
            FROM schedule_lessons
            WHERE student_id::text = @student_id
            LIMIT 1
            ''',
          ),
          parameters: <String, dynamic>{
            'student_id': studentId,
          },
        ),
      );
      if (existingLessons.isNotEmpty) {
        continue;
      }

      final normalized = _normalizeSchedulePayload(
        legacySchedule,
        skipInvalid: true,
      );
      if (normalized.isEmpty) {
        continue;
      }
      await _runTxWithReconnect(
        (session) => _replaceStudentScheduleInSession(
          session,
          studentId: studentId,
          schedule: normalized,
        ),
      );
    }
  }

  Time? _asTime(Object? value) {
    if (value is Time) {
      return value;
    }
    if (value is DateTime) {
      return Time(value.hour, value.minute, value.second, value.millisecond);
    }
    if (value is String) {
      final parsed = _parseClockTime(value);
      if (parsed == null) {
        return null;
      }
      return parsed.toPgTime();
    }
    return null;
  }

  String _formatLessonTime(Time startTime, Time endTime) {
    final start = _formatTimeValue(startTime);
    final end = _formatTimeValue(endTime);
    if (start == end) {
      return start;
    }
    return '$start-$end';
  }

  String _formatTimeValue(Time value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  _LessonTimeRange? _parseLessonTime(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp('[–—−]'), '-')
        .replaceAll(RegExp(r'\s*-\s*'), '-');
    if (normalized.isEmpty) {
      return null;
    }

    final parts = normalized.split('-');
    if (parts.length == 1) {
      final time = _parseClockTime(parts.first);
      if (time == null) {
        return null;
      }
      return _LessonTimeRange(
        startTime: time.toPgTime(),
        endTime: time.toPgTime(),
      );
    }
    if (parts.length != 2) {
      return null;
    }

    final start = _parseClockTime(parts.first);
    final end = _parseClockTime(parts.last);
    if (start == null || end == null) {
      return null;
    }

    return _LessonTimeRange(
      startTime: start.toPgTime(),
      endTime: end.toPgTime(),
    );
  }

  _ClockTime? _parseClockTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return _ClockTime(hour: hour, minute: minute);
  }

  bool _isPlaceholderTeacherName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'не указан' ||
        normalized == 'не указана' ||
        normalized == 'неизвестно' ||
        normalized == '—' ||
        normalized == '-';
  }

  Future<T> _runTxWithReconnect<T>(
    Future<T> Function(TxSession session) action,
  ) async {
    try {
      return await _connection.runTx(action);
    } catch (error) {
      if (!_isReconnectableError(error)) {
        rethrow;
      }

      await _reconnect();
      return _connection.runTx(action);
    }
  }

  Future<T> _runWithReconnect<T>(
    Future<T> Function(Connection connection) action,
  ) async {
    try {
      return await action(_connection);
    } catch (error) {
      if (!_isReconnectableError(error)) {
        rethrow;
      }

      await _reconnect();
      return action(_connection);
    }
  }

  bool _isReconnectableError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('connection is not open') ||
        message.contains('connection closed');
  }

  bool _isUniqueViolation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('duplicate key value') &&
        message.contains('students_email_key');
  }

  bool _isTeacherUniqueViolation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('duplicate key value') &&
        message.contains('teachers_email_key');
  }

  bool _isSubjectUniqueViolation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('duplicate key value') &&
        message.contains('subjects_name_lower_idx');
  }

  Future<void> _reconnect() async {
    final inFlight = _reconnectInProgress;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final reconnectTask = _performReconnect();
    _reconnectInProgress = reconnectTask;
    try {
      await reconnectTask;
    } finally {
      if (identical(_reconnectInProgress, reconnectTask)) {
        _reconnectInProgress = null;
      }
    }
  }

  Future<void> _performReconnect() async {
    try {
      await _connection.close();
    } catch (_) {
      // The connection may already be closed; proceed with reopening.
    }

    _connection = await Connection.openFromUrl(_config.databaseUrl);
    await _initialize();
  }

  Future<void> _initialize() async {
    await _connection.execute('CREATE EXTENSION IF NOT EXISTS pgcrypto');
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS students (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        student_identifier TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        curator TEXT NOT NULL,
        attendance DOUBLE PRECISION NOT NULL DEFAULT 0,
        completed_assignments INTEGER NOT NULL DEFAULT 0,
        total_assignments INTEGER NOT NULL DEFAULT 0,
        schedule JSONB NOT NULL DEFAULT '[]'::jsonb,
        grades JSONB NOT NULL DEFAULT '[]'::jsonb,
        documents JSONB NOT NULL DEFAULT '[]'::jsonb,
        announcements JSONB NOT NULL DEFAULT '[]'::jsonb,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
    );
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS teachers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
    );
    await _connection.execute(
      '''
      ALTER TABLE teachers
      ALTER COLUMN email DROP NOT NULL
      ''',
    );
    await _connection.execute(
      '''
      ALTER TABLE teachers
      ALTER COLUMN password_hash DROP NOT NULL
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS teachers_full_name_idx
      ON teachers (lower(full_name))
      ''',
    );
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS subjects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
    );
    await _connection.execute(
      '''
      CREATE UNIQUE INDEX IF NOT EXISTS subjects_name_lower_idx
      ON subjects (lower(name))
      ''',
    );
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS teacher_subjects (
        teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
        subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (teacher_id, subject_id)
      )
      ''',
    );
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS schedule_lessons (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        room TEXT NOT NULL,
        lesson_type TEXT NOT NULL,
        subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE RESTRICT,
        teacher_id UUID REFERENCES teachers(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS schedule_lessons_student_idx
      ON schedule_lessons (student_id, weekday, start_time)
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS schedule_lessons_teacher_idx
      ON schedule_lessons (teacher_id, weekday, start_time)
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS schedule_lessons_subject_idx
      ON schedule_lessons (subject_id)
      ''',
    );
    await _connection.execute(
      '''
      CREATE TABLE IF NOT EXISTS curator_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        curator_teacher_id UUID REFERENCES teachers(id) ON DELETE SET NULL,
        student_name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        curator_name TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
      ''',
    );
    await _connection.execute(
      '''
      ALTER TABLE curator_messages
      ADD COLUMN IF NOT EXISTS curator_teacher_id UUID REFERENCES teachers(id) ON DELETE SET NULL
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS curator_messages_teacher_idx
      ON curator_messages (curator_teacher_id, created_at DESC)
      ''',
    );
    await _connection.execute(
      '''
      CREATE INDEX IF NOT EXISTS curator_messages_curator_idx
      ON curator_messages (lower(curator_name), created_at DESC)
      ''',
    );

    if (_config.seedDemoData) {
      await _seedDemoStudent();
      await _seedDemoTeacher();
    }
    await _migrateLegacyStudentSchedules();
  }

  Future<void> _seedDemoStudent() async {
    final demoStore = DemoStudentStore(_config);
    final cabinet = demoStore.getCabinetByEmail(_config.demoStudentEmail);
    final profile = cabinet['profile'] as Map<String, dynamic>;

    await _connection.execute(
      Sql.named(
        '''
        INSERT INTO students (
          email,
          password_hash,
          full_name,
          first_name,
          group_name,
          student_identifier,
          phone,
          curator,
          attendance,
          completed_assignments,
          total_assignments,
          schedule,
          grades,
          documents,
          announcements,
          updated_at
        ) VALUES (
          @email,
          crypt(@password, gen_salt('bf')),
          @full_name,
          @first_name,
          @group_name,
          @student_identifier,
          @phone,
          @curator,
          @attendance,
          @completed_assignments,
          @total_assignments,
          CAST(@schedule AS jsonb),
          CAST(@grades AS jsonb),
          CAST(@documents AS jsonb),
          CAST(@announcements AS jsonb),
          NOW()
        )
        ON CONFLICT (email) DO UPDATE SET
          password_hash = crypt(@password, gen_salt('bf')),
          full_name = @full_name,
          first_name = @first_name,
          group_name = @group_name,
          student_identifier = @student_identifier,
          phone = @phone,
          curator = @curator,
          attendance = @attendance,
          completed_assignments = @completed_assignments,
          total_assignments = @total_assignments,
          schedule = CAST(@schedule AS jsonb),
          grades = CAST(@grades AS jsonb),
          documents = CAST(@documents AS jsonb),
          announcements = CAST(@announcements AS jsonb),
          updated_at = NOW()
        ''',
      ),
      parameters: <String, dynamic>{
        'email': _config.demoStudentEmail,
        'password': _config.demoStudentPassword,
        'full_name': profile['fullName'],
        'first_name': profile['firstName'],
        'group_name': profile['group'],
        'student_identifier': profile['studentId'],
        'phone': profile['phone'],
        'curator': profile['curator'],
        'attendance': profile['attendance'],
        'completed_assignments': profile['completedAssignments'],
        'total_assignments': profile['totalAssignments'],
        'schedule': jsonEncode(cabinet['schedule']),
        'grades': jsonEncode(cabinet['grades']),
        'documents': jsonEncode(cabinet['documents']),
        'announcements': jsonEncode(cabinet['announcements']),
      },
    );
  }

  Future<void> _seedDemoTeacher() async {
    final normalizedEmail = _config.teacherEmail.trim().toLowerCase();
    final normalizedName = _config.teacherName.trim();
    if (normalizedEmail.isEmpty || normalizedName.isEmpty) {
      return;
    }

    await _connection.runTx((session) async {
      final byEmail = await session.execute(
        Sql.named(
          '''
          SELECT id::text AS id
          FROM teachers
          WHERE lower(email) = lower(@email)
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'email': normalizedEmail,
        },
      );
      if (byEmail.isNotEmpty) {
        await session.execute(
          Sql.named(
            '''
            UPDATE teachers
            SET
              full_name = @full_name,
              password_hash = crypt(@password, gen_salt('bf')),
              updated_at = NOW()
            WHERE id::text = @id
            ''',
          ),
          parameters: <String, dynamic>{
            'id': byEmail.first.first?.toString() ?? '',
            'full_name': normalizedName,
            'password': _config.teacherPassword,
          },
        );
        return;
      }

      final byName = await session.execute(
        Sql.named(
          '''
          SELECT id::text AS id
          FROM teachers
          WHERE lower(full_name) = lower(@full_name)
          ORDER BY created_at ASC
          LIMIT 1
          ''',
        ),
        parameters: <String, dynamic>{
          'full_name': normalizedName,
        },
      );
      if (byName.isNotEmpty) {
        await session.execute(
          Sql.named(
            '''
            UPDATE teachers
            SET
              email = @email,
              password_hash = crypt(@password, gen_salt('bf')),
              full_name = @full_name,
              updated_at = NOW()
            WHERE id::text = @id
            ''',
          ),
          parameters: <String, dynamic>{
            'id': byName.first.first?.toString() ?? '',
            'email': normalizedEmail,
            'password': _config.teacherPassword,
            'full_name': normalizedName,
          },
        );
        return;
      }

      await session.execute(
        Sql.named(
          '''
          INSERT INTO teachers (
            email,
            password_hash,
            full_name,
            updated_at
          ) VALUES (
            @email,
            crypt(@password, gen_salt('bf')),
            @full_name,
            NOW()
          )
          ''',
        ),
        parameters: <String, dynamic>{
          'email': normalizedEmail,
          'password': _config.teacherPassword,
          'full_name': normalizedName,
        },
      );
    });
  }

  List<Map<String, dynamic>> _decodeJsonList(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  String _extractFirstName(String fullName) {
    if (fullName.isEmpty) {
      return 'Студент';
    }

    return fullName.split(RegExp(r'\s+')).first;
  }

  String _generateStudentIdentifier() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'STU$timestamp';
  }

  List<Map<String, dynamic>> _defaultSchedule() {
    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _defaultDocuments() {
    return const <Map<String, dynamic>>[
      {
        'title': 'Памятка первокурсника.pdf',
        'status': 'Доступен',
        'updatedAt': 'Создан при регистрации',
      },
    ];
  }

  List<Map<String, dynamic>> _defaultAnnouncements() {
    return const <Map<String, dynamic>>[
      {
        'title': 'Аккаунт создан',
        'description': 'Заполните профиль и дождитесь назначения расписания.',
        'dateLabel': 'сейчас',
      },
    ];
  }
}

class _ScheduleLessonInput {
  const _ScheduleLessonInput({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.type,
  });

  final int weekday;
  final Time startTime;
  final Time endTime;
  final String subject;
  final String room;
  final String teacher;
  final String type;

  Map<String, dynamic> toLegacyJson() {
    final start = _formatTimePart(startTime);
    final end = _formatTimePart(endTime);
    return <String, dynamic>{
      'weekday': weekday,
      'time': start == end ? start : '$start-$end',
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'type': type,
    };
  }

  static String _formatTimePart(Time time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _LessonTimeRange {
  const _LessonTimeRange({
    required this.startTime,
    required this.endTime,
  });

  final Time startTime;
  final Time endTime;
}

class _ClockTime {
  const _ClockTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;

  Time toPgTime() => Time(hour, minute);
}
