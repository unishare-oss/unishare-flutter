import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/requests/data/models/suggestion_dto.dart';

Map<String, dynamic> _firestoreData() {
  final now = Timestamp.fromDate(DateTime(2026, 5, 9, 12));
  return {
    'id': 'sug-1',
    'postId': 'post-1',
    'postTitle': 'DS midterm notes',
    'postType': 'lectureNote',
    'suggestedByUserId': 'user-2',
    'suggestedByName': 'Bob',
    'suggestedByAvatar': null,
    'createdAt': now,
  };
}

void main() {
  group('SuggestionDto', () {
    test('fromJson preserves all fields', () {
      final data = _firestoreData();
      final dto = SuggestionDto.fromJson(data);

      expect(dto.id, 'sug-1');
      expect(dto.postId, 'post-1');
      expect(dto.postTitle, 'DS midterm notes');
      expect(dto.postType, 'lectureNote');
      expect(dto.suggestedByUserId, 'user-2');
      expect(dto.suggestedByName, 'Bob');
      expect(dto.suggestedByAvatar, isNull);
    });

    test('toDomain maps all fields', () {
      final data = _firestoreData();
      final entity = SuggestionDto.fromJson(data).toDomain();

      expect(entity.id, 'sug-1');
      expect(entity.postId, 'post-1');
      expect(entity.postTitle, 'DS midterm notes');
      expect(entity.postType, 'lectureNote');
      expect(entity.suggestedByUserId, 'user-2');
      expect(entity.suggestedByName, 'Bob');
      expect(entity.suggestedByAvatar, isNull);
      expect(entity.createdAt, DateTime(2026, 5, 9, 12));
    });

    test('suggestedByAvatar maps when present', () {
      final data = Map<String, dynamic>.from(_firestoreData())
        ..['suggestedByAvatar'] = 'https://example.com/avatar.jpg';
      final entity = SuggestionDto.fromJson(data).toDomain();

      expect(entity.suggestedByAvatar, 'https://example.com/avatar.jpg');
    });
  });
}
