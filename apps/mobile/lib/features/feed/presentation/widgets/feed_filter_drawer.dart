import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/feed/presentation/providers/feed_filter_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class FeedFilterDrawer extends ConsumerStatefulWidget {
  const FeedFilterDrawer({super.key, required this.loadedPosts});

  final List<Post> loadedPosts;

  static Future<void> show(BuildContext context, List<Post> loadedPosts) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FeedFilterDrawer(loadedPosts: loadedPosts),
    );
  }

  @override
  ConsumerState<FeedFilterDrawer> createState() => _FeedFilterDrawerState();
}

class _FeedFilterDrawerState extends ConsumerState<FeedFilterDrawer> {
  late FeedSortOrder _sortOrder;
  int? _year;
  String? _courseId;
  String? _courseName;
  String? _moduleNumber;

  @override
  void initState() {
    super.initState();
    final current = ref.read(feedFilterProvider);
    _sortOrder = current.sortOrder;
    _year = current.year;
    _courseId = current.courseId;
    _courseName = current.courseName;
    _moduleNumber = current.moduleNumber;
  }

  List<String> _moduleOptions() {
    var posts = widget.loadedPosts;
    if (_year != null) posts = posts.where((p) => p.year == _year).toList();
    if (_courseId != null) {
      posts = posts.where((p) => p.courseId == _courseId).toList();
    }
    return posts
        .map((p) => p.moduleNumber)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _apply() {
    final notifier = ref.read(feedFilterProvider.notifier);
    notifier.setSortOrder(_sortOrder);
    notifier.setYear(_year);
    notifier.setCourse(_courseId, _courseName);
    notifier.setModule(_moduleNumber);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(feedFilterProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    final user = ref.watch(authStateProvider).asData?.value;
    final deptId = user?.departmentId;
    final coursesAsync = deptId != null
        ? ref.watch(coursesProvider(deptId, _year ?? 1))
        : const AsyncData<List<({String id, String name})>>([]);

    final moduleOptions = _moduleOptions();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Filter posts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          // Sort toggle
          Row(
            children: [
              Expanded(
                child: _SortButton(
                  label: 'RECENT',
                  icon: Icons.access_time_outlined,
                  selected: _sortOrder == FeedSortOrder.recent,
                  onTap: () =>
                      setState(() => _sortOrder = FeedSortOrder.recent),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _SortButton(
                  label: 'TRENDING',
                  icon: Icons.trending_up,
                  selected: false,
                  enabled: false,
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Year + Module row
          Row(
            children: [
              Expanded(
                child: _DropdownField<int?>(
                  value: _year,
                  hint: 'All years',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All years'),
                    ),
                    for (int y = 1; y <= 4; y++)
                      DropdownMenuItem(value: y, child: Text('Year $y')),
                  ],
                  onChanged: (v) => setState(() {
                    _year = v;
                    _moduleNumber = null;
                    _courseId = null;
                    _courseName = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField<String?>(
                  value: _moduleNumber,
                  hint: 'All modules',
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All modules'),
                    ),
                    for (final m in moduleOptions)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: moduleOptions.isEmpty
                      ? null
                      : (v) => setState(() => _moduleNumber = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Course dropdown
          coursesAsync.when(
            loading: () => const _DropdownField<String?>(
              value: null,
              hint: 'Loading...',
              items: [],
              onChanged: null,
            ),
            error: (_, _) => const _DropdownField<String?>(
              value: null,
              hint: 'All courses',
              items: [
                DropdownMenuItem(value: null, child: Text('All courses')),
              ],
              onChanged: null,
            ),
            data: (courses) {
              final inList = courses.any((c) => c.id == _courseId);
              return _DropdownField<String?>(
                value: _courseId,
                hint: 'All courses',
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All courses'),
                  ),
                  // Keep the pre-selected course visible even if it belongs
                  // to a different year than currently loaded.
                  if (_courseId != null && !inList && _courseName != null)
                    DropdownMenuItem(
                      value: _courseId,
                      child: Text(_courseName!),
                    ),
                  for (final c in courses)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() {
                  _courseId = v;
                  _courseName = v == null
                      ? null
                      : (courses.any((c) => c.id == v)
                            ? courses.firstWhere((c) => c.id == v).name
                            : _courseName);
                  _moduleNumber = null;
                }),
              );
            },
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.mutedForeground,
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Clear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ac.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Apply',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final effectiveColor = selected
        ? ac.amber
        : enabled
        ? ac.textMuted
        : ac.textMuted.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? ac.amber : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? ac.amber.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
        color: cs.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
          ),
          dropdownColor: cs.surface,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: ac.textMuted),
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}
