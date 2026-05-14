import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/feed/domain/entities/post_filter_preferences.dart';

part 'filter_preferences_provider.g.dart';

// Deferred to the data-layer phase alongside PreferencesRepositoryImpl.
// Requires currentUserProvider and preferencesRepositoryProvider, neither of
// which is implemented yet. Not read by any UI — feedFilterProvider
// handles session-local filter state in the meantime.
@riverpod
class FilterPreferencesNotifier extends _$FilterPreferencesNotifier {
  @override
  Future<PostFilterPreferences> build() async {
    // final uid = ref.read(currentUserProvider).requireValue.uid;
    // final useCase = GetFilterPreferences(ref.read(preferencesRepositoryProvider));
    // return useCase.call(uid);
    throw UnimplementedError();
  }

  Future<void> save(List<String> selectedTags) async {
    // Call SaveFilterPreferences use case then invalidate self.
    throw UnimplementedError();
  }

  Future<void> clear() => save(const []);
}
