// Pure Dart — zero Flutter or Firebase imports.

class ModerationVerdict {
  const ModerationVerdict({
    required this.recommended,
    required this.confidence,
    required this.reason,
    required this.processedAt,
  });

  /// 'approve' | 'reject'
  final String recommended;

  /// 0.0 – 1.0
  final double confidence;

  final String reason;
  final DateTime processedAt;
}
