// ============================================================================
// SharedPreferences 全局 key 常量 (v25 · 跨 screen 共享)
// ============================================================================
//
// 设计原因(code-reviewer 反馈):跨 screen 的 pref key 不应该定义在某个
// screen 文件里被另一个 screen import · 应该有一个独立常量层。
// onboarding_screen + splash_screen 都引用 kOnboardingSeenKey,
// 把它放这里就不会因 screen 重构而 import 静默失效。

class PrefsKeys {
  PrefsKeys._();

  /// 用户是否已看过 v1 引导三屏 · 看过后 splash 直接 → /login
  static const String onboardingSeenV1 = 'onboarding_seen_v1';

  /// 主题偏好 · 'light' / 'dark' / 'system'
  static const String themeMode = 'theme_mode';

  /// 用户选择的 locale · null (未设置) = 跟随系统 · 'en' / 'zh' = 手动
  static const String localeCode = 'locale_code';
}
