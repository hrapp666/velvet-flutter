// ============================================================================
// FeedSkeleton · v25 · Pinterest masonry 占位
// ----------------------------------------------------------------------------
// 替代 feed_screen.dart 里的 _LoadingState (CircularProgressIndicator)
// 6 个 card · 高度参差(masonry 节奏)· crossAxisCount 2 对齐生产 feed
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  // 参差高度 · 2-3-1-2-3-1 节奏(更像真 moment cover)
  static const List<double> _heights = [220, 160, 280, 200, 240, 180];

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Vt.s12,
          vertical: Vt.s16,
        ),
        child: MasonryGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: Vt.s12,
          crossAxisSpacing: Vt.s12,
          itemCount: _heights.length,
          itemBuilder: (_, i) => _MomentCardSkeleton(coverHeight: _heights[i]),
        ),
      ),
    );
  }
}

class _MomentCardSkeleton extends StatelessWidget {
  final double coverHeight;
  const _MomentCardSkeleton({required this.coverHeight});

  @override
  Widget build(BuildContext context) {
    // 整个 card 是 dumb white · parent SkeletonShimmer 一次性涂 gradient
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Vt.rMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cover image
          SkeletonBox(height: coverHeight, radius: 0),
          Padding(
            padding: const EdgeInsets.all(Vt.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // title
                SkeletonTextLine(widthFactor: 0.85, height: 12),
                SizedBox(height: Vt.s8),
                SkeletonTextLine(widthFactor: 0.55, height: 12),
                SizedBox(height: Vt.s12),
                // seller row · avatar + name
                Row(
                  children: [
                    SkeletonAvatar(size: 22),
                    SizedBox(width: Vt.s8),
                    Expanded(
                      child: SkeletonTextLine(widthFactor: 0.6, height: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
