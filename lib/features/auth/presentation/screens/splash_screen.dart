// ============================================================================
// Splash · v13 复刻 H5 editorial luxury 风格
// ----------------------------------------------------------------------------
// VELVET 大金 logo + "天 鹅 绒" 中文副标 + "余 温 · 私 下 流 转"
// 顶部 hairline + 底部 hairline + inset vignette
// 检查已有 token：有 → /feed，无 → /login
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/api/api_client.dart';
import 'package:velvet/core/constants/prefs_keys.dart';
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
    final token = await ApiClient.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      // 启动 WebSocket
      ChatSocket.instance.connect();
      context.go('/feed');
      return;
    }
    // 没登录 · 检查是否看过 onboarding
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(PrefsKeys.onboardingSeenV1) ?? false;
    if (!mounted) return;
    if (!seen) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
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
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      Color(0x29C9A961), // gold @ 16%
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66C9A961),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 中央内容
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // EST · MMXXVI
                  _FadeIn(
                    delay: 300,
                    ctrl: _ctrl,
                    child: Text(
                      'EST · MMXXVI',
                      style: Vt.label.copyWith(
                        color: Vt.gold,
                        letterSpacing: 6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // VelvetGlyph3D · 陀螺仪驱动 3D tilt · shimmer 由 _glyphShimmer 驱动
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
                            size: 140,
                            shimmerProgress: _glyphShimmer.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 天 鹅 绒
                  _FadeIn(
                    delay: 1000,
                    ctrl: _ctrl,
                    child: Text(
                      '天   鹅   绒',
                      style: Vt.cnDisplay.copyWith(
                        fontSize: Vt.tmd,
                        letterSpacing: 8,
                        color: Vt.gold.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 渐变细线 + 钻石
                  _FadeIn(
                    delay: 1200,
                    ctrl: _ctrl,
                    child: SizedBox(
                      width: 1,
                      height: 72,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Vt.gold,
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Vt.gold,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x99C9A961),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SOME WARMTH · STILL LINGERS
                  _FadeIn(
                    delay: 1500,
                    ctrl: _ctrl,
                    child: Text(
                      'SOME WARMTH · STILL LINGERS',
                      style: Vt.label.copyWith(
                        color: Vt.textSecondary,
                        letterSpacing: 2.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 底部 · 余 温 · 私 下 流 转
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: _FadeIn(
                delay: 2000,
                ctrl: _ctrl,
                child: Center(
                  child: Text(
                    '余   温   ·   私   下   流   转',
                    style: Vt.cnHeading.copyWith(
                      fontSize: Vt.tsm,
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
            ),

            // 底部 status text
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'CONNECTING',
                  style: Vt.caption.copyWith(
                    fontSize: Vt.t2xs,
                    color: Vt.textTertiary,
                    letterSpacing: 2,
                  ),
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
