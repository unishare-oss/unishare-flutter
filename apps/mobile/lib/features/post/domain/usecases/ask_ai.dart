import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';

class AskAiParams {
  const AskAiParams({
    required this.postId,
    required this.summary,
    required this.history,
    required this.question,
    this.extractedText,
  });

  final String postId;
  final String summary;
  final List<AiMessage> history;
  final String question;

  /// PROP-0011 Phase 3 — full document text from the post doc. When supplied,
  /// the worker uses this for grounding instead of the summary, enabling
  /// answers that reference details outside the 3-7 bullet summary.
  final String? extractedText;
}

class AskAiUseCase {
  const AskAiUseCase(this._repository);

  final AskAiRepository _repository;

  Stream<AiMessage> call(AskAiParams params) => _repository.ask(
    summary: params.summary,
    extractedText: params.extractedText,
    history: params.history,
    question: params.question,
  );
}
