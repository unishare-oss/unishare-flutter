import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post_feed/domain/entities/post_filter_preferences.dart';

part 'filter_preferences_provider.g.dart';

// TODO: wire preferencesRepositoryProvider and currentUserProvider
@riverpod
class FilterPreferencesNotifier extends _$FilterPreferencesNotifier {
  @override
  Future<PostFilterPreferences> build() async {
    // TODO: read uid from currentUserProvider
    // final uid = ref.read(currentUserProvider).requireValue.uid;
    // final useCase = GetFilterPreferences(ref.read(preferencesRepositoryProvider));
    // return useCase.call(uid);
    throw UnimplementedError();
  }

  Future<void> save(List<String> selectedTags) async {
    // TODO: implement save — call SaveFilterPreferences use case then update state
    throw UnimplementedError();
  }

  Future<void> clear() => save(const []);
}
