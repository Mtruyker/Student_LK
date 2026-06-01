import 'dart:convert';

import 'config.dart';

class DemoStudentStore {
  DemoStudentStore(this._config);

  final ServerConfig _config;

  String get demoEmail => _config.demoStudentEmail;
  String get demoPassword => _config.demoStudentPassword;

  bool validateCredentials({
    required String email,
    required String password,
  }) {
    return email.trim().toLowerCase() == demoEmail.toLowerCase() &&
        password == demoPassword;
  }

  Map<String, dynamic> getCabinetByEmail(String email) {
    if (email.trim().toLowerCase() != demoEmail.toLowerCase()) {
      throw StateError('Student not found');
    }

    return jsonDecode(jsonEncode(_cabinetTemplate(email)))
        as Map<String, dynamic>;
  }

  Map<String, dynamic> _cabinetTemplate(String email) {
    return <String, dynamic>{
      'profile': <String, dynamic>{
        'fullName': 'Иван Иванов',
        'firstName': 'Иван',
        'group': 'АТ-21',
        'studentId': 'AT2101234',
        'email': email,
        'phone': '+7 (999) 123-45-67',
        'curator': 'Марина Петровна Соколова',
        'attendance': 0.94,
        'completedAssignments': 18,
        'totalAssignments': 21,
      },
      'schedule': <Map<String, dynamic>>[
        {
          'weekday': 1,
          'time': '08:00',
          'subject': 'Агрономия',
          'room': '101',
          'teacher': 'А. Н. Сергеев',
          'type': 'Лекция',
        },
        {
          'weekday': 1,
          'time': '10:00',
          'subject': 'Механизация',
          'room': '205',
          'teacher': 'И. В. Андреев',
          'type': 'Практика',
        },
        {
          'weekday': 1,
          'time': '14:00',
          'subject': 'Экономика',
          'room': '302',
          'teacher': 'Т. А. Белова',
          'type': 'Семинар',
        },
        {
          'weekday': 2,
          'time': '09:00',
          'subject': 'Ботаника',
          'room': '203',
          'teacher': 'Н. С. Макарова',
          'type': 'Лабораторная',
        },
        {
          'weekday': 2,
          'time': '11:00',
          'subject': 'Почвоведение',
          'room': '118',
          'teacher': 'Д. П. Яковлев',
          'type': 'Лекция',
        },
        {
          'weekday': 3,
          'time': '08:30',
          'subject': 'Технология растениеводства',
          'room': '214',
          'teacher': 'Е. К. Смирнова',
          'type': 'Практика',
        },
        {
          'weekday': 3,
          'time': '12:00',
          'subject': 'Экономика',
          'room': '302',
          'teacher': 'Т. А. Белова',
          'type': 'Лекция',
        },
        {
          'weekday': 4,
          'time': '10:00',
          'subject': 'Охрана труда',
          'room': '110',
          'teacher': 'Л. П. Романова',
          'type': 'Лекция',
        },
        {
          'weekday': 4,
          'time': '13:00',
          'subject': 'Механизация',
          'room': '205',
          'teacher': 'И. В. Андреев',
          'type': 'Лабораторная',
        },
        {
          'weekday': 5,
          'time': '09:30',
          'subject': 'Агрономия',
          'room': '101',
          'teacher': 'А. Н. Сергеев',
          'type': 'Практика',
        },
        {
          'weekday': 5,
          'time': '11:30',
          'subject': 'Физическая культура',
          'room': 'Спортзал',
          'teacher': 'О. М. Крылов',
          'type': 'Занятие',
        },
      ],
      'grades': <Map<String, dynamic>>[
        {
          'subject': 'Агрономия',
          'grade': 5,
          'progress': 0.92,
          'completedTasks': 6,
          'totalTasks': 6,
          'teacher': 'А. Н. Сергеев',
        },
        {
          'subject': 'Ботаника',
          'grade': 4,
          'progress': 0.81,
          'completedTasks': 4,
          'totalTasks': 5,
          'teacher': 'Н. С. Макарова',
        },
        {
          'subject': 'Механизация',
          'grade': 5,
          'progress': 0.96,
          'completedTasks': 5,
          'totalTasks': 5,
          'teacher': 'И. В. Андреев',
        },
        {
          'subject': 'Экономика',
          'grade': 4,
          'progress': 0.86,
          'completedTasks': 3,
          'totalTasks': 4,
          'teacher': 'Т. А. Белова',
        },
        {
          'subject': 'Почвоведение',
          'grade': 5,
          'progress': 0.89,
          'completedTasks': 4,
          'totalTasks': 5,
          'teacher': 'Д. П. Яковлев',
        },
      ],
      'documents': <Map<String, dynamic>>[
        {
          'title': 'Договор обучения.pdf',
          'status': 'Доступен',
          'updatedAt': 'Обновлен 15 февраля',
        },
        {
          'title': 'Справка студента.pdf',
          'status': 'Подготовлен',
          'updatedAt': 'Обновлен 1 марта',
        },
        {
          'title': 'Индивидуальный учебный план.pdf',
          'status': 'Требует подпись',
          'updatedAt': 'Обновлен 27 февраля',
        },
      ],
      'announcements': <Map<String, dynamic>>[
        {
          'title': 'Практика в тепличном комплексе',
          'description':
              'В пятницу сбор у главного корпуса в 08:45. Не забудьте спецодежду.',
          'dateLabel': '7 марта',
        },
        {
          'title': 'Окно подачи заявления',
          'description':
              'До 12 марта можно отправить запрос на справку об обучении в электронном виде.',
          'dateLabel': 'до 12 марта',
        },
      ],
    };
  }
}
