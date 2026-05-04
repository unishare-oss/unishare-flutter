// TODO(flutter-engineer): call initPostDraftBox() in main.dart after Hive.initFlutter()

import 'package:hive_flutter/hive_flutter.dart';

import '../../../features/post/data/models/post_draft_model.dart';

Future<void> initPostDraftBox() async {
  Hive.registerAdapter(PostDraftModelAdapter());
  await Hive.openBox<PostDraftModel>('draft_queue');
}
