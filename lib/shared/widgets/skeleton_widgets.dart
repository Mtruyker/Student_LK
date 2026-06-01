import 'package:flutter/material.dart';

/// A shimmer effect widget for skeleton loading states
class ShimmerWidget extends StatefulWidget {
  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;
  final bool enabled;

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.period,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Basic skeleton container with rounded corners
class SkeletonContainer extends StatelessWidget {
  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  });

  final double? width;
  final double height;
  final int lines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonContainer(
        width: width ?? double.infinity,
        height: height,
        borderRadius: BorderRadius.circular(height / 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final lineWidth = isLast && width == null
            ? MediaQuery.of(context).size.width * 0.6
            : width;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: SkeletonContainer(
            width: lineWidth ?? double.infinity,
            height: height,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
      }),
    );
  }
}

/// Skeleton for circular avatars
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({
    super.key,
    this.radius = 20,
  });

  final double radius;

  @override
  Widget build(BuildContext context) {
    return SkeletonContainer(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Skeleton for cards with content
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.child,
  });

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: child ?? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonText(height: 20, width: 150),
          const SizedBox(height: 12),
          const SkeletonText(lines: 2),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonContainer(width: 80, height: 32),
              const Spacer(),
              SkeletonContainer(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.titleWidth,
    this.subtitleWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final bool hasLeading;
  final bool hasTrailing;
  final double? titleWidth;
  final double? subtitleWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonAvatar(radius: 24),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(
                  width: titleWidth ?? 120,
                  height: 16,
                ),
                const SizedBox(height: 8),
                SkeletonText(
                  width: subtitleWidth ?? 200,
                  height: 14,
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const SkeletonContainer(width: 24, height: 24),
          ],
        ],
      ),
    );
  }
}

/// Wrapper that adds shimmer effect to any skeleton widget
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      enabled: enabled,
      child: child,
    );
  }
}