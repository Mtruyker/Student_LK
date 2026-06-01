class TeacherProfile {
  final String fullName;
  final String email;
  final bool isCurator;
  final int curatorStudentsCount;

  const TeacherProfile({
    required this.fullName,
    required this.email,
    required this.isCurator,
    required this.curatorStudentsCount,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      fullName:
          _readString(json, const <String>['fullName', 'full_name', 'name']),
      email: _readString(json, const <String>['email']),
      isCurator: _readBool(json, const <String>['isCurator', 'is_curator']),
      curatorStudentsCount: _readInt(
        json,
        const <String>['curatorStudentsCount', 'curator_students_count'],
      ),
    );
  }
}

class TeacherLesson {
  final int weekday;
  final String time;
  final String subject;
  final String room;
  final String type;
  final List<String> groups;

  const TeacherLesson({
    required this.weekday,
    required this.time,
    required this.subject,
    required this.room,
    required this.type,
    required this.groups,
  });

  factory TeacherLesson.fromJson(Map<String, dynamic> json) {
    return TeacherLesson(
      weekday: _readInt(json, const <String>['weekday']),
      time: _readString(json, const <String>['time']),
      subject: _readString(json, const <String>['subject']),
      room: _readString(json, const <String>['room']),
      type: _readString(json, const <String>['type', 'lesson_type']),
      groups: _readStringList(
        json,
        const <String>['groups', 'group', 'group_name'],
      ),
    );
  }
}

class CuratorMessage {
  final String id;
  final String studentName;
  final String group;
  final String message;
  final String status;
  final String teacherReply;
  final String repliedAt;
  final String dateLabel;
  final String createdAt;

  const CuratorMessage({
    required this.id,
    required this.studentName,
    required this.group,
    required this.message,
    this.status = 'new',
    this.teacherReply = '',
    this.repliedAt = '',
    required this.dateLabel,
    required this.createdAt,
  });

  factory CuratorMessage.fromJson(Map<String, dynamic> json) {
    return CuratorMessage(
      id: _readString(json, const <String>['id']),
      studentName: _readString(
        json,
        const <String>['studentName', 'student_name', 'student', 'full_name'],
      ),
      group: _readString(json, const <String>['group', 'group_name']),
      message: _readString(json, const <String>['message']),
      status: _readString(json, const <String>['status'], fallback: 'new'),
      teacherReply: _readString(
        json,
        const <String>['teacherReply', 'teacher_reply'],
      ),
      repliedAt: _readString(
        json,
        const <String>['repliedAt', 'teacher_reply_at'],
      ),
      dateLabel: _readString(
        json,
        const <String>['dateLabel', 'date_label', 'date', 'created_at'],
      ),
      createdAt: _readString(json, const <String>['createdAt', 'created_at']),
    );
  }

  bool get hasReply => teacherReply.trim().isNotEmpty;

  String get statusLabel {
    switch (status.trim().toLowerCase()) {
      case 'answered':
        return 'Отвечено';
      case 'processing':
      case 'in_progress':
        return 'В работе';
      default:
        return 'Новый';
    }
  }

  bool get isNew => status.trim().toLowerCase() == 'new';
}

class TeacherDashboardData {
  final TeacherProfile profile;
  final List<TeacherLesson> schedule;
  final List<CuratorMessage> curatorMessages;

  const TeacherDashboardData({
    required this.profile,
    required this.schedule,
    required this.curatorMessages,
  });

  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardData(
      profile: TeacherProfile.fromJson(
        _readMap(json, const <String>['profile', 'teacher']),
      ),
      schedule: _readList(json, const <String>['schedule', 'lessons'])
          .map(TeacherLesson.fromJson)
          .toList(),
      curatorMessages:
          _readList(json, const <String>['curatorMessages', 'messages'])
              .map(CuratorMessage.fromJson)
              .toList(),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}

int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
  }
  return fallback;
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(
    Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
  }
  return const <Map<String, dynamic>>[];
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return <String>[text];
    }
  }

  return const <String>[];
}
