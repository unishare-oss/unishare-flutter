import 'package:flutter/material.dart';

const _kOrange = Color(0xFFD97706);
const _kTextMuted = Color(0xFF8A837E);
const _kForeground = Color(0xFF1C1917);

class FeedEmptyStateWidget extends StatelessWidget {
  const FeedEmptyStateWidget({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_off, size: 48, color: _kTextMuted),
            const SizedBox(height: 16),
            const Text(
              'No posts match your filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kForeground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try selecting different tags or clear the filter to see all posts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kTextMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kOrange,
                side: const BorderSide(color: _kOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear filter'),
            ),
          ],
        ),
      ),
    );
  }
}
