// ============================================================================
// Velvet · VelvetGlyph · v25 · H2
// ----------------------------------------------------------------------------
// 自绘品牌 glyph 替代 Text('VELVET') + ShaderMask(gradientGoldLogo)。
//
// 语义：抽象 V 字 + 酒红天鹅绒底 + 金属箔质感。
//   - 左右两笔对称 Path · lineTo 手工画,不用 Text('V')
//   - 每笔独立 LinearGradient (goldIvory → gold → goldDeepest)
//   - 底部交汇点 dot + glowGold shadow
//   - stroke 顶 4px → 底 6px (视觉加重底部,模拟雕刻金属加厚)
//   - shimmer 沿 V 字流动(gradient stops 随 progress 偏移)
//
// 为什么 Path 不用 Text:
//   - Text 字符受字体影响,无法控制 stroke gradient
//   - Path 可以精确控制几何、宽度渐变、交汇点高光
//   - 未来可以 morph(比如 onboarding 第 3 屏 V → 圆圈动画)
//
// 为什么 shimmerProgress 是参数不是内部 state:
//   - 避免 widget 内创建 AnimationController → tick leak 风险(A1 pre-mortem)
//   - caller 用 TickerProviderStateMixin + dispose 严格管理
//   - 多个 glyph 可以共享一个 controller (splash 屏 + onboarding 屏)
//
// 为什么 3D tilt 是独立 widget:
//   - 核心 glyph 保持纯 2D · 便于 golden test / unit test
//   - 3D 只是 Transform wrapper · 单一职责
//   - 陀螺仪 / pointer 驱动逻辑不污染 glyph 本体
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';

/// 自绘金属质感 V 字品牌 glyph。
///
/// 默认 96x96 · 透明背景 · 静态渲染。
/// 可选 shimmer 动画:传入 shimmerProgress(0-1) · caller 管理 controller。
/// 可选 withBackdrop:包一层 velvetGradient 圆角底(适合 splash)。
class VelvetGlyph extends StatelessWidget {
  const VelvetGlyph({
    super.key,
    this.size = 96,
    this.withBackdrop = false,
    this.shimmerProgress,
  })  : assert(size > 0, 'size must be positive'),
        assert(
          shimmerProgress == null ||
              (shimmerProgress >= 0 && shimmerProgress <= 1),
          'shimmerProgress must be in [0, 1]',
        );

  /// 整个 widget 宽高(正方形)。默认 96。
  final double size;

  /// 是否包 velvetGradient 圆角底板。默认 false(caller 自己放背景)。
  final bool withBackdrop;

  /// Shimmer 流动进度 0-1。null = 静态。
  /// 由 caller 的 AnimationController 驱动。
  final double? shimmerProgress;

  @override
  Widget build(BuildContext context) {
    final glyph = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VelvetGlyphPainter(
          shimmerProgress: shimmerProgress ?? 0,
        ),
      ),
    );

    if (!withBackdrop) return glyph;

    // v25 C2 reviewer M1 修:根据 Theme 感知 light/dark 模式选 backdrop 色
    // dark 模式:velvet 渐变
    // light 模式:warm cream 渐变
    return Builder(
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final gradientColors = isDark
            ? const [Vt.bgHighest, Vt.bgPrimary, Vt.bgVoid]
            : const [Vt.bgLightHighest, Vt.bgLightPrimary, Vt.bgLightVoid];
        final borderColor =
            isDark ? Vt.borderHairline : Vt.borderLightHairline;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.6),
              radius: 1.5,
              colors: gradientColors,
              stops: const [0.0, 0.4, 1.0],
            ),
            borderRadius: BorderRadius.circular(Vt.rLg),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Vt.s20),
            child: glyph,
          ),
        );
      },
    );
  }
}

/// 3D tilt wrapper · perspective transform 包 VelvetGlyph。
///
/// tiltX / tiltY 范围 -1 ~ 1(陀螺仪 normalize 后的值)。
/// 旋转角度被 clamp 到 ±0.3 rad · 避免透视崩溃。
class VelvetGlyph3D extends StatelessWidget {
  const VelvetGlyph3D({
    super.key,
    required this.glyph,
    this.tiltX = 0,
    this.tiltY = 0,
  });

  /// 内部 glyph(caller 控制 size/shimmer)。
  final VelvetGlyph glyph;

  /// X 轴倾斜 -1 ~ 1(正 = 向上仰)。
  final double tiltX;

  /// Y 轴倾斜 -1 ~ 1(正 = 向右转)。
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    final tx = tiltX.clamp(-1.0, 1.0);
    final ty = tiltY.clamp(-1.0, 1.0);
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(tx * 0.3)
      ..rotateY(ty * 0.3);

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: glyph,
    );
  }
}

// ============================================================================
// Painter
// ----------------------------------------------------------------------------
// 几何构造:
//   padding = size * 0.2
//   canvas inner = size * 0.6
//   left stroke : (padding, padding) → (size/2, size - padding)
//   right stroke: (size - padding, padding) → (size/2, size - padding)
//   merge dot   : (size/2, size - padding) radius 4% size
//
// 金属渐变:
//   每笔单独 Paint().shader · LinearGradient(顶 → 底)
//   colors = [goldIvory, goldLight, gold, goldDark, goldDeepest]
//   stops  = gradientGoldLogoStops 加上 shimmer 偏移
//
// stroke 宽度:
//   顶 4px · 底 6px · 用 PathMetric 无法直接变宽 → 画两层:
//     底层 strokeWidth 6 (深金)
//     顶层 strokeWidth 4 (浅金)
//   视觉上形成"底重顶轻"的锥形
// ============================================================================

class _VelvetGlyphPainter extends CustomPainter {
  const _VelvetGlyphPainter({required this.shimmerProgress});

  final double shimmerProgress;

  // 几何常量
  static const double _paddingRatio = 0.2;
  static const double _strokeOuter = 6.0;
  static const double _strokeInner = 4.0;
  static const double _dotRatio = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = w * _paddingRatio;
    final centerX = w / 2;
    final bottomY = h - padding;

    // 左右两笔的端点
    final leftTop = Offset(padding, padding);
    final rightTop = Offset(w - padding, padding);
    final mergePoint = Offset(centerX, bottomY);

    // shimmer 偏移:让 gradient stops 随 progress 流动
    final shiftedStops = _buildShimmerStops(shimmerProgress);

    // 左笔 path
    final leftPath = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(mergePoint.dx, mergePoint.dy);

    // 右笔 path
    final rightPath = Path()
      ..moveTo(rightTop.dx, rightTop.dy)
      ..lineTo(mergePoint.dx, mergePoint.dy);

    // 左笔 shader rect (顶到底的局部 rect)
    final leftRect = Rect.fromPoints(leftTop, mergePoint);
    final rightRect = Rect.fromPoints(
      Offset(mergePoint.dx, mergePoint.dy),
      rightTop,
    );

    // ----- 底层 stroke(粗 · 深金 · 形成视觉锥形重心)-----
    final leftOuterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeOuter
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Vt.gold, Vt.goldDark, Vt.goldDeepest],
        stops: shiftedStops.outer,
      ).createShader(leftRect);

    final rightOuterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeOuter
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Vt.gold, Vt.goldDark, Vt.goldDeepest],
        stops: shiftedStops.outer,
      ).createShader(rightRect);

    canvas.drawPath(leftPath, leftOuterPaint);
    canvas.drawPath(rightPath, rightOuterPaint);

    // ----- 顶层 stroke(细 · 高光 · 模拟金属反光)-----
    final leftInnerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeInner
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Vt.goldIvory, Vt.goldLight, Vt.gold],
        stops: shiftedStops.inner,
      ).createShader(leftRect);

    final rightInnerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeInner
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Vt.goldIvory, Vt.goldLight, Vt.gold],
        stops: shiftedStops.inner,
      ).createShader(rightRect);

    canvas.drawPath(leftPath, leftInnerPaint);
    canvas.drawPath(rightPath, rightInnerPaint);

    // ----- 交汇点光源 -----
    final dotRadius = w * _dotRatio;

    // 光晕 glow(Vt.shadowGold40 · 24px blur)
    final glowPaint = Paint()
      ..color = Vt.shadowGold40
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(mergePoint, dotRadius * 1.8, glowPaint);

    // 核心亮点(radial ivory → gold)
    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Vt.goldIvory, Vt.gold, Vt.goldDark],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: mergePoint, radius: dotRadius),
      );
    canvas.drawCircle(mergePoint, dotRadius, dotPaint);
  }

  /// 生成 shimmer 流动的 gradient stops。
  /// progress 0 = 默认 stops · progress 1 = stops 向下偏移 20% 形成流动感。
  /// 使用三停止点(对应 3 色 LinearGradient)。
  _ShimmerStops _buildShimmerStops(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    // 让高光段在 progress=0 时位于顶部,progress=1 时位于底部
    final shift = clamped * 0.4 - 0.2; // -0.2 ~ +0.2
    double s0 = (0.0 + shift).clamp(0.0, 1.0);
    double s1 = (0.5 + shift).clamp(0.0, 1.0);
    double s2 = (1.0 + shift).clamp(0.0, 1.0);
    // 保证严格递增(Flutter LinearGradient 要求)
    if (s1 <= s0) s1 = s0 + 0.001;
    if (s2 <= s1) s2 = s1 + 0.001;
    if (s2 > 1.0) s2 = 1.0;
    if (s1 >= s2) s1 = s2 - 0.001;
    if (s0 >= s1) s0 = s1 - 0.001;
    final stops = <double>[s0, s1, s2];
    return _ShimmerStops(inner: stops, outer: stops);
  }

  @override
  bool shouldRepaint(covariant _VelvetGlyphPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress;
  }
}

/// Shimmer stops 对(内外层可独立,当前共用)。
class _ShimmerStops {
  const _ShimmerStops({required this.inner, required this.outer});
  final List<double> inner;
  final List<double> outer;
}

// ============================================================================
// 用法
// ----------------------------------------------------------------------------
//
// 1. 静态:
//    const VelvetGlyph(size: 120)
//
// 2. 带背景:
//    const VelvetGlyph(size: 120, withBackdrop: true)
//
// 3. 3D tilt(陀螺仪驱动):
//    VelvetGlyph3D(
//      tiltX: gyroX,
//      tiltY: gyroY,
//      glyph: const VelvetGlyph(size: 200),
//    )
//
// 4. Shimmer 流动(控制器由 caller 提供):
//    AnimatedBuilder(
//      animation: _shimmerController,
//      builder: (_, __) => VelvetGlyph(
//        size: 200,
//        shimmerProgress: _shimmerController.value,
//      ),
//    )
// ============================================================================
