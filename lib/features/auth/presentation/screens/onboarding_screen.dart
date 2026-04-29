// ============================================================================
// Onboarding · 引导三屏（v25 · PRIVÉ · DÉRIVE · NUIT）
// ----------------------------------------------------------------------------
// 编辑部级 editorial：罗马数字 + 法文单大字 + 中文瘦金体副标 + 极窄 hairline
// 调性：安静、克制、夜里、只给一个人看
// 路由：splash → 首次未看过 → onboarding → 看完标记 onboarding_seen → login
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:velvet/core/constants/prefs_keys.dart';
import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/brand/velvet_glyph.dart';
import 'package:velvet/shared/widgets/micro/spring_tap.dart';

/// Re-export for test backward-compat
const String kOnboardingSeenKey = PrefsKeys.onboardingSeenV1;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _bgCtrl;
  int _page = 0;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      roman: 'I',
      display: 'PRIVÉ',
      cn: '私 藏',
      eyebrow: 'WHAT LINGERS',
      body: '那些被你摩挲过的故事 ·\n柜底的光 · 抽屉里的温度 ·\n先留给你自己。',
    ),
    _Slide(
      roman: 'II',
      display: 'DÉRIVE',
      cn: '流 转',
      eyebrow: 'LET IT DRIFT',
      body: '挂出它 · 不是卖 · 是让它\n在夜里 · 自己找到\n懂的人。',
    ),
    _Slide(
      roman: 'III',
      display: 'NUIT',
      cn: '夜 里',
      eyebrow: 'THE SAME NIGHT',
      body: '不喧哗 · 不比价 ·\n懂的人会在同一个夜里 ·\n安静地找到你。',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Pre-mortem #1: 先停动画再 dispose · 避免 tick callback 在 dispose 后触发
    _bgCtrl.stop();
    _bgCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndGo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.onboardingSeenV1, true);
    if (!mounted) return;
    context.go('/login');
  }

  bool _animating = false;

  Future<void> _nextOrFinish() async {
    // Pre-mortem #2 + reviewer feedback: 锁要在所有分支前 set · 包括 last page
    if (_animating) return;
    _animating = true;
    try {
      if (_page >= _slides.length - 1) {
        await _markSeenAndGo();
      } else {
        await _controller.nextPage(
          duration: Vt.slow,
          curve: Vt.curveCinematic,
        );
      }
    } finally {
      if (mounted) _animating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景 · 慢速呼吸的 velvet ambient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.4,
                colors: Vt.gradientAmbient,
              ),
            ),
          ),
          _BreathingGoldHalo(ctrl: _bgCtrl),

          // 顶部 · EST · SKIP
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
              child: Column(
                children: [
                  const SizedBox(height: Vt.s8),
                  Row(
                    children: [
                      Text(
                        'EST · MMXXVI',
                        style: Vt.label.copyWith(
                          color: Vt.textTertiary,
                          letterSpacing: 4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Spacer(),
                      _SkipButton(onTap: () => unawaited(_markSeenAndGo())),
                    ],
                  ),
                  const SizedBox(height: Vt.s16),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => _SlideView(
                        slide: _slides[i],
                        active: i == _page,
                      ),
                    ),
                  ),
                  _PageIndicator(count: _slides.length, current: _page),
                  const SizedBox(height: Vt.s32),
                  _PrimaryCta(
                    label: isLast ? '开始 · BEGIN' : '继续 · NEXT',
                    onTap: () => unawaited(_nextOrFinish()),
                  ),
                  const SizedBox(height: Vt.s16),
                  Text(
                    'TOUCH   WHAT   WAS   TOUCHED',
                    style: Vt.label.copyWith(
                      color: Vt.textTertiary,
                      letterSpacing: 3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: Vt.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Slide 数据
// ─────────────────────────────────────────────────────────────────

class _Slide {
  final String roman;
  final String display;
  final String cn;
  final String eyebrow;
  final String body;
  const _Slide({
    required this.roman,
    required this.display,
    required this.cn,
    required this.eyebrow,
    required this.body,
  });
}

// ─────────────────────────────────────────────────────────────────
// Slide 视图 · 罗马数字 / 法文大字 / 中文副标 / body
// ─────────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final bool active;
  const _SlideView({required this.slide, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.35,
      duration: Vt.normal,
      curve: Vt.curveDefault,
      // 包 SingleChildScrollView 防止 small device / VelvetGlyph 加入后溢出
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: Vt.s32, bottom: Vt.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一屏品牌出现仪式 · 仅 roman='I' 出现 VelvetGlyph
              if (slide.roman == 'I') ...[
                const SizedBox(height: Vt.s4),
                const Center(child: VelvetGlyph(size: 48)),
                const SizedBox(height: Vt.s16),
              ],
              // 罗马数字 · 金色细边
              Text(
                slide.roman,
                style: Vt.displayHero.copyWith(
                  fontSize: Vt.tlg,
                  color: Vt.gold,
                  letterSpacing: 6,
                  fontStyle: FontStyle.italic,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: Vt.s8),
              // 金色短 hairline
              const _GoldHairline(width: 48),
              const SizedBox(height: Vt.s32),
              // Eyebrow 小英文
              Text(
                slide.eyebrow,
                style: Vt.label.copyWith(
                  color: Vt.textSecondary,
                  letterSpacing: 4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: Vt.s16),
              // 法文大字 · gold gradient shader
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Vt.gradientGoldLogo,
                  stops: Vt.gradientGoldLogoStops,
                ).createShader(rect),
                child: Text(
                  slide.display,
                  style: Vt.displayHero.copyWith(
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Vt.shadowGold40, blurRadius: 48),
                      Shadow(color: Vt.shadowGold25, blurRadius: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Vt.s16),
              // 中文副标
              Text(
                slide.cn,
                style: Vt.cnDisplay.copyWith(
                  fontSize: Vt.tlg,
                  letterSpacing: 8,
                  color: Vt.gold.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: Vt.s40),
              // Body
              Text(
                slide.body,
                style: Vt.bodyLg.copyWith(
                  color: Vt.textSecondary,
                  height: 1.9,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 背景金色呼吸光晕
// ─────────────────────────────────────────────────────────────────

class _BreathingGoldHalo extends StatelessWidget {
  final AnimationController ctrl;
  const _BreathingGoldHalo({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final eased = Curves.easeInOut.transform(ctrl.value);
        final opacity = 0.08 + 0.10 * eased;
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.9,
                  colors: [
                    Vt.gold.withValues(alpha: opacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Skip 按钮
// ─────────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Vt.s12,
          vertical: Vt.s8,
        ),
        child: Text(
          'SKIP',
          style: Vt.label.copyWith(
            color: Vt.textTertiary,
            letterSpacing: 3,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 分页指示器 · 3 个 hairline · 当前档填金
// ─────────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: Vt.normal,
          curve: Vt.curveDefault,
          margin: const EdgeInsets.symmetric(horizontal: Vt.s6),
          width: isActive ? 32 : 12,
          height: 1,
          decoration: BoxDecoration(
            color: isActive ? Vt.gold : Vt.borderMedium,
            boxShadow: isActive ? const [Vt.shadowGoldHairline] : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 金色 hairline
// ─────────────────────────────────────────────────────────────────

class _GoldHairline extends StatelessWidget {
  final double width;
  const _GoldHairline({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Vt.gold, Colors.transparent],
        ),
        boxShadow: [Vt.shadowGoldLine],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 主 CTA
// ─────────────────────────────────────────────────────────────────

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // v5 editorial: 0 圆角 + 1px gold border + gold→ivory 渐变光晕（对齐 login CTA）
    return SpringTap(
      onTap: onTap,
      glow: true,
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Vt.gold.withValues(alpha: 0.06),
          border: Border.all(color: Vt.gold),
          boxShadow: [
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.35),
              blurRadius: 32,
              spreadRadius: -8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Vt.button.copyWith(
            color: Vt.gold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
