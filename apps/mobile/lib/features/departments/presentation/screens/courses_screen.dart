import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({
    super.key,
    required this.deptId,
    required this.departmentName,
  });

  final String deptId;
  final String departmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(departmentName),
          leading: const BackButton(),
          bottom: TabBar(
            indicatorColor: ac.amber,
            labelColor: ac.amber,
            unselectedLabelColor: ac.textMuted,
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Year 1'),
              Tab(text: 'Year 2'),
              Tab(text: 'Year 3'),
              Tab(text: 'Year 4'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            1,
            2,
            3,
            4,
          ].map((year) => _YearTab(deptId: deptId, year: year)).toList(),
        ),
      ),
    );
  }
}

class _YearTab extends ConsumerWidget {
  const _YearTab({required this.deptId, required this.year});

  final String deptId;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    final coursesAsync = ref.watch(coursesProvider(deptId, year));

    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load courses.',
          style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
        ),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Text(
              'No courses for Year $year.',
              style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MainNavBar.bottomInset,
          ),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final course = courses[index];
            return GestureDetector(
              onTap: () {
                final notifier = ref.read(feedFilterProvider.notifier);
                notifier.setYear(year);
                notifier.setCourse(course.id, course.name);
                context.go('/feed');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ac.muted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.book_outlined,
                        size: 20,
                        color: ac.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        course.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: ac.textMuted),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
