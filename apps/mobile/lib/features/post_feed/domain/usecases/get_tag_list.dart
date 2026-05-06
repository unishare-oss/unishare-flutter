import 'package:unishare_mobile/features/post_feed/domain/entities/tag_entity.dart';
import 'package:unishare_mobile/features/post_feed/domain/repositories/tag_repository.dart';

class GetTagList {
  const GetTagList(this._repository);

  final TagRepository _repository;

  Future<List<TagEntity>> call() => _repository.getTags();
}
