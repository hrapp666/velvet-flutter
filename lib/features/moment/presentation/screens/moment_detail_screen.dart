// ============================================================================
// MomentDetail · 动态详情页（视觉锚点 #3 — 转化率核心）
// ----------------------------------------------------------------------------
// 视觉策略：
//   - 顶部：全屏沉浸式封面（占屏 60%）+ 暗角 vignette + 顶部毛玻璃返回栏
//   - 中部：浮起卡片（向上滑出）— 包含标题、价格、描述、属性 chip
//   - 卖家信息卡：头像 + 名字 + 信誉 + 关注按钮
//   - 底部固定 CTA：全宽樱花粉胶囊 "私下聊聊"（带粉色生物发光）
//   - 右下角浮动：收藏 / 分享 / 举报 三连
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/share_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ambient/grain_overlay.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/moment_model.dart';
import '../../data/repositories/comment_repository.dart';
import '../providers/moment_provider.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';

class MomentDetailScreen extends ConsumerStatefulWidget {
  final int momentId;
  const MomentDetailScreen({super.key, required this.momentId});

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _cardSlide;

  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _cardSlide = CurvedAnimation(parent: _entryCtrl, curve: Vt.curveCinematic);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    unawaited(HapticService.instance.medium());
    try {
      final repo = ref.read(momentRepositoryProvider);
      final favorited = await repo.toggleFavorite(widget.momentId);
      if (!mounted) return;
      setState(() => _isFavorited = favorited);
    } on Object catch (e) {
      if (!mounted) return;
      VelvetToast.show(context, '操作失败：$e', isError: true);
    }
  }

  Future<void> _toggleLike() async {
    unawaited(HapticService.instance.medium());
    try {
      final repo = ref.read(momentRepositoryProvider);
      await repo.toggleLike(widget.momentId);
      ref.invalidate(momentDetailProvider(widget.momentId));
    } on Object catch (_) {
      // 静默原因：点赞非关键路径，失败不阻塞 UI，detail 下次 invalidate 自动恢复
    }
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 1.4,
          colors: [
            Vt.bgAmbientSoft,
            Vt.bgAmbientDeep,
            Vt.bgVoid,
          ],
        ),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Vt.goldLight,
              Vt.goldDark,
            ],
          ).createShader(rect),
          child: const Text(
            'V',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 120,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 8,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final momentAsync = ref.watch(momentDetailProvider(widget.momentId));

    final cover = momentAsync.maybeWhen(
      data: (m) => m.mediaUrls.isNotEmpty
          ? m.mediaUrls.first
          : 'https://picsum.photos/seed/velvet${m.id}/900/1200',
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── 顶部全屏封面 · Hero 对接 MomentCard 的同 tag ───
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: size.height * 0.62,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero 只包图片本身 · vignette/gradient 不参与 flight
                Hero(
                  tag: 'moment-cover-${widget.momentId}',
                  child: cover != null
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _coverPlaceholder(),
                          errorWidget: (_, __, ___) => _coverPlaceholder(),
                        )
                      : _coverPlaceholder(),
                ),

                // 暗角
                DecoratedBox(decoration: Vt.vignetteOverlay),

                // 底部到内容的渐变过渡（更深更柔）
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 280,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Vt.bgVoid.withValues(alpha: 0.75),
                          Vt.bgVoid,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 主滚动内容 ───
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: size.height * 0.52)),

              // 真数据详情卡
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _cardSlide,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 60 * (1 - _cardSlide.value)),
                    child: Opacity(opacity: _cardSlide.value, child: child),
                  ),
                  child: switch (momentAsync) {
                    AsyncData(:final value) => _DetailContent(value),
                    AsyncError(:final error) => _DetailError(error.toString()),
                    _ => const _DetailLoading(),
                  },
                ),
              ),

              // ─── 评论区 ───
              SliverToBoxAdapter(
                child: _CommentsSection(momentId: widget.momentId),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: padding.bottom + 120),
              ),
            ],
          ),

          // ─── 顶部毛玻璃返回栏 ───
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: padding.top + 8,
                    left: Vt.s16,
                    right: Vt.s16,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Vt.bgVoid.withValues(alpha: 0.6),
                        Vt.bgVoid.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      _GlassIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _GlassIconBtn(
                        icon: _isFavorited
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        active: _isFavorited,
                        onTap: _toggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      _GlassIconBtn(
                        icon: Icons.ios_share_rounded,
                        onTap: () {
                          final m = momentAsync.valueOrNull;
                          if (m == null) return;
                          final rawTitle = m.title;
                          final shareTitle =
                              rawTitle != null && rawTitle.isNotEmpty
                                  ? rawTitle
                                  : m.content;
                          unawaited(
                            ShareService.instance.shareMoment(
                              momentId: m.id,
                              title: shareTitle,
                              summary: m.content,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _GlassIconBtn(
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── 底部固定 CTA ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCta(
              bottomPadding: padding.bottom,
              liked: momentAsync.valueOrNull?.liked ?? false,
              onLike: _toggleLike,
              onChat: () {
                final m = momentAsync.valueOrNull;
                if (m == null) return;
                // 没真实 conversationId · 先跳 chat list · 用户手动选 seller
                // TODO(v26): 后端 GET /api/v1/chat/start?with=userId 开会话
                context.push('/chat/0');
              },
            ),
          ),

          // UI12 · editorial 胶片纹理 · detail 页更轻 (封面自带材质)
          const GrainOverlay(intensity: 0.018, seed: 23),
        ],
      ),
    );
  }
}

// ============================================================================
// 浮起的详情内容卡 — 真接 momentDetailProvider
// ============================================================================
class _DetailContent extends StatelessWidget {
  final MomentModel m;
  const _DetailContent(this.m);

  String _formatTime(DateTime? t) {
    if (t == null) return '— 某时 —';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  @override
  Widget build(BuildContext context) {
    final price = (m.itemPriceCents ?? 0) / 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 顶部装饰 hairline + 罗马数字编号
          Container(
            width: 56,
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Vt.gold, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: Vt.s16),
          Text(
            'N° ${m.id.toString().padLeft(3, '0')}  ·  ${m.location ?? 'PRIVATE'}',
            style: Vt.label.copyWith(
              color: Vt.gold,
              letterSpacing: 4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: Vt.s24),

          // 主标题
          Text(
            m.title?.isNotEmpty == true ? m.title! : '无 题',
            textAlign: TextAlign.center,
            style: GoogleFontsLocal.cormorant(
              fontSize: 44,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              height: 1.1,
              color: Vt.textGoldSoft,
              shadows: [
                Shadow(
                  color: Vt.gold.withValues(alpha: 0.4),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s16),

          // 中间渐变线 + 钻石
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
          const SizedBox(height: Vt.s24),

          // 价格（如果有）
          if (m.hasItem && m.itemPriceCents != null) ...[
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Vt.gradientGold4,
              ).createShader(rect),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(
                    text: '¥ ',
                    style: TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: price.toStringAsFixed(0),
                    style: const TextStyle(
                      fontFamily: 'Cormorant Garamond',
                      fontSize: 56,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: Vt.s32),
          ],

          // 描述（带引号装饰）
          if (m.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Vt.s8),
              child: Text(
                '"${m.content}"',
                textAlign: TextAlign.center,
                style: Vt.cnBody.copyWith(
                  fontSize: Vt.tmd,
                  height: 1.95,
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Vt.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: Vt.s40),

          // 元数据行
          Container(
            padding: const EdgeInsets.symmetric(vertical: Vt.s24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
                bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MetaItem(num: m.viewCount.toString(), label: 'VIEWS'),
                _MetaItem(num: m.likeCount.toString(), label: 'HEARTS'),
                _MetaItem(num: m.favoriteCount.toString(), label: 'SAVED'),
                _MetaItem(num: m.commentCount.toString(), label: 'NOTES'),
              ],
            ),
          ),

          // tags
          if (m.tags.isNotEmpty) ...[
            const SizedBox(height: Vt.s32),
            Wrap(
              spacing: Vt.s8,
              runSpacing: Vt.s8,
              alignment: WrapAlignment.center,
              children: m.tags.map((t) => _Chip(label: t)).toList(),
            ),
          ],

          const SizedBox(height: Vt.s40),

          // CURATED BY 卖家（点击进入她主页）
          GestureDetector(
            onTap: () => context.push('/user/${m.userId}'),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(
                  'CURATED BY',
                  style: Vt.label.copyWith(
                    color: Vt.gold.withValues(alpha: 0.7),
                    letterSpacing: 4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: Vt.s8),
                Text(
                  m.userNickname,
                  style: GoogleFontsLocal.cormorant(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    color: Vt.textGoldSoft,
                    decoration: TextDecoration.underline,
                    decorationColor: Vt.gold.withValues(alpha: 0.4),
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s24),
          Text(
            _formatTime(m.createdAt),
            style: Vt.bodySm.copyWith(
              color: Vt.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: Vt.s32),
        ],
      ),
    );
  }
}

// 元数据小项
class _MetaItem extends StatelessWidget {
  final String num;
  final String label;
  const _MetaItem({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num,
          style: GoogleFontsLocal.cormorant(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Vt.gold,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Vt.label.copyWith(
            color: Vt.textSecondary,
            letterSpacing: 2,
            fontSize: 9,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// loading / error 占位
class _DetailLoading extends StatelessWidget {
  const _DetailLoading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Vt.gold),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String error;
  const _DetailError(this.error);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Vt.s32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 32, color: Vt.gold.withValues(alpha: 0.6)),
            const SizedBox(height: Vt.s16),
            Text('— 加载失败 —',
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: 4,
                )),
            const SizedBox(height: Vt.s8),
            Text(error,
                style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// 内部 helper：用 google_fonts 真实加载 Cormorant Garamond
class GoogleFontsLocal {
  static TextStyle cormorant({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }
}


// ============================================================================
// 底部固定 CTA — 心动 + "私下聊聊" 樱花粉胶囊
// 主人反馈: 这两个按钮原本不响应点击(静态 Container) · v25 修复为真交互
// ============================================================================
class _BottomCta extends StatelessWidget {
  final double bottomPadding;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onChat;
  const _BottomCta({
    required this.bottomPadding,
    required this.liked,
    required this.onLike,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            top: Vt.s16,
            left: Vt.s20,
            right: Vt.s20,
            bottom: bottomPadding + Vt.s16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Vt.bgVoid.withValues(alpha: 0.0),
                Vt.bgVoid.withValues(alpha: 0.6),
                Vt.bgVoid.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Row(
            children: [
              // 心动按钮 (原静态 Container → SpringTap + onLike)
              SpringTap(
                onTap: onLike,
                pressedScale: 0.88,
                glow: liked,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: liked
                        ? Vt.gold.withValues(alpha: 0.2)
                        : Vt.glassFill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: liked ? Vt.gold : Vt.glassBorder,
                    ),
                  ),
                  child: Icon(
                    liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Vt.gold,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: Vt.s12),
              // 主 CTA · "私 下 聊 聊" · SpringTap + onChat
              Expanded(
                child: SpringTap(
                  onTap: onChat,
                  glow: true, // 主 CTA 永远 burst
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Vt.rPill),
                      gradient: const LinearGradient(
                        colors: [Vt.gold, Vt.goldDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Vt.gold.withValues(alpha: 0.6),
                          blurRadius: 32,
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Vt.gold.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '私 下 聊 聊',
                          style: Vt.button.copyWith(
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 通用小组件
// ============================================================================
class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _GlassIconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      pressedScale: 0.88, // 小按钮下压更明显
      glow: active,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? Vt.gold.withValues(alpha: 0.2) : Vt.glassFill,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Vt.gold : Vt.glassBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Vt.gold : Vt.textPrimary,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Vt.bgElevated,
        borderRadius: BorderRadius.circular(Vt.rXs),
        border: Border.all(color: Vt.borderSubtle),
      ),
      child: Text(
        label,
        style: Vt.label.copyWith(
          color: Vt.textSecondary,
          fontSize: Vt.t2xs,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ============================================================================
// 评论区（私语）
// ============================================================================
class _CommentsSection extends ConsumerStatefulWidget {
  final int momentId;
  const _CommentsSection({required this.momentId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      VelvetToast.show(context, '写一句吧');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(commentsProvider(widget.momentId).notifier)
          .send(text);
      _ctrl.clear();
      if (mounted) {
        VelvetToast.show(context, '已 寄 出');
      }
    } on Object catch (e) {
      if (mounted) {
        VelvetToast.show(context, '寄出失败：$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.momentId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s24, Vt.s24, Vt.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题：私 语 ─── NOTES
          Row(
            children: [
              Text(
                '私 语',
                style: Vt.headingSm.copyWith(
                  color: Vt.gold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: Vt.s12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Vt.gold, Colors.transparent],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Vt.s12),
              Text(
                'NOTES',
                style: Vt.label.copyWith(
                  color: Vt.textTertiary,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: Vt.s24),

          // 评论列表
          ...switch (commentsAsync) {
            AsyncData(:final value) when value.isEmpty => [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Vt.s32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '还没有人留下私语',
                          style: Vt.bodyMd.copyWith(color: Vt.textSecondary),
                        ),
                        const SizedBox(height: Vt.s8),
                        Text(
                          '第一句 · 由你写下',
                          style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            AsyncData(:final value) => value.map((c) => _CommentTile(c)).toList(),
            AsyncError() => [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Vt.s24),
                  child: Center(
                    child: Text('— 暂时听不见私语 —',
                        style: Vt.bodySm.copyWith(color: Vt.textTertiary)),
                  ),
                ),
              ],
            _ => [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Vt.s24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Vt.gold,
                      ),
                    ),
                  ),
                ),
              ],
          },

          const SizedBox(height: Vt.s24),

          // 输入框
          Container(
            padding: const EdgeInsets.fromLTRB(Vt.s16, Vt.s12, Vt.s12, Vt.s12),
            decoration: BoxDecoration(
              color: Vt.gold.withValues(alpha: 0.04),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                    style: Vt.bodyMd.copyWith(color: Vt.textPrimary),
                    decoration: InputDecoration(
                      hintText: '写下你的私语…',
                      hintStyle: Vt.bodyMd.copyWith(
                        color: Vt.gold.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: Vt.s8),
                SpringTap(
                  onTap: _sending ? null : _send,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Vt.s16,
                      vertical: Vt.s8,
                    ),
                    decoration: BoxDecoration(
                      color: _sending
                          ? Vt.gold.withValues(alpha: 0.2)
                          : Vt.gold.withValues(alpha: 0.06),
                      border: Border.all(color: Vt.gold),
                    ),
                    child: Text(
                      _sending ? '寄出中…' : '寄 出',
                      style: Vt.label.copyWith(
                        color: Vt.gold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile(this.comment);

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Vt.s16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Vt.borderHairline, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.userNickname,
                style: Vt.bodyMd.copyWith(
                  color: Vt.gold,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: Vt.s8),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Vt.gold.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Vt.s8),
              Text(
                _formatTime(comment.createdAt),
                style: Vt.bodySm.copyWith(
                  color: Vt.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: Vt.s8),
          Text(
            comment.content,
            style: Vt.bodyMd.copyWith(
              color: Vt.textPrimary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
