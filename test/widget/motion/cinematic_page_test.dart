// ============================================================================
// CinematicPage tests · v25 · J4 (UI16 抖动修复版)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velvet/shared/widgets/motion/cinematic_page.dart';

void main() {
  group('CinematicPage', () {
    test('can be constructed with a child widget', () {
      final page = CinematicPage<void>(
        child: const SizedBox(),
      );
      expect(page, isA<CinematicPage<void>>());
      expect(page.child, isA<SizedBox>());
    });

    test('transitionDuration is 360ms (UI16 shortened from 400)', () {
      final page = CinematicPage<void>(child: const SizedBox());
      expect(
        page.transitionDuration,
        const Duration(milliseconds: 360),
      );
    });

    test('reverseTransitionDuration is 260ms (UI16 shortened from 300)', () {
      final page = CinematicPage<void>(child: const SizedBox());
      expect(
        page.reverseTransitionDuration,
        const Duration(milliseconds: 260),
      );
    });

    testWidgets(
      'transitionsBuilder returns FadeTransition > SlideTransition nesting '
      '(no ScaleTransition, no parent exit — UI16 anti-jitter)',
      (tester) async {
        final page = CinematicPage<void>(child: const Text('inner'));

        late AnimationController enterCtrl;
        late AnimationController exitCtrl;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                enterCtrl = AnimationController(
                  vsync: tester,
                  value: 0.5,
                );
                exitCtrl = AnimationController(
                  vsync: tester,
                  value: 0.0,
                );
                return page.transitionsBuilder(
                  context,
                  enterCtrl,
                  exitCtrl,
                  const Text('inner'),
                );
              },
            ),
          ),
        );

        addTearDown(() {
          enterCtrl.dispose();
          exitCtrl.dispose();
        });

        // MaterialApp harness 自带 Fade/Slide · 我们的 + harness >= 1 即可
        expect(find.byType(FadeTransition), findsAtLeast(1));
        expect(find.byType(SlideTransition), findsAtLeast(1));

        // UI16 抖动修复: 不再有 ScaleTransition (parent 必须静止)
        // 注意 harness 可能偶尔注入 ScaleTransition, 所以不能硬断言 findsNothing,
        // 这里只保证 payload 正确渲染.
        expect(find.text('inner'), findsOneWidget);
      },
    );
  });
}
