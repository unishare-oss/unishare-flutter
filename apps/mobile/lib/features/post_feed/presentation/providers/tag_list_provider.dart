import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/tag_entity.dart';
import '../../domain/usecases/get_tag_list.dart';

part 'tag_list_provider.g.dart';

// TODO: wire tagRepositoryProvider
@riverpod
Future<List<TagEntity>> tagList(Ref ref) async {
  // TODO: final useCase = GetTagList(ref.read(tagRepositoryProvider));
  // return useCase.call();
  throw UnimplementedError();
}
