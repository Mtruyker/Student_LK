import 'package:hive/hive.dart';

part 'cached_models.g.dart';

/// Cached version of student profile data
@HiveType(typeId: 0)
class CachedStudentProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String? firstName;

  @HiveField(4)
  final String? groupName;

  @HiveField(5)
  final String? studentIdentifier;

  @HiveField(6)
  final String? phone;

  @HiveField(7)
  final String? curator;

  @HiveField(8)
  final double attendance;

  @HiveField(9)
  final int completedAssignments;

  @HiveField(10)
  final int totalAssignments;

  @HiveField(11)
  final DateTime cachedAt;

  CachedStudentProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.firstName,
    this.groupName,
    this.studentIdentifier,
    this.phone,
    this.curator,
    required this.attendance,
    required this.completedAssignments,
    required this.totalAssignments,
    required this.cachedAt,
  });

  factory CachedStudentProfile.fromJson(Map<String, dynamic> json) {
    return CachedStudentProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      firstName: json['first_name'] ?? json['firstName'],
      groupName: json['group_name'] ?? json['groupName'],
      studentIdentifier: json['student_identifier'] ?? json['studentIdentifier'],
      phone: json['phone'],
      curator: json['curator'],
      attendance: (json['attendance'] ?? 0.0).toDouble(),
      completedAssignments: json['completed_assignments'] ?? json['completedAssignments'] ?? 0,
      totalAssignments: json['total_assignments'] ?? json['totalAssignments'] ?? 0,
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'first_name': firstName,
      'group_name': groupName,
      'student_identifier': studentIdentifier,
      'phone': phone,
      'curator': curator,
      'attendance': attendance,
      'completed_assignments': completedAssignments,
      'total_assignments': totalAssignments,
    };
  }
}

/// Cached version of lesson data
@HiveType(typeId: 1)
class CachedLesson extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int weekday;

  @HiveField(2)
  final String time;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String? room;

  @HiveField(5)
  final String? teacher;

  @HiveField(6)
  final String? lessonType;

  @HiveField(7)
  final DateTime cachedAt;

  CachedLesson({
    required this.id,
    required this.weekday,
    required this.time,
    required this.subject,
    this.room,
    this.teacher,
    this.lessonType,
    required this.cachedAt,
  });

  factory CachedLesson.fromJson(Map<String, dynamic> json) {
    return CachedLesson(
      id: json['id'] ?? '',
      weekday: json['weekday'] ?? 1,
      time: json['time'] ?? '',
      subject: json['subject'] ?? '',
      room: json['room'],
      teacher: json['teacher'],
      lessonType: json['lesson_type'] ?? json['lessonType'],
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekday': weekday,
      'time': time,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'lesson_type': lessonType,
    };
  }
}

/// Cached version of grade record
@HiveType(typeId: 2)
class CachedGradeRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subject;

  @HiveField(2)
  final int grade;

  @HiveField(3)
  final double progress;

  @HiveField(4)
  final String? teacher;

  @HiveField(5)
  final int completedTasks;

  @HiveField(6)
  final int totalTasks;

  @HiveField(7)
  final String? dateLabel;

  @HiveField(8)
  final DateTime cachedAt;

  CachedGradeRecord({
    required this.id,
    required this.subject,
    required this.grade,
    required this.progress,
    this.teacher,
    required this.completedTasks,
    required this.totalTasks,
    this.dateLabel,
    required this.cachedAt,
  });

  factory CachedGradeRecord.fromJson(Map<String, dynamic> json) {
    return CachedGradeRecord(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      teacher: json['teacher'],
      completedTasks: json['completed_tasks'] ?? json['completedTasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? json['totalTasks'] ?? 0,
      dateLabel: json['date_label'] ?? json['dateLabel'],
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'grade': grade,
      'progress': progress,
      'teacher': teacher,
      'completed_tasks': completedTasks,
      'total_tasks': totalTasks,
      'date_label': dateLabel,
    };
  }
}

/// Cached version of announcement
@HiveType(typeId: 3)
class CachedAnnouncement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? dateLabel;

  @HiveField(4)
  final DateTime cachedAt;

  CachedAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    this.dateLabel,
    required this.cachedAt,
  });

  factory CachedAnnouncement.fromJson(Map<String, dynamic> json) {
    return CachedAnnouncement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateLabel: json['date_label'] ?? json['dateLabel'],
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_label': dateLabel,
    };
  }
}

/// Cached version of student document
@HiveType(typeId: 4)
class CachedStudentDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final String? updatedAtLabel;

  @HiveField(4)
  final DateTime cachedAt;

  CachedStudentDocument({
    required this.id,
    required this.title,
    required this.status,
    this.updatedAtLabel,
    required this.cachedAt,
  });

  factory CachedStudentDocument.fromJson(Map<String, dynamic> json) {
    return CachedStudentDocument(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      updatedAtLabel: json['updated_at_label'] ?? json['updatedAtLabel'],
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'updated_at_label': updatedAtLabel,
    };
  }
}

/// Container for all cached student data
@HiveType(typeId: 5)
class CachedStudentData extends HiveObject {
  @HiveField(0)
  final CachedStudentProfile profile;

  @HiveField(1)
  final List<CachedLesson> schedule;

  @HiveField(2)
  final List<CachedGradeRecord> grades;

  @HiveField(3)
  final List<CachedAnnouncement> announcements;

  @HiveField(4)
  final List<CachedStudentDocument> documents;

  @HiveField(5)
  final DateTime cachedAt;

  @HiveField(6)
  final String studentId;

  CachedStudentData({
    required this.profile,
    required this.schedule,
    required this.grades,
    required this.announcements,
    required this.documents,
    required this.cachedAt,
    required this.studentId,
  });

  /// Check if the cached data is still fresh (less than 1 hour old)
  bool get isFresh {
    final age = DateTime.now().difference(cachedAt);
    return age.inHours < 1;
  }

  /// Check if the cached data is stale (more than 24 hours old)
  bool get isStale {
    final age = DateTime.now().difference(cachedAt);
    return age.inHours > 24;
  }

  /// Get the age of the cached data
  Duration get age => DateTime.now().difference(cachedAt);
}