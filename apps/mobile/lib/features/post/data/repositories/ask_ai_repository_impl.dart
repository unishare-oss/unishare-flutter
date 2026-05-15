import 'package:unishare_mobile/features/post/data/datasources/ask_ai_datasource.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';

const _offTopicReply = "I can only answer questions about this document.";

class AskAiRepositoryImpl implements AskAiRepository {
  const AskAiRepositoryImpl(this._datasource);

  final AskAiDatasource _datasource;

  @override
  Stream<AiMessage> ask({
    required String summary,
    required List<AiMessage> history,
    required String question,
  }) async* {
    final serialized = history
        .where((m) => !m.isPending)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
        .toList();

    try {
      String accumulated = '';

      await for (final event in _datasource.stream(
        summary: summary,
        question: question,
        history: serialized,
      )) {
        if (event.containsKey('error')) {
          throw Exception(event['error']);
        } else if (event.containsKey('t')) {
          accumulated += event['t'] as String;
          yield AiMessage(content: accumulated, isUser: false);
        } else if (event['done'] == true) {
          final isOffTopic = event['isOffTopic'] as bool? ?? false;
          if (isOffTopic) {
            yield AiMessage(
              content: _offTopicReply,
              isUser: false,
              isOffTopic: true,
            );
          }
        }
      }
    } catch (e) {
      if (e is AskAiException) rethrow;
      throw AskAiException(e.toString());
    }
  }
}
