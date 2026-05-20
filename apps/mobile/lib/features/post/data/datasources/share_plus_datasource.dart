import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ShareFallbackResult { shared, copiedToClipboard }

class SharePlusDataSource {
  const SharePlusDataSource();

  static const _baseUrl = 'https://share.psstee.dev';

  Future<ShareFallbackResult> share({
    required String postId,
    required String postTitle,
  }) async {
    final url = '$_baseUrl/posts/$postId';
    final text = '$postTitle — $url';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      // Dismissed by user (cancelled) is still treated as success — silent.
      return ShareFallbackResult.shared;
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: url));
      return ShareFallbackResult.copiedToClipboard;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      return ShareFallbackResult.copiedToClipboard;
    }
  }
}
