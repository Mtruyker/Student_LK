import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/theme/app_colors.dart';
import '../state/student_app_state.dart';
import 'widgets/skeleton_widgets.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<StudentAppState>();

    // Show skeleton loading during initial load or refresh
    if (appState.isInitializing || appState.isRefreshing) {
      return const ScheduleSkeleton();
    }

    final lessons = appState.selectedLessons;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: <Widget>[
        _ScheduleHero(
          title: appState.weekdayLabel(appState.selectedWeekday),
          lessonsCount: lessons.length,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final weekday in appState.supportedWeekdays)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(appState.weekdayLabel(weekday)),
                    selected: appState.selectedWeekday == weekday,
                    onSelected: (_) =>
                        context.read<StudentAppState>().selectWeekday(weekday),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (lessons.isEmpty)
          const _EmptySchedule()
        else
          for (final lesson in lessons) ...<Widget>[
            _ScheduleCard(lesson: lesson),
            if (lesson != lessons.last) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ScheduleHero extends StatelessWidget {
  const _ScheduleHero({
    required this.title,
    required this.lessonsCount,
  });

  final String title;
  final int lessonsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  lessonsCount == 0
                      ? 'На выбранный день занятий нет'
                      : 'Запланировано пар: $lessonsCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.lesson});

  final dynamic lesson;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                lesson.time,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          lesson.subject,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lesson.type,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MetaLine(
                    icon: Icons.room_outlined,
                    text: 'Аудитория ${lesson.room}',
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(
                    icon: Icons.person_outline_rounded,
                    text: lesson.teacher,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'На выбранный день занятий нет',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Переключите день сверху, чтобы посмотреть пары на неделю.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
