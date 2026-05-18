import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/achievements_hero.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_detail_sheet.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final catalog = ref.watch(badgeCatalogProvider).asData?.value ?? const [];
    final earned =
        ref.watch(earnedBadgesProvider(uid)).asData?.value ?? const [];
    final earnedMap = <String, EarnedBadge>{
      for (final e in earned) e.badgeId: e,
    };

    final unlocked = catalog.where((b) => earnedMap.containsKey(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final locked = catalog.where((b) => !earnedMap.containsKey(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: AchievementsHero(uid: uid)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Earned · ${unlocked.length}',
                style: AppTypography.mono(
                  base: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
              ),
            ),
          ),
          _BadgeGrid(badges: unlocked, earnedMap: earnedMap),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Locked · ${locked.length}',
                style: AppTypography.mono(
                  base: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
              ),
            ),
          ),
          _BadgeGrid(badges: locked, earnedMap: earnedMap),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.earnedMap});
  final List<AchievementBadge> badges;
  final Map<String, EarnedBadge> earnedMap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 96,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, i) {
          final b = badges[i];
          final earned = earnedMap[b.id];
          const iconSize = 72.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tap ripple is confined to the badge frame via a matching
              // borderRadius; without this the splash would bleed across
              // the whole column including the label below.
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    badgeFrameRadius(iconSize),
                  ),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => BadgeDetailSheet(badge: b, earned: earned),
                  ),
                  child: BadgeIcon(
                    badge: b,
                    locked: earned == null,
                    size: iconSize,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                b.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          );
        }, childCount: badges.length),
      ),
    );
  }
}
