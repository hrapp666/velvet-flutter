// ============================================================================
// StaggeredList · 多 child 依次 reveal 的 helper wrapper
// ----------------------------------------------------------------------------
// 把 List<Widget> 按 stagger 间隔包一圈 ScrollReveal，产生电影级逐一入场。
//
// 设计决策：
//   - stagger 80ms：Apple / Stripe 动效分析均在 60-100ms 区间；
//     80ms 在 60fps 下约 5 帧，视觉上"追着跑"但不拥挤，是电影感的
//     最小可感知差距。< 60ms 太快 → 感觉同时出现；> 120ms 太慢 → 卡顿感。
//   - StatelessWidget：无状态，只做结构映射，所有动画状态在 ScrollReveal 里。
// ============================================================================

import 'package:flutter/material.dart';

import 'scroll_reveal.dart';

/// 把 [children] 包成 staggered reveal 列表。
///
/// 每个 child 比前一个晚 [stagger] 启动，产生"一个接一个"的电影感入场。
///
/// 用法：
/// ```dart
/// StaggeredList(
///   children: momentCards,
///   stagger: Duration(milliseconds: 80),
/// )
/// ```
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 80),
    this.fromOffsetY = 40.0,
    this.revealDuration = const Duration(milliseconds: 600),
  });

  final List<Widget> children;

  /// 相邻两 child 入场的时间间隔，默认 80ms。
  final Duration stagger;

  /// 各 child 的初始 Y 偏移，透传给 ScrollReveal。
  final double fromOffsetY;

  /// 每个 child reveal 动画的时长，默认 600ms。
  final Duration revealDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.asMap().entries.map((entry) {
        return ScrollReveal(
          delay: stagger * entry.key,
          duration: revealDuration,
          fromOffsetY: fromOffsetY,
          child: entry.value,
        );
      }).toList(),
    );
  }
}
