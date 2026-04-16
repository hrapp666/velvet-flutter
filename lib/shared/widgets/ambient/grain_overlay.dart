// ============================================================================
// GrainOverlay · v25 · UI12 (UI17 中文可读性修复版)
// ----------------------------------------------------------------------------
// Editorial luxury 的"纸张纹理"覆盖层 · Ferrari/Stripe/Airbnb 用了十年的
// 让屏幕不再"塑料感"的微妙做法.
//
// UI17 修复 (主人反馈"回字糊成一团"):
// ----------------------------------------------------------------------------
// 原版使用 BlendMode.overlay + 黑白点混合 + intensity 0.05 + density 0.004
// 叠在中文文本上导致"笔画糊成一团":
//   - BlendMode.overlay 会根据底色亮度做"乘/屏"反转 · 中文方块字笔画密集 ·
//     每个点都在扰动相邻像素 · 结果笔画边缘被噪点侵蚀
//   - 黑点叠在深色 bg (Vt.bgVoid) 上 · 把文本区域进一步暗化
//   - density 0.004 意味着 390×844 屏 ~1316 个点 · 算到中文字密集区 · 人眼
//     感知为"文字被污染"
//
// 修复策略:
//   - BlendMode.plus (纯加法, 只添加亮度 · 绝不反转/减暗 · 不伤文字对比度)
//   - 移除黑点 · 只留白点 · 避免任何"抵消"文字的可能
//   - intensity 默认 0.06 → 0.022 (降三分之二)
//   - density 默认 0.004 → 0.0016 (降 60%)
//   - radius 收紧到 0.4~1.0px · 更精细的胶片感
//
// 用法:
//   Stack(
//     children: [
//       BackgroundLayer(),
//       ContentLayer(),
//       const GrainOverlay(), // 用默认值即安全
//     ],
//   )
// ============================================================================

import 'dart:math' show Random;

import 'package:flutter/material.dart';

/// 在上层加一个细腻噪点纹理 · 让屏幕有"纸张/绒面/胶片"质感.
///
/// [intensity] 0.0 ~ 0.08 · 默认 0.022 · 再高会污染中文小字可读性.
/// [density] 每平方 px 的点数 · 默认 0.0016.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({
    super.key,
    this.intensity = 0.022,
    this.density = 0.0016,
    this.seed = 42,
  })  : assert(intensity >= 0 && intensity <= 0.1, 'intensity 0..0.1'),
        assert(density > 0 && density <= 0.008, 'density (0..0.008]');

  /// 每个点的最大 alpha 值 · 默认 0.022 = 2.2% · 再高就污染中文笔画.
  final double intensity;

  /// 单位面积点数密度 · 默认 0.0016.
  final double density;

  /// random seed · 保持一致才能避免 rebuild 时 flicker.
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GrainPainter(
            intensity: intensity,
            density: density,
            seed: seed,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({
    required this.intensity,
    required this.density,
    required this.seed,
  });

  final double intensity;
  final double density;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final count = (size.width * size.height * density).toInt();
    // UI17: BlendMode.plus · 只加光 · 不反转底色 · 不伤文字笔画
    final paint = Paint()..blendMode = BlendMode.plus;

    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // 收紧到 0.4~1.0px · 更精细
      final radius = 0.4 + rng.nextDouble() * 0.6;
      // 只白点 · 移除黑点 · 避免暗化文字
      final alpha = (0.3 + rng.nextDouble() * 0.7) * intensity;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.intensity != intensity ||
      old.density != density ||
      old.seed != seed;
}
