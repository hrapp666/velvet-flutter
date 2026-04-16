// ============================================================================
// SplashScreen · VelvetGlyph 集成测试 (v25 · UI04)
// ----------------------------------------------------------------------------
// 验证:
//  1. SplashScreen 内存在 GyroscopeTilt + VelvetGlyph3D + VelvetGlyph
//  2. _glyphShimmer dispose 顺序正确 · navigation away 不 crash
//  3. 2.4s timer 期间 shimmer AnimatedBuilder 正常 tick 不 throw
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/features/auth/presentation/screens/splash_screen.dart';
import 'package:velvet/shared/widgets/brand/velvet_glyph.dart';
import 'package:velvet/shared/widgets/motion/gyroscope_tilt.dart';

Widget _harness() {
  // SplashScreen 用 context.go('/feed' | '/onboarding' | '/login')
  // 提供最小 GoRouter stub + Riverpod ProviderScope
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('FEED_PAGE'))),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('ONBOARDING_PAGE'))),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('LOGIN_PAGE'))),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      theme: ThemeData.dark(),
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SplashScreen · VelvetGlyph 集成', () {
    testWidgets('SplashScreen 内存在 GyroscopeTilt + VelvetGlyph3D + VelvetGlyph',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GyroscopeTilt), findsOneWidget);
      expect(find.byType(VelvetGlyph3D), findsOneWidget);
      expect(find.byType(VelvetGlyph), findsOneWidget);
      // 等 2400ms timer + 导航 · 防止 pending timer
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('VelvetGlyph size = 140', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 300));

      final box = tester.getSize(find.byType(VelvetGlyph));
      expect(box.width, 140);
      expect(box.height, 140);

      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('shimmer AnimatedBuilder 在多帧内不 throw', (tester) async {
      await tester.pumpWidget(_harness());
      // 模拟几帧 shimmer tick · 确认没有 exception
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(VelvetGlyph), findsOneWidget);
      // 等 timer 到
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('navigation away 前 dispose 不 crash · _glyphShimmer 顺序正确',
        (tester) async {
      await tester.pumpWidget(_harness());
      // 等 2.4s timer 过 · 避免 pending timer panic
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump(const Duration(milliseconds: 200));

      // 主动替换整棵树 → 强制 SplashScreen 走 dispose
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: Text('REPLACED'))),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('REPLACED'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
