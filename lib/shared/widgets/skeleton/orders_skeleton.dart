// ============================================================================
// OrdersSkeleton · v25 · orders_screen 占位
// ----------------------------------------------------------------------------
// 5 个订单卡片 · 每个含 标题 + 状态 tag + 价格 + 缩略图
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';

class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(Vt.s16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: Vt.s12),
        itemBuilder: (_, __) => const _OrderCardSkeleton(),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Vt.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Vt.rLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 80, height: 80, radius: Vt.rSm),
          SizedBox(width: Vt.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonTextLine(widthFactor: 0.7, height: 14),
                SizedBox(height: Vt.s8),
                SkeletonTextLine(widthFactor: 0.45, height: 11),
                SizedBox(height: Vt.s16),
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 18, radius: Vt.rXs),
                    Spacer(),
                    SkeletonBox(width: 64, height: 18, radius: Vt.rXs),
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
