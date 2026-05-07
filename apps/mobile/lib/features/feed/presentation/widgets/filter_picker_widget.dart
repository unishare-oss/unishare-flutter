import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

class FilterPickerWidget extends StatefulWidget {
  const FilterPickerWidget({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onConfirm,
  });

  final List<String> availableTags;
  final List<String> selectedTags;
  final void Function(List<String> selected) onConfirm;

  static Future<void> show(
    BuildContext context, {
    required List<String> availableTags,
    required List<String> selectedTags,
    required void Function(List<String>) onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FilterPickerWidget(
        availableTags: availableTags,
        selectedTags: selectedTags,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<FilterPickerWidget> createState() => _FilterPickerWidgetState();
}

class _FilterPickerWidgetState extends State<FilterPickerWidget> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(dividerColor),
              _buildHeader(cs, ac),
              Divider(height: 1, color: dividerColor),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.availableTags.length,
                  itemBuilder: (context, index) {
                    final tag = widget.availableTags[index];
                    final checked = _selected.contains(tag);
                    return InkWell(
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(tag);
                        } else {
                          _selected.add(tag);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              activeColor: ac.amber,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(tag);
                                } else {
                                  _selected.remove(tag);
                                }
                              }),
                            ),
                            Text(
                              tag,
                              style: GoogleFonts.firaCode(
                                fontSize: 13,
                                color: checked ? ac.amber : cs.onSurface,
                                fontWeight: checked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: dividerColor),
              _buildActions(cs, ac, dividerColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(Color dividerColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppColors ac) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter by tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          if (_selected.isNotEmpty)
            Text(
              '${_selected.length} selected',
              style: TextStyle(fontSize: 12, color: ac.amber),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(ColorScheme cs, AppColors ac, Color dividerColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _selected.clear());
                widget.onConfirm(const []);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.mutedForeground,
                side: BorderSide(color: dividerColor),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(
                  widget.availableTags.where(_selected.contains).toList(),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
