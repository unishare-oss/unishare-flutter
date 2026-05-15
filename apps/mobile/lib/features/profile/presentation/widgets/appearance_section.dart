import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme_data.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/shared/theme/providers/font_size_provider.dart';
import 'package:unishare_mobile/shared/theme/providers/theme_provider.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final selectedThemeId = ref.watch(themeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    final themes = AppThemes.all.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'APPEARANCE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Theme', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: themes.length,
          itemBuilder: (context, i) {
            final t = themes[i];
            final isSelected = t.id == selectedThemeId;
            return GestureDetector(
              onTap: () => ref.read(themeProvider.notifier).setTheme(t.id),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? ac.amber : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ThemePreview(themeData: t)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: theme.textTheme.labelMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? ac.amber : ac.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Font Size', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FontSizeButton(
                label: 'a',
                selected: fontSize == AppFontSize.normal,
                onTap: () =>
                    ref.read(fontSizeProvider.notifier).set(AppFontSize.normal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FontSizeButton(
                label: 'A',
                large: true,
                selected: fontSize == AppFontSize.large,
                onTap: () =>
                    ref.read(fontSizeProvider.notifier).set(AppFontSize.large),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          fontSize == AppFontSize.normal ? 'Normal' : 'Normal-Large',
          style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Theme preview
// ---------------------------------------------------------------------------

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.themeData});
  final AppThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      child: CustomPaint(painter: ThemePreviewPainter(themeData)),
    );
  }
}

class ThemePreviewPainter extends CustomPainter {
  ThemePreviewPainter(this.t);
  final AppThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = t.background;
    canvas.drawRect(Offset.zero & size, bg);

    final sidebarW = size.width * 0.28;
    final sidebar = Paint()..color = t.muted;
    canvas.drawRect(Rect.fromLTWH(0, 0, sidebarW, size.height), sidebar);

    final accentP = Paint()..color = t.amber;
    final r = Paint()
      ..color = t.mutedForeground.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final lx = sidebarW + 8;
    final lw = size.width - lx - 8;
    for (int i = 0; i < 3; i++) {
      final y = 8.0 + i * 10;
      final w = i == 0 ? lw : lw * (i == 1 ? 0.7 : 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx, y, w, 4),
          const Radius.circular(2),
        ),
        r,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, 38, lw * 0.4, 5),
        const Radius.circular(2),
      ),
      accentP,
    );

    final dot = Paint()..color = t.amber;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(sidebarW * 0.3, 12.0 + i * 14), 3, dot);
    }
  }

  @override
  bool shouldRepaint(ThemePreviewPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Font size button
// ---------------------------------------------------------------------------

class FontSizeButton extends StatelessWidget {
  const FontSizeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: selected ? ac.amberSubtle : null,
          border: Border.all(
            color: selected ? ac.amber : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: large ? 22 : 14,
            color: selected ? ac.amber : null,
          ),
        ),
      ),
    );
  }
}
