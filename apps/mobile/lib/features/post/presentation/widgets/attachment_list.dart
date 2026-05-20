import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Vertical file-attachment list used on the Post Detail screen.
///
/// Each row: [icon/thumb] · [filename] · [visibility] [download]
/// Matches the attachment list style shown in the Figma design.
class AttachmentList extends StatelessWidget {
  const AttachmentList({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
  });

  final List<String> mediaUrls;
  final List<String> mediaTypes;

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(mediaUrls.length, (i) {
        final type = i < mediaTypes.length ? mediaTypes[i] : 'image';
        return _AttachmentRow(url: mediaUrls[i], type: type);
      }),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.url, required this.type});

  final String url;
  final String type;

  static String _filename(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return rawUrl;
    return Uri.decodeComponent(segments.last);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _onView(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _LeadingIcon(url: url, type: type, appColors: appColors),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _filename(url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _RowIconButton(
                  icon: Icons.download_rounded,
                  color: appColors.textMuted,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download coming soon')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onView(BuildContext context) {
    context.push(
      '/preview',
      extra: (url: url, type: type, filename: _filename(url)),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.url,
    required this.type,
    required this.appColors,
  });

  final String url;
  final String type;
  final AppColors appColors;

  @override
  Widget build(BuildContext context) {
    if (type == 'pdf') {
      return Icon(
        Icons.picture_as_pdf_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 26,
      );
    }
    if (type == 'video') {
      return Icon(Icons.play_circle_rounded, color: appColors.amber, size: 26);
    }
    // Image: small thumbnail
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (ctx, u) => Container(
          width: 36,
          height: 36,
          color: appColors.muted,
          child: Icon(
            Icons.image_outlined,
            size: 16,
            color: appColors.textMuted,
          ),
        ),
        errorWidget: (ctx, u, e) => Container(
          width: 36,
          height: 36,
          color: appColors.muted,
          child: Icon(
            Icons.broken_image_rounded,
            size: 16,
            color: appColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
