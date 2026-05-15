import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/notifications/domain/entities/notification_item.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Custom JSON converter that handles Firestore [Timestamp] <-> [DateTime].
class _TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const _TimestampConverter();

  @override
  DateTime fromJson(Timestamp ts) => ts.toDate();

  @override
  Timestamp toJson(DateTime dt) => Timestamp.fromDate(dt);
}

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String type,
    required bool isRead,
    @_TimestampConverter() required DateTime createdAt,
    required String title,
    required String body,
    required String actorId,
    required String actorName,
    String? actorPhotoUrl,
    required String targetId,
    required String targetType,
    required String targetTitle,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

extension NotificationModelMapper on NotificationModel {
  AppNotification toDomain() => AppNotification(
    id: id,
    type: _parseType(type),
    isRead: isRead,
    createdAt: createdAt,
    title: title,
    body: body,
    actorId: actorId,
    actorName: actorName,
    actorPhotoUrl: actorPhotoUrl,
    targetId: targetId,
    targetType: targetType,
    targetTitle: targetTitle,
  );
}

/// Maps a Firestore string value such as `'post_comment_added'` to the
/// corresponding [NotificationType] enum variant.
///
/// Falls back to [NotificationType.postCommentAdded] if the string is unknown.
NotificationType _parseType(String raw) => NotificationType.values.firstWhere(
  (e) => e.name == _snakeToCamel(raw),
  orElse: () => NotificationType.postCommentAdded,
);

/// Converts `'post_comment_added'` → `'postCommentAdded'` for enum lookup.
String _snakeToCamel(String s) =>
    s.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m.group(1)!.toUpperCase());
