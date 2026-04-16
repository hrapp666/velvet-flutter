// ============================================================================
// Velvet · ThemeProvider (v25 · C2)
// ----------------------------------------------------------------------------
// 三档切换：dark / light / system
// 默认 dark — Velvet 品牌身份是 editorial night mood
// 用 StateNotifierProvider 而非 StateProvider：需要在 set 时同时 persist
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/prefs_keys.dart';

/// 从字符串解析 ThemeMode，null / 未知 → dark（Velvet 品牌默认）
ThemeMode _parseThemeMode(String? raw) {
  return switch (raw) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
}

/// ThemeMode → 持久化字符串
String _serializeThemeMode(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
    ThemeMode.dark => 'dark',
  };
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._prefs)
      : super(_parseThemeMode(_prefs.getString(PrefsKeys.themeMode)));

  final SharedPreferences _prefs;

  /// 切换主题并立即持久化
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(PrefsKeys.themeMode, _serializeThemeMode(mode));
  }
}

/// SharedPreferences 异步提供器（由外部注入，方便测试 override）
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden before use. '
    'Call ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])',
  );
});

/// 主题状态提供器
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref.watch(sharedPreferencesProvider)),
);
