import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/core/cancellation/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('isCancelled is false initially', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('isCancelled is true after cancel()', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('listener fires immediately when token is already cancelled', () {
      final token = CancellationToken()..cancel();
      var fired = false;
      token.addCancelListener(() => fired = true);
      expect(fired, isTrue);
    });

    test('listener fires when cancel() is called later', () {
      final token = CancellationToken();
      var fired = false;
      token.addCancelListener(() => fired = true);
      expect(fired, isFalse);
      token.cancel();
      expect(fired, isTrue);
    });

    test('cancel() is idempotent — listener fires only once', () {
      final token = CancellationToken();
      var count = 0;
      token.addCancelListener(() => count++);
      token.cancel();
      token.cancel();
      expect(count, 1);
    });
  });
}
