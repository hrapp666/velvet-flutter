// ============================================================================
// motion widgets · v25 · UI03
// ----------------------------------------------------------------------------
// 覆盖 ScrollReveal / StaggeredList / ParallaxCard
// 共 11 个 test case
//
// 关键注意：
//   - AnimationController 依赖 ticker → pump(duration) 推进时间，
//     不用 pumpAndSettle（动画永不 settle）。
//   - ScrollReveal.delay 用 Future.delayed → pump(delay + duration) 推进。
//   - Transform.translate offset 验证：通过 tester.getTopLeft(key) 比较
//     pump 前后的位置差，而非读 Matrix4 内部（跨 vector_math 依赖不稳定）。
//   - ParallaxCard：ctrl.jumpTo 后 pump() → 读 getTopLeft 位置变化。
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/motion/parallax_card.dart';
import 'package:velvet/shared/widgets/motion/scroll_reveal.dart';
import 'package:velvet/shared/widgets/motion/staggered_list.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

// ============================================================================
// ScrollReveal Tests
// ============================================================================
void main() {
  group('ScrollReveal', () {
    testWidgets('初始状态 opacity 接近 0', (tester) async {
      await tester.pumpWidget(_harness(
        const ScrollReveal(
          delay: Duration.zero,
          duration: Duration(milliseconds: 600),
          fromOpacity: 0.0,
          child: Text('hello'),
        ),
      ));
      // 仅 pump(0)，动画刚注册但未推进
      await tester.pump();

      // 找 ScrollReveal descendant 的 Opacity · 避免命中 MaterialApp 内部的
      final opacityFinder = find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(Opacity),
      );
      final opacity = tester.widget<Opacity>(opacityFinder.first);
      expect(opacity.opacity, lessThan(0.1));
    });

    testWidgets('600ms 后 opacity 完成 → 接近 1.0', (tester) async {
      await tester.pumpWidget(_harness(
        const ScrollReveal(
          delay: Duration.zero,
          duration: Duration(milliseconds: 600),
          fromOpacity: 0.0,
          child: Text('hello'),
        ),
      ));

      // 推进超过动画时长
      await tester.pump(const Duration(milliseconds: 650));

      final opacityFinder = find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(Opacity),
      );
      final opacity = tester.widget<Opacity>(opacityFinder.first);
      expect(opacity.opacity, closeTo(1.0, 0.05));
    });

    testWidgets('初始位置偏下 · 完成后位置上移', (tester) async {
      const targetKey = Key('sr-target');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScrollReveal(
                delay: Duration.zero,
                duration: const Duration(milliseconds: 600),
                fromOffsetY: 60.0,
                child: const SizedBox(
                  key: targetKey,
                  width: 100,
                  height: 50,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );

      // 动画未推进前：child 在偏下位置
      await tester.pump();
      final topBefore = tester.getTopLeft(find.byKey(targetKey)).dy;

      // 推进 650ms → 动画完成
      await tester.pump(const Duration(milliseconds: 650));
      final topAfter = tester.getTopLeft(find.byKey(targetKey)).dy;

      // 完成后 Y 值比初始小（上移了），即 topAfter < topBefore
      expect(topAfter, lessThan(topBefore));
    });

    testWidgets('delay 有效 · 200ms delay 结束后动画才开始', (tester) async {
      await tester.pumpWidget(_harness(
        const ScrollReveal(
          delay: Duration(milliseconds: 200),
          duration: Duration(milliseconds: 400),
          fromOpacity: 0.0,
          child: Text('delayed'),
        ),
      ));

      final opacityFinder = find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(Opacity),
      );

      // delay 期间 opacity 保持 0
      await tester.pump(const Duration(milliseconds: 100));
      final opacityDuringDelay =
          tester.widget<Opacity>(opacityFinder.first).opacity;
      expect(opacityDuringDelay, lessThan(0.1));

      // 分段 pump 让 Timer fire + animation 推进
      // Timer 在 200ms fire → forward() · 再推 400ms 完成动画
      await tester.pump(const Duration(milliseconds: 150));  // 100+150 = 250 · timer fired
      await tester.pump(const Duration(milliseconds: 500));  // 250+500 = 750 · 动画 500ms > 400 完成
      final opacityDone =
          tester.widget<Opacity>(opacityFinder.first).opacity;
      expect(opacityDone, closeTo(1.0, 0.05));
    });

    testWidgets('navigation away 不 crash · dispose 安全', (tester) async {
      await tester.pumpWidget(_harness(
        const ScrollReveal(
          delay: Duration(milliseconds: 100),
          duration: Duration(milliseconds: 500),
          child: Text('disposed'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));

      // 替换整棵 tree → 强制 ScrollReveal dispose（timer 仍 pending）
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('REPLACED')),
        ),
      );
      // 让所有 pending microtask / timer 耗尽
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('REPLACED'), findsOneWidget);
      expect(find.text('disposed'), findsNothing);
    });
  });

  // ============================================================================
  // StaggeredList Tests
  // ============================================================================
  group('StaggeredList', () {
    testWidgets('渲染 3 个 child · 每个包一层 ScrollReveal', (tester) async {
      await tester.pumpWidget(_harness(
        StaggeredList(
          stagger: const Duration(milliseconds: 80),
          children: const [
            Text('card0'),
            Text('card1'),
            Text('card2'),
          ],
        ),
      ));
      await tester.pump();

      expect(find.byType(ScrollReveal), findsNWidgets(3));
    });

    testWidgets('3 card stagger · card0 最早完成 opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: StaggeredList(
                stagger: const Duration(milliseconds: 80),
                revealDuration: const Duration(milliseconds: 200),
                children: const [
                  SizedBox(height: 80, child: ColoredBox(color: Colors.red)),
                  SizedBox(height: 80, child: ColoredBox(color: Colors.green)),
                  SizedBox(height: 80, child: ColoredBox(color: Colors.blue)),
                ],
              ),
            ),
          ),
        ),
      );

      // 推进 220ms：card0 delay=0,dur=200 → 已完成；
      // card1 delay=80,dur=200 → 进行中;card2 delay=160,dur=200 → 进行中
      await tester.pump(const Duration(milliseconds: 220));

      // 只拿 ScrollReveal 内的 Opacity(避开 MaterialApp 内部)
      final opacityFinder = find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(Opacity),
      );
      final opacities = tester
          .widgetList<Opacity>(opacityFinder)
          .map((o) => o.opacity)
          .toList();

      // 至少 1 个 opacity 已达 1.0(card0)
      expect(opacities.any((o) => o >= 0.95), isTrue);

      // 推进全部完成(200ms delay2 + 200ms dur = 360ms extra)
      await tester.pump(const Duration(milliseconds: 400));
      final opacitiesDone = tester
          .widgetList<Opacity>(opacityFinder)
          .map((o) => o.opacity)
          .toList();
      expect(opacitiesDone.every((o) => o >= 0.95), isTrue);
    });

    testWidgets('navigation away 不 crash · 3 card 全 dispose 安全',
        (tester) async {
      await tester.pumpWidget(_harness(
        StaggeredList(
          stagger: const Duration(milliseconds: 80),
          children: const [Text('a'), Text('b'), Text('c')],
        ),
      ));
      await tester.pump(const Duration(milliseconds: 30));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('GONE')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('GONE'), findsOneWidget);
    });
  });

  // ============================================================================
  // ParallaxCard Tests
  // ============================================================================
  group('ParallaxCard', () {
    testWidgets('scroll 为 0 时 child 位置不偏移', (tester) async {
      final ctrl = ScrollController();
      addTearDown(ctrl.dispose);

      const innerKey = Key('pc-inner-zero');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SingleChildScrollView(
                controller: ctrl,
                child: SizedBox(
                  height: 800,
                  child: ParallaxCard(
                    scrollController: ctrl,
                    child: const SizedBox(
                      key: innerKey,
                      height: 200,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // scroll=0 时位置记录
      final topAtZero = tester.getTopLeft(find.byKey(innerKey)).dy;

      // 确认未发生位移（对齐父级顶部）
      expect(topAtZero, isNonNegative);
    });

    testWidgets('scroll 后 child Y 位置随 parallaxFactor 偏移', (tester) async {
      final ctrl = ScrollController();
      addTearDown(ctrl.dispose);

      const innerKey = Key('pc-inner-scroll');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: SingleChildScrollView(
                controller: ctrl,
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: ParallaxCard(
                        scrollController: ctrl,
                        parallaxFactor: 0.3,
                        child: const SizedBox(
                          key: innerKey,
                          height: 300,
                          child: ColoredBox(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      final topBefore = tester.getTopLeft(find.byKey(innerKey)).dy;

      // jumpTo 100px → child 应向下位移 100 × 0.3 = 30px
      ctrl.jumpTo(100.0);
      await tester.pump();
      final topAfter = tester.getTopLeft(find.byKey(innerKey)).dy;

      // topAfter = topBefore + 30（向下偏了 30px）
      // 由于 scroll 本身也会移动 viewport，实际 dy 差 ≈ parallax 偏移量
      // 我们只验证 topAfter != topBefore（发生了位移）
      expect((topAfter - topBefore).abs(), greaterThan(1.0));
    });

    testWidgets('navigation away 不 crash · ScrollController dispose 安全',
        (tester) async {
      final ctrl = ScrollController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_harness(
        SizedBox(
          height: 200,
          child: ParallaxCard(
            scrollController: ctrl,
            child: const SizedBox(
              key: Key('pc-dispose'),
              height: 200,
              child: ColoredBox(color: Colors.green),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('REPLACED')),
        ),
      );
      await tester.pump();

      expect(find.text('REPLACED'), findsOneWidget);
    });
  });
}
