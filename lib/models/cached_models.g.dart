// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedStudentProfileAdapter extends TypeAdapter<CachedStudentProfile> {
  @override
  final int typeId = 0;

  @override
  CachedStudentProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedStudentProfile(
      id: fields[0] as String,
      email: fields[1] as String,
      fullName: fields[2] as String,
      firstName: fields[3] as String?,
      groupName: fields[4] as String?,
      studentIdentifier: fields[5] as String?,
      phone: fields[6] as String?,
      curator: fields[7] as String?,
      attendance: fields[8] as double,
      completedAssignments: fields[9] as int,
      totalAssignments: fields[10] as int,
      cachedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedStudentProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.groupName)
      ..writeByte(5)
      ..write(obj.studentIdentifier)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.curator)
      ..writeByte(8)
      ..write(obj.attendance)
      ..writeByte(9)
      ..write(obj.completedAssignments)
      ..writeByte(10)
      ..write(obj.totalAssignments)
      ..writeByte(11)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedStudentProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedLessonAdapter extends TypeAdapter<CachedLesson> {
  @override
  final int typeId = 1;

  @override
  CachedLesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedLesson(
      id: fields[0] as String,
      weekday: fields[1] as int,
      time: fields[2] as String,
      subject: fields[3] as String,
      room: fields[4] as String?,
      teacher: fields[5] as String?,
      lessonType: fields[6] as String?,
      cachedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedLesson obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekday)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.room)
      ..writeByte(5)
      ..write(obj.teacher)
      ..writeByte(6)
      ..write(obj.lessonType)
      ..writeByte(7)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedLessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedGradeRecordAdapter extends TypeAdapter<CachedGradeRecord> {
  @override
  final int typeId = 2;

  @override
  CachedGradeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedGradeRecord(
      id: fields[0] as String,
      subject: fields[1] as String,
      grade: fields[2] as int,
      progress: fields[3] as double,
      teacher: fields[4] as String?,
      completedTasks: fields[5] as int,
      totalTasks: fields[6] as int,
      dateLabel: fields[7] as String?,
      cachedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedGradeRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subject)
      ..writeByte(2)
      ..write(obj.grade)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.teacher)
      ..writeByte(5)
      ..write(obj.completedTasks)
      ..writeByte(6)
      ..write(obj.totalTasks)
      ..writeByte(7)
      ..write(obj.dateLabel)
      ..writeByte(8)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedGradeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedAnnouncementAdapter extends TypeAdapter<CachedAnnouncement> {
  @override
  final int typeId = 3;

  @override
  CachedAnnouncement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAnnouncement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateLabel: fields[3] as String?,
      cachedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAnnouncement obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateLabel)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAnnouncementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedStudentDocumentAdapter extends TypeAdapter<CachedStudentDocument> {
  @override
  final int typeId = 4;

  @override
  CachedStudentDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedStudentDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      status: fields[2] as String,
      updatedAtLabel: fields[3] as String?,
      cachedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedStudentDocument obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.updatedAtLabel)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedStudentDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedStudentDataAdapter extends TypeAdapter<CachedStudentData> {
  @override
  final int typeId = 5;

  @override
  CachedStudentData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedStudentData(
      profile: fields[0] as CachedStudentProfile,
      schedule: (fields[1] as List).cast<CachedLesson>(),
      grades: (fields[2] as List).cast<CachedGradeRecord>(),
      announcements: (fields[3] as List).cast<CachedAnnouncement>(),
      documents: (fields[4] as List).cast<CachedStudentDocument>(),
      cachedAt: fields[5] as DateTime,
      studentId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedStudentData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.profile)
      ..writeByte(1)
      ..write(obj.schedule)
      ..writeByte(2)
      ..write(obj.grades)
      ..writeByte(3)
      ..write(obj.announcements)
      ..writeByte(4)
      ..write(obj.documents)
      ..writeByte(5)
      ..write(obj.cachedAt)
      ..writeByte(6)
      ..write(obj.studentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedStudentDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
