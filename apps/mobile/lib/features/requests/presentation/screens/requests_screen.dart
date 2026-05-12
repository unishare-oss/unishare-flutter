import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/requests/presentation/providers/requests_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/new_request_dialog.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_card.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_filter_bar.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final filter = ref.watch(requestsFilterStateProvider);
    final filterNotifier = ref.read(requestsFilterStateProvider.notifier);
    final requestsAsync = ref.watch(requestsProvider(filter));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const NewRequestDialog(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'New Request',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          RequestFilterBar(
            selectedStatus: filter.status,
            selectedDepartmentId: filter.departmentId,
            selectedYear: filter.year,
            selectedCourseId: filter.courseId,
            onStatusChanged: filterNotifier.setStatus,
            onDepartmentChanged: filterNotifier.setDepartmentId,
            onYearChanged: filterNotifier.setYear,
            onCourseChanged: filterNotifier.setCourseId,
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const _OfflineBanner(
                message: 'Unable to load requests. Check your connection.',
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) =>
                      RequestCard(request: requests[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: ac.mutedForeground),
            const SizedBox(height: 16),
            Text(
              'No requests yet.',
              style: theme.textTheme.titleSmall?.copyWith(color: ac.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to request a resource for your course.',
              style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatefulWidget {
  const _OfflineBanner({required this.message});
  final String message;

  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final ac = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        MaterialBanner(
          content: Text(widget.message),
          backgroundColor: ac.amber.withValues(alpha: 0.1),
          actions: [
            TextButton(
              onPressed: () => setState(() => _dismissed = true),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ],
    );
  }
}
