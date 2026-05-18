import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';

void main() {
  group('validateDisplayedBadgesSelection', () {
    test('accepts a valid selection of earned badges', () {
      validateDisplayedBadgesSelection(
        proposed: const ['a', 'b'],
        earnedIds: const {'a', 'b', 'c'},
      );
    });

    test('rejects more than 3 badges', () {
      expect(
        () => validateDisplayedBadgesSelection(
          proposed: const ['a', 'b', 'c', 'd'],
          earnedIds: const {'a', 'b', 'c', 'd'},
        ),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });

    test('rejects duplicates', () {
      expect(
        () => validateDisplayedBadgesSelection(
          proposed: const ['a', 'a'],
          earnedIds: const {'a'},
        ),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });

    test('rejects unearned badges', () {
      expect(
        () => validateDisplayedBadgesSelection(
          proposed: const ['a', 'x'],
          earnedIds: const {'a'},
        ),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });
  });
}
