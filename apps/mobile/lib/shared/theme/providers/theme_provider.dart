import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_theme.dart';
import '../themes.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _boxName = 'settings';
  static const _key = 'selected_theme';

  @override
  String build() {
    try {
      final box = Hive.box(_boxName);
      final id = box.get(_key, defaultValue: 'unishare') as String;
      return AppThemes.all.containsKey(id) ? id : 'unishare';
    } catch (_) {
      return 'unishare';
    }
  }

  Future<void> setTheme(String id) async {
    if (!AppThemes.all.containsKey(id)) return;
    state = id;
    await Hive.box(_boxName).put(_key, id);
  }
}

@Riverpod(keepAlive: true)
ThemeData activeTheme(Ref ref) {
  final id = ref.watch(themeProvider);
  return AppTheme.fromId(id);
}
