import '../entities/tag_entity.dart';
import '../repositories/tag_repository.dart';

class GetTagList {
  const GetTagList(this._repository);

  final TagRepository _repository;

  Future<List<TagEntity>> call() => _repository.getTags();
}
