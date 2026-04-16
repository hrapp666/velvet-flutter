// ============================================================================
// SearchSkeleton · v25 · search_screen 占位
// ----------------------------------------------------------------------------
// 8 个 grid item · 4 列(对位生产 search grid 视觉密度)
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // search_screen 把 SearchSkeleton 放在 Expanded 内 · 不能 shrinkWrap
    // 用 SkeletonShimmer 包 GridView · 让它自然填满 Expanded
    return SkeletonShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(Vt.s12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Vt.s12,
          crossAxisSpacing: Vt.s12,
          childAspectRatio: 0.78,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => const _SearchTileSkeleton(),
      ),
    );
  }
}

class _SearchTileSkeleton extends StatelessWidget {
  const _SearchTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Vt.rMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: SkeletonBox(height: 0, radius: 0)),
          Padding(
            padding: const EdgeInsets.all(Vt.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonTextLine(widthFactor: 0.85, height: 11),
                SizedBox(height: Vt.s6),
                SkeletonTextLine(widthFactor: 0.5, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
