import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';

part 'request_dto.freezed.dart';
part 'request_dto.g.dart';

/// Custom JSON converter that handles Firestore [Timestamp] <-> [DateTime].
class _TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const _TimestampConverter();

  @override
  DateTime fromJson(Timestamp ts) => ts.toDate();

  @override
  Timestamp toJson(DateTime dt) => Timestamp.fromDate(dt);
}

@freezed
abstract class RequestDto with _$RequestDto {
  const factory RequestDto({
    required String id,
    required String requesterId,
    required String requesterName,
    String? requesterAvatar,
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
    required String status,
    String? fulfilledByPostId,
    String? fulfilledByPostTitle,
    @Default(0) int upvoteCount,
    @_TimestampConverter() required DateTime createdAt,
    @_TimestampConverter() required DateTime updatedAt,
  }) = _RequestDto;

  factory RequestDto.fromJson(Map<String, dynamic> json) =>
      _$RequestDtoFromJson(json);
}

extension RequestDtoMapper on RequestDto {
  ContentRequest toDomain() => ContentRequest(
    id: id,
    requesterId: requesterId,
    requesterName: requesterName,
    requesterAvatar: requesterAvatar,
    departmentId: departmentId,
    departmentName: departmentName,
    year: year,
    courseId: courseId,
    courseName: courseName,
    title: title,
    description: description,
    status: status == 'fulfilled'
        ? RequestStatus.fulfilled
        : RequestStatus.open,
    fulfilledByPostId: fulfilledByPostId,
    fulfilledByPostTitle: fulfilledByPostTitle,
    upvoteCount: upvoteCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
