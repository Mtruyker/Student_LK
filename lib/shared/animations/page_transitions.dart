import 'package:flutter/material.dart';

/// Плавный fade + slide переход для страниц
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 350),
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.03);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final offsetAnimation = animation.drive(tween);

            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));
            final fadeAnimation = animation.drive(fadeTween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Анимация появления элементов списка с задержкой
class StaggeredListAnimation extends StatelessWidget {
  const StaggeredListAnimation({
    required this.index,
    required this.child,
    this.delay = 40,
    super.key,
  });

  final int index;
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * delay)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Анимация скейла при нажатии на карточку/кнопку
class ScaleOnTap extends StatefulWidget {
  const ScaleOnTap({
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
