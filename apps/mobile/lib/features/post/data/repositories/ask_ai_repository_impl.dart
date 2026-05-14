import 'package:unishare_mobile/features/post/data/datasources/ask_ai_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';

class AskAiRepositoryImpl implements AskAiRepository {
  const AskAiRepositoryImpl(this._datasource);

  final AskAiDatasource _datasource;

  @override
  Future<AiMessage> ask({
    required String summary,
    required List<AiMessage> history,
    required String question,
  }) async {
    final serialized = history
        .where((m) => !m.isPending)
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    try {
      final data = await _datasource.call(
        summary: summary,
        question: question,
        history: serialized,
      );
      return AiMessage(
        content: data['reply'] as String,
        isUser: false,
        isOffTopic: data['isOffTopic'] as bool? ?? false,
      );
    } catch (e) {
      throw AskAiException(e.toString());
    }
  }
}
