// ============================================================================
// Velvet · main.dart (v25 · C2 主题 + I1 i18n)
// Touch what was touched.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/dark_theme.dart';
import 'shared/theme/light_theme.dart';
import 'shared/theme/locale_provider.dart';
import 'shared/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 锁竖屏 · Velvet 是约会类 app · 横屏破版
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VelvetApp(),
    ),
  );
}

class VelvetApp extends ConsumerWidget {
  const VelvetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Velvet',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: mode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      // ── i18n (v25 · I1) ──
      // locale == null → 跟随系统 · 非 null → 手动锁定
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Dynamic Type: 响应系统字号 · 但 clamp 到 [0.9, 1.3] 避免极端
      // 缩放破版 editorial 排版 · 满足 Apple 辅助功能要求
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
