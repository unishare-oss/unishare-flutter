import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/post_draft_model.dart';
import '../../domain/entities/post_draft.dart';
import 'post_repository_provider.dart';

part 'draft_queue_provider.g.dart';

@riverpod
class DraftQueueNotifier extends _$DraftQueueNotifier {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<BoxEvent>? _boxSub;

  @override
  List<PostDraft> build() {
    ref.onDispose(() {
      _connSub?.cancel();
      _boxSub?.cancel();
    });

    final box = Hive.box<PostDraftModel>('draft_queue');

    _boxSub = box.watch().listen((_) {
      state = _fromBox(box);
    });

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        sync();
      }
    });

    return _fromBox(box);
  }

  List<PostDraft> _fromBox(Box<PostDraftModel> box) {
    return (box.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  Future<void> sync() async {
    final useCase = ref.read(syncDraftQueueUseCaseProvider);
    await useCase().drain<void>();
  }
}
