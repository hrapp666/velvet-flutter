// ============================================================================
// GyroscopeTilt · v25 · UI04
// ----------------------------------------------------------------------------
// 订阅 accelerometer 事件，低通滤波平滑，把 x/y 映射到 -1~1 的 tiltX/tiltY
// 通过 builder pattern 传给子 widget（通常是 VelvetGlyph3D）。
//
// 低通滤波公式（指数移动平均 / EMA）：
//   output(t) = output(t-1) * (1 - α) + input(t) * α
//   α = smoothFactor ∈ (0, 1]
//   α 越小 = 平滑越强 = 响应越迟；α 越大 = 响应越快 = 抖动越多。
//   默认 α=0.15 → ~6.7 帧滞后（60fps 约 112ms 延迟），人眼感知顺滑。
//
// 为什么用 accelerometer 而不是 gyroscope:
//   - accelerometerEventStream 返回设备在重力参考系中的分量，
//     物理量含义是"手机当前相对水平的倾斜程度"（静止时 = 重力方向）。
//   - gyroscope 返回角速度（rad/s），需要积分才能得到角度，且有漂移。
//   - splash 场景要的是"手机歪了多少角"，不是"转了多快" → accelerometer 直接对位。
//
// 为什么 sensors_plus 而不是 sensors:
//   - `sensors` 包已停止维护（pub 最后更新 2019）。
//   - `sensors_plus` 是 Flutter Community 官方维护接班者，
//     API 稳定、支持 null safety、iOS/Android/Web/Desktop 全平台。
//
// 为什么 maxTilt = 0.8:
//   - VelvetGlyph3D 内部 rotateX/Y 角度 = tilt * 0.3 rad（≈ 17°）。
//   - maxTilt=0.8 → 最大旋转 0.24 rad（≈ 14°）。
//   - 视觉足够明显但不破坏 logo 可读性；>0.9 时顶部笔画被透视截断。
//
// 为什么 smoothFactor = 0.15:
//   - 实测在 60fps 设备上，EMA α=0.15 响应延迟约 100ms，
//     足够跟手但不会抖动到 V 字看不清。
//   - α<0.05 = 太迟，手机都放平了 logo 还在歪；α>0.4 = 肉眼可见颤抖。
//
// 为什么 builder pattern:
//   - GyroscopeTilt 不关心内部渲染，只产生两个 double。
//   - builder 让 caller 完全自由组合（可以加 AnimatedBuilder、shimmer 等）。
//   - 避免在传感器 widget 内硬编码 VelvetGlyph3D，保持单一职责。
// ============================================================================

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 加速计驱动的 3D tilt builder。
///
/// 订阅 [accelerometerEventStream] → 低通滤波 → 输出 tiltX/tiltY ∈ [-maxTilt, maxTilt]。
/// 在 [dispose] 时自动取消订阅，防止 memory leak。
class GyroscopeTilt extends StatefulWidget {
  const GyroscopeTilt({
    super.key,
    required this.builder,
    this.smoothFactor = 0.15,
    this.maxTilt = 0.8,
    this.autoStart = true,
  })  : assert(
          smoothFactor > 0 && smoothFactor <= 1,
          'smoothFactor must be in (0, 1]',
        ),
        assert(maxTilt > 0 && maxTilt <= 1, 'maxTilt must be in (0, 1]');

  /// 子 widget 构建函数，接收 tiltX / tiltY ∈ [-maxTilt, maxTilt]。
  final Widget Function(BuildContext context, double tiltX, double tiltY)
      builder;

  /// 低通滤波系数 α ∈ (0, 1]。越小越平滑，默认 0.15。
  final double smoothFactor;

  /// tiltX / tiltY 的最大绝对值，默认 0.8。
  final double maxTilt;

  /// 是否在 [initState] 时自动订阅传感器，默认 true。
  /// 设为 false 可用于测试或延迟启动。
  final bool autoStart;

  @override
  State<GyroscopeTilt> createState() => _GyroscopeTiltState();
}

class _GyroscopeTiltState extends State<GyroscopeTilt> {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _start();
  }

  void _start() {
    _sub = accelerometerEventStream().listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted) return;
    // accelerometer x/y 单位 m/s²；静止平放时 ≈ 0；垂直立起时 ≈ ±9.8
    // 除以 10 → 大致 normalize 到 ±1（稍微宽一点，让极端倾角也能达到 maxTilt）
    final rawX = (event.x / 10.0).clamp(-1.0, 1.0);
    final rawY = (event.y / 10.0).clamp(-1.0, 1.0);
    // 低通滤波：output = output * (1 - α) + input * α
    final alpha = widget.smoothFactor;
    setState(() {
      _tiltX = _tiltX * (1 - alpha) + rawX * alpha;
      _tiltY = _tiltY * (1 - alpha) + rawY * alpha;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedX = _tiltX.clamp(-widget.maxTilt, widget.maxTilt);
    final clampedY = _tiltY.clamp(-widget.maxTilt, widget.maxTilt);
    return widget.builder(context, clampedX, clampedY);
  }
}
