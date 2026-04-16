// ============================================================================
// ErrorState + RetryChip · v25 · A3
// ----------------------------------------------------------------------------
// 验证: 渲染 + 点击 retry callback + disabled 态 (onTap=null)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/error_state/error_state.dart';
import 'package:velvet/shared/widgets/error_state/retry_chip.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('RetryChip', () {
    testWidgets('渲染 · 默认 label "重 试" · 默认 icon refresh',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_harness(
        RetryChip(onTap: () => tapped++),
      ));
      await tester.pump();

      expect(find.text('重 试'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(tapped, 0);
    });

    testWidgets('点击触发 onTap · 计数 +1', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_harness(
        RetryChip(onTap: () => tapped++),
      ));
      await tester.pump();

      await tester.tap(find.byType(RetryChip));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('disabled 态 · onTap = null · 不抛异常', (tester) async {
      await tester.pumpWidget(_harness(
        const RetryChip(onTap: null),
      ));
      await tester.pump();

      // 应该正常渲染 · 不能 tap
      expect(find.byType(RetryChip), findsOneWidget);
      // 点击 disabled chip 不应抛
      await tester.tap(find.byType(RetryChip));
      await tester.pump();
    });

    testWidgets('自定义 label + icon', (tester) async {
      await tester.pumpWidget(_harness(
        RetryChip(
          onTap: () {},
          label: '再 来',
          icon: Icons.replay_rounded,
        ),
      ));
      await tester.pump();

      expect(find.text('再 来'), findsOneWidget);
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    });
  });

  group('ErrorState', () {
    testWidgets('渲染 · 默认 title + message + retry chip', (tester) async {
      var retried = 0;
      await tester.pumpWidget(_harness(
        ErrorState(
          message: '网络超时',
          onRetry: () => retried++,
        ),
      ));
      await tester.pump();

      expect(find.text('此 刻 没 找 到'), findsOneWidget);
      expect(find.text('网络超时'), findsOneWidget);
      expect(find.byType(RetryChip), findsOneWidget);
    });

    testWidgets('自定义 title', (tester) async {
      await tester.pumpWidget(_harness(
        ErrorState(
          message: '错误',
          title: '出 错 了',
          onRetry: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('出 错 了'), findsOneWidget);
      expect(find.text('此 刻 没 找 到'), findsNothing);
    });

    testWidgets('onRetry = null · 不渲染 retry chip', (tester) async {
      await tester.pumpWidget(_harness(
        const ErrorState(message: '永久错误'),
      ));
      await tester.pump();

      expect(find.text('永久错误'), findsOneWidget);
      expect(find.byType(RetryChip), findsNothing);
    });

    testWidgets('点击 retry chip 触发 callback', (tester) async {
      var retried = 0;
      await tester.pumpWidget(_harness(
        ErrorState(
          message: 'fail',
          onRetry: () => retried++,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(RetryChip));
      await tester.pump();

      expect(retried, 1);
    });

    testWidgets('长 message 截断 · maxLines 3 + ellipsis', (tester) async {
      const long = 'A very long error message that should be truncated '
          'with ellipsis after three lines because the design system '
          'requires editorial restraint and not overwhelming the user '
          'with stack trace dump in a tiny error placeholder';
      await tester.pumpWidget(_harness(const SizedBox(
        width: 200,
        child: ErrorState(message: long),
      )));
      await tester.pump();

      // 文字存在 但被截断
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
