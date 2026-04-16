// ============================================================================
// Velvet · Dark Theme (v25 · C2)
// ----------------------------------------------------------------------------
// 从 main.dart 抽离 · 保持原有 editorial night mood 不变
// 品牌锚点：天鹅绒酒红 + 黄金箔 + 黑天鹅绒纹理
// ============================================================================

import 'package:flutter/material.dart';

import 'design_tokens.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Vt.bgPrimary,
    // UI18 · 强制禁用 Material 3 默认 ZoomPageTransitionsBuilder
    // Material 3 默认 Android push = scale 0.80→1.0 + fade · 这就是主人说的
    // "页面开始是小的然后一下又正常了". 全平台改成 FadeUpwards (纯 fade + 轻微
    // 上推), 和 CinematicPage 风格一致 · 无 scale = 无抖动.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.dark(
      primary: Vt.gold,
      secondary: Vt.goldLight,
      tertiary: Vt.velvet,
      surface: Vt.bgVoid,
      surfaceContainerLow: Vt.bgElevated,
      surfaceContainerHigh: Vt.bgHighest,
      onPrimary: Vt.bgVoid,
      onSecondary: Vt.bgVoid,
      onSurface: Vt.textPrimary,
      error: Vt.warn,
    ),
    textTheme: TextTheme(
      displayLarge: Vt.displayHero,
      displayMedium: Vt.displayLg,
      displaySmall: Vt.displayMd,
      headlineLarge: Vt.headingLg,
      headlineMedium: Vt.headingMd,
      headlineSmall: Vt.headingSm,
      bodyLarge: Vt.bodyLg,
      bodyMedium: Vt.bodyMd,
      bodySmall: Vt.bodySm,
      labelLarge: Vt.button,
      labelMedium: Vt.label,
      labelSmall: Vt.caption,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: Vt.borderHairline,
  );
}
