// test/widget/features/departments/screens/courses_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/courses_screen.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _buildSubject({
  List<({String id, String name})> year1Courses = const [],
}) {
  return ProviderScope(
    overrides: [
      coursesProvider('dept1', 1).overrideWith((_) async => year1Courses),
      coursesProvider('dept1', 2).overrideWith((_) async => const []),
      coursesProvider('dept1', 3).overrideWith((_) async => const []),
      coursesProvider('dept1', 4).overrideWith((_) async => const []),
    ],
    child: MaterialApp(
      theme: AppTheme.build(AppThemes.unishare),
      home: const CoursesScreen(deptId: 'dept1', departmentName: 'Engineering'),
    ),
  );
}

void main() {
  testWidgets('shows department name in AppBar', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('Engineering'), findsOneWidget);
  });

  testWidgets('shows four year tabs', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    for (final label in ['Year 1', 'Year 2', 'Year 3', 'Year 4']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows course names when courses exist', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        year1Courses: [
          (id: 'c1', name: 'Calculus I'),
          (id: 'c2', name: 'Programming I'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Calculus I'), findsOneWidget);
    expect(find.text('Programming I'), findsOneWidget);
  });

  testWidgets('shows empty state when no courses for year', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('No courses for Year 1.'), findsOneWidget);
  });

  testWidgets('course tiles are tappable', (tester) async {
    await tester.pumpWidget(
      _buildSubject(year1Courses: [(id: 'c1', name: 'Calculus I')]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
