import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';

IconData _resolveGlyph(String name) {
  switch (name) {
    case 'user-circle':
      return LucideIcons.userCircle;
    case 'paper-plane-tilt':
      return LucideIcons.send;
    case 'bookmark-simple':
      return LucideIcons.bookmark;
    case 'chat-circle-dots':
      return LucideIcons.messageCircleMore;
    case 'hand-waving':
      return LucideIcons.hand;
    case 'sparkle':
      return LucideIcons.sparkle;
    case 'stack':
      return LucideIcons.layers;
    case 'lightbulb':
      return LucideIcons.lightbulb;
    case 'notebook':
      return LucideIcons.notebook;
    case 'chats':
      return LucideIcons.messagesSquare;
    case 'hand-heart':
      return LucideIcons.heartHandshake;
    case 'compass':
      return LucideIcons.compass;
    case 'books':
      return LucideIcons.bookOpenText;
    case 'ear':
      return LucideIcons.ear;
    case 'anchor':
      return LucideIcons.anchor;
    case 'crown-simple':
      return LucideIcons.crown;
    case 'tree':
      return LucideIcons.treePine;
    case 'seal-check':
      return LucideIcons.badgeCheck;
    case 'globe':
      return LucideIcons.globe;
    case 'medal':
      return LucideIcons.medal;
    default:
      return LucideIcons.circleHelp;
  }
}

class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.badge,
    required this.locked,
    this.size = 48,
  });

  final AchievementBadge badge;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BadgeFrame(
      tier: badge.tier,
      locked: locked,
      size: size,
      child: Icon(locked ? LucideIcons.lock : _resolveGlyph(badge.glyph)),
    );
  }
}
