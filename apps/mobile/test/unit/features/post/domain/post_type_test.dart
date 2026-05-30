import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

void main() {
  group('PostType.displayLabel', () {
    test('lectureNote maps to NOTE', () {
      expect(PostType.lectureNote.displayLabel, 'NOTE');
    });

    test('exercise maps to EXERCISE', () {
      expect(PostType.exercise.displayLabel, 'EXERCISE');
    });
  });

  group('PostType.fromName', () {
    test('parses the canonical enum name', () {
      expect(PostType.fromName('lectureNote'), PostType.lectureNote);
      expect(PostType.fromName('exercise'), PostType.exercise);
    });

    test('is case-insensitive', () {
      expect(PostType.fromName('LECTURENOTE'), PostType.lectureNote);
      expect(PostType.fromName('Exercise'), PostType.exercise);
    });

    test('falls back to exercise for unknown or empty values', () {
      expect(PostType.fromName(''), PostType.exercise);
      expect(PostType.fromName('garbage'), PostType.exercise);
    });

    test('round-trips through .name for every value', () {
      for (final type in PostType.values) {
        expect(PostType.fromName(type.name), type);
      }
    });
  });
}
