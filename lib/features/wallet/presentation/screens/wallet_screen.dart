// ============================================================================
// WalletScreen · 我的钱包
// ----------------------------------------------------------------------------
// 顶部：大字可提现余额 + 三栏 (pending / withdrawn / total sales)
// 中部：申请提现 CTA + 说明
// 底部：提现记录列表
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../../shared/widgets/skeleton/wallet_skeleton.dart';
import '../../data/models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import 'withdraw_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final withdrawalsAsync = ref.watch(myWithdrawalsProvider);

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: RefreshIndicator(
          color: Vt.gold,
          backgroundColor: Vt.bgElevated,
          onRefresh: () async {
            await ref.read(myWalletProvider.notifier).refresh();
            ref.invalidate(myWithdrawalsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(
                child: walletAsync.when(
                  data: (w) => _hero(context, w),
                  loading: () => const WalletSkeleton(),
                  error: (e, _) => ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(myWalletProvider),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _withdrawalsTitle()),
              withdrawalsAsync.when(
                data: (list) => list.isEmpty
                    ? SliverToBoxAdapter(child: _empty())
                    : SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Vt.s12),
                        itemBuilder: (_, i) => _withdrawalRow(list[i]),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: WithdrawalsListSkeleton(),
                ),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Vt.s96)),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
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
          Text('VELVET', style: Vt.headingLg.copyWith(
            color: Vt.textPrimary, letterSpacing: 5,
          )),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 16, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text('钱 包', style: Vt.cnLabel.copyWith(color: Vt.textSecondary)),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, WalletDto w) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Vt.s24, Vt.s16, Vt.s24, Vt.s32),
      padding: const EdgeInsets.all(Vt.s32),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0x22C9A961), Color(0x08000000)],
        ),
        border: Border.all(color: Vt.borderMedium),
      ),
      child: Column(
        children: [
          // Eyebrow
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 36, height: 1, color: Vt.gold.withValues(alpha: 0.5)),
              const SizedBox(width: Vt.s12),
              Text('MY VELVET WALLET',
                  style: Vt.label.copyWith(color: Vt.gold, fontSize: Vt.t2xs, letterSpacing: 3.5)),
              const SizedBox(width: Vt.s12),
              Container(width: 36, height: 1, color: Vt.gold.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: Vt.s12),
          Text('可 提 现 余 额',
              style: Vt.cnLabel.copyWith(color: Vt.textTertiary)),
          const SizedBox(height: Vt.s12),
          Text(
            '¥${w.balanceYuan.toStringAsFixed(2)}',
            style: Vt.displayLg.copyWith(
              color: Vt.gold, letterSpacing: -1,
              shadows: const [Shadow(color: Color(0x80C9A961), blurRadius: 30)],
            ),
          ),
          const SizedBox(height: Vt.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _subStat('¥${w.pendingYuan.toStringAsFixed(2)}', '待 结 算'),
              _subStat('¥${w.withdrawnYuan.toStringAsFixed(2)}', '已 提 现'),
              _subStat('¥${w.totalSalesYuan.toStringAsFixed(2)}', '累 计 成 交'),
            ],
          ),
          const SizedBox(height: Vt.s32),
          SizedBox(
            width: double.infinity,
            child: SpringTap(
              onTap: w.balanceCents < 1000
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => WithdrawScreen(wallet: w),
                      )),
              glow: w.balanceCents >= 1000,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Vt.s20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: w.balanceCents < 1000
                      ? Vt.gold.withValues(alpha: 0.2)
                      : Vt.gold,
                ),
                child: Text(
                  w.balanceCents < 1000 ? '余 额 不 足 ¥10' : '申 请 提 现',
                  style: Vt.cnButton.copyWith(
                    color: w.balanceCents < 1000
                        ? Vt.textTertiary
                        : Vt.bgVoid,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Vt.s16),
          Text(
            '订单确认收货后入待结算 · T+7 后进可提现余额\n最低 ¥10 · 微信 / 支付宝 / 银行卡三通道',
            style: Vt.cnLabel.copyWith(
              color: Vt.textTertiary, height: 1.8, fontSize: Vt.t2xs,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _subStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: Vt.bodyLg.copyWith(color: Vt.textPrimary)),
        const SizedBox(height: Vt.s4),
        Text(label, style: Vt.cnLabel.copyWith(color: Vt.textTertiary, fontSize: Vt.t2xs)),
      ],
    );
  }

  Widget _withdrawalsTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s16, Vt.s24, Vt.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('提 现 记 录', style: Vt.cnLabel.copyWith(color: Vt.gold)),
          const SizedBox(width: Vt.s12),
          Text('History',
              style: Vt.label.copyWith(
                color: Vt.textTertiary, fontSize: Vt.t2xs, letterSpacing: 2,
                fontStyle: FontStyle.italic,
              )),
        ],
      ),
    );
  }

  Widget _withdrawalRow(WithdrawalDto wd) {
    Color statusColor;
    switch (wd.status) {
      case WithdrawStatus.paid:
        statusColor = Vt.statusSuccess; break;
      case WithdrawStatus.rejected:
        statusColor = Vt.statusError; break;
      default:
        statusColor = Vt.gold;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s24),
      child: Container(
        padding: const EdgeInsets.all(Vt.s16),
        decoration: BoxDecoration(
          color: Vt.gold.withValues(alpha: 0.04),
          border: Border.all(color: Vt.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¥${wd.amountYuan.toStringAsFixed(2)}',
                      style: Vt.headingMd.copyWith(color: Vt.gold)),
                  const SizedBox(height: Vt.s4),
                  Text(
                    '${wd.method.label} · ${_maskAccount(wd.account)} · ${_fmtDate(wd.createdAt)}',
                    style: Vt.cnLabel.copyWith(color: Vt.textTertiary, fontSize: Vt.t2xs),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Vt.s12, vertical: Vt.s6),
              decoration: BoxDecoration(
                border: Border.all(color: statusColor),
              ),
              child: Text(
                wd.status.label,
                style: Vt.label.copyWith(color: statusColor, fontSize: Vt.t2xs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Vt.s48),
      child: Column(
        children: [
          Text('❦', style: Vt.displayLg.copyWith(
            color: Vt.gold.withValues(alpha: 0.4), fontSize: Vt.t2xl,
          )),
          const SizedBox(height: Vt.s12),
          Text('— 还 没 有 提 现 —',
              style: Vt.cnLabel.copyWith(color: Vt.textTertiary)),
          const SizedBox(height: Vt.s4),
          Text('NO WITHDRAWAL YET',
              style: Vt.label.copyWith(
                color: Vt.textDisabled, fontSize: Vt.t2xs,
                fontStyle: FontStyle.italic,
              )),
        ],
      ),
    );
  }

  String _maskAccount(String s) {
    if (s.length <= 4) return s;
    return '****${s.substring(s.length - 4)}';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }
}
