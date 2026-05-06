import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post_feed/domain/entities/tag_entity.dart';

part 'tag_list_provider.g.dart';

// TODO: wire tagRepositoryProvider
@riverpod
Future<List<TagEntity>> tagList(Ref ref) async {
  // TODO: final useCase = GetTagList(ref.read(tagRepositoryProvider));
  // return useCase.call();
  throw UnimplementedError();
}
