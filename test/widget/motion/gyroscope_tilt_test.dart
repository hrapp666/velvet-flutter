// ============================================================================
// GyroscopeTilt · widget test · v25 · UI04
// ----------------------------------------------------------------------------
// 真实 accelerometer stream 需要真机 / 模拟器硬件，无法在 CI 单元测试中触发。
// 这里验证：
//   1. 初始 tiltX = 0 / tiltY = 0（无 sensor 事件时默认值正确）
//   2. autoStart = false 时不订阅（dispose 不抛异常、也不 cancel 非 null sub）
//   3. dispose 时 subscription 被 cancel（mounted 保护正常）
//   4. builder 被调用、且 Widget tree 正确渲染
//   5. assert 参数边界（smoothFactor / maxTilt 越界抛 AssertionError）
// ============================================================================

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/motion/gyroscope_tilt.dart';

/// 最小 harness：WidgetsApp 提供 Directionality/MediaQuery 等。
Widget _harness(Widget child) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    builder: (_, __) => child,
  );
}

void main() {
  group('GyroscopeTilt · 初始状态', () {
    testWidgets('autoStart=false · 初始 tiltX=0 tiltY=0 · builder 被调用',
        (tester) async {
      double? capturedX;
      double? capturedY;

      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            autoStart: false,
            builder: (_, x, y) {
              capturedX = x;
              capturedY = y;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      // 没有 sensor 事件 → 初始值都是 0
      expect(capturedX, 0.0);
      expect(capturedY, 0.0);
    });

    testWidgets('autoStart=true · 初始值仍为 0（无 sensor 事件注入）',
        (tester) async {
      double? capturedX;
      double? capturedY;

      // autoStart=true 但测试环境无法产生真实 accelerometer 事件
      // → builder 以默认值 0/0 渲染
      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            // autoStart=true is default; sensors_plus will emit nothing in test
            builder: (_, x, y) {
              capturedX = x;
              capturedY = y;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(capturedX, 0.0);
      expect(capturedY, 0.0);
    });
  });

  group('GyroscopeTilt · builder pattern', () {
    testWidgets('builder 返回的 Widget 正确挂载到 tree', (tester) async {
      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            autoStart: false,
            builder: (_, __, ___) => const Text(
              'GLYPH_PLACEHOLDER',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GLYPH_PLACEHOLDER'), findsOneWidget);
    });

    testWidgets('maxTilt=0.5 · builder 收到的值不超出 ±0.5', (tester) async {
      double? lastX;
      double? lastY;

      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            autoStart: false,
            maxTilt: 0.5,
            builder: (_, x, y) {
              lastX = x;
              lastY = y;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      // 初始仍为 0，不超出 maxTilt
      expect(lastX, lessThanOrEqualTo(0.5));
      expect(lastX, greaterThanOrEqualTo(-0.5));
      expect(lastY, lessThanOrEqualTo(0.5));
      expect(lastY, greaterThanOrEqualTo(-0.5));
    });
  });

  group('GyroscopeTilt · dispose', () {
    testWidgets('autoStart=false · dispose 不 throw（sub 为 null）',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            autoStart: false,
            builder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      // 替换整棵树 → 触发 GyroscopeTilt.dispose()
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: _emptyBuilder,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('autoStart=true · dispose 不 throw（sub.cancel 正常）',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          GyroscopeTilt(
            builder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      // 强制 dispose
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: _emptyBuilder,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('GyroscopeTilt · assert 边界', () {
    test('smoothFactor = 0 应该 assert fail', () {
      expect(
        () => GyroscopeTilt(
          smoothFactor: 0,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('smoothFactor > 1 应该 assert fail', () {
      expect(
        () => GyroscopeTilt(
          smoothFactor: 1.1,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('maxTilt = 0 应该 assert fail', () {
      expect(
        () => GyroscopeTilt(
          maxTilt: 0,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('maxTilt > 1 应该 assert fail', () {
      expect(
        () => GyroscopeTilt(
          maxTilt: 1.1,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });

    test('合法参数不 throw', () {
      expect(
        () => GyroscopeTilt(
          smoothFactor: 0.15,
          maxTilt: 0.8,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
        returnsNormally,
      );
    });
  });
}

/// 用于替换整棵树时的空 builder（避免 const lambda 问题）。
Widget _emptyBuilder(BuildContext context, Widget? child) {
  return const SizedBox.shrink();
}
