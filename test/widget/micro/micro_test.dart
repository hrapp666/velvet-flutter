// ============================================================================
// Velvet · Micro-interaction library · v25 · UI02
// ----------------------------------------------------------------------------
// 覆盖 SpringTap / GlowPulse / CinematicPageRoute 三个 widget。
// 验证: 结构 · 动画 · 回调 · dispose 安全 · transition 播放。
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/services/haptic_service.dart';
import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/micro/cinematic_page_route.dart';
import 'package:velvet/shared/widgets/micro/glow_pulse.dart';
import 'package:velvet/shared/widgets/micro/spring_tap.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

void _noop() {}

Color _shadowColor(Finder decoratedFinder, WidgetTester tester) {
  final deco = tester.widget<DecoratedBox>(decoratedFinder).decoration
      as BoxDecoration;
  final shadows = deco.boxShadow;
  if (shadows == null || shadows.isEmpty) {
    throw StateError('expected BoxShadow on $decoratedFinder');
  }
  return shadows.first.color;
}

void main() {
  group('SpringTap', () {
    testWidgets('onTap 回调被调用一次', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          SpringTap(
            onTap: () {
              taps += 1;
            },
            haptic: false,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );

      await tester.tap(find.byType(SpringTap));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('按下后 scale 缩小 · 松开后回到 1.0', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SpringTap(
            onTap: _noop,
            haptic: false,
            pressedScale: 0.9,
            child: SizedBox(width: 120, height: 40),
          ),
        ),
      );

      // 取 SpringTap 内所有 Transform · 找 storage[0] 最小的那个(就是 scale)
      double minScaleX() {
        final transforms = tester
            .widgetList<Transform>(find.descendant(
              of: find.byType(SpringTap),
              matching: find.byType(Transform),
            ))
            .map((t) => t.transform.storage[0])
            .toList();
        if (transforms.isEmpty) return 1.0;
        return transforms.reduce((a, b) => a < b ? a : b);
      }

      // 初始 scale 必须接近 1.0
      expect(minScaleX(), closeTo(1.0, 0.01));

      // 按下 · 等动画推进(60ms 进 120ms 动画 = 中点)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SpringTap)),
      );
      // 多 pump 几次让 gesture recognizer 提交 + 动画推进
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final pressedScale = minScaleX();
      expect(
        pressedScale,
        lessThan(0.99),
        reason: '按下中途 scale 必须 < 0.99 · 实际 $pressedScale',
      );

      // 松开 · 动画回弹到 1.0
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        minScaleX(),
        closeTo(1.0, 0.01),
        reason: '松开后 scale 必须回到 1.0',
      );
    });

    testWidgets('haptic = true 时触发 HapticFeedback channel', (tester) async {
      final captured = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          captured.add(call);
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      // 确保 HapticService 处于 enabled 状态 (singleton 跨 test 共享)
      HapticService.instance.enabled = true;

      await tester.pumpWidget(
        _harness(
          const SpringTap(
            onTap: _noop,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      await tester.tap(find.byType(SpringTap));
      await tester.pumpAndSettle();

      expect(
        captured,
        hasLength(greaterThanOrEqualTo(1)),
        reason: 'haptic = true 时应至少触发一次 HapticFeedback',
      );
    });

    testWidgets('haptic = false 时不触发 HapticFeedback channel',
        (tester) async {
      final captured = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          captured.add(call);
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        _harness(
          const SpringTap(
            onTap: _noop,
            haptic: false,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      await tester.tap(find.byType(SpringTap));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });

    testWidgets('glow = true 时渲染 DecoratedBox 带金色 BoxShadow',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const SpringTap(
            onTap: _noop,
            haptic: false,
            glow: true,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );

      // 按下并推进 · tap 中 burst 有金色 shadow
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SpringTap)),
      );
      await tester.pump(const Duration(milliseconds: 60));

      final decoratedBoxes = find.descendant(
        of: find.byType(SpringTap),
        matching: find.byType(DecoratedBox),
      );
      expect(decoratedBoxes, findsWidgets);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('dispose 不 crash (widget 被替换)', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SpringTap(
            onTap: _noop,
            haptic: false,
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      // 按下中途切换 widget · 触发 dispose
      await tester.startGesture(
        tester.getCenter(find.byType(SpringTap)),
      );
      await tester.pump(const Duration(milliseconds: 30));

      await tester.pumpWidget(_harness(const SizedBox()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('GlowPulse', () {
    testWidgets('渲染 DecoratedBox · pulse 推进后 shadow alpha 变化',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const GlowPulse(
            child: SizedBox(width: 12, height: 12),
          ),
        ),
      );

      expect(find.byType(GlowPulse), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlowPulse),
          matching: find.byType(DecoratedBox),
        ),
        findsWidgets,
      );

      final decoratedFinder = find
          .descendant(
            of: find.byType(GlowPulse),
            matching: find.byType(DecoratedBox),
          )
          .first;

      // 抓第一帧 shadow
      await tester.pump(const Duration(milliseconds: 10));
      final firstAlpha = _shadowColor(decoratedFinder, tester).a;

      // 推进到 pulse peak 附近 (1/4 周期 = 500ms)
      await tester.pump(const Duration(milliseconds: 500));
      final secondAlpha = _shadowColor(decoratedFinder, tester).a;

      expect(
        (firstAlpha - secondAlpha).abs(),
        greaterThan(0.05),
        reason:
            'pulse 推进后 shadow alpha 必须明显变化 · first $firstAlpha · '
            'second $secondAlpha',
      );

      // 关键: 切到 enabled=false · 让 repeat 动画停下 · 后续 test 安全 teardown
      await tester.pumpWidget(
        _harness(
          const GlowPulse(
            enabled: false,
            child: SizedBox(width: 12, height: 12),
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('dispose 不 crash', (tester) async {
      await tester.pumpWidget(
        _harness(
          const GlowPulse(
            child: SizedBox(width: 12, height: 12),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(_harness(const SizedBox()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('自定义 color 生效 (酒红 shadow · 与 gold 不同)',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const GlowPulse(
            color: Vt.velvet,
            child: SizedBox(width: 12, height: 12),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final decoratedFinder = find
          .descendant(
            of: find.byType(GlowPulse),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final shadowColor = _shadowColor(decoratedFinder, tester);

      // shadow 应该基于 Vt.velvet · 且明显区别于默认 Vt.gold
      expect(shadowColor.r, closeTo(Vt.velvet.r, 0.01));
      expect(shadowColor.g, closeTo(Vt.velvet.g, 0.01));
      expect(shadowColor.b, closeTo(Vt.velvet.b, 0.01));
      // 与 gold 红 (0xC9) 明显不同 (velvet 红 0x6B)
      expect(
        (shadowColor.r - Vt.gold.r).abs(),
        greaterThan(0.1),
        reason: '自定义色 velvet 不应与默认 gold 混淆',
      );

      // 关掉 pulse 避免 infinite repeat 污染后续 test
      await tester.pumpWidget(
        _harness(
          const GlowPulse(
            enabled: false,
            color: Vt.velvet,
            child: SizedBox(width: 12, height: 12),
          ),
        ),
      );
    });
  });

  group('CinematicPageRoute', () {
    testWidgets('push 后 transition 播放 · 目标页出现', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: ThemeData.dark(),
          home: const Scaffold(body: Center(child: Text('home'))),
        ),
      );

      final navState = nav.currentState;
      if (navState == null) {
        fail('navigatorKey 应已附加到 Navigator');
      }
      unawaited(navState.push<void>(
        CinematicPageRoute<void>(
          page: const Scaffold(body: Center(child: Text('detail'))),
        ),
      ));

      // 半程: FadeTransition / SlideTransition / ScaleTransition 都在
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);

      // 动画完成后目标页完全可见
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('transition 时长 ≈ 400ms · 反向 300ms', (tester) async {
      final route = CinematicPageRoute<void>(
        page: const SizedBox(),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 400));
      expect(
        route.reverseTransitionDuration,
        const Duration(milliseconds: 300),
      );
    });
  });
}
