import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/data/models/request_dto.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';

Map<String, dynamic> _firestoreData() {
  final now = Timestamp.fromDate(DateTime(2026, 5, 9, 12));
  return {
    'id': 'req-1',
    'requesterId': 'user-1',
    'requesterName': 'Alice',
    'requesterAvatar': null,
    'departmentId': 'dept-1',
    'departmentName': 'Computer Science',
    'year': '2',
    'courseId': 'CSC234',
    'courseName': 'CSC234',
    'title': 'Data Structures notes',
    'description': null,
    'status': 'open',
    'fulfilledByPostId': null,
    'fulfilledByPostTitle': null,
    'upvoteCount': 0,
    'createdAt': now,
    'updatedAt': now,
  };
}

void main() {
  group('RequestDto', () {
    test('fromJson round-trip preserves all fields', () {
      final data = _firestoreData();
      final dto = RequestDto.fromJson(data);

      expect(dto.id, 'req-1');
      expect(dto.requesterId, 'user-1');
      expect(dto.requesterName, 'Alice');
      expect(dto.departmentId, 'dept-1');
      expect(dto.year, '2');
      expect(dto.courseId, 'CSC234');
      expect(dto.title, 'Data Structures notes');
      expect(dto.status, 'open');
      expect(dto.upvoteCount, 0);
    });

    test('toDomain maps open status correctly', () {
      final data = _firestoreData();
      final entity = RequestDto.fromJson(data).toDomain();

      expect(entity.status, RequestStatus.open);
      expect(entity.id, 'req-1');
      expect(entity.title, 'Data Structures notes');
    });

    test('toDomain maps fulfilled status correctly', () {
      final data = Map<String, dynamic>.from(_firestoreData())
        ..['status'] = 'fulfilled'
        ..['fulfilledByPostId'] = 'post-99'
        ..['fulfilledByPostTitle'] = 'DS midterm notes';
      final entity = RequestDto.fromJson(data).toDomain();

      expect(entity.status, RequestStatus.fulfilled);
      expect(entity.fulfilledByPostId, 'post-99');
      expect(entity.fulfilledByPostTitle, 'DS midterm notes');
    });

    test('unknown status defaults to open', () {
      final data = Map<String, dynamic>.from(_firestoreData())
        ..['status'] = 'unknown_value';
      final entity = RequestDto.fromJson(data).toDomain();

      expect(entity.status, RequestStatus.open);
    });
  });
}
