import 'package:flutter/material.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class AiSummaryPanel extends StatefulWidget {
  const AiSummaryPanel({super.key, required this.status, this.summary});
  final SummaryStatus? status;
  final String? summary;
  @override
  State<AiSummaryPanel> createState() => _AiSummaryPanelState();
}

class _AiSummaryPanelState extends State<AiSummaryPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.status == SummaryStatus.pending) {
      _shimmerController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AiSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == SummaryStatus.pending) {
      if (!_shimmerController.isAnimating)
        _shimmerController.repeat(reverse: true);
    } else {
      if (_shimmerController.isAnimating) _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == null) return const SizedBox.shrink();

    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ac.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ac, theme),
          if (_expanded) _buildBody(context, ac, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors ac, ThemeData theme) {
    final canExpand = widget.status == SummaryStatus.done;
    return InkWell(
      onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(8),
        bottom: _expanded ? Radius.zero : const Radius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 13, color: ac.amber),
            const SizedBox(width: 6),
            Text(
              'AI SUMMARY',
              style: AppTypography.mono(
                base: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ac.amber,
                  letterSpacing: 0.6,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            if (canExpand)
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: ac.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppColors ac, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: switch (widget.status!) {
        SummaryStatus.pending => _buildShimmer(ac),
        SummaryStatus.done => _buildDone(theme, ac),
        SummaryStatus.flagged || SummaryStatus.error => _buildChip(
          context,
          ac,
          theme,
          'Summary unavailable',
        ),
        SummaryStatus.unsupportedType => _buildChip(
          context,
          ac,
          theme,
          'Summary not supported for this file type',
        ),
      },
    );
  }

  Widget _buildShimmer(AppColors ac) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final opacity = 0.3 + 0.4 * _shimmerController.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            for (final width in [double.infinity, 200.0, 160.0]) ...[
              Opacity(
                opacity: opacity,
                child: Container(
                  height: 12,
                  width: width,
                  decoration: BoxDecoration(
                    color: ac.amber.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDone(ThemeData theme, AppColors ac) {
    final raw = widget.summary ?? '';
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final intro = lines.firstWhere(
      (l) => !l.trimLeft().startsWith('•'),
      orElse: () => '',
    );
    final bullets = lines.where((l) => l.trimLeft().startsWith('•')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(intro, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 8),
        ],
        for (final bullet in bullets) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ac.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  bullet.trimLeft().replaceFirst('•', '').trimLeft(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    AppColors ac,
    ThemeData theme,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: ac.amber),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}
