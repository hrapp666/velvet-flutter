// ============================================================================
// SkeletonBox · v25 · 共享 dumb shape (无 Shimmer · 由 parent SkeletonShimmer 包)
// ----------------------------------------------------------------------------
// 重要 (code-reviewer 反馈 · A2 v2 修):
//   - 之前每个 SkeletonBox 自己 Shimmer.fromColors → 18 controller per FeedSkeleton
//   - shimmer pkg 设计为 PARENT 包一次 · CHILDREN 全用 opaque white
//   - 现在的 box/avatar/textline 是 dumb shape · 必须配 SkeletonShimmer 父包
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:velvet/shared/theme/design_tokens.dart';

/// Parent shimmer wrapper · 一次创建一个 controller · 包整片 skeleton
/// 用法:`SkeletonShimmer(child: Column(children: [SkeletonBox(...), ...]))`
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // 在 dark 主题下用 bgElevated → goldDeepest 微弱金 highlight
      // shimmer 包内部用 ShaderMask · child 必须 opaque · 我们用 white 让 mask 完整渲染
      baseColor: Vt.bgElevated,
      highlightColor: Vt.bgHighest,
      period: const Duration(milliseconds: 1600),
      child: child,
    );
  }
}

/// 通用 dumb shape · opaque white · 让 parent ShaderMask 完整渲染 gradient
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = Vt.rSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        // opaque white · ShaderMask 才能完整渲染 gradient
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 圆形 dumb shape (头像)
class SkeletonAvatar extends StatelessWidget {
  final double size;
  const SkeletonAvatar({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 一行短文本 dumb shape · 默认 60% 宽
class SkeletonTextLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const SkeletonTextLine({
    super.key,
    this.widthFactor = 0.6,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: Vt.rXxs),
    );
  }
}
