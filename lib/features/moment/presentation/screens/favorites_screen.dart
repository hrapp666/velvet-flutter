// ============================================================================
// FavoritesScreen · 我 的 收 藏 · v5 Editorial Luxury
// ----------------------------------------------------------------------------
// H5 真相源: styles.css L5120 .fav-wrap / .fav-list / .fav-card
//   - padding 110/sp5/sp9 · grid 2 col · gap sp4
//   - .fav-card: 0 圆角 · ::before/::after L 角金线 (top-left 10×10 / bottom-right 10×10)
//   - .fav-cover aspect 4/5 · 0 圆角 · inset hairline gold on hover
//   - .fav-title clamp(15,17) · .fav-price 4 档金 ShaderMask
// ============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/editorial/page_fleuron.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';
import '../../../../core/api/api_client.dart';

// autoDispose · 每次进入收藏页重新拉取
// 同事反馈"点击收藏后,收藏页没数据" = 全局缓存的空列表没刷新
// autoDispose 让 push /favorites 时重建 future, toggleFavorite 后立即可见
final myFavoritesProvider =
    FutureProvider.autoDispose<List<MomentModel>>((ref) async {
  final repo = ref.read(momentRepositoryProvider);
  return repo.myFavorites(page: 0, size: 30);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFavoritesProvider);
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: RefreshIndicator(
                color: Vt.gold,
                backgroundColor: Vt.bgElevated,
                onRefresh: () async {
                  ref.invalidate(myFavoritesProvider);
                  await Future<void>.delayed(
                      const Duration(milliseconds: 300));
                },
                child: switch (async) {
                  AsyncData(:final value) when value.isEmpty =>
                    const EmptyState(
                      title: '— 还 没 有 收 藏 —',
                      subtitle: 'tap ♡ to keep what moves you',
                    ),
                  AsyncData(:final value) => _FavGrid(items: value),
                  AsyncError(:final error) => ErrorState(
                      message: userMessageOf(error, fallback: '加载收藏失败'),
                      onRetry: () => ref.invalidate(myFavoritesProvider),
                    ),
                  _ => const Center(
                      child: CircularProgressIndicator(
                          color: Vt.gold, strokeWidth: 1.5),
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 顶部 header · 返回 + VELVET + 收 藏 (italic gold)
// ============================================================================
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s24, Vt.s24, Vt.s16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Vt.gold, size: 16),
            ),
          ),
          const SizedBox(width: Vt.s8),
          Text(
            'VELVET',
            style: Vt.headingLg.copyWith(
              color: Vt.textPrimary,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 16, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text(
            '收 藏',
            style: Vt.cnLabel.copyWith(color: Vt.textSecondary),
          ),
          const Spacer(),
          // 罗马数字位 · 总数
          Text(
            'COLLECTION',
            style: Vt.label.copyWith(
              color: Vt.textTertiary,
              letterSpacing: 3,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Fav grid · 2 col · 0 圆角 · L 角装饰
// ============================================================================
class _FavGrid extends StatelessWidget {
  final List<MomentModel> items;
  const _FavGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Vt.s20, Vt.s8, Vt.s20, Vt.s24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: Vt.s12,
              mainAxisSpacing: Vt.s24,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ScrollReveal(
                delay: Duration(milliseconds: (i * 50).clamp(0, 500)),
                duration: const Duration(milliseconds: 500),
                fromOffsetY: 26,
                child: _FavCard(m: items[i]),
              ),
              childCount: items.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: PageFleuron(caption: 'Velvet · Favorites'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Vt.s24)),
      ],
    );
  }
}

// ============================================================================
// _FavCard · 0 圆角 + L 角装饰 (top-left + bottom-right) · 4/5 cover + meta
// ============================================================================
class _FavCard extends StatelessWidget {
  final MomentModel m;
  const _FavCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final cover = m.mediaUrls.isNotEmpty
        ? m.mediaUrls.first
        : 'https://picsum.photos/seed/velvet${m.id}/600/800';
    final hasPrice = (m.hasItem == true) && (m.itemPriceCents != null);
    return GestureDetector(
      onTap: () => context.push('/moment/${m.id}'),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主卡片 · 0 圆角 · 1px gold-15 边
          Container(
            decoration: BoxDecoration(
              color: Vt.bgElevated,
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.18),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 4/5 cover ───
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Hero(
                    tag: 'moment-cover-${m.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Vt.bgVoid,
                          child: CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                ColoredBox(color: Vt.bgElevated),
                            errorWidget: (_, __, ___) =>
                                ColoredBox(color: Vt.bgElevated),
                          ),
                        ),
                        // 暗角
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.55, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Vt.bgVoid.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // inset gold hairline
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Vt.gold.withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ─── meta ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Vt.s12, Vt.s12, Vt.s12, Vt.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title?.isNotEmpty == true ? m.title! : '无 题',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Vt.cnBody.copyWith(
                          color: Vt.textPrimary,
                          fontSize: Vt.tsm,
                          letterSpacing: 1,
                          height: 1.45,
                        ),
                      ),
                      if (hasPrice) ...[
                        const SizedBox(height: Vt.s8),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: Vt.gradientGold4,
                          ).createShader(rect),
                          child: Text(
                            '¥ ${(m.itemPriceCents! / 100).toStringAsFixed(0)}',
                            style: Vt.price.copyWith(
                              color: Colors.white,
                              fontSize: Vt.tlg,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              height: 1,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: Vt.s4),
                        Text(
                          m.userNickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Vt.label.copyWith(
                            color: Vt.gold.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ─── L 角装饰 (top-left) · 12×12 gold ───
          const Positioned(top: -1, left: -1, child: _LCorner.topLeft()),
          // ─── L 角装饰 (bottom-right) · 12×12 gold ───
          const Positioned(bottom: -1, right: -1, child: _LCorner.bottomRight()),
        ],
      ),
    );
  }
}

// ============================================================================
// _LCorner · 12×12 + 单两侧 1px gold border (跟 chat_detail _Bubble._corner 同源)
// ============================================================================
class _LCorner extends StatelessWidget {
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const _LCorner.topLeft()
      : top = true,
        bottom = false,
        left = true,
        right = false;

  const _LCorner.bottomRight()
      : top = false,
        bottom = true,
        left = false,
        right = true;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: Vt.gold.withValues(alpha: 0.85),
      width: 1.2,
    );
    return IgnorePointer(
      child: SizedBox(
        width: 12,
        height: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: top ? border : BorderSide.none,
              bottom: bottom ? border : BorderSide.none,
              left: left ? border : BorderSide.none,
              right: right ? border : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
