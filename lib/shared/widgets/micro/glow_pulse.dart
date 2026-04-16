// ============================================================================
// Velvet · GlowPulse · v25 · UI02
// ----------------------------------------------------------------------------
// 持续 pulse 的金色光晕 · ambient 反馈专用。
// 用于:
//   - 新消息 dot (chat list 未读指示)
//   - "连接中" 状态 (websocket online)
//   - 精选 / 限时标签的微光呼吸
//
// 设计决策:
//   - 自包含 AnimationController (不像 VelvetGlyph 把 progress 外抛) · 因为
//     pulse 是无限循环 · caller 外抛反而污染。caller 只负责"要不要显示"。
//   - period 2s: 呼吸频率 · 跟 iOS 通知指示灯一致 · 不抢眼。
//   - maxOpacity 0.35 / maxBlur 16: Velvet 克制风格 · 远低于 neon 水平 ·
//     目的是"似有若无的存在感" · 不是"炫技发光"。
//   - 曲线走 sin(pi * t) 实现"进 → 出"对称 · 避免线性 tween 的生硬切断。
//   - 单 ticker 轻量 · 一个页面同时几十个 GlowPulse 也不卡。
//
// dispose 顺序: stop → dispose (A1 铁律)。
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';

/// 持续 pulse 的金色光晕 wrapper。
///
/// 用法:
/// ```dart
/// GlowPulse(
///   child: UnreadDot(),
/// )
/// ```
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.color,
    this.maxOpacity = 0.35,
    this.period = const Duration(seconds: 2),
    this.maxBlur = 16,
    this.enabled = true,
  })  : assert(maxOpacity >= 0 && maxOpacity <= 1),
        assert(maxBlur >= 0);

  /// 包的内容。
  final Widget child;

  /// 发光色 · null 时用 [Vt.gold]。
  final Color? color;

  /// 峰值透明度 · 默认 0.35 (克制)。
  final double maxOpacity;

  /// 一次完整 pulse 周期 · 默认 2s。
  final Duration period;

  /// 峰值模糊半径 · 默认 16。
  final double maxBlur;

  /// 关闭时 pulse 静止 · child 仍渲染 · 适合按状态开关。
  final bool enabled;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    if (widget.enabled) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlowPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _ctrl.duration = widget.period;
      if (_ctrl.isAnimating) {
        _ctrl
          ..stop()
          ..repeat();
      }
    }
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _ctrl.repeat();
      } else {
        _ctrl
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    // A1 铁律: 先 stop · 再 dispose。
    _ctrl.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Vt.gold;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // sin 波: 0 → 1 → 0 · 比线性更柔。
        final eased = math.sin(_ctrl.value * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: eased * widget.maxOpacity),
                blurRadius: eased * widget.maxBlur,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
