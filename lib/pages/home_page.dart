import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../shared/animations/page_transitions.dart';
import '../shared/theme/app_colors.dart';
import '../shared/widgets/connectivity_widgets.dart';
import '../shared/widgets/error_widgets.dart';
import '../state/student_app_state.dart';
import 'grades_page.dart';
import 'profile_page.dart';
import 'schedule_page.dart';
import 'widgets/action_tile.dart';
import 'widgets/announcement_tile.dart';
import 'widgets/lesson_widgets.dart';
import 'widgets/section_card.dart';
import 'widgets/skeleton_widgets.dart';
import 'widgets/stat_badge.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<StudentAppState>();
    final pages = <Widget>[
      const _HomeContent(),
      const SchedulePage(),
      const GradesPage(),
      const ProfilePage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final extraWide = constraints.maxWidth >= 1240;

        return Scaffold(
          appBar: AppBar(
            title: Text(_tabTitle(context, appState.selectedTab)),
            actions: <Widget>[
              IconButton(
                onPressed: appState.isRefreshing
                    ? null
                    : () => context.read<StudentAppState>().refreshCabinet(),
                icon: appState.isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: AppLocalizations.of(context)!.refresh,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    context.read<StudentAppState>().signOut();
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text(AppLocalizations.of(context)!.logout),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: <Widget>[
                if (wide)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: NavigationRail(
                        extended: extraWide,
                        selectedIndex: appState.selectedTab.index,
                        onDestinationSelected:
                            context.read<StudentAppState>().selectTabIndex,
                        labelType: extraWide
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        leading: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: _CampusBadge(),
                        ),
                        destinations: <NavigationRailDestination>[
                          NavigationRailDestination(
                            icon: const Icon(Icons.dashboard_outlined),
                            selectedIcon: const Icon(Icons.dashboard_rounded),
                            label: Text(AppLocalizations.of(context)!.homeTab),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.calendar_month_outlined),
                            selectedIcon: const Icon(Icons.calendar_month_rounded),
                            label: Text(AppLocalizations.of(context)!.scheduleTab),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.bar_chart_outlined),
                            selectedIcon: const Icon(Icons.bar_chart_rounded),
                            label: Text(AppLocalizations.of(context)!.gradesTab),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.person_outline_rounded),
                            selectedIcon: const Icon(Icons.person_rounded),
                            label: Text(AppLocalizations.of(context)!.profileTab),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      const ConnectivityStatusWidget(showCacheInfo: true),
                      if (appState.loadError != null)
                        ErrorBanner(
                          error: Exception(appState.loadError!),
                          onRetry: () => appState.refreshCabinet(),
                          onDismiss: () => appState.clearAuthFeedback(),
                        ),
                      Expanded(
                        child: IndexedStack(
                          index: appState.selectedTab.index,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: appState.selectedTab.index,
                  onDestinationSelected:
                      context.read<StudentAppState>().selectTabIndex,
                  destinations: <NavigationDestination>[
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: AppLocalizations.of(context)!.homeTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month_rounded),
                      label: AppLocalizations.of(context)!.scheduleTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bar_chart_outlined),
                      selectedIcon: const Icon(Icons.bar_chart_rounded),
                      label: AppLocalizations.of(context)!.gradesTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: AppLocalizations.of(context)!.profileTab,
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _tabTitle(BuildContext context, AppTab tab) {
    final l10n = AppLocalizations.of(context)!;
    switch (tab) {
      case AppTab.dashboard:
        return l10n.homeTab;
      case AppTab.schedule:
        return l10n.scheduleTab;
      case AppTab.grades:
        return l10n.gradesTab;
      case AppTab.profile:
        return l10n.profileTab;
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<StudentAppState>();

    // Show skeleton loading during initial load or refresh
    if (appState.isInitializing || (appState.isRefreshing && !appState.isAuthenticated)) {
      return const DashboardSkeleton();
    }

    final strongest = appState.strongestSubject;
    final attention = appState.attentionSubject;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1060;

        final leftColumn = <Widget>[
          StaggeredListAnimation(
            index: 0,
            child: SectionCard(
              title: AppLocalizations.of(context)!.nextLesson,
              trailing: TextButton(
                onPressed: () =>
                    context.read<StudentAppState>().selectTab(AppTab.schedule),
                child: Text(AppLocalizations.of(context)!.allLessons),
              ),
              child: appState.nextLesson == null
                  ? const _SectionEmptyState(
                      icon: Icons.nightlight_round,
                      title: 'На сегодня занятий больше нет',
                      subtitle:
                          'Откройте расписание, чтобы посмотреть остальные дни недели.',
                    )
                  : LessonPreview(lesson: appState.nextLesson!),
            ),
          ),
          const SizedBox(height: 16),
          StaggeredListAnimation(
            index: 1,
            child: SectionCard(
              title: AppLocalizations.of(context)!.today,
              child: appState.todayLessons.isEmpty
                  ? const _SectionEmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Сегодня пар нет',
                      subtitle:
                          'Можно переключиться на другое расписание или заняться документами и запросами.',
                    )
                  : Column(
                      children: <Widget>[
                        for (final lesson in appState.todayLessons) ...<Widget>[
                          CompactLessonRow(lesson: lesson),
                          if (lesson != appState.todayLessons.last)
                            const Divider(height: 24),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          StaggeredListAnimation(
            index: 2,
            child: SectionCard(
              title: AppLocalizations.of(context)!.announcements,
              child: appState.announcements.isEmpty
                  ? const _SectionEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Новых объявлений пока нет',
                      subtitle:
                          'Когда появятся обновления от учебной части или по документам, они появятся здесь.',
                    )
                  : Column(
                      children: <Widget>[
                        for (final announcement in appState.announcements) ...<Widget>[
                          AnnouncementTile(announcement: announcement),
                          if (announcement != appState.announcements.last)
                            const Divider(height: 24),
                        ],
                      ],
                    ),
            ),
          ),
        ];

        final rightColumn = <Widget>[
          _FocusCard(
            strongestSubject: strongest?.subject,
            strongestNote: strongest == null
                ? null
                : 'Прогресс ${(strongest.progress * 100).round()}% и оценка ${strongest.grade}',
            attentionSubject: attention?.subject,
            attentionNote: attention == null
                ? null
                : 'Стоит подтянуть до следующего контроля. Сейчас ${(attention.progress * 100).round()}%',
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: AppLocalizations.of(context)!.quickActions,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ActionTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Расписание',
                  subtitle: 'Пары на неделю',
                  onTap: () =>
                      context.read<StudentAppState>().selectTab(AppTab.schedule),
                ),
                ActionTile(
                  icon: Icons.insights_rounded,
                  label: 'Оценки',
                  subtitle: 'Прогресс и баллы',
                  onTap: () =>
                      context.read<StudentAppState>().selectTab(AppTab.grades),
                ),
                ActionTile(
                  icon: Icons.description_rounded,
                  label: 'Документы',
                  subtitle: 'Справки и файлы',
                  onTap: () =>
                      context.read<StudentAppState>().selectTab(AppTab.profile),
                ),
                ActionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Профиль',
                  subtitle: 'Контакты и куратор',
                  onTap: () =>
                      context.read<StudentAppState>().selectTab(AppTab.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: AppLocalizations.of(context)!.contextInfo,
            child: Column(
              children: <Widget>[
                _ContextLine(
                  icon: Icons.groups_rounded,
                  label: 'Группа',
                  value: appState.profile.group,
                ),
                const SizedBox(height: 12),
                _ContextLine(
                  icon: Icons.support_agent_rounded,
                  label: 'Куратор',
                  value: appState.profile.curator,
                ),
                const SizedBox(height: 12),
                _ContextLine(
                  icon: Icons.badge_outlined,
                  label: 'Студенческий ID',
                  value: appState.profile.studentId,
                ),
              ],
            ),
          ),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: <Widget>[
            _DashboardHero(appState: appState),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: Column(children: leftColumn),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(children: rightColumn),
                  ),
                ],
              )
            else ...<Widget>[
              ...leftColumn,
              const SizedBox(height: 16),
              ...rightColumn,
            ],
          ],
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.appState});

  final StudentAppState appState;

  @override
  Widget build(BuildContext context) {
    final profile = appState.profile;
    final completion = profile.totalAssignments == 0
        ? 0.0
        : profile.completedAssignments / profile.totalAssignments;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: AppColors.heroGradientFor(
          AppShellRole.student,
          Theme.of(context).brightness,
        ),
      ),
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
                      AppLocalizations.of(context)!.welcome,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.74),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.firstName.isEmpty
                          ? profile.fullName
                          : profile.firstName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Группа ${profile.group} • посещаемость ${(profile.attendance * 100).round()}% • выполнено ${profile.completedAssignments}/${profile.totalAssignments}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              StatBadge(
                label: AppLocalizations.of(context)!.averageGrade,
                value: appState.averageGrade.toStringAsFixed(1),
              ),
              StatBadge(
                label: AppLocalizations.of(context)!.documentsCount,
                value: '${appState.availableDocumentsCount}',
              ),
              StatBadge(
                label: AppLocalizations.of(context)!.subjectsCount,
                value: '${appState.grades.length}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.semesterProgress,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: completion.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.strongestSubject,
    required this.strongestNote,
    required this.attentionSubject,
    required this.attentionNote,
  });

  final String? strongestSubject;
  final String? strongestNote;
  final String? attentionSubject;
  final String? attentionNote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фокус семестра',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 16),
            if (strongestSubject == null || attentionSubject == null)
              const _SectionEmptyState(
                icon: Icons.auto_graph_rounded,
                title: 'Пока нет данных для аналитики',
                subtitle: 'Когда появятся оценки, здесь будет видно сильные и слабые стороны.',
              )
            else ...<Widget>[
              _FocusLine(
                label: 'Сильная сторона',
                title: strongestSubject!,
                note: strongestNote!,
                color: AppColors.success,
              ),
              const SizedBox(height: 14),
              _FocusLine(
                label: 'Нужно подтянуть',
                title: attentionSubject!,
                note: attentionNote!,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusLine extends StatelessWidget {
  const _FocusLine({
    required this.label,
    required this.title,
    required this.note,
    required this.color,
  });

  final String label;
  final String title;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.insights_rounded, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(note, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CampusBadge extends StatelessWidget {
  const _CampusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(
          AppShellRole.student,
          Theme.of(context).brightness,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
    );
  }
}
