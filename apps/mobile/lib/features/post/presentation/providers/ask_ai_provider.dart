import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/ask_ai.dart';
import 'package:unishare_mobile/features/post/presentation/providers/ask_ai_repository_provider.dart';

part 'ask_ai_provider.g.dart';

@riverpod
class AskAi extends _$AskAi {
  late final AskAiUseCase _useCase;

  @override
  AsyncValue<List<AiMessage>> build(String postId) {
    _useCase = ref.watch(askAiUseCaseProvider);
    return const AsyncData(<AiMessage>[]);
  }

  Future<void> sendMessage(
    String question, {
    required String summary,
    String? extractedText,
  }) async {
    final history = state.value ?? [];
    final userMsg = AiMessage(content: question, isUser: true);
    const pending = AiMessage(content: '', isUser: false, isPending: true);

    final assistantIndex = history.length + 1;
    state = AsyncData([...history, userMsg, pending]);

    try {
      final params = AskAiParams(
        postId: postId,
        summary: summary,
        extractedText: extractedText,
        history: [...history, userMsg],
        question: question,
      );
      await for (final msg in _useCase.call(params)) {
        final current = List<AiMessage>.from(state.value ?? []);
        if (current.isNotEmpty) {
          current[current.length - 1] = msg;
          state = AsyncData(current);
        }
      }
    } on AskAiException catch (e, st) {
      final current = List<AiMessage>.from(state.value ?? []);
      if (assistantIndex < current.length) current.removeAt(assistantIndex);
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    }
  }
}
