class StudentProfile {
  final String fullName;
  final String firstName;
  final String group;
  final String studentId;
  final String email;
  final String phone;
  final String curator;
  final double attendance;
  final int completedAssignments;
  final int totalAssignments;

  const StudentProfile({
    required this.fullName,
    required this.firstName,
    required this.group,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.curator,
    required this.attendance,
    required this.completedAssignments,
    required this.totalAssignments,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      fullName: _readString(json, ['fullName', 'full_name', 'name']),
      firstName: _readString(
        json,
        ['firstName', 'first_name'],
        fallback: _firstNameFromFullName(
          _readString(json, ['fullName', 'full_name', 'name']),
        ),
      ),
      group: _readString(json, ['group', 'groupName', 'group_name']),
      studentId: _readString(
        json,
        ['studentId', 'student_id', 'student_identifier', 'id'],
      ),
      email: _readString(json, ['email']),
      phone: _readString(json, ['phone', 'phoneNumber', 'phone_number']),
      curator: _readString(json, ['curator', 'advisor']),
      attendance: _readDouble(json, ['attendance']),
      completedAssignments: _readInt(
        json,
        ['completedAssignments', 'completed_assignments'],
      ),
      totalAssignments: _readInt(
        json,
        ['totalAssignments', 'total_assignments'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': studentId,
      'full_name': fullName,
      'first_name': firstName,
      'group_name': group,
      'student_identifier': studentId,
      'email': email,
      'phone': phone,
      'curator': curator,
      'attendance': attendance,
      'completed_assignments': completedAssignments,
      'total_assignments': totalAssignments,
    };
  }
}

class Lesson {
  final int weekday;
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final String type;

  const Lesson({
    required this.weekday,
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.type,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      weekday: _readWeekday(json),
      time: _readString(json, ['time', 'startTime', 'start_time']),
      subject: _readString(json, ['subject', 'title']),
      room: _readString(json, ['room', 'auditorium']),
      teacher: _readString(json, ['teacher', 'lecturer']),
      type: _readString(json, ['type', 'lessonType', 'lesson_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': '$weekday-$time-$subject',
      'weekday': weekday,
      'time': time,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'lesson_type': type,
    };
  }
}

class GradeRecord {
  final String subject;
  final int grade;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final String teacher;

  const GradeRecord({
    required this.subject,
    required this.grade,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.teacher,
  });

  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    return GradeRecord(
      subject: _readString(json, ['subject', 'title']),
      grade: _readInt(json, ['grade', 'mark']),
      progress: _readDouble(json, ['progress']),
      completedTasks: _readInt(
        json,
        ['completedTasks', 'completed_tasks'],
      ),
      totalTasks: _readInt(json, ['totalTasks', 'total_tasks']),
      teacher: _readString(json, ['teacher', 'lecturer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': '$subject-$grade',
      'subject': subject,
      'grade': grade,
      'progress': progress,
      'completed_tasks': completedTasks,
      'total_tasks': totalTasks,
      'teacher': teacher,
      'date_label': 'Today',
    };
  }
}

class StudentDocument {
  final String id;
  final String title;
  final String status;
  final String updatedAt;
  final String note;

  const StudentDocument({
    this.id = '',
    required this.title,
    required this.status,
    required this.updatedAt,
    this.note = '',
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: _readString(json, ['id']),
      title: _readString(json, ['title', 'fileName', 'file_name']),
      status: _readString(json, ['status']),
      updatedAt: _readString(
        json,
        ['updatedAt', 'updated_at', 'updated_at_label', 'created_at'],
      ),
      note: _readString(json, ['note', 'description', 'comment']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'updated_at_label': updatedAt,
    };
  }

  bool get isReady {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('готов') || normalized.contains('доступ');
  }

  bool get requiresAttention {
    return status.trim().toLowerCase().contains('требует');
  }
}

class StudentAnnouncement {
  final String title;
  final String description;
  final String dateLabel;

  const StudentAnnouncement({
    required this.title,
    required this.description,
    required this.dateLabel,
  });

  factory StudentAnnouncement.fromJson(Map<String, dynamic> json) {
    return StudentAnnouncement(
      title: _readString(json, ['title']),
      description: _readString(json, ['description', 'body']),
      dateLabel: _readString(
        json,
        ['dateLabel', 'date_label', 'date', 'created_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': '$title-${dateLabel.hashCode}',
      'title': title,
      'description': description,
      'date_label': dateLabel,
    };
  }
}

class StudentCabinetData {
  final StudentProfile profile;
  final List<Lesson> schedule;
  final List<GradeRecord> grades;
  final List<StudentDocument> documents;
  final List<StudentAnnouncement> announcements;

  const StudentCabinetData({
    required this.profile,
    required this.schedule,
    required this.grades,
    required this.documents,
    required this.announcements,
  });

  factory StudentCabinetData.fromJson(Map<String, dynamic> json) {
    return StudentCabinetData(
      profile: StudentProfile.fromJson(
        _readMap(json, ['profile', 'student', 'user']),
      ),
      schedule: _readList(
        json,
        ['schedule', 'lessons'],
      ).map(Lesson.fromJson).toList(),
      grades: _readList(
        json,
        ['grades', 'marks'],
      ).map(GradeRecord.fromJson).toList(),
      documents: _readList(
        json,
        ['documents', 'files'],
      ).map(StudentDocument.fromJson).toList(),
      announcements: _readList(
        json,
        ['announcements', 'news'],
      ).map(StudentAnnouncement.fromJson).toList(),
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
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return fallback;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
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

List<Map<String, dynamic>> _readList(Map<String, dynamic> json, List<String> keys) {
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

int _readWeekday(Map<String, dynamic> json) {
  final value = json['weekday'] ?? json['day'] ?? json['weekDay'];

  if (value is int) {
    return value;
  }

  final raw = value?.toString().trim().toLowerCase() ?? '';
  switch (raw) {
    case '1':
    case 'monday':
    case 'понедельник':
      return DateTime.monday;
    case '2':
    case 'tuesday':
    case 'вторник':
      return DateTime.tuesday;
    case '3':
    case 'wednesday':
    case 'среда':
      return DateTime.wednesday;
    case '4':
    case 'thursday':
    case 'четверг':
      return DateTime.thursday;
    case '5':
    case 'friday':
    case 'пятница':
      return DateTime.friday;
    case '6':
    case 'saturday':
    case 'суббота':
      return DateTime.saturday;
    case '7':
    case 'sunday':
    case 'воскресенье':
      return DateTime.sunday;
    default:
      return DateTime.monday;
  }
}

String _firstNameFromFullName(String fullName) {
  if (fullName.trim().isEmpty) {
    return '';
  }

  return fullName.trim().split(RegExp(r'\s+')).first;
}
