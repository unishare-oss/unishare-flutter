import '../entities/tag_entity.dart';

abstract interface class TagRepository {
  Future<List<TagEntity>> getTags();
}
