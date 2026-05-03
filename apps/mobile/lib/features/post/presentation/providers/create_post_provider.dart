import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/post_draft.dart';
import 'post_repository_provider.dart';

part 'create_post_provider.g.dart';

sealed class CreatePostState {
  const CreatePostState();
}

final class CreatePostIdle extends CreatePostState {
  const CreatePostIdle();
}

final class CreatePostUploading extends CreatePostState {
  const CreatePostUploading({required this.progress});
  final double progress;
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
    required String title,
    required String body,
    required List<String> tags,
    required List<String> localMediaPaths,
  }) async {
    final useCase = ref.read(createPostUseCaseProvider);
    final id = List.generate(20, (_) => _chars[_rand.nextInt(_chars.length)]).join();

    final draft = PostDraft(
      id: id,
      title: title,
      body: body,
      tags: tags,
      localMediaPaths: localMediaPaths,
      uploadedUrls: {},
      createdAt: DateTime.now(),
    );

    state = const CreatePostUploading(progress: 0.0);

    try {
      final results = await Connectivity().checkConnectivity();
      final isConnected = !results.contains(ConnectivityResult.none);

      final result = await useCase(
        draft: draft,
        isConnected: isConnected,
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
}
