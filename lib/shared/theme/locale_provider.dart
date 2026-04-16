// ============================================================================
// Velvet · LocaleProvider (v25 · I1)
// ----------------------------------------------------------------------------
// 三档 locale：
//   - null          → 跟随系统（默认）
//   - Locale('en')  → 手动英文
//   - Locale('zh')  → 手动中文
//
// 为什么同步读 SharedPreferences 而不是 async _load()？
//   main.dart 已经 await SharedPreferences.getInstance() 然后通过
//   sharedPreferencesProvider 注入,所以这里直接在构造器里同步取值,避免首帧
//   用 null 再异步切成已保存 locale 造成的 rebuild 闪烁。theme_provider 已经
//   是同一个模式（StateNotifier + 构造器 prefs 读取）,保持一致。
//
// 持久化字符串：
//   'en' / 'zh'           → 手动档
//   key 不存在（prefs 里没这个 key） → null · 跟随系统
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/constants/prefs_keys.dart';
import 'package:velvet/shared/theme/theme_provider.dart';

/// 支持的手动档 language code · 必须与 AppLocalizations.supportedLocales 对齐
const Set<String> _supportedLanguageCodes = <String>{'en', 'zh'};

/// 从字符串解析 Locale · null / 未知 / 不支持 → null(跟随系统)
Locale? _parseLocale(String? raw) {
  if (raw == null) return null;
  if (!_supportedLanguageCodes.contains(raw)) return null;
  return Locale(raw);
}

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs)
      : super(_parseLocale(_prefs.getString(PrefsKeys.localeCode)));

  final SharedPreferences _prefs;

  /// 切换 locale · null = 跟随系统,否则持久化 languageCode。
  /// 非支持的 locale 被拒绝(state 保持当前值)。
  Future<void> setLocale(Locale? locale) async {
    if (locale != null &&
        !_supportedLanguageCodes.contains(locale.languageCode)) {
      return;
    }
    state = locale;
    if (locale == null) {
      await _prefs.remove(PrefsKeys.localeCode);
    } else {
      await _prefs.setString(PrefsKeys.localeCode, locale.languageCode);
    }
  }
}

/// Locale state 提供器 · main.dart 通过 ref.watch 把值喂给 MaterialApp.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(ref.watch(sharedPreferencesProvider)),
);
