// ============================================================================
// MainScaffold · 5 tab 主框架（沉浸式毛玻璃底部导航）
// ============================================================================
// 视觉策略：
//   - 5 tab：发现 / 同好 / 发布 / 消息 / 我
//   - 中间发布按钮放大 + 樱花粉发光（核心 CTA）
//   - 底部毛玻璃面板（blur 18 + saturate 1.8 — Sentry 启发）
//   - 选中态：金色填充 + 微小 scale
//   - 未选中：textTertiary，hover 时 textSecondary
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/haptic_service.dart';
import '../theme/design_tokens.dart';
import 'micro/spring_tap.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _TabConfig(path: '/feed', icon: Icons.diamond_outlined, activeIcon: Icons.diamond, label: '发现'),
    _TabConfig(path: '/discover', icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: '收藏'),
    _TabConfig(path: '/publish', icon: Icons.add_rounded, activeIcon: Icons.add_rounded, label: '发布', isCenter: true),
    _TabConfig(path: '/chats', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: '私聊'),
    _TabConfig(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: '我'),
  ];

  int _indexFromLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Vt.bgPrimary,
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: Vt.glassBlur, sigmaY: Vt.glassBlur),
          child: Container(
            height: 70 + padding.bottom,
            padding: EdgeInsets.only(bottom: padding.bottom),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Vt.bgPrimary.withValues(alpha: 0.7),
                  Vt.bgVoid.withValues(alpha: 0.95),
                ],
              ),
              border: Border(
                top: BorderSide(color: Vt.borderHairline, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == selectedIndex;
                if (tab.isCenter) {
                  return _CenterPublishButton(
                    onTap: () {
                      unawaited(HapticService.instance.heavy());
                      context.go(tab.path);
                    },
                  );
                }
                return _NavItem(
                  config: tab,
                  selected: selected,
                  onTap: () {
                    unawaited(HapticService.instance.light());
                    context.go(tab.path);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
  const _TabConfig({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}

class _NavItem extends StatelessWidget {
  final _TabConfig config;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Vt.fast,
              child: Icon(
                selected ? config.activeIcon : config.icon,
                size: selected ? 24 : 22,
                color: selected ? Vt.gold : Vt.textTertiary,
                shadows: selected
                    ? [
                        Shadow(
                          color: Vt.gold.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Vt.fast,
              style: Vt.label.copyWith(
                fontSize: 9,
                color: selected ? Vt.textPrimary : Vt.textTertiary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.4,
              ),
              child: Text(config.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中央发布按钮 — 樱花粉发光球，比其他 tab 大
class _CenterPublishButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterPublishButton({required this.onTap});

  @override
  State<_CenterPublishButton> createState() => _CenterPublishButtonState();
}

class _CenterPublishButtonState extends State<_CenterPublishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: widget.onTap,
      pressedScale: 0.9, // 中心发布按钮 · 稍强反馈
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final glow = 0.45 + 0.15 * _ctrl.value;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Vt.goldLight, Vt.gold, Vt.goldDark],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Vt.gold.withValues(alpha: glow),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Vt.gold.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
