import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../repositories/student_repository.dart';
import '../shared/exceptions.dart';
import '../shared/helpers.dart' as shared;

/// Состояние расписания занятий
class ScheduleState extends ChangeNotifier {
  ScheduleState(this._repository)
      : _selectedWeekday = _initialScheduleWeekday(DateTime.now());

  final StudentRepository _repository;

  List<Lesson> _schedule = [];
  late int _selectedWeekday;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Lesson> get schedule => _schedule;
  int get selectedWeekday => _selectedWeekday;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<int> get supportedWeekdays => const <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ];

  /// Уроки для выбранного дня недели
  List<Lesson> get selectedLessons => _lessonsForWeekday(_selectedWeekday);

  /// Уроки на сегодня
  List<Lesson> get todayLessons => _lessonsForWeekday(DateTime.now().weekday);

  /// Следующий урок
  Lesson? get nextLesson {
    final now = DateTime.now();
    final lessonsToday = _lessonsForWeekday(now.weekday);

    for (final lesson in lessonsToday) {
      final lessonTime = _lessonStartDateTime(now, lesson.time);
      if (lessonTime == null) {
        continue;
      }

      if (lessonTime.isAfter(now)) {
        return lesson;
      }
    }

    return null;
  }

  /// Загрузка расписания
  Future<void> loadSchedule(List<Lesson> lessons) async {
    _schedule = lessons;
    _error = null;
    notifyListeners();
  }

  /// Обновление расписания
  Future<void> refreshSchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cabinetData = await _repository.fetchCabinet();
      _schedule = cabinetData.schedule;
    } on AppAuthException catch (error) {
      _error = error.message;
      rethrow; // Пробрасываем auth ошибки выше
    } on AppDataException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Не удалось обновить расписание.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Выбор дня недели
  void selectWeekday(int weekday) {
    if (_selectedWeekday == weekday) {
      return;
    }

    _selectedWeekday = weekday;
    notifyListeners();
  }

  /// Получение названия дня недели
  String weekdayLabel(int weekday) => shared.weekdayLabel(weekday);

  /// Очистка ошибок
  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }

  /// Получение уроков для конкретного дня недели
  List<Lesson> _lessonsForWeekday(int weekday) {
    final lessons =
        _schedule.where((lesson) => lesson.weekday == weekday).toList()
          ..sort((a, b) {
            final left = _lessonStartMinutes(a.time);
            final right = _lessonStartMinutes(b.time);
            if (left != null && right != null) {
              return left.compareTo(right);
            }
            if (left != null) {
              return -1;
            }
            if (right != null) {
              return 1;
            }
            return a.time.compareTo(b.time);
          });
    return lessons;
  }
}

/// Получение времени начала урока как DateTime
DateTime? _lessonStartDateTime(DateTime day, String value) {
  final startMinutes = _lessonStartMinutes(value);
  if (startMinutes == null) {
    return null;
  }

  return DateTime(
    day.year,
    day.month,
    day.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );
}

/// Получение времени начала урока в минутах от начала дня
int? _lessonStartMinutes(String value) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return (hour * 60) + minute;
}

/// Определение начального дня недели для расписания
int _initialScheduleWeekday(DateTime now) {
  if (now.weekday < DateTime.monday || now.weekday > DateTime.friday) {
    return DateTime.monday;
  }

  return now.weekday;
}