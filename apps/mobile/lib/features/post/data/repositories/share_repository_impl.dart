import 'package:unishare_mobile/features/post/data/datasources/share_plus_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_exceptions.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_repository.dart';

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
