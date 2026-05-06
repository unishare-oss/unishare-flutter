import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_tag_filters_provider.g.dart';

@riverpod
class ActiveTagFilters extends _$ActiveTagFilters {
  @override
  List<String> build() => const [];

  void set(List<String> tags) => state = tags;
  void clear() => state = const [];
}
