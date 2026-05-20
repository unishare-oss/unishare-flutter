import 'package:unishare_mobile/features/post/domain/entities/post.dart';

abstract class ShareRepository {
  Future<void> share(Post post);
}
