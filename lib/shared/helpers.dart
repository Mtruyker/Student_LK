String weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Понедельник';
    case DateTime.tuesday:
      return 'Вторник';
    case DateTime.wednesday:
      return 'Среда';
    case DateTime.thursday:
      return 'Четверг';
    case DateTime.friday:
      return 'Пятница';
    case DateTime.saturday:
      return 'Суббота';
    case DateTime.sunday:
      return 'Воскресенье';
    default:
      return 'День';
  }
}
