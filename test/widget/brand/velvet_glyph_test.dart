// ============================================================================
// VelvetGlyph · v25 · H2
// ----------------------------------------------------------------------------
// 验证渲染结构 · 不验证像素(golden test v26 加 baseline)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/brand/velvet_glyph.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('VelvetGlyph · 基础渲染', () {
    testWidgets('默认 size 96 · 透明背景 · 渲染 CustomPaint', (tester) async {
      await tester.pumpWidget(_harness(const VelvetGlyph()));
      await tester.pump();

      expect(find.byType(VelvetGlyph), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // 默认 96x96
      final box = tester.getSize(find.byType(VelvetGlyph));
      expect(box.width, 96);
      expect(box.height, 96);
    });

    testWidgets('自定义 size 200 · SizedBox 宽高 200', (tester) async {
      await tester.pumpWidget(_harness(const VelvetGlyph(size: 200)));
      await tester.pump();

      // 内部第一个 SizedBox 尺寸 = 200(withBackdrop=false 时整体就是 glyph)
      final glyphBox = tester.getSize(find.byType(VelvetGlyph));
      expect(glyphBox.width, 200);
      expect(glyphBox.height, 200);
    });
  });

  group('VelvetGlyph · backdrop', () {
    testWidgets('withBackdrop = true · 渲染 DecoratedBox', (tester) async {
      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 120, withBackdrop: true)),
      );
      await tester.pump();

      expect(find.byType(VelvetGlyph), findsOneWidget);

      // 内部必然有 DecoratedBox(velvetGradient 底板)
      final decoratedFinder = find.descendant(
        of: find.byType(VelvetGlyph),
        matching: find.byType(DecoratedBox),
      );
      expect(decoratedFinder, findsWidgets);

      // DecoratedBox 内部有 CustomPaint
      expect(
        find.descendant(
          of: decoratedFinder.first,
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('withBackdrop = false · 无 DecoratedBox 直接子', (tester) async {
      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 96)),
      );
      await tester.pump();

      // VelvetGlyph 直接子是 SizedBox(不是 DecoratedBox)
      final directSizedBox = find.descendant(
        of: find.byType(VelvetGlyph),
        matching: find.byType(SizedBox),
      );
      expect(directSizedBox, findsWidgets);
    });
  });

  group('VelvetGlyph3D · tilt wrapper', () {
    testWidgets('默认 tiltX=0 tiltY=0 · 渲染 Transform + 内部 VelvetGlyph',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const VelvetGlyph3D(
            glyph: VelvetGlyph(size: 120),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VelvetGlyph3D), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(VelvetGlyph), findsOneWidget);
    });

    testWidgets('tiltX=0.5 tiltY=-0.5 · Transform matrix 不是 identity',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const VelvetGlyph3D(
            tiltX: 0.5,
            tiltY: -0.5,
            glyph: VelvetGlyph(size: 120),
          ),
        ),
      );
      await tester.pump();

      final transformFinder = find.descendant(
        of: find.byType(VelvetGlyph3D),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsWidgets);

      final transform = tester.widget<Transform>(transformFinder.first);
      // perspective entry (3,2) = 0.001 + rotateX/Y · 不等于 identity
      expect(transform.transform, isNot(equals(Matrix4.identity())));
    });

    testWidgets('tilt 超出 ±1 · clamp 不 crash', (tester) async {
      await tester.pumpWidget(
        _harness(
          const VelvetGlyph3D(
            tiltX: 5.0,
            tiltY: -5.0,
            glyph: VelvetGlyph(size: 120),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(VelvetGlyph3D), findsOneWidget);
    });
  });

  group('VelvetGlyph · shimmer progress', () {
    testWidgets('shimmerProgress 0 vs 1 · 都能渲染不 crash', (tester) async {
      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 120, shimmerProgress: 0.0)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(VelvetGlyph), findsOneWidget);

      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 120, shimmerProgress: 1.0)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(VelvetGlyph), findsOneWidget);
    });

    testWidgets('shimmerProgress 变化 · shouldRepaint 触发 pump 成功',
        (tester) async {
      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 120, shimmerProgress: 0.3)),
      );
      await tester.pump();

      await tester.pumpWidget(
        _harness(const VelvetGlyph(size: 120, shimmerProgress: 0.7)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    test('size 必须 > 0 · size 0 应该 assert fail', () {
      expect(
        () => VelvetGlyph(size: 0),
        throwsAssertionError,
      );
    });

    test('shimmerProgress 超出 [0,1] 应该 assert fail', () {
      expect(
        () => VelvetGlyph(size: 96, shimmerProgress: 1.5),
        throwsAssertionError,
      );
      expect(
        () => VelvetGlyph(size: 96, shimmerProgress: -0.1),
        throwsAssertionError,
      );
    });
  });
}
