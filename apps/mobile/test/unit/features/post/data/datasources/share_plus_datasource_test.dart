import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/data/datasources/share_plus_datasource.dart';

// ---------------------------------------------------------------------------
// The Flutter Clipboard uses SystemChannels.platform ('flutter/platform')
// with JSONMethodCodec. share_plus uses its own platform channel.
// ---------------------------------------------------------------------------

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

// flutter/platform uses JSONMethodCodec — must match when stubbing.
const _platformChannel = OptionalMethodChannel(
  'flutter/platform',
  JSONMethodCodec(),
);

void _stubShareThrows() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        _shareChannel,
        (call) async => throw PlatformException(code: 'unavailable'),
      );
}

void _stubShareSucceeds() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shareChannel, (call) async => null);
}

void _clearStubs() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shareChannel, null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_platformChannel, null);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ds = SharePlusDataSource();

  group('SharePlusDataSource — fallback on PlatformException', () {
    tearDown(_clearStubs);

    test(
      'returns copiedToClipboard when share throws PlatformException',
      () async {
        _stubShareThrows();

        // Stub flutter/platform so Clipboard.setData does not throw.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_platformChannel, (call) async => null);

        final result = await ds.share(postId: 'p1', postTitle: 'Title');
        expect(result, ShareFallbackResult.copiedToClipboard);
      },
    );

    test('clipboard receives the correct URL when fallback fires', () async {
      _stubShareThrows();

      final clipboardCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_platformChannel, (call) async {
            clipboardCalls.add(call);
            return null;
          });

      await ds.share(postId: 'post-99', postTitle: 'Lecture Notes');

      final setDataCall = clipboardCalls.firstWhere(
        (c) => c.method == 'Clipboard.setData',
        orElse: () => throw StateError(
          'Clipboard.setData was not called. '
          'Calls: ${clipboardCalls.map((c) => c.method).toList()}',
        ),
      );
      final text = (setDataCall.arguments as Map)['text'] as String;
      expect(text, 'https://share.psstee.dev/posts/post-99');
    });

    test('returns shared when share platform channel succeeds', () async {
      _stubShareSucceeds();

      final result = await ds.share(postId: 'p2', postTitle: 'Notes');
      expect(result, ShareFallbackResult.shared);
    });
  });
}
