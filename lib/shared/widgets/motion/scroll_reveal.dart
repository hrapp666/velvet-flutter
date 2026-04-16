// ============================================================================
// ScrollReveal · 通用 scroll-trigger reveal wrapper
// ----------------------------------------------------------------------------
// 任何 child 包起来 → slide-up + fade-in 入场动画。
//
// 设计决策：
//   - 不装 visibility_detector：Velvet 禁止引入 pubspec 未列表的 package。
//     用 Future.delayed(delay) 代替 viewport 触发：feed 场景 card 列表
//     在进入视口时几乎是顺序性的，延迟启动足以产生电影级 stagger 效果，
//     且实现更简洁、无额外依赖、测试更可控。
//   - delay 参数 → 由 StaggeredList 注入，实现多 card 依次入场。
//   - dispose 顺序：先 stop() 再 dispose()，避免 ticker after dispose crash。
//   - 不用 SlideTransition（需要 RelativeRectTween），改用 Transform.translate
//     驱动 fromOffsetY → 0 线性映射，compositor 层做 translate，无 layout。
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 包裹任意 child，child 进入时从下方 [fromOffsetY] px slide-in + fade-in。
///
/// 用法：
/// ```dart
/// ScrollReveal(
///   delay: Duration(milliseconds: 160),
///   child: MomentCard(...),
/// )
/// ```
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Vt.cinematic,       // 800ms — cinematic token
    this.fromOffsetY = 40.0,
    this.fromOpacity = 0.0,
  });

  final Widget child;

  /// 启动延迟 — 由外部（StaggeredList）注入序列错位。
  final Duration delay;

  /// 动画总时长，默认 Vt.cinematic (800ms)。
  final Duration duration;

  /// 初始 Y 偏移（像素），向下为正。card 从 +40px 滑入 0。
  final double fromOffsetY;

  /// 初始透明度，0.0 = 完全透明。
  final double fromOpacity;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  // _ctrl 在 initState 第一行就赋值，后续 dispose 前都不为 null。
  // 用 nullable + null-safe calls 代替 late，避免 late + !。
  AnimationController? _ctrl;
  Animation<double>? _opacity;
  Animation<double>? _offsetY;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    final ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl = ctrl;

    final curve = CurvedAnimation(
      parent: ctrl,
      curve: Vt.curveCinematic,         // expo-out (0.22,1,0.36,1)
    );

    _opacity = Tween<double>(
      begin: widget.fromOpacity,
      end: 1.0,
    ).animate(curve);

    _offsetY = Tween<double>(
      begin: widget.fromOffsetY,
      end: 0.0,
    ).animate(curve);

    // 延迟启动 — 用 Timer (zone-aware · 在 flutter_test FakeAsync 里能正常 fire)
    // 之前用 Future.delayed 在 testWidgets 里不 fire
    if (widget.delay == Duration.zero) {
      ctrl.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _ctrl?.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _delayTimer = null;
    _ctrl?.stop();
    _ctrl?.dispose();
    _ctrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _ctrl ?? kAlwaysCompleteAnimation;
    final opacityAnim = _opacity;
    final offsetAnim = _offsetY;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = opacityAnim?.value ?? 1.0;
        final offsetY = offsetAnim?.value ?? 0.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
