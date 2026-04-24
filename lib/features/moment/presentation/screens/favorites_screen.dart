// ============================================================================
// FavoritesScreen · 我的收藏
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';

final myFavoritesProvider = FutureProvider<List<MomentModel>>((ref) async {
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
            _header(context),
            Expanded(
              child: RefreshIndicator(
                color: Vt.gold,
                backgroundColor: Vt.bgElevated,
                onRefresh: () async {
                  ref.invalidate(myFavoritesProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: async.when(
                  data: (list) => list.isEmpty
                      ? const EmptyState(
                          title: '— 还 没 有 收 藏 —',
                          subtitle: 'tap ♡ to keep what moves you',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(Vt.s16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: Vt.s12,
                            mainAxisSpacing: Vt.s12,
                          ),
                          itemCount: list.length,
                          itemBuilder: (_, i) => ScrollReveal(
                            delay: Duration(
                                milliseconds: (i * 50).clamp(0, 500)),
                            duration: const Duration(milliseconds: 500),
                            fromOffsetY: 26,
                            child: _card(context, list[i]),
                          ),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Vt.gold, strokeWidth: 1.5),
                  ),
                  error: (e, _) => ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(myFavoritesProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s24, Vt.s24, Vt.s16),
      child: Row(
        children: [
          GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40, height: 40,
                      child: Icon(Icons.arrow_back, color: Vt.gold, size: 18),
                    ),
                  ),
          const SizedBox(width: Vt.s8),
          Text('VELVET',
              style: Vt.headingLg.copyWith(
                  color: Vt.textPrimary, letterSpacing: 5)),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 16, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text('收 藏', style: Vt.cnLabel.copyWith(color: Vt.textSecondary)),
        ],
      ),
    );
  }

  // _empty() 已迁移到 lib/shared/widgets/empty_state/empty_state.dart

  Widget _card(BuildContext context, MomentModel m) {
    final cover = (m.mediaUrls.isNotEmpty)
        ? m.mediaUrls.first
        : 'https://picsum.photos/seed/velvet${m.id}/600/800';
    return GestureDetector(
      onTap: () => context.push('/moment/${m.id}'),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Vt.bgElevated,
                border: Border.all(color: Vt.borderSubtle),
                image: DecorationImage(
                  image: NetworkImage(cover),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: Vt.s12,
            right: Vt.s12,
            bottom: Vt.s12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.title?.isNotEmpty == true ? m.title! : '无题',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Vt.cnBody.copyWith(
                    color: Vt.textPrimary, fontSize: Vt.tsm,
                  ),
                ),
                if (m.hasItem == true && m.itemPriceCents != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '¥ ${(m.itemPriceCents! / 100).toStringAsFixed(0)}',
                    style: Vt.price.copyWith(
                      color: Vt.gold, fontSize: Vt.tsm,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
