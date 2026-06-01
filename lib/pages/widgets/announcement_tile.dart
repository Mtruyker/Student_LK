import 'package:flutter/material.dart';

import '../../models/student_models.dart';
import '../../shared/theme/app_colors.dart';

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.announcement});

  final StudentAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.campaign_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                announcement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                announcement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            announcement.dateLabel,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
