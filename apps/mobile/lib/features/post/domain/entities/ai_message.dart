class AiMessage {
  const AiMessage({
    required this.content,
    required this.isUser,
    this.isOffTopic = false,
    this.isPending = false,
  });

  final String content;
  final bool isUser;
  final bool isOffTopic;
  final bool isPending;
}
