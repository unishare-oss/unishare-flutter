import '../../domain/entities/tag_entity.dart';
import '../../domain/repositories/tag_repository.dart';

// TODO: inject TagFirestoreDatasource
class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl();

  @override
  Future<List<TagEntity>> getTags() {
    // TODO: delegate to TagFirestoreDatasource; sort by department then code
    throw UnimplementedError();
  }
}
