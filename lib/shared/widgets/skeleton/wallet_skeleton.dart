// ============================================================================
// WalletSkeleton · v25 · wallet_screen 占位
// ----------------------------------------------------------------------------
// hero 余额大数字 + 4 个 quick action + 流水列表
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';

class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(Vt.s24),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: const [
          _BalanceHeroSkeleton(),
          SizedBox(height: Vt.s32),
          _QuickActionsSkeleton(),
          SizedBox(height: Vt.s32),
          SkeletonTextLine(widthFactor: 0.25, height: 14),
          SizedBox(height: Vt.s16),
          _TransactionRowSkeleton(),
          SizedBox(height: Vt.s12),
          _TransactionRowSkeleton(),
          SizedBox(height: Vt.s12),
          _TransactionRowSkeleton(),
          SizedBox(height: Vt.s12),
          _TransactionRowSkeleton(),
        ],
      ),
    );
  }
}

/// 流水列表骨架 · 用于 walletScreen 的 withdrawalsAsync.loading 分支
/// 与 WalletSkeleton 的 hero 区分开 · 单独 4 行 transaction 占位
class WithdrawalsListSkeleton extends StatelessWidget {
  const WithdrawalsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: Vt.s12),
        itemBuilder: (_, __) => const _TransactionRowSkeleton(),
      ),
    );
  }
}

class _BalanceHeroSkeleton extends StatelessWidget {
  const _BalanceHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Vt.s24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Vt.rXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonTextLine(widthFactor: 0.3, height: 11),
          SizedBox(height: Vt.s12),
          SkeletonBox(width: 200, height: 38, radius: Vt.rXxs),
          SizedBox(height: Vt.s12),
          SkeletonTextLine(widthFactor: 0.45, height: 11),
        ],
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _ActionPill(),
        _ActionPill(),
        _ActionPill(),
        _ActionPill(),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBox(width: 56, height: 56, radius: Vt.rLg),
        SizedBox(height: Vt.s8),
        SkeletonBox(width: 40, height: 10, radius: Vt.rXxs),
      ],
    );
  }
}

class _TransactionRowSkeleton extends StatelessWidget {
  const _TransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SkeletonBox(width: 36, height: 36, radius: Vt.rSm),
        SizedBox(width: Vt.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonTextLine(widthFactor: 0.5, height: 12),
              SizedBox(height: Vt.s6),
              SkeletonTextLine(widthFactor: 0.3, height: 10),
            ],
          ),
        ),
        SkeletonBox(width: 60, height: 14, radius: Vt.rXxs),
      ],
    );
  }
}
