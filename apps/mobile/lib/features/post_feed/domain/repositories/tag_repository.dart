import 'package:unishare_mobile/features/post_feed/domain/entities/tag_entity.dart';

abstract interface class TagRepository {
  Future<List<TagEntity>> getTags();
}
