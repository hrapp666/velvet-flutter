// ============================================================================
// Velvet · Light Theme (v25 · C2)
// ----------------------------------------------------------------------------
// 灵感：Notion warm minimalism
// 暖奶油底色对应 Velvet 金色调性 — 冷白会与 gold 打架
// 所有色值都来自 Vt.bgLight* / Vt.textLight* token，不硬编码 Color(0xFF...)
// gold / velvet accent 颜色 dark/light 共用（品牌锚点不变）
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Vt.bgLightPrimary,
    // UI18 · 同 dark_theme · 禁用 Material 3 默认 ZoomPageTransitionsBuilder
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
    colorScheme: const ColorScheme.light(
      primary: Vt.gold,
      secondary: Vt.goldLight,
      tertiary: Vt.velvet,
      surface: Vt.bgLightVoid,
      surfaceContainerLow: Vt.bgLightElevated,
      surfaceContainerHigh: Vt.bgLightHighest,
      onPrimary: Vt.bgLightVoid,
      onSecondary: Vt.bgLightVoid,
      onSurface: Vt.textLightPrimary,
      error: Vt.warn,
    ),
    textTheme: TextTheme(
      displayLarge: _lightDisplay(Vt.t4xl, FontWeight.w500, 8.0, 0.96),
      displayMedium: _lightDisplay(Vt.t3xl, FontWeight.w500, 6.0, 0.98),
      displaySmall: _lightDisplay(Vt.t2xl, FontWeight.w400, 3.0, 1.02),
      headlineLarge: _lightHeading(Vt.txl, FontWeight.w400, 0.5, 1.15),
      headlineMedium: _lightHeading(Vt.tlg, FontWeight.w400, 0.4, 1.2),
      headlineSmall: _lightHeading(Vt.tmd, FontWeight.w500, 0.3, 1.3),
      bodyLarge: _lightBody(Vt.tmd, FontWeight.w300, 0.2, 1.6),
      bodyMedium: _lightBody(Vt.tsm, FontWeight.w300, 0.2, 1.55,
          color: Vt.textLightSecondary),
      bodySmall: _lightBody(Vt.txs, FontWeight.w300, 0.3, 1.5,
          color: Vt.textLightSecondary),
      labelLarge: GoogleFonts.cormorantGaramond(
        fontSize: Vt.tmd,
        fontWeight: FontWeight.w500,
        letterSpacing: 4.0,
        height: 1.0,
        color: Vt.gold,
      ),
      labelMedium: GoogleFonts.cormorantGaramond(
        fontSize: Vt.txs,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.5,
        height: 1.4,
        color: Vt.textLightTertiary,
      ),
      labelSmall: GoogleFonts.cormorantGaramond(
        fontSize: Vt.t2xs,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 2.5,
        height: 1.2,
        color: Vt.gold,
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: Vt.borderLightHairline,
  );
}

TextStyle _lightDisplay(
  double size,
  FontWeight weight,
  double spacing,
  double height,
) {
  return GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: Vt.textLightPrimary,
  );
}

TextStyle _lightHeading(
  double size,
  FontWeight weight,
  double spacing,
  double height,
) {
  return GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: Vt.textLightPrimary,
  );
}

TextStyle _lightBody(
  double size,
  FontWeight weight,
  double spacing,
  double height, {
  Color color = Vt.textLightPrimary,
}) {
  return GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: color,
  );
}
