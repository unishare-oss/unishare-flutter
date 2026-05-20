import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/moderation/domain/entities/moderation_verdict.dart';

class ModerationVerdictModel {
  const ModerationVerdictModel({
    required this.recommended,
    required this.confidence,
    required this.reason,
    required this.processedAt,
  });

  final String recommended;
  final double confidence;
  final String reason;
  final DateTime processedAt;

  static ModerationVerdictModel? fromMap(Map<String, dynamic> map) {
    final recommended = map['recommended'] as String?;
    if (recommended == null) return null;

    final ts = map['processedAt'];
    final processedAt = ts is Timestamp
        ? ts.toDate()
        : DateTime.fromMillisecondsSinceEpoch((ts as int? ?? 0));

    return ModerationVerdictModel(
      recommended: recommended,
      confidence: (map['confidence'] as num? ?? 0.0).toDouble(),
      reason: (map['reason'] as String? ?? ''),
      processedAt: processedAt,
    );
  }

  ModerationVerdict toEntity() => ModerationVerdict(
    recommended: recommended,
    confidence: confidence,
    reason: reason,
    processedAt: processedAt,
  );
}
