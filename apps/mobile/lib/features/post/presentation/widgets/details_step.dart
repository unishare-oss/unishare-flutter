import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';

const _kWhite = Colors.white;
const _kPrimary = Color(0xFFD97706);
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);

class DetailsStep extends StatefulWidget {
  const DetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.moduleNumberController,
    required this.externalUrlController,
    required this.postingIdentity,
    required this.semester,
    required this.tags,
    required this.onIdentityChanged,
    required this.onSemesterChanged,
    required this.onTagsChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController moduleNumberController;
  final TextEditingController externalUrlController;
  final PostingIdentity postingIdentity;
  final int semester;
  final List<String> tags;
  final ValueChanged<PostingIdentity> onIdentityChanged;
  final ValueChanged<int> onSemesterChanged;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  final _tagCtrl = TextEditingController();

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim().replaceAll('#', '');
    if (tag.isEmpty || widget.tags.contains(tag)) {
      _tagCtrl.clear();
      return;
    }
    if (widget.tags.length >= 5) {
      _tagCtrl.clear();
      return;
    }
    widget.onTagsChanged(List<String>.from(widget.tags)..add(tag));
    _tagCtrl.clear();
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(List<String>.from(widget.tags)..remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add details',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kFg,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          _FieldLabel('TITLE', required: true),
          const SizedBox(height: 6),
          _TextField(
            controller: widget.titleController,
            hint: 'e.g. Complete Lecture Notes Week 1-6',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Description
          _FieldLabel('DESCRIPTION', required: true),
          const SizedBox(height: 6),
          _TextField(
            controller: widget.descriptionController,
            hint: "Describe what you're sharing...",
            maxLines: 5,
          ),
          const SizedBox(height: 16),

          // Posting identity
          _FieldLabel('POSTING IDENTITY'),
          const SizedBox(height: 8),
          _IdentitySelector(
            value: widget.postingIdentity,
            onChanged: widget.onIdentityChanged,
          ),
          const SizedBox(height: 16),

          // Semester — dropdown
          _FieldLabel('SEMESTER', required: true),
          const SizedBox(height: 6),
          _SemesterDropdown(
            value: widget.semester,
            onChanged: widget.onSemesterChanged,
          ),
          const SizedBox(height: 16),

          // Module number
          _FieldLabel('MODULE NUMBER', required: true),
          const SizedBox(height: 6),
          _TextField(
            controller: widget.moduleNumberController,
            hint: 'e.g. 4',
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // External URL
          _FieldLabel('EXTERNAL URL', optional: true),
          const SizedBox(height: 6),
          _TextField(
            controller: widget.externalUrlController,
            hint: 'https://...',
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // Tags
          _FieldLabel('TAGS', optional: true),
          const SizedBox(height: 6),
          _TextField(
            controller: _tagCtrl,
            hint: 'Type a tag and press Enter...',
            textInputAction: TextInputAction.done,
            onSubmitted: _addTag,
          ),
          const SizedBox(height: 6),
          Text(
            'Add up to 5 tags to help others discover your post.',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kMuted),
          ),
          if (widget.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.tags
                  .map((t) => _TagChip(label: t, onDelete: () => _removeTag(t)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Posting identity — bordered cards
// ---------------------------------------------------------------------------

class _IdentitySelector extends StatelessWidget {
  const _IdentitySelector({required this.value, required this.onChanged});

  final PostingIdentity value;
  final ValueChanged<PostingIdentity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IdentityCard(
          label: 'Post with your profile',
          selected: value == PostingIdentity.named,
          onTap: () => onChanged(PostingIdentity.named),
        ),
        const SizedBox(height: 8),
        _IdentityCard(
          label: 'Post anonymously',
          selected: value == PostingIdentity.anonymous,
          onTap: () => onChanged(PostingIdentity.anonymous),
        ),
        const SizedBox(height: 6),
        Text(
          'Moderators can still review the post, but other users will not see your identity.',
          style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kMuted),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _kWhite,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kPrimary : _kBorder,
                  width: selected ? 5 : 1.5,
                ),
                color: _kWhite,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Semester dropdown
// ---------------------------------------------------------------------------

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _kWhite,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _kMuted, size: 18),
          dropdownColor: _kWhite,
          borderRadius: BorderRadius.circular(6),
          focusColor: Colors.transparent,
          items: [1, 2]
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    'Semester $s',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kFg,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: GoogleFonts.spaceGrotesk(fontSize: 14, color: _kFg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: _kMuted),
        filled: true,
        fillColor: _kWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false, this.optional = false});

  final String text;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kMuted,
          letterSpacing: 0.55,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: _kPrimary, fontSize: 13),
            ),
          if (optional) const TextSpan(text: ' (optional)'),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onDelete});
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _kWhite,
      border: Border.all(color: _kBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#$label',
          style: GoogleFonts.firaCode(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kMuted,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.close, size: 14, color: _kMuted),
        ),
      ],
    ),
  );
}
