// Pure Dart — zero Flutter or Firebase imports.

abstract interface class ReactionRepository {
  Future<void> toggleReaction(String postId, String reactionType);
  Stream<Set<String>> watchUserReactions(String postId);
}
