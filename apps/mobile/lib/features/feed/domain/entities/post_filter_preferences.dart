class PostFilterPreferences {
  const PostFilterPreferences({
    required this.selectedTags,
    required this.updatedAt,
  });

  final List<String> selectedTags;
  final DateTime updatedAt;

  bool get isActive => selectedTags.isNotEmpty;

  PostFilterPreferences copyWith({
    List<String>? selectedTags,
    DateTime? updatedAt,
  }) {
    return PostFilterPreferences(
      selectedTags: selectedTags ?? this.selectedTags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PostFilterPreferences empty() => PostFilterPreferences(
    selectedTags: const [],
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
