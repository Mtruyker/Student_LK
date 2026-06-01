import 'package:excel/excel.dart';

// ── Bell schedules ──────────────────────────────────────────────────

const Map<String, String> defaultBellSchedule = <String, String>{
  '1-2': '08:30-10:00',
  '3-4': '10:10-11:40',
  '5-6': '12:10-13:40',
  '7-8': '13:50-15:20',
};

const Map<String, String> mondayBellSchedule = <String, String>{
  '1-2': '09:40-11:10',
  '3-4': '11:20-12:50',
  '5-6': '13:20-14:50',
};

const Map<String, String> thursdayBellSchedule = <String, String>{
  '1-2': '08:30-10:00',
  '3-4': '10:10-11:40',
  '5-6': '12:10-13:40',
  '7-8': '13:50-14:50',
};

// ── Weekday parsing ─────────────────────────────────────────────────

const Map<String, int> _weekdayMap = <String, int>{
  '1': DateTime.monday,
  '2': DateTime.tuesday,
  '3': DateTime.wednesday,
  '4': DateTime.thursday,
  '5': DateTime.friday,
  '6': DateTime.saturday,
  '7': DateTime.sunday,
  'monday': DateTime.monday,
  'mon': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'tue': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'wed': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'thu': DateTime.thursday,
  'friday': DateTime.friday,
  'fri': DateTime.friday,
  'saturday': DateTime.saturday,
  'sat': DateTime.saturday,
  'sunday': DateTime.sunday,
  'sun': DateTime.sunday,
  'понедельник': DateTime.monday,
  'пн': DateTime.monday,
  'вторник': DateTime.tuesday,
  'вт': DateTime.tuesday,
  'среда': DateTime.wednesday,
  'ср': DateTime.wednesday,
  'четверг': DateTime.thursday,
  'чт': DateTime.thursday,
  'пятница': DateTime.friday,
  'пт': DateTime.friday,
  'суббота': DateTime.saturday,
  'сб': DateTime.saturday,
  'воскресенье': DateTime.sunday,
  'вс': DateTime.sunday,
};

int? parseWeekdayFromText(String value) {
  final text = value.trim().toLowerCase();
  if (text.isEmpty) return null;

  final asInt = int.tryParse(text);
  if (asInt != null && asInt >= 1 && asInt <= 7) return asInt;

  final compact =
      text.replaceAll('.', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  final exact = _weekdayMap[compact];
  if (exact != null) return exact;

  for (final entry in _weekdayMap.entries) {
    if (compact.startsWith('${entry.key} ')) return entry.value;
  }
  return null;
}

int? parseWeekday(String value) {
  final parsed = parseWeekdayFromText(value);
  if (parsed != null) return parsed;

  final normalized = value.trim().toLowerCase().replaceAll('.', '');
  return _weekdayMap[normalized];
}

int? parseWeekdayNameOnly(String value) {
  final parsed = parseWeekdayFromText(value);
  if (parsed != null) return parsed;

  final normalized = value.trim().toLowerCase().replaceAll('.', '');
  return _weekdayMap[normalized];
}

int? extractWeekdayNameFromRow(List<Data?> row) {
  for (final cell in row) {
    final text = cellToText(cell);
    if (text.isEmpty) continue;
    final weekday = parseWeekdayNameOnly(text);
    if (weekday != null) return weekday;
  }
  return null;
}

// ── Cell & header utilities ─────────────────────────────────────────

String cellToText(Data? data) {
  final value = data?.value;
  if (value == null) return '';
  if (value is TextCellValue) return value.value.toString().trim();
  if (value is IntCellValue) return value.value.toString().trim();
  if (value is DoubleCellValue) {
    final number = value.value;
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toString();
  }
  if (value is DateTimeCellValue) {
    final dt = value.asDateTimeLocal();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  if (value is TimeCellValue) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  return value.toString().trim();
}

bool rowHasValues(List<Data?> row) {
  return row.any((cell) => cellToText(cell).isNotEmpty);
}

String readColumnValue(
  List<Data?> row, {
  required Map<String, int>? headerMap,
  required String key,
  required int index,
}) {
  final column = headerMap?[key] ?? index;
  if (column < 0 || column >= row.length) return '';
  return cellToText(row[column]);
}

String normalizeHeader(String value) {
  final lowered = value.toLowerCase().trim();
  return lowered.replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
}

String? headerAliasToKey(String normalized) {
  const aliases = <String, List<String>>{
    'weekday': <String>[
      'weekday', 'day', 'дни', 'день', 'деньнедели', 'деньнед',
    ],
    'time': <String>[
      'time', 'часы', 'время', 'начало',
    ],
    'subject': <String>[
      'subject', 'предмет', 'дисциплина',
    ],
    'room': <String>[
      'room', 'auditory', 'аудитория', 'кабинет',
    ],
    'teacher': <String>[
      'teacher', 'преподаватель', 'препод',
    ],
    'type': <String>[
      'type', 'тип', 'вид', 'формат',
    ],
  };

  for (final entry in aliases.entries) {
    if (entry.value.contains(normalized)) return entry.key;
  }
  return null;
}

Map<String, int>? tryParseHeader(List<Data?> row) {
  final found = <String, int>{};
  for (var i = 0; i < row.length; i++) {
    final raw = cellToText(row[i]);
    if (raw.isEmpty) continue;
    final normalized = normalizeHeader(raw);
    final key = headerAliasToKey(normalized);
    if (key != null && !found.containsKey(key)) {
      found[key] = i;
    }
  }

  if (found.length >= 3) return found;
  return null;
}

// ── Time slot utilities ─────────────────────────────────────────────

bool isTimeSlot(String value) {
  final text = value.trim().toLowerCase().replaceAll(RegExp('[–—−]'), '-');
  if (text.isEmpty) return false;

  final pairPattern = RegExp(r'^\d{1,2}\s*-\s*\d{1,2}$');
  final hhmmPattern = RegExp(r'^\d{1,2}:\d{2}$');
  final rangePattern = RegExp(r'^\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}$');
  return pairPattern.hasMatch(text) ||
      hhmmPattern.hasMatch(text) ||
      rangePattern.hasMatch(text);
}

String normalizeTimeSlot(String value) {
  final text = value.trim().replaceAll(RegExp('[–—−]'), '-');
  final normalized = text.replaceAll(RegExp(r'\s*-\s*'), '-');
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}

String resolveLessonTime(String value, {required int weekday}) {
  final normalized = normalizeTimeSlot(value);
  late final Map<String, String> bellSchedule;
  switch (weekday) {
    case DateTime.monday:
      bellSchedule = mondayBellSchedule;
      break;
    case DateTime.thursday:
      bellSchedule = thursdayBellSchedule;
      break;
    default:
      bellSchedule = defaultBellSchedule;
      break;
  }
  return bellSchedule[normalized] ?? normalized;
}

// ── Group label detection ───────────────────────────────────────────

bool isGroupLabel(String value) {
  final normalized = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
  if (normalized.isEmpty) return false;
  if (isTimeSlot(value)) return false;
  if (parseWeekdayFromText(value) != null) return false;

  final hasLetter = RegExp(r'[a-zа-я]').hasMatch(normalized);
  final hasDigit = RegExp(r'\d').hasMatch(normalized);
  if (!hasLetter || !hasDigit) return false;
  if (normalized.length > 12) return false;

  const noiseWords = <String>{
    'расписание', 'семестр', 'курс', 'год', 'занятий',
  };
  for (final word in noiseWords) {
    if (normalized.contains(word)) return false;
  }
  return true;
}

String normalizeCellText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool isNonLessonSubject(String value) {
  final normalized = normalizeCellText(value).toLowerCase();
  return normalized == 'выходной' ||
      normalized == 'вых' ||
      normalized == 'нет занятий';
}

int findLikelyTimeColumn(List<List<Data?>> rows) {
  final scoreByColumn = <int, int>{};
  for (final row in rows) {
    for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
      final text = cellToText(row[columnIndex]);
      if (isTimeSlot(text)) {
        scoreByColumn[columnIndex] = (scoreByColumn[columnIndex] ?? 0) + 1;
      }
    }
  }

  if (scoreByColumn.isEmpty) return -1;

  final sorted = scoreByColumn.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final best = sorted.first;
  if (best.value < 1) return -1;
  return best.key;
}
