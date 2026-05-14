import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/ask_ai.dart';
import 'package:unishare_mobile/features/post/presentation/providers/ask_ai_repository_provider.dart';

part 'ask_ai_provider.g.dart';

@riverpod
class AskAi extends _$AskAi {
  @override
  AsyncValue<List<AiMessage>> build(String postId) =>
      const AsyncData(<AiMessage>[]);

  Future<void> sendMessage(String question, {required String summary}) async {
    final history = state.value ?? [];
    final userMsg = AiMessage(content: question, isUser: true);
    const pending = AiMessage(content: '', isUser: false, isPending: true);

    state = AsyncData([...history, userMsg, pending]);

    try {
      final params = AskAiParams(
        postId: postId,
        summary: summary,
        history: [...history, userMsg],
        question: question,
      );
      final reply = await ref.read(askAiUseCaseProvider).call(params);
      final updated = [...(state.value ?? [])];
      updated[updated.length - 1] = reply;
      state = AsyncData(updated);
    } on AskAiException catch (e, st) {
      final withoutPending = (state.value ?? [])
          .where((m) => !m.isPending)
          .toList();
      state = AsyncData(withoutPending);
      Error.throwWithStackTrace(e, st);
    }
  }
}
