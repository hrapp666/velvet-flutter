// ============================================================================
// UserPublicScreen · 看别人的主页 · v5 Editorial Luxury
// ============================================================================

import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moment/data/models/moment_model.dart';
import '../../../moment/presentation/providers/moment_provider.dart';
import '../../../safety/safety_dialogs.dart';

class UserPublicScreen extends ConsumerStatefulWidget {
  final int userId;
  const UserPublicScreen({super.key, required this.userId});

  @override
  ConsumerState<UserPublicScreen> createState() => _UserPublicScreenState();
}

class _UserPublicScreenState extends ConsumerState<UserPublicScreen> {
  UserProfile? _user;
  List<MomentModel> _moments = [];
  bool _loading = true;
  bool _following = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final userRes =
          await api.dio.get<dynamic>('/api/v1/users/public/${widget.userId}');
      final u = UserProfile.fromJson(userRes.data as Map<String, dynamic>);

      final momentsRes = await ref
          .read(momentRepositoryProvider)
          .listByUser(widget.userId, page: 0, size: 30);

      if (!mounted) return;
      setState(() {
        _user = u;
        _moments = momentsRes.content;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? '加载失败';
        _loading = false;
      });
    } on Object catch (_) {
      // 静默原因：解析/类型异常时不能让 UI 卡 loading · 给用户错误态可重试
      if (!mounted) return;
      setState(() {
        _error = '加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final res =
          await api.dio.post<dynamic>('/api/v1/users/${user.id}/follow');
      final followed =
          (res.data as Map<String, dynamic>)['followed'] as bool? ?? false;
      if (!mounted) return;
      setState(() => _following = followed);
      VelvetToast.show(context, followed ? '已 关 注' : '取 消 关 注');
    } on Object catch (e) {
      if (!mounted) return;
      VelvetToast.show(context, '失败：$e', isError: true);
    }
  }

  /// 举报 / 拉黑 菜单（Apple UGC 1.2 合规）
  Future<void> _showSafetyMenu(UserProfile user) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (sheetCtx) {
        final padding = MediaQuery.paddingOf(sheetCtx);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Vt.bgElevated.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.32)),
              ),
            ),
            padding: EdgeInsets.only(
              top: Vt.s16,
              bottom: padding.bottom + Vt.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetTile(
                  sheetCtx,
                  icon: Icons.flag_outlined,
                  label: '举 报 此 用 户',
                  value: 'report',
                ),
                _sheetTile(
                  sheetCtx,
                  icon: Icons.block_outlined,
                  label: '拉 黑 此 用 户',
                  value: 'block',
                ),
                _sheetTile(
                  sheetCtx,
                  icon: Icons.close,
                  label: '取 消',
                  value: null,
                  muted: true,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'report':
        await showReportDialog(
          context,
          ref,
          targetType: ReportTargetType.user,
          targetId: user.id,
        );
      case 'block':
        final blocked = await showBlockDialog(
          context,
          ref,
          userId: user.id,
          nickname: user.nickname,
        );
        if (blocked && mounted) {
          context.pop();
        }
    }
  }

  Widget _sheetTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required String label,
    required String? value,
    bool muted = false,
  }) {
    return InkWell(
      onTap: () => Navigator.of(sheetCtx).pop(value),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Vt.s24, vertical: Vt.s16),
        child: Row(
          children: [
            Icon(
              icon,
              color: muted ? Vt.textTertiary : Vt.gold,
              size: 20,
            ),
            const SizedBox(width: Vt.s16),
            Expanded(
              child: Text(
                label,
                style: Vt.cnBody.copyWith(
                  color: muted ? Vt.textTertiary : Vt.textPrimary,
                  letterSpacing: 4,
                  fontSize: Vt.tmd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Stack(
        children: [
          // Ambient 顶部金光
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
                    radius: 1.0,
                    colors: [
                      Vt.gold.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Vt.gold,
                ),
              ),
            )
          else if (_error != null)
            _ErrorView(error: _error!, onRetry: _load)
          else if (_user != null)
            _Body(
              user: _user!,
              moments: _moments,
              following: _following,
              padding: padding,
              onFollow: _toggleFollow,
              onMessage: () => VelvetToast.show(context, '可 从 具 体 动 态 页 发 私 信'),
            ),

          // 顶部返回栏
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.only(
                    top: padding.top + Vt.s12,
                    left: Vt.s8,
                    right: Vt.s8,
                    bottom: Vt.s12,
                  ),
                  decoration: BoxDecoration(
                    color: Vt.bgVoid.withValues(alpha: 0.72),
                    border: Border(
                      bottom: BorderSide(
                          color: Vt.gold.withValues(alpha: 0.18)),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Vt.gold,
                            size: 18,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_user != null)
                        GestureDetector(
                          onTap: () => _showSafetyMenu(_user!),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: Vt.gold,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
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

// ────────────────────────────────────────────────────────────────────────────
// 主体内容
// ────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final UserProfile user;
  final List<MomentModel> moments;
  final bool following;
  final EdgeInsets padding;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _Body({
    required this.user,
    required this.moments,
    required this.following,
    required this.padding,
    required this.onFollow,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        0,
        padding.top + Vt.s96,
        0,
        padding.bottom + Vt.s64,
      ),
      child: Column(
        children: [
          const _Ornament(),
          const SizedBox(height: Vt.s24),
          _AvatarRing(letter: _initialOf(user.nickname)),
          const SizedBox(height: Vt.s20),
          Text(
            'MEMBER',
            style: Vt.label.copyWith(
              color: Vt.gold.withValues(alpha: 0.7),
              letterSpacing: 6,
              fontSize: Vt.t2xs,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: Vt.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s32),
            child: ShaderMask(
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
                  letterSpacing: -1,
                  color: Colors.white,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Vt.gold.withValues(alpha: 0.33),
                      blurRadius: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Vt.s12),
          Container(
            padding: const EdgeInsets.only(bottom: Vt.s4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Vt.gold.withValues(alpha: 0.28),
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Text(
              '@${user.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Vt.label.copyWith(
                color: Vt.textSecondary,
                letterSpacing: 3,
                fontSize: Vt.t2xs,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: Vt.s28),
          const _OrnamentRich(),
          const SizedBox(height: Vt.s24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s48),
            child: Text(
              switch (user.bio) {
                final b? when b.isNotEmpty => b,
                _ => '— 尚 未 留 言 —',
              },
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: Vt.cnBody.copyWith(
                color: Vt.textSecondary,
                letterSpacing: 1.5,
                fontStyle: FontStyle.italic,
                height: 1.85,
              ),
            ),
          ),
          const SizedBox(height: Vt.s40),
          // 三栏数据
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Vt.s32),
            padding: const EdgeInsets.symmetric(vertical: Vt.s24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.5),
                radius: 0.9,
                colors: [
                  Vt.gold.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
                bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCol(
                    value: user.momentsCount.toString(),
                    label: '发 布',
                  ),
                ),
                const _VStatDivider(),
                Expanded(
                  child: _StatCol(
                    value: user.followersCount.toString(),
                    label: '关 注 者',
                  ),
                ),
                const _VStatDivider(),
                Expanded(
                  child: _StatCol(
                    value: user.followingCount.toString(),
                    label: '关 注 中',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s32),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: following
                            ? Vt.gold.withValues(alpha: 0.18)
                            : Vt.gold.withValues(alpha: 0.06),
                        border: Border.all(color: Vt.gold),
                        boxShadow: following
                            ? null
                            : [
                                BoxShadow(
                                  color: Vt.gold.withValues(alpha: 0.32),
                                  blurRadius: 24,
                                  spreadRadius: -8,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          following ? '已 关 注' : '关 注',
                          style: Vt.cnButton.copyWith(
                            letterSpacing: 8,
                            color: Vt.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Vt.s12),
                Expanded(
                  child: GestureDetector(
                    onTap: onMessage,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Vt.gold.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '私 下 聊',
                          style: Vt.cnButton.copyWith(
                            fontSize: Vt.tsm,
                            letterSpacing: 6,
                            color: Vt.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s48),
          // 她的发布
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Vt.s32),
            child: Row(
              children: [
                Text(
                  '她 的 发 布',
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tmd,
                    letterSpacing: 6,
                    color: Vt.gold,
                  ),
                ),
                const SizedBox(width: Vt.s12),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Vt.gold.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s20),
          if (moments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Vt.s32),
              child: Column(
                children: [
                  for (var i = 0; i < moments.length; i++)
                    _MomentRow(
                      moment: moments[i],
                      isLast: i == moments.length - 1,
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Vt.s32,
                vertical: Vt.s48,
              ),
              child: Text(
                '— 尚 未 发 布 —',
                textAlign: TextAlign.center,
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: 6,
                  color: Vt.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initialOf(String name) {
    if (name.isEmpty) return 'V';
    return name.characters.first.toUpperCase();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 装饰组件
// ────────────────────────────────────────────────────────────────────────────

class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Vt.s12),
          child: Text(
            '❦',
            style: Vt.displayMd.copyWith(
              fontSize: Vt.tlg,
              color: Vt.gold,
              shadows: [
                Shadow(
                  color: Vt.gold.withValues(alpha: 0.55),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 96,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Vt.gold.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
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
    return SizedBox(
      width: 140,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.5),
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
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final String letter;
  const _AvatarRing({required this.letter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Vt.gold.withValues(alpha: 0),
                  Vt.goldLight,
                  Vt.gold,
                  Vt.goldDark,
                  Vt.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Vt.bgPrimary,
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Vt.bgAmbientSoft, Vt.bgAmbientBottom],
              ),
              boxShadow: [
                BoxShadow(
                  color: Vt.gold.withValues(alpha: 0.32),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Vt.gradientGold4,
                ).createShader(rect),
                child: Text(
                  letter,
                  style: Vt.displayMd.copyWith(
                    fontSize: Vt.t2xl,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Vt.gradientGold4,
          ).createShader(rect),
          child: Text(
            value,
            style: Vt.displayLg.copyWith(
              fontSize: Vt.t3xl,
              fontWeight: FontWeight.w500,
              letterSpacing: -1.5,
              height: 0.88,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: Vt.s8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Vt.cnLabel.copyWith(
            color: Vt.textSecondary,
            letterSpacing: 4,
            fontSize: Vt.t2xs,
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
    return SizedBox(
      width: 1,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Vt.gold.withValues(alpha: 0.32),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 错误态
// ────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Vt.gold.withValues(alpha: 0.6),
            ),
            const SizedBox(height: Vt.s16),
            Text(
              '— 加 载 失 败 —',
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tsm,
                letterSpacing: 6,
                color: Vt.gold,
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
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Vt.s24,
                  vertical: Vt.s12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Vt.gold),
                ),
                child: Text(
                  '重 试',
                  style: Vt.cnLabel.copyWith(
                    color: Vt.gold,
                    letterSpacing: 4,
                    fontSize: Vt.tsm,
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

// ────────────────────────────────────────────────────────────────────────────
// her moment row
// ────────────────────────────────────────────────────────────────────────────

class _MomentRow extends StatelessWidget {
  final MomentModel moment;
  final bool isLast;

  const _MomentRow({required this.moment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cover =
        moment.mediaUrls.isNotEmpty ? moment.mediaUrls.first : null;
    return GestureDetector(
      onTap: () => context.push('/moment/${moment.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Vt.s16),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: Vt.gold.withValues(alpha: 0.09)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                color: Vt.bgPrimary,
                border: Border.all(color: Vt.gold.withValues(alpha: 0.32)),
              ),
              child: cover != null
                  ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: Vt.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title?.isNotEmpty == true ? moment.title! : '无 题',
                    style: Vt.cnHeading.copyWith(
                      fontSize: Vt.tmd,
                      color: Vt.textGoldSoft,
                      letterSpacing: 3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Vt.s8),
                  if (moment.hasItem && moment.itemPriceCents != null)
                    Text(
                      '¥ ${(moment.itemPriceCents! / 100).toStringAsFixed(0)}',
                      style: Vt.price.copyWith(
                        fontSize: Vt.tlg,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Vt.gold.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        'V',
        style: Vt.displayMd.copyWith(
          fontSize: Vt.tlg,
          fontWeight: FontWeight.w500,
          color: Vt.gold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
