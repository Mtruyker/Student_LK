import 'package:excel/excel.dart';

import '../constants/admin_groups.dart';
import '../models/admin_models.dart';
import 'excel_parse_helpers.dart';

class ScheduleExcelImporter {
  static const List<String> _minimumColumns = <String>[
    'weekday',
    'time',
    'subject',
  ];

  static List<AdminLesson> parse(
    List<int> bytes, {
    String? groupHint,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('Excel-файл не содержит листов.');
    }

    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const FormatException('Excel-файл пуст.');
    }

    String? structuredError;
    try {
      final lessons = _parseStructuredRows(rows);
      if (lessons.isNotEmpty) return lessons;
    } on FormatException catch (error) {
      structuredError = error.message;
    }

    final normalizedGroup = normalizeAdminGroup(groupHint ?? '');
    if (normalizedGroup.isNotEmpty) {
      final groupLessons = _parseGroupGridRows(rows, groupHint: groupHint!);
      if (groupLessons.isNotEmpty) return groupLessons;
    }

    if (structuredError != null && structuredError.trim().isNotEmpty) {
      throw FormatException(
        '$structuredError Дополнительно проверьте, что в файле есть колонка группы '
        '(${groupHint ?? 'не указана'}) для сеточного формата.',
      );
    }
    throw const FormatException(
      'Не удалось распознать формат расписания в Excel-файле.',
    );
  }

  static Map<String, List<AdminLesson>> parseGroupGridForAllGroups(
    List<int> bytes,
  ) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('Excel-файл не содержит листов.');
    }

    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw const FormatException('Excel-файл пуст.');
    }

    return _parseGroupGridAll(rows);
  }

  // ── Structured format ───────────────────────────────────────────

  static List<AdminLesson> _parseStructuredRows(List<List<Data?>> rows) {
    final firstDataRowIndex = rows.indexWhere(rowHasValues);
    if (firstDataRowIndex < 0) {
      throw const FormatException('Excel-файл не содержит данных.');
    }

    final headerMap = tryParseHeader(rows[firstDataRowIndex]);
    var startRowIndex = firstDataRowIndex;
    if (headerMap != null) {
      final missing = _minimumColumns
          .where((key) => !headerMap.containsKey(key))
          .toList(growable: false);
      if (missing.isNotEmpty) {
        throw FormatException(
          'В заголовке не хватает колонок: ${missing.join(', ')}.',
        );
      }
      startRowIndex += 1;
    }

    final lessons = <AdminLesson>[];
    for (var rowIndex = startRowIndex; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (!rowHasValues(row)) continue;

      final weekdayText =
          readColumnValue(row, headerMap: headerMap, key: 'weekday', index: 0);
      final time =
          readColumnValue(row, headerMap: headerMap, key: 'time', index: 1);
      final subject =
          readColumnValue(row, headerMap: headerMap, key: 'subject', index: 2);
      final room =
          readColumnValue(row, headerMap: headerMap, key: 'room', index: 3);
      final teacher =
          readColumnValue(row, headerMap: headerMap, key: 'teacher', index: 4);
      final type =
          readColumnValue(row, headerMap: headerMap, key: 'type', index: 5);

      final isEmpty = weekdayText.isEmpty &&
          time.isEmpty &&
          subject.isEmpty &&
          room.isEmpty &&
          teacher.isEmpty &&
          type.isEmpty;
      if (isEmpty) continue;

      final weekday = parseWeekday(weekdayText);
      if (weekday == null) {
        throw FormatException(
          'Строка ${rowIndex + 1}: не удалось определить день недели "$weekdayText".',
        );
      }

      if (time.isEmpty ||
          subject.isEmpty ||
          (room.isEmpty && teacher.isEmpty && type.isEmpty)) {
        throw FormatException(
          'Строка ${rowIndex + 1}: заполните минимум день, время и предмет.',
        );
      }

      lessons.add(
        AdminLesson(
          weekday: weekday,
          time: resolveLessonTime(time, weekday: weekday),
          subject: subject,
          room: room.isEmpty ? '—' : room,
          teacher: teacher.isEmpty ? 'Не указан' : teacher,
          type: type.isEmpty ? 'Занятие' : type,
        ),
      );
    }

    if (lessons.isEmpty) {
      throw const FormatException(
        'В файле нет валидных строк расписания.',
      );
    }

    return lessons;
  }

  // ── Group grid (single group) ───────────────────────────────────

  static List<AdminLesson> _parseGroupGridRows(
    List<List<Data?>> rows, {
    required String groupHint,
  }) {
    final normalizedGroup = normalizeAdminGroup(groupHint);
    if (normalizedGroup.isEmpty) return const <AdminLesson>[];

    final fixedTemplateLessons = _tryParseFixedGroupGridAll(rows);
    if (fixedTemplateLessons != null) {
      if (!supportedAdminNormalizedGroups.contains(normalizedGroup)) {
        throw FormatException(
          'Группа "$groupHint" отсутствует в этом шаблоне. '
          'Допустимые группы: ${supportedAdminGroups.join(', ')}.',
        );
      }

      final lessons = fixedTemplateLessons[normalizedGroup];
      if (lessons == null || lessons.isEmpty) {
        throw FormatException(
          'По группе "$groupHint" не найдено занятий с заполненными ячейками.',
        );
      }
      return lessons;
    }

    final byGroups = _parseGroupGridAll(rows);
    final lessons = byGroups[normalizedGroup];
    if (lessons == null || lessons.isEmpty) {
      throw FormatException(
        'По группе "$groupHint" не найдено занятий с заполненными ячейками.',
      );
    }

    return lessons;
  }

  // ── Group grid (all groups) ─────────────────────────────────────

  static Map<String, List<AdminLesson>> _parseGroupGridAll(
    List<List<Data?>> rows,
  ) {
    final fixedTemplateLessons = _tryParseFixedGroupGridAll(rows);
    if (fixedTemplateLessons != null) return fixedTemplateLessons;

    final timeColumnIndex = findLikelyTimeColumn(rows);
    if (timeColumnIndex < 0) {
      throw const FormatException(
        'Не найдена колонка с временными слотами (например, 1-2, 3-4).',
      );
    }

    final firstTimeRow = rows.indexWhere(
      (row) => isTimeSlot(
        readColumnValue(row, headerMap: null, key: 'time', index: timeColumnIndex),
      ),
    );
    final headerSearchEnd = firstTimeRow > 0 ? firstTimeRow : 25;

    var headerRowIndex = -1;
    var headerCandidates = <_GroupColumn>[];
    for (var rowIndex = 0;
        rowIndex < rows.length && rowIndex <= headerSearchEnd;
        rowIndex++) {
      final row = rows[rowIndex];
      final candidates = <_GroupColumn>[];
      final seen = <String>{};
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final label = cellToText(row[columnIndex]);
        if (!isGroupLabel(label)) continue;
        final normalized = normalizeAdminGroup(label);
        if (normalized.isEmpty || seen.contains(normalized)) continue;
        seen.add(normalized);
        candidates.add(
          _GroupColumn(
            normalizedGroup: normalized,
            subjectColumnIndex: columnIndex,
            roomColumnIndex: columnIndex + 1,
          ),
        );
      }

      if (candidates.length > headerCandidates.length) {
        headerCandidates = candidates;
        headerRowIndex = rowIndex;
      }
    }

    if (headerRowIndex < 0 || headerCandidates.isEmpty) {
      throw const FormatException(
        'В сеточном формате не удалось найти строку с названиями групп.',
      );
    }

    final byGroups = <String, List<AdminLesson>>{};
    int? currentWeekday;
    for (var rowIndex = headerRowIndex + 1;
        rowIndex < rows.length;
        rowIndex++) {
      final row = rows[rowIndex];
      final weekdayFromRow = extractWeekdayNameFromRow(row);
      if (weekdayFromRow != null) currentWeekday = weekdayFromRow;

      final time = readColumnValue(
        row, headerMap: null, key: 'time', index: timeColumnIndex,
      );
      if (!isTimeSlot(time) || currentWeekday == null) continue;

      for (final group in headerCandidates) {
        final subject = readColumnValue(
          row, headerMap: null, key: 'subject', index: group.subjectColumnIndex,
        );
        if (subject.isEmpty) continue;
        final room = readColumnValue(
          row, headerMap: null, key: 'room', index: group.roomColumnIndex,
        );

        byGroups.putIfAbsent(group.normalizedGroup, () => <AdminLesson>[]);
        byGroups[group.normalizedGroup]!.add(
          AdminLesson(
            weekday: currentWeekday,
            time: resolveLessonTime(time, weekday: currentWeekday),
            subject: subject.replaceAll(RegExp(r'\s+'), ' ').trim(),
            room: room.isEmpty ? '—' : room,
            teacher: 'Не указан',
            type: 'Занятие',
          ),
        );
      }
    }

    byGroups.removeWhere((_, lessons) => lessons.isEmpty);
    if (byGroups.isEmpty) {
      throw const FormatException(
        'В сеточном формате не найдено ни одной заполненной пары для групп.',
      );
    }

    return byGroups;
  }

  // ── Fixed template format ───────────────────────────────────────

  static Map<String, List<AdminLesson>>? _tryParseFixedGroupGridAll(
    List<List<Data?>> rows,
  ) {
    final header = _findFixedTemplateHeader(rows);
    if (header == null) return null;

    final byGroups = <String, List<AdminLesson>>{};
    int? currentWeekday;
    for (var rowIndex = header.headerRowIndex + 1;
        rowIndex < rows.length;
        rowIndex++) {
      final row = rows[rowIndex];
      final weekdayText = readColumnValue(
        row, headerMap: null, key: 'weekday', index: header.weekdayColumnIndex,
      );
      final weekdayFromRow = parseWeekdayFromText(weekdayText);
      if (weekdayFromRow != null) currentWeekday = weekdayFromRow;

      final time = readColumnValue(
        row, headerMap: null, key: 'time', index: header.timeColumnIndex,
      );
      if (!isTimeSlot(time) || currentWeekday == null) continue;

      for (final group in header.groupColumns) {
        final subject = normalizeCellText(
          readColumnValue(
            row, headerMap: null, key: 'subject', index: group.subjectColumnIndex,
          ),
        );
        if (subject.isEmpty || isNonLessonSubject(subject)) continue;

        final room = normalizeCellText(
          readColumnValue(
            row, headerMap: null, key: 'room', index: group.roomColumnIndex,
          ),
        );

        byGroups.putIfAbsent(group.normalizedGroup, () => <AdminLesson>[]);
        byGroups[group.normalizedGroup]!.add(
          AdminLesson(
            weekday: currentWeekday,
            time: resolveLessonTime(time, weekday: currentWeekday),
            subject: subject,
            room: room.isEmpty ? '—' : room,
            teacher: 'Не указан',
            type: 'Занятие',
          ),
        );
      }
    }

    byGroups.removeWhere((_, lessons) => lessons.isEmpty);
    if (byGroups.isEmpty) {
      throw const FormatException(
        'В Excel-шаблоне не найдено ни одной заполненной пары для поддерживаемых групп.',
      );
    }

    return byGroups;
  }

  static _FixedTemplateHeader? _findFixedTemplateHeader(
    List<List<Data?>> rows,
  ) {
    final headerScanLimit = rows.length < 20 ? rows.length : 20;
    for (var rowIndex = 0; rowIndex < headerScanLimit; rowIndex++) {
      final row = rows[rowIndex];
      final weekdayKey = headerAliasToKey(
        normalizeHeader(
          readColumnValue(row, headerMap: null, key: 'weekday', index: 0),
        ),
      );
      final timeKey = headerAliasToKey(
        normalizeHeader(
          readColumnValue(row, headerMap: null, key: 'time', index: 1),
        ),
      );
      if (weekdayKey != 'weekday' || timeKey != 'time') continue;

      final groupColumns = <_GroupColumn>[];
      final unsupportedLabels = <String>[];
      final seen = <String>{};
      for (var columnIndex = 2; columnIndex < row.length; columnIndex++) {
        final label = cellToText(row[columnIndex]);
        if (!isGroupLabel(label)) continue;

        final normalized = normalizeAdminGroup(label);
        if (!seen.add(normalized)) continue;

        if (!supportedAdminNormalizedGroups.contains(normalized)) {
          unsupportedLabels.add(label.trim());
          continue;
        }

        groupColumns.add(
          _GroupColumn(
            normalizedGroup: normalized,
            subjectColumnIndex: columnIndex,
            roomColumnIndex: columnIndex + 1,
          ),
        );
      }

      if (groupColumns.length < 8) continue;

      if (unsupportedLabels.isNotEmpty) {
        throw FormatException(
          'В шаблоне найдены неподдерживаемые группы: '
          '${unsupportedLabels.join(', ')}. '
          'Допустимые группы: ${supportedAdminGroups.join(', ')}.',
        );
      }

      return _FixedTemplateHeader(
        headerRowIndex: rowIndex,
        weekdayColumnIndex: 0,
        timeColumnIndex: 1,
        groupColumns: groupColumns,
      );
    }

    return null;
  }
}

class _GroupColumn {
  const _GroupColumn({
    required this.normalizedGroup,
    required this.subjectColumnIndex,
    required this.roomColumnIndex,
  });

  final String normalizedGroup;
  final int subjectColumnIndex;
  final int roomColumnIndex;
}

class _FixedTemplateHeader {
  const _FixedTemplateHeader({
    required this.headerRowIndex,
    required this.weekdayColumnIndex,
    required this.timeColumnIndex,
    required this.groupColumns,
  });

  final int headerRowIndex;
  final int weekdayColumnIndex;
  final int timeColumnIndex;
  final List<_GroupColumn> groupColumns;
}
