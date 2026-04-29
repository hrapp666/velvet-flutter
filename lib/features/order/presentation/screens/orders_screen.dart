// ============================================================================
// OrdersScreen · 我的订单（买家 / 卖家双 tab）· v5 Editorial Luxury
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
            const _Header(),
            _Tabs(
              side: _side,
              onChange: (s) {
                unawaited(HapticService.instance.light());
                setState(() => _side = s);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: Vt.gold,
                backgroundColor: Vt.bgElevated,
                onRefresh: () =>
                    ref.read(myOrdersProvider(_side).notifier).refresh(),
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
                            Vt.s24,
                            Vt.s24,
                            Vt.s24,
                            Vt.s120,
                          ),
                          itemCount: list.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Vt.s16),
                          itemBuilder: (_, i) {
                            if (i == list.length) return const _PageFleuron();
                            return ScrollReveal(
                              delay: Duration(
                                milliseconds: (i * 55).clamp(0, 400),
                              ),
                              duration: const Duration(milliseconds: 480),
                              fromOffsetY: 24,
                              child: _OrderCard(
                                order: list[i],
                                side: _side,
                                actions: _buildActions(list[i]),
                              ),
                            );
                          },
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

  List<Widget> _buildActions(OrderDto o) {
    final notifier = ref.read(myOrdersProvider(_side).notifier);
    if (_side == OrderSide.buyer) {
      switch (o.status) {
        case OrderStatus.pending:
          return [
            _GhostBtn(label: '取 消', onTap: () => notifier.cancel(o.id)),
            const SizedBox(width: Vt.s8),
            _SolidBtn(
              label: '付 款',
              onTap: () async {
                final ok = await showPaymentSheet(context, o);
                if (ok) await notifier.refresh();
              },
            ),
          ];
        case OrderStatus.shipped:
          return [
            _SolidBtn(
              label: '确 认 收 货',
              onTap: () => notifier.confirm(o.id),
            ),
          ];
        case OrderStatus.paid:
        case OrderStatus.received:
        case OrderStatus.confirmed:
        case OrderStatus.canceled:
        case OrderStatus.refundReq:
        case OrderStatus.refunded:
          return const [];
      }
    } else {
      if (o.status == OrderStatus.paid) {
        return [
          _SolidBtn(label: '发 货', onTap: () => notifier.ship(o.id)),
        ];
      }
    }
    return const [];
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Header · VELVET / 订单
// ────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Vt.s16, Vt.s12, Vt.s24, Vt.s12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Vt.gold,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: Vt.s4),
          Text(
            'VELVET',
            style: Vt.displayMd.copyWith(
              fontSize: Vt.tlg,
              fontWeight: FontWeight.w500,
              letterSpacing: 6,
              color: Vt.textPrimary,
            ),
          ),
          const SizedBox(width: Vt.s12),
          Container(width: 1, height: 16, color: Vt.borderMedium),
          const SizedBox(width: Vt.s12),
          Text(
            '订 单',
            style: Vt.cnLabel.copyWith(
              color: Vt.textSecondary,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Text(
            'Receipts',
            style: Vt.label.copyWith(
              color: Vt.gold.withValues(alpha: 0.45),
              fontSize: Vt.t2xs,
              letterSpacing: 3,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tabs · 我买的 / 我卖的 · 32px gradient underline
// ────────────────────────────────────────────────────────────────────────────

class _Tabs extends StatelessWidget {
  final OrderSide side;
  final ValueChanged<OrderSide> onChange;

  const _Tabs({required this.side, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Vt.s20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.09)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabBtn(
            label: '我 买 的',
            on: side == OrderSide.buyer,
            onTap: () => onChange(OrderSide.buyer),
          ),
          const SizedBox(width: Vt.s64),
          _TabBtn(
            label: '我 卖 的',
            on: side == OrderSide.seller,
            onTap: () => onChange(OrderSide.seller),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Vt.cnHeading.copyWith(
              fontSize: Vt.tmd,
              letterSpacing: 6,
              color: on ? Vt.gold : Vt.textTertiary,
              shadows: on
                  ? [
                      Shadow(
                        color: Vt.gold.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: Vt.s8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: on ? 32 : 0,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Vt.gold.withValues(alpha: 0),
                  Vt.gold,
                  Vt.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Order Card · 编辑式 L 角装饰
// ────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderDto order;
  final OrderSide side;
  final List<Widget> actions;

  const _OrderCard({
    required this.order,
    required this.side,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            Vt.s20,
            Vt.s16,
            Vt.s20,
            Vt.s20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Vt.gold.withValues(alpha: 0.06),
                Vt.gold.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(color: Vt.gold.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NO. ${order.id}',
                    style: Vt.label.copyWith(
                      color: Vt.gold.withValues(alpha: 0.5),
                      fontSize: Vt.t2xs,
                      letterSpacing: 3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: Vt.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderCover(url: order.coverSnapshot),
                  const SizedBox(width: Vt.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.titleSnapshot ?? '未 命 名',
                          style: Vt.cnHeading.copyWith(
                            fontSize: Vt.tmd,
                            color: Vt.textPrimary,
                            letterSpacing: 3,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Vt.s8),
                        Text(
                          '${side == OrderSide.buyer ? '卖 家' : '买 家'} · ${side == OrderSide.buyer ? order.sellerNickname : order.buyerNickname}',
                          style: Vt.cnLabel.copyWith(
                            color: Vt.textTertiary,
                            fontSize: Vt.t2xs,
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Vt.s12),
                        _PriceTag(yuan: order.priceYuan),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Vt.s16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Vt.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
        // L corner decorations · 4 角
        const Positioned(
          left: -1,
          top: -1,
          child: _LCorner(alignment: Alignment.topLeft),
        ),
        const Positioned(
          right: -1,
          top: -1,
          child: _LCorner(alignment: Alignment.topRight),
        ),
        const Positioned(
          left: -1,
          bottom: -1,
          child: _LCorner(alignment: Alignment.bottomLeft),
        ),
        const Positioned(
          right: -1,
          bottom: -1,
          child: _LCorner(alignment: Alignment.bottomRight),
        ),
      ],
    );
  }
}

class _LCorner extends StatelessWidget {
  final Alignment alignment;
  const _LCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const color = Vt.gold;
    final top = (alignment == Alignment.topLeft ||
            alignment == Alignment.topRight)
        ? const BorderSide(color: color, width: 1)
        : BorderSide.none;
    final bottom = (alignment == Alignment.bottomLeft ||
            alignment == Alignment.bottomRight)
        ? const BorderSide(color: color, width: 1)
        : BorderSide.none;
    final left = (alignment == Alignment.topLeft ||
            alignment == Alignment.bottomLeft)
        ? const BorderSide(color: color, width: 1)
        : BorderSide.none;
    final right = (alignment == Alignment.topRight ||
            alignment == Alignment.bottomRight)
        ? const BorderSide(color: color, width: 1)
        : BorderSide.none;
    return SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top,
            bottom: bottom,
            left: left,
            right: right,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Status Chip · 状态特定颜色
// ────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final hasGlow = status == OrderStatus.paid;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Vt.s12, vertical: Vt.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Text(
        status.label,
        style: Vt.cnLabel.copyWith(
          color: color,
          fontSize: Vt.t2xs,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    return switch (s) {
      OrderStatus.pending => Vt.gold.withValues(alpha: 0.6),
      OrderStatus.paid => Vt.gold,
      OrderStatus.shipped => Vt.statusSuccess,
      OrderStatus.received => Vt.textPrimary,
      OrderStatus.confirmed => Vt.textPrimary,
      OrderStatus.canceled => Vt.statusError,
      OrderStatus.refundReq => Vt.statusError,
      OrderStatus.refunded => Vt.statusError,
    };
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Cover · 88x88 inset shadow
// ────────────────────────────────────────────────────────────────────────────

class _OrderCover extends StatelessWidget {
  final String? url;
  const _OrderCover({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Vt.bgElevated,
        border: Border.all(color: Vt.gold.withValues(alpha: 0.22)),
        image: url != null
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: url == null
          ? Text(
              '♦',
              style: Vt.displayMd.copyWith(
                fontSize: Vt.txl,
                color: Vt.gold.withValues(alpha: 0.32),
              ),
            )
          : null,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Price · ¥ + glow
// ────────────────────────────────────────────────────────────────────────────

class _PriceTag extends StatelessWidget {
  final double yuan;
  const _PriceTag({required this.yuan});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '¥',
          style: Vt.price.copyWith(
            fontSize: Vt.tlg,
            color: Vt.gold,
            letterSpacing: 1,
            height: 1,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          yuan.toStringAsFixed(2),
          style: Vt.price.copyWith(
            fontSize: Vt.t2xl,
            fontWeight: FontWeight.w500,
            color: Vt.gold,
            letterSpacing: -1,
            height: 1,
            shadows: [
              Shadow(
                color: Vt.gold.withValues(alpha: 0.4),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Buttons · solid gold / ghost ash
// ────────────────────────────────────────────────────────────────────────────

class _SolidBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SolidBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      glow: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Vt.s20,
          vertical: Vt.s12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Vt.goldLight, Vt.gold, Vt.goldDark],
          ),
          boxShadow: [
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(
          label,
          style: Vt.cnButton.copyWith(
            color: Vt.bgVoid,
            fontSize: Vt.tsm,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Vt.s20,
          vertical: Vt.s12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Vt.gold.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: Vt.cnButton.copyWith(
            color: Vt.textSecondary,
            fontSize: Vt.tsm,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Page Fleuron · 收尾装饰
// ────────────────────────────────────────────────────────────────────────────

class _PageFleuron extends StatelessWidget {
  const _PageFleuron();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Vt.s40, Vt.s48, Vt.s40, Vt.s24),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: Vt.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Vt.s8),
                child: Text(
                  '❦',
                  style: Vt.displayMd.copyWith(
                    fontSize: Vt.tmd,
                    color: Vt.gold.withValues(alpha: 0.55),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Vt.gold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Vt.s12),
          Text(
            'Velvet · Orders',
            style: Vt.label.copyWith(
              color: Vt.textTertiary,
              fontSize: Vt.t2xs,
              letterSpacing: 5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
