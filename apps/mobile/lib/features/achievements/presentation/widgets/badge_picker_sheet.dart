import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class BadgePickerSheet extends ConsumerStatefulWidget {
  const BadgePickerSheet({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<BadgePickerSheet> createState() => _BadgePickerSheetState();
}

class _BadgePickerSheetState extends ConsumerState<BadgePickerSheet> {
  /// `null` until we receive the first gamification snapshot. Then it
  /// reflects the user's currently-displayed badges so the picker always
  /// opens with the live selection pre-checked, even if the gamification
  /// stream was still loading at the moment `initState` ran.
  List<String>? _selected;
  bool _seededFromProvider = false;

  void _toggle(String id) {
    final current = _selected ?? const <String>[];
    setState(() {
      final next = List<String>.of(current);
      if (next.contains(id)) {
        next.remove(id);
      } else if (next.length < 3) {
        next.add(id);
      }
      _selected = next;
    });
  }

  Future<void> _save() async {
    final earned =
        ref.read(earnedBadgesProvider(widget.uid)).asData?.value ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final usecase = SetDisplayedBadges(
      ref.read(gamificationRepositoryProvider),
    );
    try {
      await usecase(
        uid: widget.uid,
        proposed: _selected ?? const <String>[],
        earnedIds: earnedIds,
      );
      if (mounted) Navigator.of(context).pop();
    } on DisplayedBadgesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final catalog = ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final earned =
        ref.watch(earnedBadgesProvider(widget.uid)).asData?.value ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final available = catalog.where((b) => earnedIds.contains(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // Seed from the live gamification snapshot the first time it resolves
    // — `initState` may have run while the stream was still loading.
    final gamification = ref
        .watch(userGamificationProvider(widget.uid))
        .asData
        ?.value;
    if (!_seededFromProvider && gamification != null) {
      _seededFromProvider = true;
      _selected = List<String>.of(gamification.displayedBadges);
    }
    final selected = _selected ?? const <String>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pick up to 3 badges to display',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${selected.length} / 3 selected',
              style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
            ),
            const SizedBox(height: 16),
            if (available.isEmpty)
              Text(
                'Earn your first badge to display it here.',
                style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: available.map((AchievementBadge b) {
                  final isSelected = selected.contains(b.id);
                  const pickerSize = 56.0;
                  return Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => _toggle(b.id),
                      borderRadius: BorderRadius.circular(
                        badgeFrameRadius(pickerSize),
                      ),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.4,
                        child: BadgeIcon(
                          badge: b,
                          locked: false,
                          size: pickerSize,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
