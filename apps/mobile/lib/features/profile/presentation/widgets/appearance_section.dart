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
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final selectedId = ref.watch(themeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final themes = AppThemes.all.values.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPEARANCE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 14),
          Text(
            'THEME',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: themes.length,
            itemBuilder: (_, i) {
              final t = themes[i];
              final isSelected = t.id == selectedId;
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Theme ${t.name}',
                onTap: () => ref.read(themeProvider.notifier).setTheme(t.id),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).setTheme(t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? ac.amber : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: ac.amber.withValues(alpha: 0.28),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      // RepaintBoundary isolates the painter onto its own
                      // compositor layer so unrelated rebuilds (form fields,
                      // text changes, etc.) don't force the 6 theme previews
                      // to recomposite.
                      child: RepaintBoundary(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: _ThemePreviewPainter(t)),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                color: t.card.withValues(alpha: 0.92),
                                child: Text(
                                  t.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.foreground,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: ac.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'TEXT SIZE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FontSizeStepper(
            step: fontSize,
            onIncrement: () => ref.read(fontSizeProvider.notifier).increment(),
            onDecrement: () => ref.read(fontSizeProvider.notifier).decrement(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme preview painter
// ---------------------------------------------------------------------------

class _ThemePreviewPainter extends CustomPainter {
  const _ThemePreviewPainter(this.t);
  final AppThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = t.background);

    // Top nav bar
    final navH = h * 0.17;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, navH), Paint()..color = t.card);
    // Nav title pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, navH * 0.3, w * 0.5, navH * 0.38),
        const Radius.circular(2),
      ),
      Paint()..color = t.foreground.withValues(alpha: 0.85),
    );

    // Content card
    final cardTop = h * 0.25;
    final cardH = h * 0.47;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, cardTop, w * 0.84, cardH),
        const Radius.circular(5),
      ),
      Paint()..color = t.card,
    );

    // Text lines
    final lx = w * 0.15;
    final lw = w * 0.7;
    final lineColor = t.mutedForeground.withValues(alpha: 0.55);
    final widths = [lw, lw * 0.72, lw * 0.5];
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            lx,
            cardTop + h * 0.07 + i * h * 0.1,
            widths[i],
            h * 0.045,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = lineColor,
      );
    }

    // Accent button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, cardTop + cardH - h * 0.12, lw * 0.5, h * 0.065),
        const Radius.circular(3),
      ),
      Paint()..color = t.amber,
    );

    // Bottom nav dots
    final dotY = h * 0.915;
    for (int i = 0; i < 3; i++) {
      final dotX = w * (0.3 + i * 0.2);
      final isActive = i == 1;
      canvas.drawCircle(
        Offset(dotX, dotY),
        isActive ? 2.5 : 1.8,
        Paint()
          ..color = isActive
              ? t.amber
              : t.mutedForeground.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Font size stepper
// ---------------------------------------------------------------------------

class _FontSizeStepper extends StatelessWidget {
  const _FontSizeStepper({
    required this.step,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int step;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final atMin = step <= 0;
    final atMax = step >= fontSizeScales.length - 1;
    final previewSize = 14.0 + step * 3.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: atMin ? null : onDecrement,
            ac: ac,
            theme: theme,
          ),
          Expanded(
            child: Column(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: previewSize,
                    fontWeight: FontWeight.w600,
                    color: ac.amber,
                  ),
                  child: const Text('Aa'),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(fontSizeScales.length, (i) {
                    final active = i == step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? ac.amber : theme.dividerColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  fontSizeLabels[step],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: atMax ? null : onIncrement,
            ac: ac,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.ac,
    required this.theme,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final AppColors ac;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final label = icon == Icons.add
        ? 'Increase text size'
        : 'Decrease text size';
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled
                ? ac.amberSubtle
                : theme.dividerColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: enabled ? ac.amber : theme.dividerColor),
          ),
          child: Icon(icon, size: 16, color: enabled ? ac.amber : ac.textMuted),
        ),
      ),
    );
  }
}
