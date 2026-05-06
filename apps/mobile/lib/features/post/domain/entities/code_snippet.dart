class CodeSnippet {
  const CodeSnippet({
    required this.language,
    required this.filename,
    required this.content,
  });

  final String language; // e.g. "TypeScript"
  final String filename; // without extension, e.g. "snippet"
  final String content;
}
