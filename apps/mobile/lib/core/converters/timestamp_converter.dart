import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts between Firestore [Timestamp] and [DateTime] for json_serializable.
/// Annotate Freezed DTO fields with @TimestampConverter() instead of using
/// Timestamp directly — Timestamp is not natively supported by json_serializable.
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime dateTime) => Timestamp.fromDate(dateTime);
}
