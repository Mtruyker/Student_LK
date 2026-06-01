import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/admin/services/schedule_excel_importer.dart';

void main() {
  test('imports fixed admin schedule template by supported groups only', () {
    final bytes = _buildFixedTemplateWorkbook();

    final schedules = ScheduleExcelImporter.parseGroupGridForAllGroups(bytes);

    expect(schedules.containsKey('в11'), isTrue);
    expect(schedules.containsKey('мр11'), isTrue);
    expect(schedules['в11']!.length, 5);
    expect(schedules['мр11']!.length, 1);

    final firstLesson = schedules['в11']!.first;
    expect(firstLesson.weekday, DateTime.monday);
    expect(firstLesson.time, '09:40-11:10');
    expect(firstLesson.subject, 'Математика');
    expect(firstLesson.room, '101');

    final mondayThirdLesson = schedules['в11']![2];
    expect(mondayThirdLesson.weekday, DateTime.monday);
    expect(mondayThirdLesson.time, '13:20-14:50');

    final tuesdayLesson = schedules['в11']![3];
    expect(tuesdayLesson.weekday, DateTime.tuesday);
    expect(tuesdayLesson.time, '08:30-10:00');

    final thursdayLesson = schedules['в11']![4];
    expect(thursdayLesson.weekday, DateTime.thursday);
    expect(thursdayLesson.time, '13:50-14:50');
  });

  test('rejects unsupported group for fixed admin schedule template', () {
    final bytes = _buildFixedTemplateWorkbook();

    expect(
      () => ScheduleExcelImporter.parse(bytes, groupHint: 'ТЕСТ-99'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Допустимые группы'),
        ),
      ),
    );
  });
}

List<int> _buildFixedTemplateWorkbook() {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Дни');
  sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('Часы');

  const groups = <String>[
    'В-11',
    'МР-11',
    'П-11',
    'ПК-11',
    'ЭР-11',
    'В-21',
    'МР-21',
    'П-21',
    'ПК-21',
    'ЭР-21',
    'В-31',
    'П-31',
    'ПК-31',
    'ЭР-31',
    'П-41',
    'ПК-41',
  ];

  for (var index = 0; index < groups.length; index++) {
    final subjectColumn = _excelColumnName(2 + (index * 2));
    sheet.cell(CellIndex.indexByString('${subjectColumn}5')).value =
        TextCellValue(groups[index]);
  }

  sheet.cell(CellIndex.indexByString('A6')).value =
      TextCellValue('понедельник 09.02');
  sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue('1-2');
  sheet.cell(CellIndex.indexByString('C6')).value = TextCellValue('Математика');
  sheet.cell(CellIndex.indexByString('D6')).value = TextCellValue('101');
  sheet.cell(CellIndex.indexByString('E6')).value = TextCellValue('Физика');
  sheet.cell(CellIndex.indexByString('F6')).value = TextCellValue('102');

  sheet.cell(CellIndex.indexByString('B7')).value = TextCellValue('3-4');
  sheet.cell(CellIndex.indexByString('C7')).value = TextCellValue('История');
  sheet.cell(CellIndex.indexByString('D7')).value = TextCellValue('201');

  sheet.cell(CellIndex.indexByString('B8')).value = TextCellValue('5-6');
  sheet.cell(CellIndex.indexByString('C8')).value = TextCellValue('Литература');
  sheet.cell(CellIndex.indexByString('D8')).value = TextCellValue('202');

  sheet.cell(CellIndex.indexByString('A11')).value =
      TextCellValue('вторник 10.02');
  sheet.cell(CellIndex.indexByString('B11')).value = TextCellValue('1-2');
  sheet.cell(CellIndex.indexByString('C11')).value = TextCellValue('Химия');
  sheet.cell(CellIndex.indexByString('D11')).value = TextCellValue('301');
  sheet.cell(CellIndex.indexByString('E11')).value = TextCellValue('вых');

  sheet.cell(CellIndex.indexByString('A16')).value =
      TextCellValue('четверг 12.02');
  sheet.cell(CellIndex.indexByString('B16')).value = TextCellValue('7-8');
  sheet.cell(CellIndex.indexByString('C16')).value =
      TextCellValue('Информатика');
  sheet.cell(CellIndex.indexByString('D16')).value = TextCellValue('401');

  return excel.save()!;
}

String _excelColumnName(int zeroBasedIndex) {
  var index = zeroBasedIndex + 1;
  final buffer = StringBuffer();
  while (index > 0) {
    final remainder = (index - 1) % 26;
    buffer.writeCharCode('A'.codeUnitAt(0) + remainder);
    index = (index - 1) ~/ 26;
  }
  return buffer.toString().split('').reversed.join();
}
