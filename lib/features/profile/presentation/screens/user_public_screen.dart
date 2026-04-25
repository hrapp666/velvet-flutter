// ============================================================================
// UserPublicScreen · 看别人的主页
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
      final userRes = await api.dio.get('/api/v1/users/public/${widget.userId}');
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
    }
  }

  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/api/v1/users/${user.id}/follow');
      final followed =
          (res.data as Map<String, dynamic>)['followed'] as bool? ?? false;
      if (!mounted) return;
      setState(() => _following = followed);
      VelvetToast.show(context, followed ? '已关注' : '取消关注', isError: true);
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetCtx) {
        final padding = MediaQuery.paddingOf(sheetCtx);
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Vt.rLg)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: Vt.bgElevated.withValues(alpha: 0.92),
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
                    label: '举  报  此  用  户',
                    value: 'report',
                  ),
                  _sheetTile(
                    sheetCtx,
                    icon: Icons.block_outlined,
                    label: '拉  黑  此  用  户',
                    value: 'block',
                  ),
                  _sheetTile(
                    sheetCtx,
                    icon: Icons.close,
                    label: '取  消',
                    value: null,
                    muted: true,
                  ),
                ],
              ),
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
            Icon(icon,
                color: muted ? Vt.textTertiary : Vt.gold, size: 20),
            const SizedBox(width: Vt.s16),
            Expanded(
              child: Text(
                label,
                style: Vt.cnBody.copyWith(
                  color: muted ? Vt.textTertiary : Vt.textPrimary,
                  letterSpacing: 2,
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
              height: 320,
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

            // 主体
            if (_loading)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: padding.top + 100),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Vt.gold,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 32, vertical: padding.top + 80),
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
                        _error!,
                        textAlign: TextAlign.center,
                        style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else if (_user != null)
              Builder(builder: (_) {
                final user = _user!;
                return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    0, padding.top + 100, 0, padding.bottom + 48),
                child: Column(
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

                    // 大金昵称
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Vt.label.copyWith(
                        color: Vt.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 28),

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
                    const SizedBox(height: 28),

                    // bio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
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
                    const SizedBox(height: 40),

                    // 三栏数据
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.2)),
                          bottom: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(
                              num: user.momentsCount.toString(),
                              label: 'PIECES'),
                          _Stat(
                              num: user.followersCount.toString(),
                              label: 'FOLLOWERS'),
                          _Stat(
                              num: user.followingCount.toString(),
                              label: 'FOLLOWING'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 关注按钮 / 私聊按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleFollow,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _following
                                      ? Vt.gold.withValues(alpha: 0.18)
                                      : Vt.gold.withValues(alpha: 0.06),
                                  border: Border.all(color: Vt.gold),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Vt.gold.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: -6,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _following ? '已  关  注' : '关  注',
                                    style: Vt.cnButton.copyWith(
                                      letterSpacing: 6,
                                      color: Vt.gold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                VelvetToast.show(context, '可从具体动态页发私信');
                              },
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Vt.gold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '私  下  聊',
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
                    const SizedBox(height: 40),

                    // 她的发布
                    if (_moments.isNotEmpty) ...[
                      Row(
                        children: [
                          const SizedBox(width: 36),
                          Text(
                            '她 的 发 布',
                            style: Vt.cnHeading.copyWith(
                              letterSpacing: 5,
                              color: Vt.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
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
                          const SizedBox(width: 36),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          children: _moments
                              .map((m) => _MomentRow(moment: m))
                              .toList(),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(Vt.s32),
                        child: Text(
                          '— 尚 未 发 布 —',
                          textAlign: TextAlign.center,
                          style: Vt.cnHeading.copyWith(
                            fontSize: Vt.tsm,
                            letterSpacing: 4,
                            color: Vt.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
              }),

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
                      top: padding.top + 12,
                      left: 16,
                      right: 16,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Vt.bgVoid.withValues(alpha: 0.7),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
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
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
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
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String num;
  final String label;
  const _Stat({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num,
          style: Vt.headingLg.copyWith(
            fontWeight: FontWeight.w500,
            color: Vt.gold,
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

class _MomentRow extends StatelessWidget {
  final MomentModel moment;
  const _MomentRow({required this.moment});

  @override
  Widget build(BuildContext context) {
    final cover =
        moment.mediaUrls.isNotEmpty ? moment.mediaUrls.first : null;
    return GestureDetector(
      onTap: () => context.push('/moment/${moment.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                color: Vt.bgPrimary,
                border: Border.all(color: Vt.gold.withValues(alpha: 0.3)),
              ),
              child: cover != null
                  ? Image.network(cover, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _vPlaceholder())
                  : _vPlaceholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title?.isNotEmpty == true
                        ? moment.title!
                        : '无 题',
                    style: Vt.headingSm.copyWith(
                      color: Vt.textGoldSoft,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
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
          ],
        ),
      ),
    );
  }

  Widget _vPlaceholder() {
    return Center(
      child: Text(
        'V',
        style: Vt.headingLg.copyWith(
          fontWeight: FontWeight.w500,
          color: Vt.gold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
