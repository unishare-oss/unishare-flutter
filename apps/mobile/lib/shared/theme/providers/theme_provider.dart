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
    final box = Hive.box(_boxName);
    return box.get(_key, defaultValue: 'unishare') as String;
  }

  Future<void> setTheme(String id) async {
    if (!AppThemes.all.containsKey(id)) return;
    state = id;
    await Hive.box(_boxName).put(_key, id);
  }
}

@riverpod
ThemeData activeTheme(Ref ref) {
  final id = ref.watch(themeProvider);
  return AppTheme.fromId(id);
}
