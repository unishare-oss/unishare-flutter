import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/files_step.dart';

Widget _wrap({List<PlatformFile> files = const [], CodeSnippet? codeSnippet}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FilesStep(
          files: files,
          codeSnippet: codeSnippet,
          onFilesChanged: (_) {},
          onSnippetChanged: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('FilesStep', () {
    testWidgets('renders heading and drop zone hint text', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Upload files'), findsOneWidget);
      expect(find.text('Drop files here or click to browse'), findsOneWidget);
      expect(find.textContaining('max 50 MB'), findsOneWidget);
    });

    testWidgets(
      'code snippet panel shows language dropdown and filename input',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.text('CODE SNIPPET (OPTIONAL)'), findsOneWidget);
        // Language dropdown shows default TypeScript.
        expect(find.text('TypeScript'), findsOneWidget);
        // Filename hint is present.
        expect(find.text('filename (no ext)'), findsOneWidget);
      },
    );

    testWidgets('empty snippet widget emits null via onSnippetChanged', (
      tester,
    ) async {
      CodeSnippet? received = const CodeSnippet(
        language: 'TypeScript',
        filename: 'snippet',
        content: 'something',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilesStep(
                files: const [],
                codeSnippet: null,
                onFilesChanged: (_) {},
                onSnippetChanged: (s) => received = s,
              ),
            ),
          ),
        ),
      );

      // Code textarea is initially empty — no change event fired on build.
      // Simulate typing and clearing.
      final codeField = find.byType(TextField).last;
      await tester.enterText(codeField, 'print("hi")');
      await tester.pump();

      // Now clear it.
      await tester.enterText(codeField, '');
      await tester.pump();

      expect(received, isNull);
    });

    testWidgets('file list renders row for each path', (tester) async {
      // Use paths that don't exist on disk — size will show as 0.0 MB.
      await tester.pumpWidget(
        _wrap(
          files: [
            PlatformFile(name: 'notes.pdf', size: 0, path: '/tmp/notes.pdf'),
            PlatformFile(
              name: 'lecture.png',
              size: 0,
              path: '/tmp/lecture.png',
            ),
          ],
        ),
      );
      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.text('lecture.png'), findsOneWidget);
    });
  });
}
