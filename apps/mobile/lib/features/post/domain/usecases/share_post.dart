import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/domain/repositories/share_repository.dart';

class SharePostUseCase {
  const SharePostUseCase(this._repo);

  final ShareRepository _repo;

  Future<void> call(Post post) => _repo.share(post);
}
