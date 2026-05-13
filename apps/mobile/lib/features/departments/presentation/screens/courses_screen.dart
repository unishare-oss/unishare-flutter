import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({
    super.key,
    required this.deptId,
    required this.departmentName,
  });

  final String deptId;
  final String departmentName;

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedYear = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedYear = _tabController.index + 1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    final coursesAsync = ref.watch(
      coursesProvider(widget.deptId, _selectedYear),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.departmentName),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
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
      body: coursesAsync.when(
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
                'No courses for Year $_selectedYear.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ac.textMuted,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
                onTap: () {
                  ref
                      .read(feedFilterProvider.notifier)
                      .setCourse(course.id, course.name);
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
      ),
    );
  }
}
