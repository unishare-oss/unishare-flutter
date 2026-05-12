import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

const _kLanguages = [
  'TypeScript',
  'JavaScript',
  'Python',
  'Dart',
  'Java',
  'Kotlin',
  'Swift',
  'C',
  'C++',
  'C#',
  'Rust',
  'Go',
  'SQL',
  'Bash',
  'HTML',
  'CSS',
  'Other',
];

/// Code snippet panel: language dropdown, filename input, code textarea.
/// Passes null to [onChanged] when the content is empty (no upload needed).
class CodeSnippetWidget extends StatefulWidget {
  const CodeSnippetWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CodeSnippet? value;
  final ValueChanged<CodeSnippet?> onChanged;

  @override
  State<CodeSnippetWidget> createState() => _CodeSnippetWidgetState();
}

class _CodeSnippetWidgetState extends State<CodeSnippetWidget> {
  late String _language;
  late final TextEditingController _filenameCtrl;
  late final TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _language = widget.value?.language ?? 'TypeScript';
    _filenameCtrl = TextEditingController(text: widget.value?.filename ?? '');
    _contentCtrl = TextEditingController(text: widget.value?.content ?? '');

    _filenameCtrl.addListener(_notify);
    _contentCtrl.addListener(_notify);
  }

  @override
  void dispose() {
    _filenameCtrl.removeListener(_notify);
    _contentCtrl.removeListener(_notify);
    _filenameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(
        CodeSnippet(
          language: _language,
          filename: _filenameCtrl.text.trim().isEmpty
              ? 'snippet'
              : _filenameCtrl.text.trim(),
          content: _contentCtrl.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CODE SNIPPET (OPTIONAL)',
            style: AppTypography.mono(
              base: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ac.mutedForeground,
                letterSpacing: 0.55,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Language dropdown + filename row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _LanguageDropdown(
                  value: _language,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _language = v);
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _InlineTextField(
                  controller: _filenameCtrl,
                  hint: 'filename (no ext)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Code textarea
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            style: AppTypography.mono(
              base: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface),
            ),
            decoration: InputDecoration(
              hintText: '// paste your code here…',
              hintStyle: AppTypography.mono(
                base: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ac.mutedForeground,
                ),
              ),
              filled: true,
              fillColor: scaffoldBg,
              contentPadding: const EdgeInsets.all(10),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: ac.amber, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 16,
          ),
          style: AppTypography.mono(
            base: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface),
          ),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(4),
          items: _kLanguages
              .map(
                (l) => DropdownMenuItem(
                  value: l,
                  child: Text(
                    l,
                    style: AppTypography.mono(
                      base: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        style: AppTypography.mono(
          base: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.mono(
            base: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ac.mutedForeground,
            ),
          ),
          filled: true,
          fillColor: scaffoldBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: ac.amber, width: 1.5),
          ),
        ),
      ),
    );
  }
}
