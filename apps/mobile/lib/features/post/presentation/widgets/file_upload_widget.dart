import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFFF7F3EE);
const _kWhite = Colors.white;
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);
const _kRed = Color(0xFFDC2626);

const _maxBytes = 50 * 1024 * 1024; // 50 MB per spec
const _allowedExtensions = [
  // Images
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'tiff', 'bmp', 'avif', 'heic', 'heif',
  // Documents
  'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'odt', 'odp', 'ods', 'epub',
  // Text / code
  'txt', 'md', 'html', 'css', 'csv', 'json',
  // Archives
  'zip', 'tar', 'gz',
  // Video
  'mp4', 'webm', 'ogv', 'mov', 'avi', 'mkv',
];

/// Drop zone + file list. Works on all platforms (mobile and web).
/// Uses [PlatformFile] so size is always available without dart:io.
class FileUploadWidget extends StatelessWidget {
  const FileUploadWidget({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
      withData: kIsWeb, // read bytes on web; use path on mobile
    );
    if (result == null) return;

    final updated = List<PlatformFile>.from(files);
    var skipped = false;

    for (final f in result.files) {
      if (f.size > _maxBytes) {
        skipped = true;
        continue;
      }
      if (!updated.any((e) => e.name == f.name)) updated.add(f);
    }

    if (skipped && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some files exceeded 50 MB and were skipped'),
        ),
      );
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: enabled ? () => _pick(context) : null,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _kBorder,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file, color: _kMuted, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    'Drop files here or click to browse',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: _kMuted,
                    ),
                  ),
                  Text(
                    'max 50 MB per file',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: _kMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, i) {
              final f = files[i];
              final sizeMb = (f.size / (1024 * 1024)).toStringAsFixed(1);
              final tooLarge = f.size > _maxBytes;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _FileRow(
                  name: f.name,
                  sizeLabel: '$sizeMb MB',
                  tooLarge: tooLarge,
                  onRemove: () {
                    final updated = List<PlatformFile>.from(files)..removeAt(i);
                    onChanged(updated);
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.name,
    required this.sizeLabel,
    required this.tooLarge,
    required this.onRemove,
  });

  final String name;
  final String sizeLabel;
  final bool tooLarge;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fg = tooLarge ? _kRed : _kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tooLarge ? const Color(0xFFFEF2F2) : _kWhite,
        border: Border.all(color: tooLarge ? _kRed : _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(_iconFor(name), size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.length > 30 ? '${name.substring(0, 30)}…' : name,
                  style: GoogleFonts.firaCode(fontSize: 12, color: _kFg),
                ),
                Text(
                  tooLarge ? '$sizeLabel — exceeds 50 MB' : sizeLabel,
                  style: GoogleFonts.firaCode(fontSize: 11, color: fg),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: _kMuted),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    return Icons.image_outlined;
  }
}
