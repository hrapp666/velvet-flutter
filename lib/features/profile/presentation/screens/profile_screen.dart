// ============================================================================
// ProfileScreen · v13 复刻 H5 + 真接 currentUserProvider
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/theme/locale_provider.dart';
import '../../../../shared/theme/theme_provider.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../safety/safety_dialogs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.paddingOf(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Stack(
          children: [
            // 金色 ambient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 0.9,
                      colors: [
                        Vt.gold.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 顶部 hairline
            Positioned(
              top: padding.top + 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
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
                        color: Vt.gold.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: switch (userAsync) {
                AsyncData(:final value) when value != null =>
                  _ProfileBody(user: value),
                AsyncData() => const _ProfileEmpty(),
                AsyncError(:final error) => _ProfileError(error.toString()),
                _ => const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Vt.gold,
                      ),
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserProfile user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 80, 36, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // MEMBER 标签
          Text(
            'MEMBER',
            style: Vt.label.copyWith(
              color: Vt.gold,
              letterSpacing: 5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // 大金色昵称
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Vt.gradientGold4,
            ).createShader(rect),
            child: Text(
              user.nickname,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Vt.displayMd.copyWith(
                fontSize: Vt.t2xl,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
                color: Colors.white,
                height: 1,
                shadows: const [
                  Shadow(
                    color: Color(0x55C9A961),
                    blurRadius: 32,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // @username
          Text(
            '@${user.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Vt.label.copyWith(
              color: Vt.textSecondary,
              letterSpacing: 2,
            ),
          ),
          if (user.isMerchant) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Vt.gold.withValues(alpha: 0.1),
                border: Border.all(color: Vt.gold),
              ),
              child: Text(
                '✦ 认 证 商 家',
                style: Vt.label.copyWith(
                  color: Vt.gold,
                  fontSize: Vt.t2xs,
                  letterSpacing: 2,
                ),
              ),
            ),
          ] else if (user.merchantStatus == 'PENDING') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Vt.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                '认 证 审 核 中',
                style: Vt.label.copyWith(
                  color: Vt.gold.withValues(alpha: 0.7),
                  fontSize: Vt.t2xs,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // 钻石装饰线
          SizedBox(
            width: 56,
            height: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: Vt.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              user.bio?.isNotEmpty == true
                  ? user.bio!
                  : '私 藏 · 流 转 · 懂 的 人 来',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Vt.cnBody.copyWith(
                color: Vt.textSecondary,
                letterSpacing: 2,
                fontStyle: FontStyle.italic,
                height: 1.85,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // 三栏数据
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.2)),
                bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  num: user.momentsCount.toString(),
                  label: 'PIECES',
                ),
                _StatItem(
                  num: user.followersCount.toString(),
                  label: 'FOLLOWERS',
                ),
                _StatItem(
                  num: user.followingCount.toString(),
                  label: 'FOLLOWING',
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // 我的订单（v22）
          _GoldBtn(
            label: '我  的  订  单',
            onTap: () => context.push('/orders'),
          ),
          const SizedBox(height: 16),

          // 我的钱包（v22）
          _GoldBtn(
            label: '我  的  钱  包',
            onTap: () => context.push('/wallet'),
          ),
          const SizedBox(height: 16),

          // 商家认证（v22）
          _GoldBtn(
            label: '商  家  认  证',
            onTap: () => context.push('/merchant/apply'),
          ),
          const SizedBox(height: 16),

          // 我的收藏（v22）
          _GoldBtn(
            label: '我  的  收  藏',
            onTap: () => context.push('/favorites'),
          ),
          const SizedBox(height: 16),

          // 我的发布按钮
          _GoldBtn(
            label: '我  的  发  布',
            onTap: () => context.push('/user/${user.id}'),
          ),
          const SizedBox(height: 16),

          // 编辑资料按钮（次级）
          _GhostBtn(
            label: '编  辑  资  料',
            onTap: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 16),

          // 关于 Velvet
          _GhostBtn(
            label: '关  于  Velvet',
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 16),

          // Admin 面板（仅 role=ADMIN 可见）
          if (user.isAdmin) ...[
            _GoldBtn(
              label: '管  理  后  台',
              onTap: () => context.push('/admin'),
            ),
            const SizedBox(height: 16),
          ],

          // 外观切换
          _AppearanceSection(ref: ref),
          const SizedBox(height: 24),

          // 语言切换 (v25 · I1)
          _LanguageSection(ref: ref),
          const SizedBox(height: 16),

          // 注销账号（Apple 5.1.1(v) 合规）
          _GhostBtn(
            label: '注  销  账  号',
            onTap: () async {
              final ok = await showDeleteAccountDialog(context, ref);
              if (!ok) return;
              await ref.read(authNotifierProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
          const SizedBox(height: 16),

          // 退出登录
          _GhostBtn(
            label: '退  出  登  录',
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String num;
  final String label;
  const _StatItem({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num,
          style: Vt.displayMd.copyWith(
            fontSize: Vt.t2xl,
            fontWeight: FontWeight.w500,
            color: Vt.gold,
            letterSpacing: -0.3,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Vt.label.copyWith(
            color: Vt.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      glow: true,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Vt.gold.withValues(alpha: 0.06),
          border: Border.all(color: Vt.gold),
          boxShadow: [
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Vt.cnButton.copyWith(
              fontSize: Vt.tmd,
              letterSpacing: 6,
              color: Vt.gold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Vt.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Vt.cnButton.copyWith(
              fontSize: Vt.tsm,
              letterSpacing: 5,
              color: Vt.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEmpty extends StatelessWidget {
  const _ProfileEmpty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '— 请 先 登 录 —',
            style: Vt.cnHeading.copyWith(
              fontSize: Vt.tmd,
              letterSpacing: 6,
              color: Vt.gold,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => GoRouter.of(context).go('/login'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Vt.gold),
              ),
              child: Text(
                '前  往  登  录',
                style: Vt.cnButton.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String error;
  const _ProfileError(this.error);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 32, color: Vt.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              '— 加 载 失 败 —',
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tsm,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Vt.bodySm.copyWith(color: Vt.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 外观切换区（v25 · C2）
// ----------------------------------------------------------------------------
// 三档：暗黑 / 明亮 / 跟随系统
// hairline 分隔 + cnHeading 标题风格
// ============================================================================

class _AppearanceSection extends StatelessWidget {
  final WidgetRef ref;
  const _AppearanceSection({required this.ref});

  static const _options = [
    (mode: ThemeMode.dark, label: '暗  黑'),
    (mode: ThemeMode.light, label: '明  亮'),
    (mode: ThemeMode.system, label: '跟随系统'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // hairline 分隔
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Vt.gold.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 标题
        Center(
          child: Text(
            'A P P E A R A N C E',
            style: Vt.label.copyWith(
              color: Vt.gold,
              letterSpacing: 5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 三档选项
        Row(
          children: _options.map((opt) {
            final selected = current == opt.mode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  unawaited(HapticService.instance.medium());
                  ref.read(themeProvider.notifier).setMode(opt.mode);
                },
                child: AnimatedContainer(
                  duration: Vt.fast,
                  curve: Vt.curveDefault,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: Vt.s4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Vt.gold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? Vt.gold
                          : Vt.gold.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt.label,
                      style: Vt.label.copyWith(
                        color: selected ? Vt.gold : Vt.textTertiary,
                        fontSize: Vt.txs,
                        letterSpacing: selected ? 3 : 2,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // hairline 分隔
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Vt.gold.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 语言切换区 (v25 · I1)
// ----------------------------------------------------------------------------
// 三档:跟随系统 / English / 中文
// ============================================================================

class _LanguageSection extends StatelessWidget {
  final WidgetRef ref;
  const _LanguageSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    final options = <({Locale? locale, String label})>[
      (locale: null, label: l10n?.languageSystem ?? '跟 随'),
      (locale: const Locale('en'), label: l10n?.languageEnglish ?? 'ENGLISH'),
      (locale: const Locale('zh'), label: l10n?.languageChinese ?? '中 文'),
    ];
    final title = l10n?.languageSectionTitle ?? 'L A N G U A G E';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Vt.gold.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            title,
            style: Vt.label.copyWith(
              color: Vt.gold,
              letterSpacing: 5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: options.map((opt) {
            final selected =
                current?.languageCode == opt.locale?.languageCode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  unawaited(HapticService.instance.medium());
                  ref.read(localeProvider.notifier).setLocale(opt.locale);
                },
                child: AnimatedContainer(
                  duration: Vt.fast,
                  curve: Vt.curveDefault,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: Vt.s4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Vt.gold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? Vt.gold
                          : Vt.gold.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt.label,
                      style: Vt.label.copyWith(
                        color: selected ? Vt.gold : Vt.textTertiary,
                        fontSize: Vt.txs,
                        letterSpacing: selected ? 3 : 2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
