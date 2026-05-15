import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_size_provider.g.dart';

const List<double> fontSizeScales = [0.85, 0.93, 1.0, 1.1, 1.22];
const List<String> fontSizeLabels = [
  'Compact',
  'Small',
  'Normal',
  'Large',
  'XL',
];
const int fontSizeDefaultStep = 2;

@Riverpod(keepAlive: true)
class FontSizeNotifier extends _$FontSizeNotifier {
  static const _boxName = 'settings';
  static const _key = 'font_size';

  @override
  int build() {
    try {
      final raw = Hive.box(_boxName).get(_key);
      if (raw is int) return raw.clamp(0, fontSizeScales.length - 1);
      // Migrate old string value from the previous 2-option toggle.
      if (raw == 'large') return 3;
      return fontSizeDefaultStep;
    } catch (_) {
      return fontSizeDefaultStep;
    }
  }

  Future<void> increment() async {
    final next = (state + 1).clamp(0, fontSizeScales.length - 1);
    if (next == state) return;
    state = next;
    await Hive.box(_boxName).put(_key, next);
  }

  Future<void> decrement() async {
    final next = (state - 1).clamp(0, fontSizeScales.length - 1);
    if (next == state) return;
    state = next;
    await Hive.box(_boxName).put(_key, next);
  }
}
