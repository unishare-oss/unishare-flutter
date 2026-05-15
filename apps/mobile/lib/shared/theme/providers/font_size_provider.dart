import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_size_provider.g.dart';

enum AppFontSize { normal, large }

@Riverpod(keepAlive: true)
class FontSizeNotifier extends _$FontSizeNotifier {
  static const _boxName = 'settings';
  static const _key = 'font_size';

  @override
  AppFontSize build() {
    try {
      final val =
          Hive.box(_boxName).get(_key, defaultValue: 'normal') as String;
      return val == 'large' ? AppFontSize.large : AppFontSize.normal;
    } catch (_) {
      return AppFontSize.normal;
    }
  }

  Future<void> set(AppFontSize size) async {
    state = size;
    await Hive.box(
      _boxName,
    ).put(_key, size == AppFontSize.large ? 'large' : 'normal');
  }
}
