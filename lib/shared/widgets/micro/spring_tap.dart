// ============================================================================
// Velvet · SpringTap · v25 · UI02
// ----------------------------------------------------------------------------
// 通用 spring wrapper · 任何 child 包起来就有"按下弹性 + release 回弹"效果。
// Stripe / Linear / Superhuman 按钮质感的核心零件。
//
// 设计决策:
//   - pressedScale 0.95: 顶级品牌共识值 (Stripe 0.97 · Linear 0.96 · Raycast
//     0.95) · 大于 0.95 看不出反馈 · 小于 0.9 像卡顿 · 0.95 是"被按实了"的刚好。
//   - duration 120ms: 超过 150ms 拖沓 · 低于 100ms 来不及看清 spring · 120ms
//     是 iOS 系统 scale 按钮默认值。
//   - Curves.easeOutBack: 相比 elasticOut 更克制 · Velvet 要"优雅回弹"不要
//     "橡胶球反弹" · easeOutBack 轻微 overshoot ~10% 后归位。
//   - haptic 同步在 onTapDown 不在 onTap: 回弹已开始 haptic 先响 = 手脑同步。
//   - glow 可选: ambient pulse 用 GlowPulse 专门 widget · SpringTap 的 glow
//     只是 tap 瞬间 burst · 解耦两种动画语义。
//
// dispose 顺序铁律 (A1 教训):
//   1. _ctrl.stop()   — 停掉任何未完成 tween
//   2. _ctrl.dispose() — 真正释放 ticker
//   顺序反了 · ticker 仍在推进 · dispose 抛 "used after disposed"。
// ============================================================================

import 'dart:async' show unawaited;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:velvet/shared/services/haptic_service.dart';
import 'package:velvet/shared/theme/design_tokens.dart';

/// Spring tap wrapper · 任何可交互 child 的标准反馈层。
///
/// 用法:
/// ```dart
/// SpringTap(
///   onTap: () => print('tapped'),
///   glow: true, // 可选金色 burst
///   child: const SomeButton(),
/// )
/// ```
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutBack,
    this.haptic = true,
    this.glow = false,
    this.behavior = HitTestBehavior.opaque,
  }) : assert(
          pressedScale > 0 && pressedScale <= 1,
          'pressedScale must be in (0, 1]',
        );

  /// 被包的内容 widget。
  final Widget child;

  /// tap 回调 · null 时仍会播动画但不触发 haptic 成功事件。
  final VoidCallback? onTap;

  /// 按下时的 scale 目标 · 默认 0.95。
  final double pressedScale;

  /// 前进 / 回弹动画时长 · 默认 120ms。
  final Duration duration;

  /// 动画曲线 · 默认 easeOutBack (克制回弹)。
  final Curve curve;

  /// tap 时触发 light haptic · 默认 true。
  final bool haptic;

  /// tap 时播金色 glow burst · 默认 false。
  final bool glow;

  /// GestureDetector hit test 行为 · 默认 opaque · 让透明区域也可点。
  final HitTestBehavior behavior;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pressCurve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _pressCurve = CurvedAnimation(
      parent: _ctrl,
      curve: widget.curve,
      reverseCurve: widget.curve,
    );
  }

  @override
  void dispose() {
    // A1 铁律: 先 stop · 再 dispose · 避免 ticker 残留。
    _ctrl.stop();
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _ctrl.forward();
    if (widget.haptic) {
      // fire-and-forget: haptic 是副作用 · 不阻塞动画帧。
      // 静默原因: HapticService 内部已做 platform 降级 · 不会抛。
      unawaited(HapticService.instance.light());
    }
  }

  void _handleTapUp(TapUpDetails _) {
    _ctrl.reverse();
  }

  void _handleTapCancel() {
    _ctrl.reverse();
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      onTap: widget.onTap == null ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _pressCurve,
        builder: (context, child) {
          final t = _pressCurve.value.clamp(0.0, 1.0);
          final scale = lerpDouble(1.0, widget.pressedScale, t) ?? 1.0;

          Widget content = Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );

          if (widget.glow) {
            // burst 曲线: 0 → 0.3 (peak @ t=0.5) → 0
            final burst = (t <= 0.5 ? t * 2 : (1 - t) * 2) * 0.3;
            content = DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Vt.rMd),
                boxShadow: [
                  BoxShadow(
                    color: Vt.gold.withValues(alpha: burst),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: content,
            );
          }

          return content;
        },
        child: widget.child,
      ),
    );
  }
}

