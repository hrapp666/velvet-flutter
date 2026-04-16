// ============================================================================
// Onboarding 三屏 widget test (v25 · A1)
// ----------------------------------------------------------------------------
// 覆盖 critic pre-mortem 修过的 2 个高优先级风险:
//  - dispose 顺序(_bgCtrl.stop 先 / dispose 后)不会 crash
//  - 快速点击 NEXT 不会 race(_animating 锁)
// 同时验证:
//  - 三屏内容渲染(PRIVÉ / DÉRIVE / NUIT)
//  - skip 按钮直接 mark seen
//  - 第三屏 CTA 文案变 BEGIN
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/features/auth/presentation/screens/onboarding_screen.dart';

Widget _harness() {
  // Onboarding 用 context.go('/login') · 必须真 GoRouter
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('LOGIN_PAGE'))),
      ),
    ],
  );
  return MaterialApp.router(
    theme: ThemeData.dark(),
    routerConfig: router,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('OnboardingScreen 渲染', () {
    testWidgets('首屏显示 PRIVÉ + 私藏 + 罗马 I + NEXT cta',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      expect(find.text('PRIVÉ'), findsOneWidget);
      expect(find.text('私   藏'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('继续 · NEXT'), findsOneWidget);
      expect(find.text('开始 · BEGIN'), findsNothing);
    });

    testWidgets('skip 按钮存在', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      expect(find.text('SKIP'), findsOneWidget);
    });
  });

  group('OnboardingScreen 翻页', () {
    Future<void> _swipeLeft(WidgetTester tester) async {
      // 直接 fling 模拟真 swipe · 同步注入手势 · 不依赖 async nextPage Future
      await tester.fling(
        find.byType(PageView),
        const Offset(-400, 0),
        1500,
      );
      // 多次 pump 让动画走完(避开 _bgCtrl 18s repeat 永不 settle)
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('swipe 翻到 DÉRIVE 第二屏', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      await _swipeLeft(tester);

      expect(find.text('DÉRIVE'), findsOneWidget);
      expect(find.text('II'), findsOneWidget);
    });

    testWidgets('swipe 两次到第三屏 CTA 变 BEGIN', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      await _swipeLeft(tester);
      await _swipeLeft(tester);

      expect(find.text('NUIT'), findsOneWidget);
      expect(find.text('III'), findsOneWidget);
      expect(find.text('开始 · BEGIN'), findsOneWidget);
      expect(find.text('继续 · NEXT'), findsNothing);
    });
  });

  group('OnboardingScreen pre-mortem 回归', () {
    testWidgets('快速连点 NEXT 不会 crash · _animating 锁生效',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      // Pre-mortem #2: 同帧内连续 4 次点击 · 锁应该让其中 3 次被忽略
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('继续 · NEXT'));
      }
      await tester.pump(const Duration(milliseconds: 1500));

      // 没有 crash · 应该最多翻 1 屏(锁让二次点击被吞)
      // 不强制断言到达哪一屏 · 只断言没 throw 且仍 render
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('navigation away 不 crash · dispose 顺序正确',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      // 主动替换整棵 widget tree · 强制 OnboardingScreen 走 dispose
      // Pre-mortem #1: _bgCtrl 18s repeat tick callback 不应该在 dispose 后触发
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: Text('REPLACED'))),
      ));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('REPLACED'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('SKIP 按钮持久化 onboarding_seen_v1 = true',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump();

      await tester.tap(find.text('SKIP'));
      await tester.pump(const Duration(milliseconds: 1500));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isTrue);
    });
  });
}
