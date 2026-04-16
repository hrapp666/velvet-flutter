// ============================================================================
// CinematicPage · v25 · J4 (UI16 抖动修复版)
// ----------------------------------------------------------------------------
// 用于 go_router 的 pageBuilder · 自定义 transition
// 用法(router.dart):
//   pageBuilder: (_, state) => CinematicPage(
//     key: state.pageKey,
//     child: const SomeScreen(),
//   ),
//
// UI16 修复: 去掉 secondaryAnimation 控制的 parent Scale/Fade
// ----------------------------------------------------------------------------
// 原版把 parent 页面在 push 时缩小到 0.95 + 淡出 0 · pop 时再放大回 1.0 + 淡入.
// 主人反馈: "私语页和主页跳转回去的时候会抖动".
// 根因: reverseCurve 默认等于 curve · 所以 pop 时 parent 走 easeInQuint 的反向
//       = easeOut quint · 一开始快速从 0.95 → 0.98 · 然后慢慢到 1.0.
//       这种"一开始弹一下再慢下来"在视觉上 = 抖动.
//
// iOS/Android 系统级标准 (MaterialPageRoute, CupertinoPageRoute):
//   parent 页面在 pop 时保持静止, 只有当前页滑走 + 淡出.
//   Material 只给 parent 加一个轻微 dimming (Colors.black12) 或完全不动.
//   Cupertino 给 parent 一个 -0.25 水平偏移 (iOS 标志性"左滑露出")
//
// 新版策略: 只对当前页做 enter 动画 (fade + slide 0.05) · parent 完全静止.
// 这和 iOS sheet / Material dialog 的"从下淡入升起" 体感一致.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CinematicPage<T> extends CustomTransitionPage<T> {
  const CinematicPage({
    super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 360),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: _cinematicTransition,
        );

  static Widget _cinematicTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 只对当前页做 enter · reverseCurve 独立曲线避免 pop 抖动
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(enter),
        child: child,
      ),
    );
  }
}
