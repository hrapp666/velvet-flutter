// ============================================================================
// AdminScreen · 管理员数据看板（只读 · 审核动作放 H5 版）
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminRepository(api);
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.stats();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStatsProvider);
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
                  ref.invalidate(adminStatsProvider);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: async.when(
                  data: (s) => _body(s),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Vt.gold, strokeWidth: 1.5),
                  ),
                  error: (e, _) => ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(adminStatsProvider),
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
          Text('管 理',
              style: Vt.cnLabel.copyWith(color: Vt.textSecondary)),
        ],
      ),
    );
  }

  Widget _body(AdminStats s) {
    String yuan(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s8, Vt.s24, Vt.s96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 40, height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.transparent, Vt.gold, Colors.transparent]))),
            const SizedBox(width: Vt.s12),
            Text('TODAY · OVERVIEW',
                style: Vt.label.copyWith(
                  color: Vt.gold, fontSize: 10, letterSpacing: 3,
                  fontStyle: FontStyle.italic,
                )),
            const SizedBox(width: Vt.s12),
            Container(
                width: 40, height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.transparent, Vt.gold, Colors.transparent]))),
          ],
        ),
        const SizedBox(height: Vt.s24),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Vt.s12,
          crossAxisSpacing: Vt.s12,
          childAspectRatio: 1.0,
          children: [
            _statCard('${s.todayOrderCount}', '今 日 订 单'),
            _statCard(yuan(s.todaySalesCents), '今 日 成 交'),
            _statCard(yuan(s.todayCommissionCents), '今 日 佣 金', hi: true),
            _statCard('${s.pendingMerchants}', '待 审 商 家'),
            _statCard('${s.pendingWithdrawals}', '待 审 提 现'),
            _statCard('${s.pendingReports}', '待 审 举 报'),
          ],
        ),
        const SizedBox(height: Vt.s32),
        Container(
          padding: const EdgeInsets.symmetric(vertical: Vt.s16, horizontal: Vt.s16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Vt.borderSubtle),
              bottom: BorderSide(color: Vt.borderSubtle),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: Vt.s16,
            runSpacing: Vt.s8,
            children: [
              _totalsChip('总 用 户', '${s.totalUsers}'),
              _totalsDivider(),
              _totalsChip('认 证 商 家', '${s.totalMerchants}'),
              _totalsDivider(),
              _totalsChip('累 计 成 交', yuan(s.totalSalesCents)),
              _totalsDivider(),
              _totalsChip('累 计 佣 金', yuan(s.totalCommissionCents)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, {bool hi = false}) {
    return Container(
      padding: const EdgeInsets.all(Vt.s12),
      decoration: BoxDecoration(
        color: hi ? Vt.gold.withValues(alpha: 0.14) : Vt.gold.withValues(alpha: 0.04),
        border: Border.all(color: Vt.borderSubtle),
        boxShadow: hi
            ? [BoxShadow(color: Vt.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -4)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Vt.headingMd.copyWith(
                color: Vt.gold,
                shadows: const [Shadow(color: Color(0x55C9A961), blurRadius: 12)],
              ),
            ),
          ),
          const SizedBox(height: Vt.s8),
          Text(
            label,
            style: Vt.cnLabel.copyWith(
              color: Vt.textTertiary, fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$label ',
            style: Vt.label.copyWith(
              color: Vt.textTertiary, fontSize: 10,
              fontStyle: FontStyle.italic,
            )),
        Text(value,
            style: Vt.headingSm.copyWith(color: Vt.gold, fontSize: 13)),
      ],
    );
  }

  Widget _totalsDivider() {
    return Container(width: 1, height: 12, color: Vt.borderSubtle);
  }
}
