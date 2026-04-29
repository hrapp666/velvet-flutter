// ============================================================================
// Velvet · main.dart (v25 · C2 主题 + I1 i18n)
// Touch what was touched.
// ============================================================================
// 2026-04-28: WebView 套壳路线撤回（Google Play 政策禁止纯套壳）→ 回到 Flutter
// 原生 GoRouter / Riverpod 入口，逐页 1:1 翻译 H5 truth source
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/dark_theme.dart';
import 'shared/theme/light_theme.dart';
import 'shared/theme/locale_provider.dart';
import 'shared/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 字体只走本地 bundle，禁止 fonts.gstatic.com CDN 抓取。
  // 中国网络下 CDN 不可达 → 静默 fallback 系统 serif → 全屏字体破相。
  GoogleFonts.config.allowRuntimeFetching = false;

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
    // ignore: unused_local_variable
    final mode = ref.watch(themeProvider); // 仍订阅以便未来恢复
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Velvet',
      debugShowCheckedModeBanner: false,
      // v25: Velvet 视觉系统专为黑色 void 设计 · 明亮版未完整适配 → 强制 dark
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
