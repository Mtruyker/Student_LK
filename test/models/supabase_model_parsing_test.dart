import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/admin/models/admin_models.dart';
import 'package:student_cabinet_flutter_app/models/student_models.dart';
import 'package:student_cabinet_flutter_app/teacher/models/teacher_models.dart';

void main() {
  test('StudentProfile reads Supabase snake_case fields', () {
    final profile = StudentProfile.fromJson(<String, dynamic>{
      'full_name': 'Иван Иванов',
      'first_name': 'Иван',
      'group_name': 'П-41',
      'student_identifier': 'STU-0001',
      'email': 'ivan@example.com',
      'phone': '+7 999 000-00-00',
      'curator': 'Мария Петрова',
      'attendance': 0.87,
      'completed_assignments': 14,
      'total_assignments': 16,
    });

    expect(profile.fullName, 'Иван Иванов');
    expect(profile.firstName, 'Иван');
    expect(profile.group, 'П-41');
    expect(profile.studentId, 'STU-0001');
    expect(profile.attendance, 0.87);
    expect(profile.completedAssignments, 14);
    expect(profile.totalAssignments, 16);
  });

  test('StudentDocument reads extended Supabase fields', () {
    final document = StudentDocument.fromJson(<String, dynamic>{
      'id': 'doc-1',
      'title': 'Справка об обучении.pdf',
      'status': 'Готов',
      'updated_at_label': 'Обновлено 11.04.2026 10:30',
      'comment': 'Можно забрать в учебной части',
    });

    expect(document.id, 'doc-1');
    expect(document.title, 'Справка об обучении.pdf');
    expect(document.status, 'Готов');
    expect(document.note, 'Можно забрать в учебной части');
    expect(document.isReady, isTrue);
  });

  test('Admin models read document and certificate request fields', () {
    final document = AdminStudentDocument.fromJson(<String, dynamic>{
      'id': 'doc-1',
      'title': 'Договор.pdf',
      'status': 'Доступен',
      'updated_at_label': 'Обновлено 11.04.2026 09:00',
    });
    final request = AdminCertificateRequest.fromJson(<String, dynamic>{
      'id': 'req-1',
      'type': 'Справка об обучении',
      'comment': 'Нужна для стипендии',
      'status': 'processing',
      'created_at': '2026-04-11T09:00:00Z',
    });

    expect(document.isReady, isTrue);
    expect(request.statusLabel, 'В работе');
    expect(request.comment, 'Нужна для стипендии');
  });

  test('Teacher models read reply and status fields', () {
    final lesson = TeacherLesson.fromJson(<String, dynamic>{
      'weekday': 2,
      'time': '10:10-11:40',
      'subject': 'Математика',
      'room': '203',
      'lesson_type': 'Лекция',
      'group_name': 'П-41',
    });
    final message = CuratorMessage.fromJson(<String, dynamic>{
      'id': 'msg-1',
      'full_name': 'Иван Иванов',
      'group_name': 'П-41',
      'message': 'Нужна справка',
      'status': 'answered',
      'teacher_reply': 'Подготовлю к пятнице.',
      'teacher_reply_at': '2026-04-11T12:30:00Z',
      'created_at': '2026-04-10T12:00:00Z',
    });

    expect(lesson.type, 'Лекция');
    expect(lesson.groups, <String>['П-41']);
    expect(message.studentName, 'Иван Иванов');
    expect(message.group, 'П-41');
    expect(message.statusLabel, 'Отвечено');
    expect(message.hasReply, isTrue);
    expect(message.teacherReply, 'Подготовлю к пятнице.');
  });
}
