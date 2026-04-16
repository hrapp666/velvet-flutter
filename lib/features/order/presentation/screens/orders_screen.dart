// ============================================================================
// OrdersScreen · 我的订单（买家 / 卖家双 tab）
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/orders_skeleton.dart';
import '../../../payment/presentation/widgets/payment_sheet.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderSide _side = OrderSide.buyer;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider(_side));

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _tabs(),
            Expanded(
              child: RefreshIndicator(
                color: Vt.gold,
                backgroundColor: Vt.bgElevated,
                onRefresh: () async {
                  await ref.read(myOrdersProvider(_side).notifier).refresh();
                },
                child: ordersAsync.when(
                  data: (list) => list.isEmpty
                      ? EmptyState(
                          title: '— 暂 无 订 单 —',
                          subtitle: _side == OrderSide.buyer
                              ? '逛 逛 看 · 或 许 有 心 动 的'
                              : '还 没 有 成 交 · 好 物 自 会 遇 见 人',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              Vt.s24, Vt.s20, Vt.s24, Vt.s96),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Vt.s16),
                          itemBuilder: (_, i) => ScrollReveal(
                            delay: Duration(
                                milliseconds: (i * 55).clamp(0, 400)),
                            duration: const Duration(milliseconds: 480),
                            fromOffsetY: 24,
                            child: _orderCard(list[i]),
                          ),
                        ),
                  loading: () => const OrdersSkeleton(),
                  error: (e, _) => ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(myOrdersProvider(_side)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
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
          Text('订 单', style: Vt.cnLabel.copyWith(color: Vt.textSecondary)),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Vt.borderSubtle),
          bottom: BorderSide(color: Vt.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: Vt.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabBtn(OrderSide.buyer, '我 买 的'),
          const SizedBox(width: Vt.s48),
          _tabBtn(OrderSide.seller, '我 卖 的'),
        ],
      ),
    );
  }

  Widget _tabBtn(OrderSide side, String label) {
    final on = _side == side;
    return GestureDetector(
      onTap: () {
        unawaited(HapticService.instance.light());
        setState(() => _side = side);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Vt.cnHeading.copyWith(
              color: on ? Vt.gold : Vt.textTertiary,
              shadows: on
                  ? const [Shadow(color: Color(0x66C9A961), blurRadius: 14)]
                  : null,
            ),
          ),
          const SizedBox(height: Vt.s8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: on ? 32 : 0,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Vt.gold.withValues(alpha: 0),
                Vt.gold,
                Vt.gold.withValues(alpha: 0),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // _empty() 已迁移到 lib/shared/widgets/empty_state/empty_state.dart

  Widget _orderCard(OrderDto o) {
    final status = _statusChip(o);
    final actions = _buildActions(o);
    return Container(
      padding: const EdgeInsets.all(Vt.s16),
      decoration: BoxDecoration(
        color: Vt.gold.withValues(alpha: 0.04),
        border: Border.all(color: Vt.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NO. ${o.id}',
                  style: Vt.label.copyWith(
                    color: Vt.textTertiary, fontSize: 10,
                    letterSpacing: 2, fontStyle: FontStyle.italic,
                  )),
              status,
            ],
          ),
          const SizedBox(height: Vt.s12),
          const Divider(color: Vt.borderSubtle, height: 1),
          const SizedBox(height: Vt.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Vt.bgElevated,
                  border: Border.all(color: Vt.borderSubtle),
                  image: o.coverSnapshot != null
                      ? DecorationImage(
                          image: NetworkImage(o.coverSnapshot!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: o.coverSnapshot == null
                    ? Text('♦', style: Vt.headingLg.copyWith(color: Vt.gold.withValues(alpha: 0.3)))
                    : null,
              ),
              const SizedBox(width: Vt.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.titleSnapshot ?? '未命名',
                      style: Vt.cnBody.copyWith(color: Vt.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Vt.s4),
                    Text(
                      '${_side == OrderSide.buyer ? '卖家' : '买家'} · ${_side == OrderSide.buyer ? o.sellerNickname : o.buyerNickname}',
                      style: Vt.cnLabel.copyWith(
                        color: Vt.textTertiary, fontSize: Vt.t2xs,
                      ),
                    ),
                    const SizedBox(height: Vt.s8),
                    Text(
                      '¥${o.priceYuan.toStringAsFixed(2)}',
                      style: Vt.headingMd.copyWith(color: Vt.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Vt.s12),
            const Divider(color: Vt.borderSubtle, height: 1),
            const SizedBox(height: Vt.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(OrderDto o) {
    Color c;
    switch (o.status) {
      case OrderStatus.pending:
        c = Vt.gold.withValues(alpha: 0.6); break;
      case OrderStatus.paid:
      case OrderStatus.shipped:
        c = Vt.gold; break;
      case OrderStatus.confirmed:
      case OrderStatus.received:
        c = Vt.textPrimary; break;
      case OrderStatus.canceled:
      case OrderStatus.refundReq:
      case OrderStatus.refunded:
        c = Vt.statusError; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s12, vertical: Vt.s4),
      decoration: BoxDecoration(border: Border.all(color: c)),
      child: Text(o.status.label, style: Vt.cnLabel.copyWith(color: c, fontSize: 10)),
    );
  }

  List<Widget> _buildActions(OrderDto o) {
    final notifier = ref.read(myOrdersProvider(_side).notifier);
    if (_side == OrderSide.buyer) {
      if (o.status == OrderStatus.pending) {
        return [
          _ghostBtn('取 消', () => notifier.cancel(o.id)),
          const SizedBox(width: Vt.s8),
          _solidBtn('付 款', () async {
            final ok = await showPaymentSheet(context, o);
            if (ok) await notifier.refresh();
          }),
        ];
      } else if (o.status == OrderStatus.shipped) {
        return [_solidBtn('确 认 收 货', () => notifier.confirm(o.id))];
      }
    } else {
      if (o.status == OrderStatus.paid) {
        return [_solidBtn('发 货', () => notifier.ship(o.id))];
      }
    }
    return [];
  }

  Widget _ghostBtn(String label, VoidCallback onTap) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Vt.s16, vertical: Vt.s8),
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Vt.borderMedium),
          ),
        ),
        child: Text(
          label,
          style: Vt.cnLabel
              .copyWith(color: Vt.textTertiary, fontSize: Vt.t2xs),
        ),
      ),
    );
  }

  Widget _solidBtn(String label, VoidCallback onTap) {
    return SpringTap(
      onTap: onTap,
      glow: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Vt.s16, vertical: Vt.s8),
        decoration: const BoxDecoration(color: Vt.gold),
        child: Text(
          label,
          style: Vt.cnLabel.copyWith(color: Vt.bgVoid, fontSize: Vt.t2xs),
        ),
      ),
    );
  }
}
