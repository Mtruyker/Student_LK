import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../shared/exceptions.dart';
import 'student_repository.dart';

class DemoStudentRepository implements StudentRepository {
  DemoStudentRepository();

  bool _isAuthorized = false;
  ThemeMode _themeMode = ThemeMode.system;
  StudentCabinetData _currentCabinet = _cabinetData;

  @override
  String get demoEmail => _demoProfile.email;

  @override
  String get demoPassword => 'student123';

  @override
  Future<bool> restoreSession() async => false;

  @override
  Future<ThemeMode?> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  Future<StudentCabinetData> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (email.trim().toLowerCase() != demoEmail.toLowerCase()) {
      throw const AppAuthException('Пользователь с таким e-mail не найден.');
    }

    if (password != demoPassword) {
      throw const AppAuthException(
          'Неверный пароль. Для демо используйте student123.');
    }

    _isAuthorized = true;
    return _currentCabinet;
  }

  @override
  Future<StudentCabinetData> signUp({
    required String fullName,
    required String group,
    required String email,
    required String password,
    String phone = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (email.trim().toLowerCase() == demoEmail.toLowerCase()) {
      throw const AppAuthException(
          'Пользователь с таким e-mail уже зарегистрирован.');
    }

    if (password.length < 6) {
      throw const AppAuthException(
          'Пароль должен содержать минимум 6 символов.');
    }

    _isAuthorized = true;
    _currentCabinet = _buildDemoCabinetData(
      fullName: fullName,
      group: group,
      email: email,
      phone: phone,
    );
    return _currentCabinet;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (email.trim().isEmpty || !email.contains('@')) {
      throw const AppDataException(
        'Введите корректный e-mail для восстановления доступа.',
      );
    }
  }

  @override
  Future<StudentCabinetData> fetchCabinet() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!_isAuthorized) {
      throw const AppAuthException('Сессия истекла. Выполните вход снова.');
    }

    return _currentCabinet;
  }

  @override
  Future<StudentCabinetData> requestCertificate({
    String type = 'Справка об обучении',
    String comment = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!_isAuthorized) {
      throw const AppAuthException('Сессия истекла. Выполните вход снова.');
    }

    final normalizedType = type.trim().isEmpty ? 'Справка об обучении' : type;
    final normalizedComment = comment.trim();
    final nowLabel = _formatNowLabel(DateTime.now());

    final documents = <StudentDocument>[
      StudentDocument(
        title: '$normalizedType.pdf',
        status: 'Запрошен',
        updatedAt: 'Заявка отправлена $nowLabel',
      ),
      ..._currentCabinet.documents,
    ];

    final announcementText = normalizedComment.isEmpty
        ? 'Запрос на "$normalizedType" отправлен в учебную часть.'
        : 'Запрос на "$normalizedType" отправлен. Комментарий: $normalizedComment';
    final announcements = <StudentAnnouncement>[
      StudentAnnouncement(
        title: 'Запрос справки принят',
        description: announcementText,
        dateLabel: 'сейчас',
      ),
      ..._currentCabinet.announcements,
    ];

    _currentCabinet = StudentCabinetData(
      profile: _currentCabinet.profile,
      schedule: _currentCabinet.schedule,
      grades: _currentCabinet.grades,
      documents: documents,
      announcements: announcements,
    );

    return _currentCabinet;
  }

  @override
  Future<StudentCabinetData> contactCurator({
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!_isAuthorized) {
      throw const AppAuthException('Сессия истекла. Выполните вход снова.');
    }

    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      throw const AppDataException('Введите сообщение для куратора.');
    }

    final announcements = <StudentAnnouncement>[
      StudentAnnouncement(
        title: 'Сообщение куратору отправлено',
        description: 'Ваше сообщение: "$normalizedMessage".',
        dateLabel: 'сейчас',
      ),
      ..._currentCabinet.announcements,
    ];

    _currentCabinet = StudentCabinetData(
      profile: _currentCabinet.profile,
      schedule: _currentCabinet.schedule,
      grades: _currentCabinet.grades,
      documents: _currentCabinet.documents,
      announcements: announcements,
    );

    return _currentCabinet;
  }

  @override
  Future<void> signOut() async {
    _isAuthorized = false;
  }

  String _formatNowLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}

// ── Demo data ───────────────────────────────────────────────────────

const StudentProfile _demoProfile = StudentProfile(
  fullName: 'Иван Иванов',
  firstName: 'Иван',
  group: 'АТ-21',
  studentId: 'AT2101234',
  email: 'ivan@example.com',
  phone: '+7 (999) 123-45-67',
  curator: 'Марина Петровна Соколова',
  attendance: 0.94,
  completedAssignments: 18,
  totalAssignments: 21,
);

const StudentCabinetData _cabinetData = StudentCabinetData(
  profile: _demoProfile,
  schedule: [
    Lesson(
      weekday: DateTime.monday,
      time: '08:00',
      subject: 'Агрономия',
      room: '101',
      teacher: 'А. Н. Сергеев',
      type: 'Лекция',
    ),
    Lesson(
      weekday: DateTime.monday,
      time: '10:00',
      subject: 'Механизация',
      room: '205',
      teacher: 'И. В. Андреев',
      type: 'Практика',
    ),
    Lesson(
      weekday: DateTime.monday,
      time: '14:00',
      subject: 'Экономика',
      room: '302',
      teacher: 'Т. А. Белова',
      type: 'Семинар',
    ),
    Lesson(
      weekday: DateTime.tuesday,
      time: '09:00',
      subject: 'Ботаника',
      room: '203',
      teacher: 'Н. С. Макарова',
      type: 'Лабораторная',
    ),
    Lesson(
      weekday: DateTime.tuesday,
      time: '11:00',
      subject: 'Почвоведение',
      room: '118',
      teacher: 'Д. П. Яковлев',
      type: 'Лекция',
    ),
    Lesson(
      weekday: DateTime.wednesday,
      time: '08:30',
      subject: 'Технология растениеводства',
      room: '214',
      teacher: 'Е. К. Смирнова',
      type: 'Практика',
    ),
    Lesson(
      weekday: DateTime.wednesday,
      time: '12:00',
      subject: 'Экономика',
      room: '302',
      teacher: 'Т. А. Белова',
      type: 'Лекция',
    ),
    Lesson(
      weekday: DateTime.thursday,
      time: '10:00',
      subject: 'Охрана труда',
      room: '110',
      teacher: 'Л. П. Романова',
      type: 'Лекция',
    ),
    Lesson(
      weekday: DateTime.thursday,
      time: '13:00',
      subject: 'Механизация',
      room: '205',
      teacher: 'И. В. Андреев',
      type: 'Лабораторная',
    ),
    Lesson(
      weekday: DateTime.friday,
      time: '09:30',
      subject: 'Агрономия',
      room: '101',
      teacher: 'А. Н. Сергеев',
      type: 'Практика',
    ),
    Lesson(
      weekday: DateTime.friday,
      time: '11:30',
      subject: 'Физическая культура',
      room: 'Спортзал',
      teacher: 'О. М. Крылов',
      type: 'Занятие',
    ),
  ],
  grades: [
    GradeRecord(
      subject: 'Агрономия',
      grade: 5,
      progress: 0.92,
      completedTasks: 6,
      totalTasks: 6,
      teacher: 'А. Н. Сергеев',
    ),
    GradeRecord(
      subject: 'Ботаника',
      grade: 4,
      progress: 0.81,
      completedTasks: 4,
      totalTasks: 5,
      teacher: 'Н. С. Макарова',
    ),
    GradeRecord(
      subject: 'Механизация',
      grade: 5,
      progress: 0.96,
      completedTasks: 5,
      totalTasks: 5,
      teacher: 'И. В. Андреев',
    ),
    GradeRecord(
      subject: 'Экономика',
      grade: 4,
      progress: 0.86,
      completedTasks: 3,
      totalTasks: 4,
      teacher: 'Т. А. Белова',
    ),
    GradeRecord(
      subject: 'Почвоведение',
      grade: 5,
      progress: 0.89,
      completedTasks: 4,
      totalTasks: 5,
      teacher: 'Д. П. Яковлев',
    ),
  ],
  documents: [
    StudentDocument(
      title: 'Договор обучения.pdf',
      status: 'Доступен',
      updatedAt: 'Обновлен 15 февраля',
    ),
    StudentDocument(
      title: 'Справка студента.pdf',
      status: 'Подготовлен',
      updatedAt: 'Обновлен 1 марта',
    ),
    StudentDocument(
      title: 'Индивидуальный учебный план.pdf',
      status: 'Требует подпись',
      updatedAt: 'Обновлен 27 февраля',
    ),
  ],
  announcements: [
    StudentAnnouncement(
      title: 'Практика в тепличном комплексе',
      description:
          'В пятницу сбор у главного корпуса в 08:45. Не забудьте спецодежду.',
      dateLabel: '7 марта',
    ),
    StudentAnnouncement(
      title: 'Окно подачи заявления',
      description:
          'До 12 марта можно отправить запрос на справку об обучении в электронном виде.',
      dateLabel: 'до 12 марта',
    ),
  ],
);

StudentCabinetData _buildDemoCabinetData({
  required String fullName,
  required String group,
  required String email,
  String phone = '',
}) {
  return StudentCabinetData(
    profile: StudentProfile(
      fullName: fullName,
      firstName: fullName.trim().split(RegExp(r'\s+')).first,
      group: group,
      studentId: 'STU${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      phone: phone,
      curator: 'Куратор будет назначен',
      attendance: 0,
      completedAssignments: 0,
      totalAssignments: 0,
    ),
    schedule: const <Lesson>[],
    grades: const <GradeRecord>[],
    documents: const <StudentDocument>[
      StudentDocument(
        title: 'Памятка первокурсника.pdf',
        status: 'Доступен',
        updatedAt: 'Создан при регистрации',
      ),
    ],
    announcements: const <StudentAnnouncement>[
      StudentAnnouncement(
        title: 'Аккаунт создан',
        description: 'Заполните профиль и дождитесь назначения расписания.',
        dateLabel: 'сейчас',
      ),
    ],
  );
}
