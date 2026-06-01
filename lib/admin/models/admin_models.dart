class AdminStudentSummary {
  final String id;
  final String fullName;
  final String group;
  final String email;
  final String studentId;

  const AdminStudentSummary({
    required this.id,
    required this.fullName,
    required this.group,
    required this.email,
    required this.studentId,
  });

  factory AdminStudentSummary.fromJson(Map<String, dynamic> json) {
    return AdminStudentSummary(
      id: _readString(json, const <String>['id']),
      fullName: _readString(json, const <String>['fullName', 'full_name']),
      group: _readString(json, const <String>['group', 'group_name']),
      email: _readString(json, const <String>['email']),
      studentId: _readString(
        json,
        const <String>['studentId', 'student_id', 'student_identifier'],
      ),
    );
  }
}

class AdminStudentProfile {
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

  const AdminStudentProfile({
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

  factory AdminStudentProfile.fromJson(Map<String, dynamic> json) {
    return AdminStudentProfile(
      fullName: _readString(json, const <String>['fullName', 'full_name']),
      firstName: _readString(
        json,
        const <String>['firstName', 'first_name'],
      ),
      group: _readString(json, const <String>['group', 'group_name']),
      studentId: _readString(
        json,
        const <String>['studentId', 'student_id', 'student_identifier'],
      ),
      email: _readString(json, const <String>['email']),
      phone: _readString(json, const <String>['phone']),
      curator: _readString(json, const <String>['curator']),
      attendance: _readDouble(json, const <String>['attendance']),
      completedAssignments: _readInt(
        json,
        const <String>['completedAssignments', 'completed_assignments'],
      ),
      totalAssignments: _readInt(
        json,
        const <String>['totalAssignments', 'total_assignments'],
      ),
    );
  }

  AdminStudentProfile copyWith({
    String? fullName,
    String? firstName,
    String? group,
    String? studentId,
    String? email,
    String? phone,
    String? curator,
    double? attendance,
    int? completedAssignments,
    int? totalAssignments,
  }) {
    return AdminStudentProfile(
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      group: group ?? this.group,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      curator: curator ?? this.curator,
      attendance: attendance ?? this.attendance,
      completedAssignments: completedAssignments ?? this.completedAssignments,
      totalAssignments: totalAssignments ?? this.totalAssignments,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'fullName': fullName,
      'group': group,
      'email': email,
      'phone': phone,
      'curator': curator,
      'attendance': attendance,
      'completedAssignments': completedAssignments,
      'totalAssignments': totalAssignments,
    };
  }
}

class AdminLesson {
  final int weekday;
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final String type;

  const AdminLesson({
    required this.weekday,
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.type,
  });

  factory AdminLesson.fromJson(Map<String, dynamic> json) {
    return AdminLesson(
      weekday: _readInt(json, const <String>['weekday']),
      time: _readString(json, const <String>['time']),
      subject: _readString(json, const <String>['subject']),
      room: _readString(json, const <String>['room']),
      teacher: _readString(json, const <String>['teacher']),
      type: _readString(json, const <String>['type', 'lesson_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'weekday': weekday,
      'time': time,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'type': type,
    };
  }
}

class AdminStudentDocument {
  final String id;
  final String title;
  final String status;
  final String updatedAt;
  final String note;

  const AdminStudentDocument({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.note = '',
  });

  factory AdminStudentDocument.fromJson(Map<String, dynamic> json) {
    return AdminStudentDocument(
      id: _readString(json, const <String>['id']),
      title: _readString(json, const <String>['title']),
      status: _readString(json, const <String>['status']),
      updatedAt: _readString(
        json,
        const <String>[
          'updatedAt',
          'updated_at',
          'updated_at_label',
          'date_label'
        ],
      ),
      note: _readString(json, const <String>['note', 'description', 'comment']),
    );
  }

  bool get isReady {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('готов') || normalized.contains('доступ');
  }
}

class AdminCertificateRequest {
  final String id;
  final String type;
  final String comment;
  final String status;
  final String createdAt;

  const AdminCertificateRequest({
    required this.id,
    required this.type,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  factory AdminCertificateRequest.fromJson(Map<String, dynamic> json) {
    return AdminCertificateRequest(
      id: _readString(json, const <String>['id']),
      type: _readString(json, const <String>['type']),
      comment: _readString(json, const <String>['comment']),
      status: _readString(
        json,
        const <String>['status'],
      ),
      createdAt: _readString(
        json,
        const <String>['createdAt', 'created_at', 'created_at_label'],
      ),
    );
  }

  String get statusLabel {
    switch (status.trim().toLowerCase()) {
      case 'ready':
        return 'Готово';
      case 'processing':
      case 'in_progress':
        return 'В работе';
      default:
        return 'Новый';
    }
  }

  bool get isNew => status.trim().toLowerCase() == 'new';
  bool get isProcessing {
    final normalized = status.trim().toLowerCase();
    return normalized == 'processing' || normalized == 'in_progress';
  }

  bool get isReady => status.trim().toLowerCase() == 'ready';
}

class AdminStudentDetails {
  final String id;
  final AdminStudentProfile profile;
  final List<AdminLesson> schedule;
  final List<AdminStudentDocument> documents;
  final List<AdminCertificateRequest> certificateRequests;

  const AdminStudentDetails({
    required this.id,
    required this.profile,
    required this.schedule,
    required this.documents,
    this.certificateRequests = const <AdminCertificateRequest>[],
  });

  factory AdminStudentDetails.fromJson(Map<String, dynamic> json) {
    final profileJson = _readMap(json, 'profile');
    final scheduleJson = _readList(json, 'schedule');
    final documentsJson = _readList(json, 'documents');
    final requestsJson = _readList(json, 'certificateRequests');
    return AdminStudentDetails(
      id: _readString(json, const <String>['id']),
      profile: AdminStudentProfile.fromJson(profileJson),
      schedule: scheduleJson.map(AdminLesson.fromJson).toList(),
      documents: documentsJson.map(AdminStudentDocument.fromJson).toList(),
      certificateRequests:
          requestsJson.map(AdminCertificateRequest.fromJson).toList(),
    );
  }

  AdminStudentDetails copyWith({
    String? id,
    AdminStudentProfile? profile,
    List<AdminLesson>? schedule,
    List<AdminStudentDocument>? documents,
    List<AdminCertificateRequest>? certificateRequests,
  }) {
    return AdminStudentDetails(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      schedule: schedule ?? this.schedule,
      documents: documents ?? this.documents,
      certificateRequests: certificateRequests ?? this.certificateRequests,
    );
  }
}

String _readString(Map<String, dynamic> json, List<String> keys) {
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

  return '';
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
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

  return 0;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return 0;
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();
  }
  return const <Map<String, dynamic>>[];
}
