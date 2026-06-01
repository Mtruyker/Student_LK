import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/theme/app_colors.dart';
import '../state/student_app_state.dart';
import 'widgets/skeleton_widgets.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<StudentAppState>();

    // Show skeleton loading during initial load or refresh
    if (appState.isInitializing || appState.isRefreshing) {
      return const GradesSkeleton();
    }

    final strongest = appState.strongestSubject;
    final attention = appState.attentionSubject;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryTile(
                label: 'Средний балл',
                value: appState.averageGrade.toStringAsFixed(1),
                note: 'по ${appState.grades.length} предметам',
                accent: AppColors.studentPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Выполнено заданий',
                value:
                    '${appState.profile.completedAssignments}/${appState.profile.totalAssignments}',
                note: 'текущий семестр',
                accent: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Аналитика',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 16),
                if (strongest == null || attention == null)
                  Text(
                    'Когда появятся оценки, здесь будет виден учебный фокус семестра.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else ...<Widget>[
                  _FocusLine(
                    title: 'Сильный предмет',
                    subject: strongest.subject,
                    note:
                        'Прогресс ${(strongest.progress * 100).round()}% • преподаватель ${strongest.teacher}',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 14),
                  _FocusLine(
                    title: 'Нужно подтянуть',
                    subject: attention.subject,
                    note:
                        'Прогресс ${(attention.progress * 100).round()}% • преподаватель ${attention.teacher}',
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final grade in appState.grades) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              grade.subject,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              grade.teacher,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: appState.gradeColor(grade.grade),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${grade.grade}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text(
                        'Выполнено ${grade.completedTasks}/${grade.totalTasks}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '${(grade.progress * 100).round()}%',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: grade.progress,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        appState.gradeColor(grade.grade),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (grade != appState.grades.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String label;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.show_chart_rounded, color: accent),
            ),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FocusLine extends StatelessWidget {
  const _FocusLine({
    required this.title,
    required this.subject,
    required this.note,
    required this.color,
  });

  final String title;
  final String subject;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(subject, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(note, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
