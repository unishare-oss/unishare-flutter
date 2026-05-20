import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Horizontal carousel that renders image, PDF, and video attachments.
///
/// [mediaUrls] and [mediaTypes] are parallel lists. If [mediaTypes] is shorter
/// than [mediaUrls], the extra slots are treated as "image" (safe fallback per spec).
class AttachmentCarousel extends StatelessWidget {
  const AttachmentCarousel({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
  });

  final List<String> mediaUrls;
  final List<String> mediaTypes;

  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mediaUrls.length,
        itemBuilder: (context, i) {
          final url = mediaUrls[i];
          // Fallback to "image" if mediaTypes list is shorter than mediaUrls.
          final type = i < mediaTypes.length ? mediaTypes[i] : 'image';

          return Padding(
            padding: EdgeInsets.only(right: i < mediaUrls.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 260,
                height: _height,
                child: _buildSlot(context, url, type),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _filename(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final segments = uri.pathSegments;
    return segments.isEmpty ? rawUrl : Uri.decodeComponent(segments.last);
  }

  Widget _buildSlot(BuildContext context, String url, String type) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    switch (type) {
      case 'pdf':
        return _PdfSlot(url: url);
      case 'video':
        return _VideoSlot(url: url);
      default:
        return GestureDetector(
          onTap: () => context.push(
            '/preview',
            extra: (url: url, type: 'image', filename: _filename(url)),
          ),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (ctx, _) => Container(
              color: dividerColor,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (ctx, _, e) => Container(
              color: dividerColor,
              child: Icon(Icons.broken_image, color: ac.textMuted),
            ),
          ),
        );
    }
  }
}

class _PdfSlot extends StatelessWidget {
  const _PdfSlot({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    return GestureDetector(
      onTap: () => _openPdfViewer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // PDF first-page thumbnail.
          PdfDocumentViewBuilder.uri(
            Uri.parse(url),
            builder: (ctx, document) => document == null
                ? Container(
                    color: dividerColor,
                    child: Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: ac.textMuted,
                      ),
                    ),
                  )
                : PdfPageView(document: document, pageNumber: 1),
          ),
          // "PDF" label overlay.
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PDF',
                style: TextStyle(
                  color: cs.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _filename(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final segments = uri.pathSegments;
    return segments.isEmpty ? rawUrl : Uri.decodeComponent(segments.last);
  }

  void _openPdfViewer(BuildContext context) {
    context.push(
      '/preview',
      extra: (url: url, type: 'pdf', filename: _filename(url)),
    );
  }
}

class _VideoSlot extends StatelessWidget {
  const _VideoSlot({required this.url});

  final String url;

  static String _filename(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final segments = uri.pathSegments;
    return segments.isEmpty ? rawUrl : Uri.decodeComponent(segments.last);
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push(
        '/preview',
        extra: (url: url, type: 'video', filename: _filename(url)),
      ),
      child: Container(
        color: ac.surfaceDark,
        child: Center(
          child: Icon(Icons.play_circle_fill, color: cs.surface, size: 56),
        ),
      ),
    );
  }
}
