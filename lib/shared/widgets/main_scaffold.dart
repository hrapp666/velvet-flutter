// ============================================================================
// MainScaffold · H5 v27 Editorial Luxury 底部导航（5 tab + 浮起金色发布钮）
// ----------------------------------------------------------------------------
// 严格对齐 H5 styles.css §2959-3094 + index.html L1178-1201：
//   - 5 tabs：⌂寻物 / ⌕寻找 / +发布(浮起 56) / ❦私语 / ◎我的
//   - 高度 72 + safe-area · bg rgba(0,0,0,.98) · blur 16 + saturate 1.4
//   - 顶部 1px gold-28% border · 顶 ::before 120×1px 金渐变发光线
//   - active：gold + glow + translateY(-3) scale(1.1) + 底部 20×2 金色短线
//   - 中央发布：56 圆 absolute top:-28 · radial 5 档金 · glowPulse 3s
//   - dot：16 圆 gold-light→gold 渐变 + glowPulse 2s
// v25-I1: Tab labels driven by l10n so locale switch is immediately visible.
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../services/haptic_service.dart';
import '../theme/design_tokens.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _paths = ['/feed', '/search', '/publish', '/chats', '/profile'];
  static const _glyphs = ['⌂', '⌕', '+', '❦', '◎'];
  static const _centerIndex = 2;
  static const _dotIndices = {3, 4};

  int _indexFromLocation(String location) {
    for (int i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);
    final l10n = AppLocalizations.of(context);

    final labels = [
      l10n?.navHome ?? '寻 物',
      l10n?.navSearch ?? '寻 找',
      l10n?.navPublish ?? '发 布',
      l10n?.navChats ?? '私 语',
      l10n?.navProfile ?? '我 的',
    ];

    final tabs = List.generate(
      _paths.length,
      (i) => _TabConfig(
        path: _paths[i],
        glyph: _glyphs[i],
        label: labels[i],
        isCenter: i == _centerIndex,
        hasDot: _dotIndices.contains(i),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: child,
      bottomNavigationBar: _VelvetTabbar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTap: (i) {
          final tab = tabs[i];
          unawaited(tab.isCenter
              ? HapticService.instance.heavy()
              : HapticService.instance.light());
          context.go(tab.path);
        },
      ),
    );
  }
}

class _TabConfig {
  final String path;
  final String glyph;
  final String label;
  final bool isCenter;
  final bool hasDot;
  const _TabConfig({
    required this.path,
    required this.glyph,
    required this.label,
    this.isCenter = false,
    this.hasDot = false,
  });
}

// ============================================================================
// VelvetTabbar · 像素级对齐 H5 styles.css .tabbar
// ============================================================================

class _VelvetTabbar extends StatelessWidget {
  final List<_TabConfig> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _VelvetTabbar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // H5 height:72 + padding env(safe-area-inset-bottom)
    const barHeight = 72.0;

    // 让中央 +发布 浮起 28px：clipBehavior:none 避免裁剪
    return SizedBox(
      height: barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主条（含 backdrop blur + bg + 顶部 hairline + inset 阴影）
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  // bg rgba(0,0,0,.98)
                  decoration: const BoxDecoration(
                    color: Color(0xFA000000),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          // 顶部 1px gold-28% border（box-shadow inset 0 -1px 0 #C9A961@10）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: const Color(0x47C9A961), // 28% gold
            ),
          ),
          // ::before 顶部 120×1px 金渐变发光线
          Positioned(
            top: -1,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 1,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x00C9A961),
                      Color(0xD9C9A961), // 85%
                      Vt.gold,
                      Color(0xD9C9A961),
                      Color(0x00C9A961),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Vt.gold.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: Vt.gold.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 5 个 tab 按钮（safe-area 上方）
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: List.generate(tabs.length, (i) {
                return Expanded(
                  child: _TabButton(
                    config: tabs[i],
                    active: i == selectedIndex,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 单 tab · 含 active 态 icon 上浮 / 缩放 / 金光 / 底部短线
// ============================================================================

class _TabButton extends StatelessWidget {
  final _TabConfig config;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.config,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (config.isCenter) {
      return _CenterPublishTab(config: config, active: active, onTap: onTap);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // icon · 21px serif · active 时金光 + translateY(-3) + scale(1.1)
                AnimatedSlide(
                  duration: Vt.normal,
                  curve: Curves.easeOutCubic,
                  offset: active ? const Offset(0, -0.143) : Offset.zero, // -3/21
                  child: AnimatedScale(
                    duration: Vt.normal,
                    curve: Curves.easeOutCubic,
                    scale: active ? 1.1 : 1.0,
                    child: AnimatedDefaultTextStyle(
                      duration: Vt.normal,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 21,
                        height: 1.0,
                        fontWeight: FontWeight.w400,
                        color: active
                            ? Vt.gold
                            : const Color(0x80B4A078), // rgba(180,160,120,.5)
                        shadows: active
                            ? [
                                Shadow(
                                    color: Vt.gold.withValues(alpha: 0.9),
                                    blurRadius: 20),
                                Shadow(
                                    color: Vt.gold.withValues(alpha: 0.5),
                                    blurRadius: 40),
                              ]
                            : null,
                      ),
                      child: Text(config.glyph),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 中文标签 · 11px ZCOOL · letter-spacing 0.22em · uppercase
                AnimatedDefaultTextStyle(
                  duration: Vt.normal,
                  style: GoogleFonts.zcoolXiaoWei(
                    fontSize: 11,
                    height: 1.0,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 11 * 0.22, // 0.22em
                    color: active
                        ? Vt.gold
                        : const Color(0x8CA08C64), // rgba(160,140,100,.55)
                    shadows: active
                        ? [
                            Shadow(
                                color: Vt.gold.withValues(alpha: 0.5),
                                blurRadius: 12),
                          ]
                        : null,
                  ),
                  child: Text(config.label),
                ),
              ],
            ),
          ),
          // active 底部 20×2 金色短线（H5 .tab.active::after）
          Positioned(
            bottom: 4,
            child: AnimatedOpacity(
              duration: Vt.normal,
              opacity: active ? 1 : 0,
              child: Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: Vt.gold,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                        color: Vt.gold.withValues(alpha: 0.6), blurRadius: 8),
                    BoxShadow(
                        color: Vt.gold.withValues(alpha: 0.4), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
          // dot · 仅 chats/profile 占位（未读时显示，目前 hasDot=true 但无数据 → 不展示）
        ],
      ),
    );
  }
}

// ============================================================================
// 中央 + 发布按钮 · 56 浮起 / radial 金 / glowPulse 3s
// ============================================================================

class _CenterPublishTab extends StatefulWidget {
  final _TabConfig config;
  final bool active;
  final VoidCallback onTap;
  const _CenterPublishTab({
    required this.config,
    required this.active,
    required this.onTap,
  });

  @override
  State<_CenterPublishTab> createState() => _CenterPublishTabState();
}

class _CenterPublishTabState extends State<_CenterPublishTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 浮起 56 圆 · top:-28（H5 absolute top:-28px）
          Positioned(
            top: -28,
            child: AnimatedScale(
              duration: Vt.fast,
              scale: _pressed ? 0.9 : 1.0,
              curve: Curves.easeOutCubic,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  // glowPulse 3s ease-in-out · t 0..1..0
                  final t = _ctrl.value;
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // radial 5 档：30% 28% center
                      gradient: const RadialGradient(
                        center: Alignment(-0.4, -0.44), // (30%-50%, 28%-50%)
                        radius: 0.95,
                        colors: [
                          Color(0xFFFDFAF2),
                          Color(0xFFEDD088),
                          Color(0xFFC9A961),
                          Color(0xFF8C7536),
                          Color(0xFF5A4820),
                        ],
                        stops: [0.0, 0.30, 0.62, 0.85, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xB3F8E6AA), // rgba(248,230,170,.7)
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Vt.gold
                              .withValues(alpha: 0.85 + 0.07 * t),
                          blurRadius: 40 + 20 * t,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Vt.gold
                              .withValues(alpha: 0.60 + 0.18 * t),
                          blurRadius: 18 + 12 * t,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Vt.gold
                              .withValues(alpha: 0.35 + 0.13 * t),
                          blurRadius: 70 + 30 * t,
                          spreadRadius: -24 + 4 * t,
                        ),
                        const BoxShadow(
                          color: Color(0xFA000000),
                          blurRadius: 36,
                          spreadRadius: -8,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.config.glyph,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 32,
                          height: 1.0,
                          fontWeight: FontWeight.w300,
                          color: Vt.bgVoid,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 标签 · margin-top:32px 让位浮起按钮
          Padding(
            padding: const EdgeInsets.only(top: 32 + 8),
            child: AnimatedDefaultTextStyle(
              duration: Vt.normal,
              style: GoogleFonts.zcoolXiaoWei(
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.w300,
                letterSpacing: 11 * 0.22,
                color: widget.active
                    ? Vt.gold
                    : const Color(0xB3C9A961), // gold-70
                shadows: widget.active
                    ? [
                        Shadow(
                            color: Vt.gold.withValues(alpha: 0.5),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Text(widget.config.label),
            ),
          ),
        ],
      ),
    );
  }
}
