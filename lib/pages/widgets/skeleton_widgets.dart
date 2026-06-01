import 'package:flutter/material.dart';

import '../../shared/widgets/skeleton_widgets.dart';

/// Skeleton for lesson schedule items
class LessonSkeleton extends StatelessWidget {
  const LessonSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 50, height: 14),
                const SizedBox(height: 4),
                const SkeletonText(width: 40, height: 12),
              ],
            ),
            const SizedBox(width: 16),
            // Lesson details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 120, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonText(width: 80, height: 14),
                  const SizedBox(height: 4),
                  const SkeletonText(width: 60, height: 12),
                ],
              ),
            ),
            // Status indicator
            SkeletonContainer(
              width: 8,
              height: 40,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for grade records
class GradeSkeleton extends StatelessWidget {
  const GradeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Grade circle
            SkeletonContainer(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(width: 16),
            // Subject and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 100, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonText(width: 150, height: 14),
                  const SizedBox(height: 4),
                  const SkeletonText(width: 80, height: 12),
                ],
              ),
            ),
            // Progress indicator
            const SkeletonText(width: 40, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for announcement items
class AnnouncementSkeleton extends StatelessWidget {
  const AnnouncementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonText(width: 120, height: 16),
                const Spacer(),
                const SkeletonText(width: 60, height: 12),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonText(lines: 2, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for profile stats
class StatBadgeSkeleton extends StatelessWidget {
  const StatBadgeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonText(width: 60, height: 12),
            const SizedBox(height: 8),
            const SkeletonText(width: 40, height: 24),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for action tiles
class ActionTileSkeleton extends StatelessWidget {
  const ActionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            SkeletonContainer(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 100, height: 16),
                  const SizedBox(height: 4),
                  const SkeletonText(width: 150, height: 14),
                ],
              ),
            ),
            const SkeletonContainer(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for dashboard sections
class SectionCardSkeleton extends StatelessWidget {
  const SectionCardSkeleton({
    super.key,
    this.itemCount = 3,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                const SkeletonText(width: 120, height: 20),
                const Spacer(),
                const SkeletonContainer(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: 20),
            // Section items
            ...List.generate(itemCount, (index) => Padding(
              padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 16 : 0),
              child: const SkeletonListTile(
                hasLeading: false,
                hasTrailing: true,
                padding: EdgeInsets.zero,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the entire dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              const Expanded(child: StatBadgeSkeleton()),
              const SizedBox(width: 12),
              const Expanded(child: StatBadgeSkeleton()),
              const SizedBox(width: 12),
              const Expanded(child: StatBadgeSkeleton()),
            ],
          ),
          const SizedBox(height: 24),
          // Next lesson section
          const SectionCardSkeleton(itemCount: 1),
          const SizedBox(height: 16),
          // Recent announcements
          const SectionCardSkeleton(itemCount: 2),
          const SizedBox(height: 16),
          // Quick actions
          const SectionCardSkeleton(itemCount: 3),
        ],
      ),
    );
  }
}

/// Skeleton for schedule page
class ScheduleSkeleton extends StatelessWidget {
  const ScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Weekday selector skeleton
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonLoader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) =>
                const SkeletonContainer(width: 50, height: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Lessons list
        Expanded(
          child: ListView.builder(
            itemCount: 6,
            itemBuilder: (context, index) => const LessonSkeleton(),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for grades page
class GradesSkeleton extends StatelessWidget {
  const GradesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => const GradeSkeleton(),
    );
  }
}