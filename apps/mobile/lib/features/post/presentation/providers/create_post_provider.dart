import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';

part 'create_post_provider.g.dart';

sealed class CreatePostState {
  const CreatePostState();
}

final class CreatePostIdle extends CreatePostState {
  const CreatePostIdle();
}

final class CreatePostUploading extends CreatePostState {
  const CreatePostUploading({required this.progress});
  final double progress; // [0.0, 1.0]
}

final class CreatePostPublishing extends CreatePostState {
  const CreatePostPublishing();
}

final class CreatePostPublished extends CreatePostState {
  const CreatePostPublished({required this.postId});
  final String postId;
}

final class CreatePostQueued extends CreatePostState {
  const CreatePostQueued({required this.draftId});
  final String draftId;
}

final class CreatePostError extends CreatePostState {
  const CreatePostError({required this.message, required this.draft});
  final String message;
  final PostDraft draft;
}

@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  static final _rand = Random.secure();
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  @override
  CreatePostState build() => const CreatePostIdle();

  Future<void> submit({
    required PostDraft draft,
    Map<String, Uint8List>? fileDataOverride,
  }) async {
    final useCase = ref.read(createPostUseCaseProvider);

    state = const CreatePostUploading(progress: 0.0);

    try {
      final results = await Connectivity().checkConnectivity();
      // connectivity_plus returns none on web — treat web as always connected.
      final isConnected = kIsWeb || !results.contains(ConnectivityResult.none);

      final result = await useCase(
        draft: draft,
        isConnected: isConnected,
        fileDataOverride: fileDataOverride,
        onProgress: (p) {
          state = p < 1.0
              ? CreatePostUploading(progress: p)
              : const CreatePostPublishing();
        },
      );

      state = switch (result.status) {
        DraftStatus.published => CreatePostPublished(postId: result.id),
        DraftStatus.queued => CreatePostQueued(draftId: result.id),
        _ => CreatePostError(
          message: result.errorMessage ?? 'Unknown error',
          draft: result,
        ),
      };
    } on ArgumentError catch (e) {
      state = CreatePostError(message: e.message.toString(), draft: draft);
    } catch (e) {
      state = CreatePostError(message: e.toString(), draft: draft);
    }
  }

  void reset() => state = const CreatePostIdle();

  static String generateId() =>
      List.generate(20, (_) => _chars[_rand.nextInt(_chars.length)]).join();
}
