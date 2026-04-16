// ============================================================================
// Velvet · ThemeProvider widget tests (v25 · C2)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/constants/prefs_keys.dart';
import 'package:velvet/shared/theme/theme_provider.dart';

/// 辅助：构造已注入 prefs 的 ProviderContainer
ProviderContainer _makeContainer(SharedPreferences prefs) {
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('ThemeNotifier', () {
    // -----------------------------------------------------------------------
    // Test 1: prefs 为空时默认 ThemeMode.dark
    // -----------------------------------------------------------------------
    test('default is dark when prefs is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    // -----------------------------------------------------------------------
    // Test 2: setMode(light) 后 state 更新 + prefs 持久化
    // -----------------------------------------------------------------------
    test('setMode(light) updates state and persists to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setMode(ThemeMode.light);

      expect(container.read(themeProvider), ThemeMode.light);
      expect(prefs.getString(PrefsKeys.themeMode), 'light');
    });

    // -----------------------------------------------------------------------
    // Test 3: setMode(system) 持久化字符串是 'system'
    // -----------------------------------------------------------------------
    test('setMode(system) persists string "system"', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setMode(ThemeMode.system);

      expect(prefs.getString(PrefsKeys.themeMode), 'system');
    });

    // -----------------------------------------------------------------------
    // Test 4: prefs 中已有 'light' → 初始化读回 ThemeMode.light
    // -----------------------------------------------------------------------
    test('reads ThemeMode.light from existing prefs value "light"', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.themeMode: 'light',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.light);
    });
  });
}
