// ============================================================================
// ProfileScreen · v5 Editorial Luxury (TASCHEN/Hermès 黑金 0 圆角)
// 对照 H5 #profile (h5-demo/index.html line 291-355 + styles.css line 2669-2896)
// 视觉锚点：
//   - 顶 header (VELVET · 我 的 · 返回) 1px hairline
//   - ❦ ornament 横线包裹
//   - 头像 84x84 圆 + conic gold ring（Flutter 简化为静态金环）
//   - 会 员 italic gold label
//   - 巨大金色 ShaderMask 昵称 (clamp 36-52px) + @handle underline
//   - ornament-rich 双叶分隔
//   - 居中 italic bio
//   - 3 stats with 中线分隔
//   - editorial 行式菜单：每行 ›gold arrow + 1px hairline 分隔
//   - logout 居中 ash 字
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/theme/locale_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../safety/safety_dialogs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 顶部金色 ambient 沉底
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.7),
                    radius: 1.0,
                    colors: [
                      Vt.gold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const _ProfileHeader(),
                Expanded(
                  child: switch (userAsync) {
                    AsyncData(:final value) when value != null =>
                      _ProfileBody(user: value),
                    AsyncData() => const _ProfileEmpty(),
                    AsyncError(:final error) =>
                      _ProfileError(userMessageOf(error, fallback: '加载失败')),
                    _ => const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            color: Vt.gold,
                          ),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 顶 Header · VELVET · 我 的 · spacer · 返回
// ============================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.32), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s20, Vt.s24, Vt.s16),
      child: Row(
        children: [
          Text(
            'VELVET',
            style: GoogleFontsLogo.cormorant(
              fontSize: Vt.tlg,
              letterSpacing: 6,
              color: Vt.textPrimary,
            ),
          ),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 14, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text(
            '我 的',
            style: Vt.cnLabel.copyWith(
              fontSize: Vt.tsm,
              letterSpacing: 0.5,
              color: Vt.textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Vt.s4, vertical: Vt.s4),
              child: Text(
                '返 回',
                style: Vt.cnLabel.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: 0.5,
                  color: Vt.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 兼容老调用：不引入新 import，复用 Vt 字体生成器
class GoogleFontsLogo {
  GoogleFontsLogo._();
  static TextStyle cormorant({
    required double fontSize,
    required double letterSpacing,
    required Color color,
  }) =>
      Vt.displayMd.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacing,
        color: color,
        height: 1,
      );
}

// ============================================================================
// 主体
// ============================================================================

class _ProfileBody extends ConsumerWidget {
  final UserProfile user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, Vt.s64, 0, Vt.s120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ❦ ornament 短线 + 大叶子 + 短线
          const _Ornament(short: true),
          const SizedBox(height: Vt.s24),

          // 头像
          const Center(child: _AvatarRing(letter: 'V')),
          const SizedBox(height: Vt.s20),

          // 会 员（H5 .profile-roman = 中文衬线 letter-spacing 0.4em）
          Center(
            child: Text(
              '会 员',
              style: Vt.cnLabel.copyWith(
                color: Vt.gold,
                letterSpacing: Vt.tsm * 0.4,
                fontSize: Vt.tsm,
              ),
            ),
          ),
          const SizedBox(height: Vt.s12),

          // 大金昵称
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Vt.goldIvory,
                  Vt.goldHighlight,
                  Vt.gold,
                  Vt.goldDark,
                ],
                stops: [0.0, 0.22, 0.55, 1.0],
              ).createShader(rect),
              child: Text(
                user.nickname,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Vt.displayMd.copyWith(
                  fontSize: Vt.t2xl,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Colors.white,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Vt.gold.withValues(alpha: 0.45),
                      blurRadius: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Vt.s12),

          // @handle with underline
          Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Vt.gold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                '@${user.username}',
                style: Vt.label.copyWith(
                  color: Vt.gold.withValues(alpha: 0.75),
                  letterSpacing: 1,
                  fontSize: Vt.tsm,
                ),
              ),
            ),
          ),

          // 商家认证状态徽章（保留业务逻辑）
          if (user.isMerchant) ...[
            const SizedBox(height: Vt.s16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Vt.s12, vertical: Vt.s4),
                decoration: BoxDecoration(
                  color: Vt.gold.withValues(alpha: 0.08),
                  border: Border.all(color: Vt.gold),
                ),
                child: Text(
                  '认 证 商 家',
                  style: Vt.cnLabel.copyWith(
                    color: Vt.gold,
                    fontSize: Vt.tsm,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ] else if (user.merchantStatus == 'PENDING') ...[
            const SizedBox(height: Vt.s16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Vt.s12, vertical: Vt.s4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Vt.gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '认 证 审 核 中',
                  style: Vt.cnLabel.copyWith(
                    color: Vt.gold.withValues(alpha: 0.7),
                    fontSize: Vt.tsm,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: Vt.s32),

          // ornament-rich：leaf · ln · diamond · ln · leaf
          const _OrnamentRich(),
          const SizedBox(height: Vt.s24),

          // bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s40),
            child: Text(
              user.bio?.isNotEmpty == true
                  ? user.bio!
                  : '私 藏 · 流 转 · 懂 的 人 来',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Vt.cnBody.copyWith(
                color: Vt.textPrimary.withValues(alpha: 0.85),
                letterSpacing: 0.3,
                fontStyle: FontStyle.italic,
                height: 1.95,
              ),
            ),
          ),
          const SizedBox(height: Vt.s48),

          // 3 stats · 上下 hairline + 中线
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Vt.s32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.0,
                  colors: [
                    Vt.gold.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
                border: Border(
                  top: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
                  bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _StatCol(
                          value: user.momentsCount.toString(), label: '发 布'),
                    ),
                    _VStatDivider(),
                    Expanded(
                      child: _StatCol(
                          value: user.followersCount.toString(),
                          label: '粉 丝'),
                    ),
                    _VStatDivider(),
                    Expanded(
                      child: _StatCol(
                          value: user.followingCount.toString(),
                          label: '关 注'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Vt.s48),

          // editorial 菜单列表
          _EditorialMenuItem(
            label: '我 的 订 单',
            onTap: () => context.push('/orders'),
            isFirst: true,
          ),
          _EditorialMenuItem(
            label: '商 家 认 证',
            onTap: () => context.push('/merchant/apply'),
          ),
          _EditorialMenuItem(
            label: '我 的 收 藏',
            onTap: () => context.push('/favorites'),
          ),
          _EditorialMenuItem(
            label: '我 的 发 布',
            onTap: () => context.push('/user/${user.id}'),
          ),
          _EditorialMenuItem(
            label: '编 辑 资 料',
            onTap: () => context.push('/profile/edit'),
          ),
          if (user.isAdmin)
            _EditorialMenuItem(
              label: '管 理 后 台',
              onTap: () => context.push('/admin'),
              accentGold: true,
            ),
          _EditorialMenuItem(
            label: '关 于  Velvet',
            onTap: () => context.push('/about'),
          ),
          _EditorialMenuItem(
            label: '注 销 账 号',
            onTap: () async {
              final ok = await showDeleteAccountDialog(context, ref);
              if (!ok) return;
              try {
                await ref.read(authNotifierProvider.notifier).logout();
              } on Object catch (_) {
                // 静默原因:logout 内部已清 token + 断 WS · 即便后端 logout API 失败也强制跳登录
              }
              if (!context.mounted) return;
              context.go('/login');
            },
          ),

          const SizedBox(height: Vt.s32),

          // v25: Velvet 视觉系统专为黑色 void 设计 · 明亮版未完整适配 → 暂时下掉
          // 外观切换 UI（保留 themeProvider 以便未来恢复）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
            child: const _LanguageSection(),
          ),
          const SizedBox(height: Vt.s40),

          // 退 出 · 居中 ash 字 + 上 hairline
          Container(
            margin: const EdgeInsets.only(top: Vt.s24),
            padding:
                const EdgeInsets.symmetric(horizontal: Vt.s24, vertical: Vt.s24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.10)),
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(authNotifierProvider.notifier).logout();
                  } on Object catch (_) {
                    // 静默原因:logout 内部已清 token + 断 WS · 强制跳登录
                  }
                  if (!context.mounted) return;
                  context.go('/login');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Vt.s24, vertical: Vt.s12),
                  child: Text(
                    '退 出 登 录',
                    style: Vt.cnLabel.copyWith(
                      color: Vt.textTertiary,
                      letterSpacing: 0.5,
                      fontSize: Vt.tsm,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // page-fleuron · ❦ Velvet · Est. MMXXIV
          const SizedBox(height: Vt.s40),
          const _PageFleuron(caption: 'Velvet · Est. MMXXIV'),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets · ornament / avatar / stat / menu / fleuron
// ============================================================================

class _Ornament extends StatelessWidget {
  final bool short;
  const _Ornament({this.short = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: short ? 32 : 64,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Vt.gold, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(width: Vt.s20),
        Text(
          '\u2766', // ❦
          style: Vt.displayMd.copyWith(
            fontSize: Vt.txl,
            color: Vt.gold,
            height: 1,
            shadows: [
              Shadow(
                  color: Vt.gold.withValues(alpha: 0.6), blurRadius: 18),
              Shadow(
                  color: Vt.gold.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: Vt.s20),
        Container(
          width: short ? 32 : 64,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Vt.gold, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrnamentRich extends StatelessWidget {
  const _OrnamentRich();

  @override
  Widget build(BuildContext context) {
    final leaf = Text(
      '\u2766',
      style: Vt.displayMd.copyWith(
        fontSize: Vt.tmd,
        color: Vt.gold,
        height: 1,
        shadows: [
          Shadow(color: Vt.gold.withValues(alpha: 0.5), blurRadius: 16),
        ],
      ),
    );

    Widget ln() => Container(
          width: 48,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Vt.gold, Colors.transparent],
            ),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        leaf,
        const SizedBox(width: Vt.s16),
        ln(),
        const SizedBox(width: Vt.s16),
        // diamond
        Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Vt.gold,
              boxShadow: [
                BoxShadow(
                    color: Vt.gold.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: Vt.s16),
        ln(),
        const SizedBox(width: Vt.s16),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: leaf,
        ),
      ],
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final String letter;
  const _AvatarRing({required this.letter});

  @override
  Widget build(BuildContext context) {
    // H5: 100x100 wrap, 84x84 inner avatar, conic gold ring
    // Flutter 简化为静态金环 + 内圈 radial 暖金
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外金环（替代 conic-gradient）
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.85),
                  Vt.goldIvory,
                  Vt.gold.withValues(alpha: 0.85),
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.14, 0.30, 0.47, 0.64, 0.80, 1.0],
              ),
            ),
          ),
          // void inset
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Vt.bgPrimary,
            ),
          ),
          // 内圈 avatar
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [Vt.bgVoidWarm, Vt.bgVoidCool],
              ),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Vt.gold.withValues(alpha: 0.6),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Vt.goldIvory,
                    Vt.goldLight,
                    Vt.gold,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ).createShader(rect),
                child: Text(
                  letter,
                  style: Vt.displayMd.copyWith(
                    fontSize: Vt.txl,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Vt.goldIvory,
              Vt.goldHighlight,
              Vt.gold,
              Vt.goldDark,
            ],
            stops: [0.0, 0.30, 0.65, 1.0],
          ).createShader(rect),
          child: Text(
            value,
            style: Vt.displayMd.copyWith(
              fontSize: Vt.t3xl,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 0.88,
              shadows: [
                Shadow(
                    color: Vt.gold.withValues(alpha: 0.4), blurRadius: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: Vt.s8),
        Text(
          label,
          style: Vt.cnLabel.copyWith(
            color: Vt.textTertiary.withValues(alpha: 0.7),
            fontSize: Vt.txs,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _VStatDivider extends StatelessWidget {
  const _VStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: Vt.s8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Vt.gold.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// editorial 行式菜单（H5 .profile-actions .edit）
/// - 全宽水平 row · 中文 left + ›gold arrow right
/// - 上下 1px hairline border (.09 alpha)
/// - 0 圆角
class _EditorialMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool accentGold;
  const _EditorialMenuItem({
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.accentGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentGold ? Vt.gold : Vt.textPrimary.withValues(alpha: 0.85);
    return GestureDetector(
      onTap: () {
        unawaited(HapticService.instance.light());
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: isFirst
                ? BorderSide(color: Vt.gold.withValues(alpha: 0.09))
                : BorderSide.none,
            bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.09)),
          ),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: Vt.s24, vertical: Vt.s24),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Vt.cnBody.copyWith(
                  fontSize: Vt.tmd,
                  color: color,
                  letterSpacing: 0.5,
                  height: 1,
                ),
              ),
            ),
            Text(
              '\u203A', // ›
              style: TextStyle(
                fontFamily: Vt.displayMd.fontFamily,
                fontSize: Vt.txl,
                fontWeight: FontWeight.w300,
                color: Vt.gold.withValues(alpha: 0.4),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageFleuron extends StatelessWidget {
  final String caption;
  const _PageFleuron({required this.caption});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s40),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: Vt.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Vt.s12),
                child: Text(
                  '\u2766',
                  style: Vt.displayMd.copyWith(
                    fontSize: Vt.tmd,
                    color: Vt.gold,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Vt.gold.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Vt.s12),
          Text(
            caption,
            style: Vt.label.copyWith(
              fontSize: Vt.txs,
              color: Vt.textTertiary.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 空 / 错误态
// ============================================================================

class _ProfileEmpty extends StatelessWidget {
  const _ProfileEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Ornament(short: true),
          const SizedBox(height: Vt.s24),
          Text(
            '— 请 先 登 录 —',
            style: Vt.cnHeading.copyWith(
              fontSize: Vt.tmd,
              letterSpacing: 0.5,
              color: Vt.gold,
            ),
          ),
          const SizedBox(height: Vt.s24),
          GestureDetector(
            onTap: () => GoRouter.of(context).go('/login'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Vt.s32, vertical: Vt.s14),
              decoration: BoxDecoration(
                border: Border.all(color: Vt.gold),
                color: Vt.gold.withValues(alpha: 0.06),
              ),
              child: Text(
                '前 往 登 录',
                style: Vt.cnButton.copyWith(
                  fontSize: Vt.tmd,
                  letterSpacing: 0.5,
                  color: Vt.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends ConsumerWidget {
  final String error;
  const _ProfileError(this.error);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 32, color: Vt.gold.withValues(alpha: 0.6)),
            const SizedBox(height: Vt.s16),
            Text(
              '— 加 载 失 败 —',
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tmd,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Vt.s8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Vt.bodySm.copyWith(color: Vt.textTertiary),
            ),
            const SizedBox(height: Vt.s24),
            GestureDetector(
              onTap: () => ref.invalidate(currentUserProvider),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Vt.s32,
                  vertical: Vt.s12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Vt.gold),
                ),
                child: Text(
                  '重 试',
                  style: Vt.cnButton.copyWith(
                    fontSize: Vt.tmd,
                    letterSpacing: 0.5,
                    color: Vt.gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 语言切换 (v25 · C2 · I1)
// 外观切换已下掉 — Velvet 视觉系统只适配黑色 void · 明亮版回归后再恢复
// ============================================================================

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final options = <({Locale? locale, String label})>[
      (locale: null, label: l10n?.languageSystem ?? '跟 随'),
      (locale: const Locale('en'), label: l10n?.languageEnglish ?? 'ENGLISH'),
      (locale: const Locale('zh'), label: l10n?.languageChinese ?? '中 文'),
    ];
    final title = l10n?.languageSectionTitle ?? 'L A N G U A G E';

    return _SettingSection(
      title: title,
      child: Row(
        children: options.map((opt) {
          final selected =
              current?.languageCode == opt.locale?.languageCode;
          return Expanded(
            child: _SettingChip(
              label: opt.label,
              selected: selected,
              onTap: () {
                unawaited(HapticService.instance.medium());
                ref.read(localeProvider.notifier).setLocale(opt.locale);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Vt.gold.withValues(alpha: 0.30),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: Vt.s20),
        Center(
          child: Text(
            title,
            style: Vt.label.copyWith(
              color: Vt.gold,
              letterSpacing: 2,
              fontSize: Vt.txs,
            ),
          ),
        ),
        const SizedBox(height: Vt.s16),
        child,
      ],
    );
  }
}

class _SettingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SettingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Vt.fast,
        curve: Vt.curveDefault,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: Vt.s4),
        decoration: BoxDecoration(
          color: selected
              ? Vt.gold.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color:
                selected ? Vt.gold : Vt.gold.withValues(alpha: 0.22),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Vt.label.copyWith(
              color: selected ? Vt.gold : Vt.textTertiary,
              fontSize: Vt.tsm,
              letterSpacing: 0.5,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}
