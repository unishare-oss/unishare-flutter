import 'package:unishare_mobile/features/post/data/datasources/share_plus_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_repository.dart';

/// Thrown by [ShareRepositoryImpl] when the OS share sheet is unavailable and
/// the URL has been copied to the clipboard instead. The caller (presentation
/// layer) should show a "Link copied to clipboard" SnackBar.
class ShareFallbackException implements Exception {
  const ShareFallbackException();
}

class ShareRepositoryImpl implements ShareRepository {
  const ShareRepositoryImpl(this._datasource);

  final SharePlusDataSource _datasource;

  @override
  Future<void> share(Post post) async {
    final result = await _datasource.share(
      postId: post.id,
      postTitle: post.title,
    );
    if (result == ShareFallbackResult.copiedToClipboard) {
      throw const ShareFallbackException();
    }
  }
}
