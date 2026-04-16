// ============================================================================
// Velvet · LocaleProvider widget tests (v25 · I1)
// ----------------------------------------------------------------------------
// 验证:
//   1. prefs 为空 → state null (跟随系统)
//   2. setLocale(Locale('en')) → state 'en' + prefs 持久化 'en'
//   3. setLocale(null) → state null + prefs 移除 key
//   4. prefs 已有 'zh' → 初始化 Locale('zh')
//   5. setLocale(Locale('fr')) 被拒绝 · state 不变
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/constants/prefs_keys.dart';
import 'package:velvet/shared/theme/locale_provider.dart';
import 'package:velvet/shared/theme/theme_provider.dart';

/// 辅助: 构造已注入 prefs 的 ProviderContainer
ProviderContainer _makeContainer(SharedPreferences prefs) {
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('LocaleNotifier', () {
    // -----------------------------------------------------------------------
    // Test 1: prefs 为空 → state null (跟随系统)
    // -----------------------------------------------------------------------
    test('default state is null when prefs is empty (follow system)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      expect(container.read(localeProvider), isNull);
    });

    // -----------------------------------------------------------------------
    // Test 2: setLocale(Locale('en')) → state + 持久化
    // -----------------------------------------------------------------------
    test('setLocale(en) updates state and persists to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('en'));

      expect(container.read(localeProvider), const Locale('en'));
      expect(prefs.getString(PrefsKeys.localeCode), 'en');
    });

    // -----------------------------------------------------------------------
    // Test 3: setLocale(null) → state null + prefs remove
    // -----------------------------------------------------------------------
    test('setLocale(null) clears state and removes prefs key', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.localeCode: 'zh',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      // 确认初始是 zh
      expect(container.read(localeProvider), const Locale('zh'));

      await container.read(localeProvider.notifier).setLocale(null);

      expect(container.read(localeProvider), isNull);
      expect(prefs.containsKey(PrefsKeys.localeCode), isFalse);
    });

    // -----------------------------------------------------------------------
    // Test 4: prefs 已有 'zh' → 初始化 Locale('zh')
    // -----------------------------------------------------------------------
    test('reads Locale("zh") from existing prefs value "zh"', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.localeCode: 'zh',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('zh'));
    });

    // -----------------------------------------------------------------------
    // Test 5: 不支持的 locale 被拒绝 · state 不变 · prefs 不写
    // -----------------------------------------------------------------------
    test('setLocale with unsupported language is rejected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      // 先设 en 作为已知 state
      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('en'));
      expect(container.read(localeProvider), const Locale('en'));

      // 尝试设 fr · 应被拒绝 · state 保持 en · prefs 仍为 'en'
      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('fr'));

      expect(container.read(localeProvider), const Locale('en'));
      expect(prefs.getString(PrefsKeys.localeCode), 'en');
    });

    // -----------------------------------------------------------------------
    // Test 6: prefs 中存入未知 languageCode → 初始化为 null (安全兜底)
    // -----------------------------------------------------------------------
    test('reads null when existing prefs value is unsupported', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.localeCode: 'fr',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = _makeContainer(prefs);
      addTearDown(container.dispose);

      expect(container.read(localeProvider), isNull);
    });
  });
}
