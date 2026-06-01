import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/shared/widgets/skeleton_widgets.dart';

void main() {
  group('Skeleton Widgets', () {
    testWidgets('SkeletonContainer renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonContainer(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      final container = find.byType(Container);
      expect(container, findsOneWidget);

      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.constraints?.maxWidth, 100);
      expect(containerWidget.constraints?.maxHeight, 50);
    });

    testWidgets('SkeletonText renders single line correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(
              width: 150,
              height: 16,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonContainer), findsOneWidget);
    });

    testWidgets('SkeletonText renders multiple lines correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(
              lines: 3,
              height: 16,
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SkeletonContainer), findsNWidgets(3));
    });

    testWidgets('SkeletonAvatar renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonAvatar(radius: 25),
          ),
        ),
      );

      final container = find.byType(SkeletonContainer);
      expect(container, findsOneWidget);

      final containerWidget = tester.widget<SkeletonContainer>(container);
      expect(containerWidget.width, 50); // radius * 2
      expect(containerWidget.height, 50);
    });

    testWidgets('SkeletonCard renders with default content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SkeletonText), findsWidgets);
    });

    testWidgets('SkeletonCard renders with custom child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(
              child: Text('Custom content'),
            ),
          ),
        ),
      );

      expect(find.text('Custom content'), findsOneWidget);
      expect(find.byType(SkeletonText), findsNothing);
    });

    testWidgets('SkeletonListTile renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(
              hasLeading: true,
              hasTrailing: true,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(SkeletonAvatar), findsOneWidget);
      expect(find.byType(SkeletonText), findsNWidgets(2)); // title and subtitle
      expect(find.byType(SkeletonContainer), findsNWidgets(2)); // avatar and trailing
    });

    testWidgets('ShimmerWidget animates when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerWidget(
              enabled: true,
              child: Container(
                width: 100,
                height: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedBuilder), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);

      // Pump a few frames to ensure animation is running
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ShimmerWidget does not animate when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerWidget(
              enabled: false,
              child: Container(
                width: 100,
                height: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      // When disabled, should return child directly without animation
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('SkeletonLoader wraps child with shimmer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              child: SkeletonContainer(
                width: 100,
                height: 50,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerWidget), findsOneWidget);
      expect(find.byType(SkeletonContainer), findsOneWidget);
    });

    group('Theme Integration', () {
      testWidgets('SkeletonContainer adapts to light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: SkeletonContainer(
                width: 100,
                height: 50,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        // Should use light theme colors
        expect(decoration.color, isNotNull);
      });

      testWidgets('SkeletonContainer adapts to dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SkeletonContainer(
                width: 100,
                height: 50,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        // Should use dark theme colors
        expect(decoration.color, isNotNull);
      });
    });
  });
}