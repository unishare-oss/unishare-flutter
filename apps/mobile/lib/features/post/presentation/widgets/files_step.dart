import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/code_snippet_widget.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/file_upload_widget.dart';

const _kFg = Color(0xFF1C1917);

/// Step 4: file drop zone + code snippet panel.
class FilesStep extends StatelessWidget {
  const FilesStep({
    super.key,
    required this.files,
    required this.codeSnippet,
    required this.onFilesChanged,
    required this.onSnippetChanged,
  });

  final List<PlatformFile> files;
  final CodeSnippet? codeSnippet;
  final ValueChanged<List<PlatformFile>> onFilesChanged;
  final ValueChanged<CodeSnippet?> onSnippetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload files',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kFg,
          ),
        ),
        const SizedBox(height: 24),
        FileUploadWidget(files: files, onChanged: onFilesChanged),
        const SizedBox(height: 20),
        CodeSnippetWidget(value: codeSnippet, onChanged: onSnippetChanged),
        const SizedBox(height: 8),
      ],
    );
  }
}
