// ============================================================================
// Splash · v5 Editorial Luxury · 像素级对齐 H5 #splash
// ----------------------------------------------------------------------------
// 顺序对齐 H5: 二〇二六 → ❦ ornament → VELVET → 天 鹅 绒 → diamond hairline
//             → 余 温 · 未 散 → ❦·diamond·❦ ornament-rich → 余 温 · 私 下 流 转
//             → 连 接 中 status
// 检查已有 token：有 → /feed，无 → /login（功能逻辑保留）
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/api/api_client.dart';
import 'package:velvet/core/constants/prefs_keys.dart';
import 'package:velvet/features/auth/presentation/providers/auth_provider.dart';
import 'package:velvet/features/chat/data/services/chat_socket.dart';
import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/ambient/grain_overlay.dart';
import 'package:velvet/shared/widgets/brand/velvet_glyph.dart';
import 'package:velvet/shared/widgets/motion/gyroscope_tilt.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _glyphShimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _glyphShimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2.4s 后跳转
    Timer(const Duration(milliseconds: 2400), _route);
  }

  Future<void> _route() async {
    if (!mounted) return;
    // 等 authNotifierProvider 初始化完成（内部已完整跑过 currentUser），
    // 否则 GoRouter redirect 会把还在 AsyncLoading 的状态当未登录踢回 /login。
    try {
      final user = await ref.read(authNotifierProvider.future);
      if (!mounted) return;
      if (user != null) {
        unawaited(ChatSocket.instance.connect());
        context.go('/feed');
        return;
      }
    } on AppException catch (e) {
      // 网络错误而非过期 → 本地有 token 就当登录态走 /feed,首页自己重试 currentUser
      // 否则误把临时网络抖动当登出 · 用户被反复踢到 /login
      if (e.type != AppErrorType.unauthorized) {
        final hasToken = await _hasLocalToken();
        if (!mounted) return;
        if (hasToken) {
          unawaited(ChatSocket.instance.connect());
          context.go('/feed');
          return;
        }
      }
    } on Object catch (_) {
      // 静默原因:其他未知错误降级到下方 onboarding/login 流程
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(PrefsKeys.onboardingSeenV1) ?? false;
    if (!mounted) return;
    context.go(seen ? '/login' : '/onboarding');
  }

  Future<bool> _hasLocalToken() async {
    final t = await ApiClient.getToken();
    return t != null && t.isNotEmpty;
  }

  @override
  void dispose() {
    // A1 教训: 先 stop 再 dispose · 避免 tick callback 在 dispose 后触发
    _glyphShimmer.stop();
    _glyphShimmer.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 金色 ambient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      Vt.gold.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 顶部 hairline 装饰
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 64,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Vt.gold.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 中央内容 · 顺序对齐 H5 #splash
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 二 〇 二 六 (.splash-roman, H5 line 45)
                    _FadeIn(
                      delay: 200,
                      ctrl: _ctrl,
                      child: Text(
                        '二  〇  二 六',
                        style: Vt.cnLabel.copyWith(
                          fontSize: Vt.txs,
                          letterSpacing: 6,
                          color: Vt.gold,
                          shadows: [
                            Shadow(
                              color: Vt.gold.withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 顶部 ornament: hairline · ❦ · hairline (H5 line 40-44)
                    _FadeIn(
                      delay: 350,
                      ctrl: _ctrl,
                      child: const _OrnamentRow(leafSize: 24),
                    ),
                    const SizedBox(height: 24),

                    // VelvetGlyph3D · 保留陀螺仪 + shimmer (Flutter brand mark)
                    _FadeIn(
                      delay: 500,
                      ctrl: _ctrl,
                      child: GyroscopeTilt(
                        builder: (_, tiltX, tiltY) => AnimatedBuilder(
                          animation: _glyphShimmer,
                          builder: (_, __) => VelvetGlyph3D(
                            tiltX: tiltX,
                            tiltY: tiltY,
                            glyph: VelvetGlyph(
                              size: 132,
                              shimmerProgress: _glyphShimmer.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 天 鹅 绒 (.splash-cn-mark)
                    _FadeIn(
                      delay: 1000,
                      ctrl: _ctrl,
                      child: Text(
                        '天 鹅 绒',
                        style: Vt.cnHeading.copyWith(
                          fontSize: Vt.tmd,
                          letterSpacing: 8,
                          color: Vt.gold.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 渐变细线 + 钻石 (.splash-line)
                    _FadeIn(
                      delay: 1200,
                      ctrl: _ctrl,
                      child: const _DiamondHairline(),
                    ),
                    const SizedBox(height: 24),

                    // 余 温 · 未 散 (.splash-est)
                    _FadeIn(
                      delay: 1500,
                      ctrl: _ctrl,
                      child: Text(
                        '余 温  ·  未 散',
                        style: Vt.cnBody.copyWith(
                          fontSize: Vt.tsm,
                          letterSpacing: 4,
                          color: Vt.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部 · ornament-rich + 余 温 · 私 下 流 转 + 连 接 中
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ornament-rich: ❦ — ◆ — ❦
                    _FadeIn(
                      delay: 1800,
                      ctrl: _ctrl,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _OrnamentRich(),
                      ),
                    ),
                    // 余 温 · 私 下 流 转 (.splash-cn)
                    _FadeIn(
                      delay: 2000,
                      ctrl: _ctrl,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '余 温   ·   私 下 流 转',
                          style: Vt.cnHeading.copyWith(
                            fontSize: Vt.tmd,
                            letterSpacing: 5,
                            color: Vt.gold.withValues(alpha: 0.85),
                            shadows: [
                              Shadow(
                                color: Vt.gold.withValues(alpha: 0.5),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 连 接 中 (.splash-status)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        '连 接 中',
                        style: Vt.cnCaption.copyWith(
                          fontSize: 9,
                          letterSpacing: 4,
                          color: Vt.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UI12 · editorial 胶片纹理覆盖层 · 最顶层 · 默认值即安全
            const GrainOverlay(),
          ],
        ),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final int delay;
  final AnimationController ctrl;
  final Widget child;
  const _FadeIn({required this.delay, required this.ctrl, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final progress = ((ctrl.value * 2400 - delay) / 1200).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(progress);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }
}

/// hairline · ❦ · hairline (对齐 H5 .ornament + .leaf.lg)
class _OrnamentRow extends StatelessWidget {
  final double leafSize;
  const _OrnamentRow({this.leafSize = 21});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _GoldLine(width: 64),
        const SizedBox(width: 18),
        Text(
          '\u2766', // ❦
          style: TextStyle(
            fontSize: leafSize,
            color: Vt.gold,
            height: 1.0,
            shadows: [
              Shadow(color: Vt.gold.withValues(alpha: 0.55), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(width: 18),
        const _GoldLine(width: 64),
      ],
    );
  }
}

/// ❦ · ─ · ◆ · ─ · ❦ (对齐 H5 .ornament-rich)
class _OrnamentRich extends StatelessWidget {
  const _OrnamentRich();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '\u2766',
          style: TextStyle(
            fontSize: 16,
            color: Vt.gold,
            height: 1.0,
            shadows: [
              Shadow(color: Vt.gold.withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(width: 14),
        const _GoldLine(width: 48),
        const SizedBox(width: 14),
        Transform.rotate(
          angle: 0.785398, // 45deg
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Vt.gold,
              boxShadow: [
                BoxShadow(
                  color: Vt.gold.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        const _GoldLine(width: 48),
        const SizedBox(width: 14),
        // 镜像 ❦
        Transform.flip(
          flipX: true,
          child: Text(
            '\u2766',
            style: TextStyle(
              fontSize: 16,
              color: Vt.gold,
              height: 1.0,
              shadows: [
                Shadow(color: Vt.gold.withValues(alpha: 0.5), blurRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 短金色细线（gradient transparent → gold → transparent）
class _GoldLine extends StatelessWidget {
  final double width;
  const _GoldLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Vt.gold, Colors.transparent],
        ),
      ),
    );
  }
}

/// 垂直细线 + 中央钻石（对齐 H5 .splash-line + ::before）
class _DiamondHairline extends StatelessWidget {
  const _DiamondHairline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 6,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Vt.gold, Colors.transparent],
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Vt.gold,
                boxShadow: [
                  BoxShadow(
                    color: Vt.gold.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
