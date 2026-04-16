// ============================================================================
// EmptyState · v25 · A4
// ----------------------------------------------------------------------------
// 验证: 渲染 + 可选 subtitle/cta · CTA 触发 callback
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/empty_state/empty_state.dart';
import 'package:velvet/shared/widgets/error_state/retry_chip.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('EmptyState', () {
    testWidgets('最小渲染 · 只 title', (tester) async {
      await tester.pumpWidget(_harness(
        const EmptyState(title: '— 还 没 有 故 事 —'),
      ));
      await tester.pump();

      expect(find.text('— 还 没 有 故 事 —'), findsOneWidget);
      expect(find.byType(RetryChip), findsNothing);
    });

    testWidgets('title + subtitle', (tester) async {
      await tester.pumpWidget(_harness(
        const EmptyState(
          title: '— 暂 无 订 单 —',
          subtitle: '逛 逛 看 · 或 许 有 心 动 的',
        ),
      ));
      await tester.pump();

      expect(find.text('— 暂 无 订 单 —'), findsOneWidget);
      expect(find.text('逛 逛 看 · 或 许 有 心 动 的'), findsOneWidget);
    });

    testWidgets('subtitle + CTA · 渲染 RetryChip', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_harness(
        EmptyState(
          title: '— 这 里 还 空 —',
          subtitle: '挂出第一件',
          ctaLabel: '挂 一 件',
          onCta: () => tapped++,
        ),
      ));
      await tester.pump();

      expect(find.text('挂 一 件'), findsOneWidget);
      expect(find.byType(RetryChip), findsOneWidget);

      await tester.tap(find.byType(RetryChip));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('onCta = null · 不渲染 chip 即使有 ctaLabel', (tester) async {
      await tester.pumpWidget(_harness(
        const EmptyState(
          title: '— 没 有 数 据 —',
          ctaLabel: '重 试',
        ),
      ));
      await tester.pump();

      expect(find.byType(RetryChip), findsNothing);
    });

    testWidgets('自定义 CTA icon', (tester) async {
      await tester.pumpWidget(_harness(
        EmptyState(
          title: '— 还 没 有 收 藏 —',
          ctaLabel: '去 逛 逛',
          ctaIcon: Icons.explore_rounded,
          onCta: () {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    });
  });
}
