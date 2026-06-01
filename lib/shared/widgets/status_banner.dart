import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusBannerTone {
  info,
  success,
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.text,
    this.tone = StatusBannerTone.info,
  });

  final String text;
  final StatusBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusBannerTone.success => AppColors.success,
      StatusBannerTone.info => AppColors.info,
    };

    final icon = switch (tone) {
      StatusBannerTone.success => Icons.check_circle_outline_rounded,
      StatusBannerTone.info => Icons.info_outline_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
