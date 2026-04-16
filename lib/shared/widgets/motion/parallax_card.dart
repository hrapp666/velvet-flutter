// ============================================================================
// ParallaxCard · scroll 视差深度效果 wrapper
// ----------------------------------------------------------------------------
// 监听外部 ScrollController，child 的 Y 轴位移 = scrollOffset × parallaxFactor。
//
// 设计决策：
//   - parallaxFactor 默认 0.3：
//       0 = child 完全跟随 scroll，无视差
//       1 = child 静止不动（完全反向补偿）
//       0.3 = 业界常用"轻视差"值，cover 图移动约 30% of scroll
//             → 滚动 100px 时 cover 位移 30px，有深度感但不晕眩。
//       Pinterest / Apple WWDC 会场页均在 0.2-0.4 区间。
//   - 为什么 caller 传 scrollController 而非内部创建：
//       ParallaxCard 是纯展示 widget，不拥有 scroll。feed_screen 的
//       _scrollCtrl 已经存在并管理分页 loadMore；如果内部再创建一个
//       ScrollController 就会出现两个 controller 竞争同一 Scrollable，
//       或者 ParallaxCard 根本感知不到外层的 scroll。显式传入是唯一
//       正确的依赖关系：数据流向明确，testability 高。
//   - AnimatedBuilder listening scrollController：O(1) per frame，
//     不触发 rebuild，只做 Transform，compositor 层处理。
//   - overflow: Clip.hardEdge 防止 parallax translate 时 child 溢出卡片边界。
// ============================================================================

import 'package:flutter/material.dart';

/// 监听 [scrollController]，给 [child] 施加 Y 轴视差位移。
///
/// [parallaxFactor] 控制深度感：
///   - 0.0 → 无视差（child 跟滚）
///   - 0.3 → 默认轻视差（cover 图效果）
///   - 1.0 → child 完全静止
///
/// 用法（feed_screen 中）：
/// ```dart
/// SizedBox(
///   height: 200,
///   child: ClipRRect(
///     borderRadius: BorderRadius.circular(Vt.rMd),
///     child: ParallaxCard(
///       scrollController: _scrollCtrl,
///       child: coverImage,
///     ),
///   ),
/// )
/// ```
class ParallaxCard extends StatelessWidget {
  const ParallaxCard({
    super.key,
    required this.child,
    required this.scrollController,
    this.parallaxFactor = 0.3,
  });

  final Widget child;

  /// 外层 CustomScrollView / ListView 的 ScrollController。
  /// caller 传入，ParallaxCard 只监听，不拥有。
  final ScrollController scrollController;

  /// 视差系数，0 = 无效果，1 = child 静止，负数 = 反向。
  /// 默认 0.3（Apple / Pinterest 轻视差惯例）。
  final double parallaxFactor;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, innerChild) {
          final double scrollOffset = scrollController.hasClients
              ? scrollController.offset
              : 0.0;
          return Transform.translate(
            offset: Offset(0, scrollOffset * parallaxFactor),
            child: innerChild,
          );
        },
        child: child,
      ),
    );
  }
}
