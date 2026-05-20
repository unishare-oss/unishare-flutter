import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';

abstract class AskAiRepository {
  Stream<AiMessage> ask({
    required String summary,
    required List<AiMessage> history,
    required String question,
    String? extractedText,
  });
}

class AskAiException implements Exception {
  const AskAiException(this.message);
  final String message;
  @override
  String toString() => 'AskAiException: $message';
}
