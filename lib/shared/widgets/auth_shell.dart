import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.role,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.footer,
  });

  final AppShellRole role;
  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = AppColors.heroGradientFor(role, theme.brightness);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -80,
              right: -30,
              child: _GlowOrb(color: AppColors.primaryFor(role).withValues(alpha: 0.10)),
            ),
            Positioned(
              left: -60,
              bottom: -100,
              child: _GlowOrb(color: AppColors.info.withValues(alpha: 0.08)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final content = wide
                      ? Row(
                          children: <Widget>[
                            Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(40, 32, 24, 32),
                            child: _HeroPanel(
                              kicker: kicker,
                              title: title,
                              subtitle: subtitle,
                              icon: icon,
                              gradient: gradient,
                            ),
                          ),
                        ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 32, 40, 32),
                                child: _FormPanel(footer: footer, child: child),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: <Widget>[
                              _HeroPanel(
                                kicker: kicker,
                                title: title,
                                subtitle: subtitle,
                                icon: icon,
                                gradient: gradient,
                              ),
                              const SizedBox(height: 18),
                              _FormPanel(footer: footer, child: child),
                            ],
                          ),
                        );

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
            const SizedBox(height: 48),
          Text(
            kicker,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.child,
    this.footer,
  });

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            child,
            if (footer != null) ...<Widget>[
              const SizedBox(height: 16),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
