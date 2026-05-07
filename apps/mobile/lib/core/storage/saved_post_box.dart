import 'package:hive_flutter/hive_flutter.dart';

import 'package:unishare_mobile/features/saved/data/models/saved_post_hive_model.dart';

Future<void> initSavedPostBox() async {
  Hive.registerAdapter(SavedPostHiveModelAdapter());
  await Hive.openBox<SavedPostHiveModel>('saved_posts');
}
