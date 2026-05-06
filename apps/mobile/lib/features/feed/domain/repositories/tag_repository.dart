import 'package:unishare_mobile/features/feed/domain/entities/tag_entity.dart';

abstract interface class TagRepository {
  Future<List<TagEntity>> getTags();
}
