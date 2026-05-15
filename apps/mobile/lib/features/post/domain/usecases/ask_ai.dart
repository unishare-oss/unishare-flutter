import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';

class AskAiParams {
  const AskAiParams({
    required this.postId,
    required this.summary,
    required this.history,
    required this.question,
  });

  final String postId;
  final String summary;
  final List<AiMessage> history;
  final String question;
}

class AskAiUseCase {
  const AskAiUseCase(this._repository);

  final AskAiRepository _repository;

  Stream<AiMessage> call(AskAiParams params) => _repository.ask(
    summary: params.summary,
    history: params.history,
    question: params.question,
  );
}
