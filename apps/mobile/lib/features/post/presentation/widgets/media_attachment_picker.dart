import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaAttachmentPicker extends StatelessWidget {
  const MediaAttachmentPicker({
    super.key,
    required this.paths,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  static const _maxBytes = 10 * 1024 * 1024;
  static const _exts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _exts,
      allowMultiple: true,
    );
    if (result == null) return;

    final updated = List<String>.from(paths);
    var skipped = false;

    for (final f in result.files) {
      if (f.path == null) continue;
      if (f.size > _maxBytes) {
        skipped = true;
        continue;
      }
      if (!updated.contains(f.path)) updated.add(f.path!);
    }

    if (skipped && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some files exceeded 10 MB and were skipped')),
      );
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paths.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: paths.map((path) {
              final name = path.split('/').last;
              final size =
                  File(path).existsSync() ? File(path).lengthSync() : 0;
              final kb = (size / 1024).toStringAsFixed(1);
              final tooLarge = size > _maxBytes;
              return _FileChip(
                name: name,
                sizeLabel: '$kb KB',
                tooLarge: tooLarge,
                icon: _iconFor(path),
                onRemove: () {
                  final updated = List<String>.from(paths)..remove(path);
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? () => _pick(context) : null,
          icon: const Icon(Icons.attach_file, size: 16),
          label: Text('Add attachment',
              style: GoogleFonts.spaceGrotesk(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6B6560),
            side: const BorderSide(color: Color(0xFFE2DAD0)),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    return Icons.image;
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({
    required this.name,
    required this.sizeLabel,
    required this.tooLarge,
    required this.icon,
    required this.onRemove,
  });
  final String name, sizeLabel;
  final bool tooLarge;
  final IconData icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFDC2626);
    const stone = Color(0xFF8A837E);
    final fg = tooLarge ? red : stone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tooLarge ? const Color(0xFFFEF2F2) : const Color(0xFFF7F3EE),
        border: Border.all(color: tooLarge ? red : const Color(0xFFE2DAD0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.length > 24 ? '${name.substring(0, 24)}…' : name,
                style: GoogleFonts.firaCode(fontSize: 11, color: fg),
              ),
              Text(
                tooLarge ? '$sizeLabel — exceeds 10 MB' : sizeLabel,
                style: GoogleFonts.firaCode(fontSize: 10, color: fg),
              ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: stone),
          ),
        ],
      ),
    );
  }
}
