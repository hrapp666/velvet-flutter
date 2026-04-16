// ============================================================================
// Velvet · CinematicPageRoute · v25 · UI02
// ----------------------------------------------------------------------------
// 顶级品牌 (Linear / Superhuman / Apple Music) 页面切换质感。
//
// 四个运动叠加:
//   - 旧页: opacity 1 → 0 + scale 1 → 0.95 (fade + 缩回)
//   - 新页: opacity 0 → 1 + slide from bottom 5% (淡入 + 上浮)
//
// 曲线:
//   - enter: easeOutQuint · 快速接近 · 缓慢定格 · 给"突然到达"的戏剧感
//   - exit: easeInQuint · 缓慢松开 · 快速消失 · 保证旧页不阻碍新页视线
//
// 时长:
//   - forward 400ms: 比 Material 默认 300ms 长 100ms · 让 cinematic 质感吃到
//     · 但不至于拖慢操作流 · iOS 系统 push 是 350ms · 我们取中位偏长。
//   - reverse 300ms: 返回要比前进更快 · 符合用户"脱离"心理。
//
// 为什么不直接用 MaterialPageRoute:
//   - Material 默认是 slide from right · 属于 navigation stack 语义 · 做不了
//     "揭幕 reveal"的电影感。
//   - CupertinoPageRoute 是 iOS 右滑 · 同样不够戏剧化 · 且样式被 iOS 约束死。
//   - 自定义 PageRouteBuilder 给完整控制权 · 跟品牌保持一致。
//
// 用法 (GoRouter):
// ```dart
// GoRoute(
//   path: '/detail',
//   pageBuilder: (ctx, state) => CinematicPage(key: state.pageKey, child: DetailScreen()),
// )
// ```
//
// 直接用:
// ```dart
// Navigator.of(context).push(CinematicPageRoute(page: DetailScreen()));
// ```
// ============================================================================

import 'package:flutter/material.dart';

/// 电影感 page route · fade + scale + slide 组合。
class CinematicPageRoute<T> extends PageRouteBuilder<T> {
  CinematicPageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: _buildTransitions,
        );

  /// 目标页面 widget。
  final Widget page;

  static Widget _buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuint,
      reverseCurve: Curves.easeInQuint,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInQuint,
      reverseCurve: Curves.easeOutQuint,
    );

    // 新页进场: fade + slide up 5%
    final enterFade = Tween<double>(begin: 0, end: 1).animate(enter);
    final enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(enter);

    // 旧页退场: fade + shrink 0.95
    final exitFade = Tween<double>(begin: 1, end: 0).animate(exit);
    final exitScale = Tween<double>(begin: 1, end: 0.95).animate(exit);

    return FadeTransition(
      opacity: enterFade,
      child: SlideTransition(
        position: enterSlide,
        child: ScaleTransition(
          scale: exitScale,
          child: FadeTransition(
            opacity: exitFade,
            child: child,
          ),
        ),
      ),
    );
  }
}
