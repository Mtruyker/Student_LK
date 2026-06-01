library teacher_dashboard_page;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/status_banner.dart';
import '../models/teacher_models.dart';
import '../state/teacher_app_state.dart';

part 'widgets/teacher_dashboard_widgets.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TeacherAppState>();
    final dashboard = appState.dashboard;

    if (dashboard == null && appState.isLoadingDashboard) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('РљР°Р±РёРЅРµС‚ РїСЂРµРїРѕРґР°РІР°С‚РµР»СЏ'),
        actions: <Widget>[
          IconButton(
            onPressed: appState.isLoadingDashboard
                ? null
                : () => context.read<TeacherAppState>().refreshDashboard(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'РћР±РЅРѕРІРёС‚СЊ',
          ),
          TextButton.icon(
            onPressed: () => context.read<TeacherAppState>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Р’С‹Р№С‚Рё'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboard == null
          ? _EmptyState(
              message: appState.loadError ??
                  'РќРµС‚ РґР°РЅРЅС‹С… РїСЂРµРїРѕРґР°РІР°С‚РµР»СЏ. РџСЂРѕРІРµСЂСЊС‚Рµ РїСЂРѕС„РёР»СЊ Рё РїРѕРІС‚РѕСЂРёС‚Рµ РѕР±РЅРѕРІР»РµРЅРёРµ.',
            )
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<TeacherAppState>().refreshDashboard(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1080;

                  final left = <Widget>[
                    _TeacherHero(profile: dashboard.profile),
                    const SizedBox(height: 16),
                    _KpiRow(
                      todayLessons: _todayLessonsCount(dashboard.schedule),
                      groupsCount: _groupsCount(dashboard.schedule),
                      messagesCount: dashboard.curatorMessages.length,
                    ),
                    const SizedBox(height: 16),
                    _ScheduleCard(
                      lessons: dashboard.schedule,
                      weekdayLabel: appState.weekdayLabel,
                    ),
                  ];

                  final right = <Widget>[
                    _CuratorMessagesCard(
                      profile: dashboard.profile,
                      messages: dashboard.curatorMessages,
                    ),
                  ];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: <Widget>[
                      if (appState.loadError != null) ...<Widget>[
                        _InlineError(text: appState.loadError!),
                        const SizedBox(height: 12),
                      ],
                      if (appState.actionNotice != null) ...<Widget>[
                        StatusBanner(
                          text: appState.actionNotice!,
                          tone: StatusBannerTone.success,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 7,
                              child: Column(children: left),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(children: right),
                            ),
                          ],
                        )
                      else ...<Widget>[
                        ...left,
                        const SizedBox(height: 16),
                        ...right,
                      ],
                    ],
                  );
                },
              ),
            ),
    );
  }

  int _todayLessonsCount(List<TeacherLesson> lessons) {
    final today = DateTime.now().weekday;
    return lessons.where((lesson) => lesson.weekday == today).length;
  }

  int _groupsCount(List<TeacherLesson> lessons) {
    return lessons
        .expand((lesson) => lesson.groups)
        .where((group) => group.trim().isNotEmpty)
        .toSet()
        .length;
  }
}
