// ============================================================================
// PaymentSheet · 选择付款方式的 bottom sheet
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/models/payment_model.dart';
import '../providers/payment_provider.dart';

/// 展示付款方式选择 bottom sheet，并在用户确认后调起 /payments/create + mock-paid。
///
/// 成功返回 true，失败/取消返回 false。
Future<bool> showPaymentSheet(BuildContext context, OrderDto order) async {
  return await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PaymentSheetBody(order: order),
      ) ??
      false;
}

class _PaymentSheetBody extends ConsumerStatefulWidget {
  const _PaymentSheetBody({required this.order});
  final OrderDto order;

  @override
  ConsumerState<_PaymentSheetBody> createState() => _PaymentSheetBodyState();
}

class _PaymentSheetBodyState extends ConsumerState<_PaymentSheetBody> {
  PaymentProvider _selected = PaymentProvider.mock;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final configAsync = ref.watch(paymentConfigProvider);
    final rate = configAsync.valueOrNull?.commissionRate ?? 0.06;
    final commission = (o.priceCents * rate).round();
    final sellerNet = (o.priceCents - commission) / 100.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Vt.bgAmbientSoft, Vt.bgVoid],
        ),
        border: Border(top: BorderSide(color: Vt.gold)),
      ),
      padding: EdgeInsets.fromLTRB(
        Vt.s24, Vt.s16, Vt.s24,
        MediaQuery.viewPaddingOf(context).bottom + Vt.s32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('确 认 支 付', style: Vt.cnHeading.copyWith(color: Vt.gold)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 40, height: 40,
                    child: Icon(Icons.close, color: Vt.gold, size: 18),
                  ),
                ),
              ],
            ),
            const Divider(color: Vt.borderMedium, height: Vt.s24),
            Text('商 品',
                style: Vt.cnLabel.copyWith(color: Vt.textTertiary, fontSize: Vt.t2xs)),
            const SizedBox(height: Vt.s8),
            Text(
              o.titleSnapshot ?? '此件',
              style: Vt.cnBody.copyWith(color: Vt.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Vt.s24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: Vt.s16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Vt.borderMedium, width: 0.5),
                  bottom: BorderSide(color: Vt.borderMedium, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '¥${(o.priceCents / 100).toStringAsFixed(2)}',
                    style: Vt.displayLg.copyWith(
                      color: Vt.gold,
                      shadows: const [Shadow(color: Color(0x80C9A961), blurRadius: 30)],
                    ),
                  ),
                  const SizedBox(height: Vt.s8),
                  Text(
                    '平台抽佣 ${(rate * 100).toStringAsFixed(0)}% · 卖家到手 ¥${sellerNet.toStringAsFixed(2)}',
                    style: Vt.label.copyWith(
                      color: Vt.textTertiary, fontSize: Vt.t2xs,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Vt.s24),
            Text('支 付 方 式',
                style: Vt.cnLabel.copyWith(color: Vt.textTertiary, fontSize: Vt.t2xs)),
            const SizedBox(height: Vt.s12),
            ...PaymentProvider.values.map((p) => _methodTile(p)),
            const SizedBox(height: Vt.s24),
            SpringTap(
              onTap: _submitting ? null : _submit,
              glow: !_submitting,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Vt.s20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _submitting
                      ? Vt.gold.withValues(alpha: 0.3)
                      : Vt.gold,
                ),
                child: Text(
                  _submitting ? '付 款 中' : '确 认 支 付',
                  style: Vt.cnButton.copyWith(color: Vt.bgVoid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(PaymentProvider p) {
    final on = p == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = p),
      child: Container(
        margin: const EdgeInsets.only(bottom: Vt.s12),
        padding: const EdgeInsets.all(Vt.s16),
        decoration: BoxDecoration(
          color: on ? Vt.gold.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(color: on ? Vt.gold : Vt.borderMedium),
          boxShadow: on
              ? [BoxShadow(color: Vt.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -4)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Vt.gold : Vt.gold.withValues(alpha: 0.08),
                border: Border.all(color: Vt.gold),
              ),
              child: Text(
                _iconFor(p),
                style: Vt.headingMd.copyWith(
                  color: on ? Vt.bgVoid : Vt.gold,
                ),
              ),
            ),
            const SizedBox(width: Vt.s16),
            Expanded(
              child: Text(
                p.label,
                style: Vt.cnBody.copyWith(color: Vt.textPrimary),
              ),
            ),
            if (p == PaymentProvider.wechat)
              Text('推 荐',
                  style: Vt.label.copyWith(
                    color: Vt.gold, fontSize: Vt.t2xs,
                    fontStyle: FontStyle.italic,
                  )),
            if (p == PaymentProvider.mock)
              Text('沙 盒',
                  style: Vt.label.copyWith(
                    color: Vt.gold, fontSize: Vt.t2xs,
                    fontStyle: FontStyle.italic,
                  )),
          ],
        ),
      ),
    );
  }

  String _iconFor(PaymentProvider p) {
    switch (p) {
      case PaymentProvider.wechat:
        return '微';
      case PaymentProvider.alipay:
        return '支';
      case PaymentProvider.mock:
        return '◎';
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      await repo.createPayment(
        orderId: widget.order.id,
        provider: _selected,
      );
      if (_selected == PaymentProvider.mock) {
        await repo.mockMarkPaid(widget.order.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      VelvetToast.show(context, '付款失败 · $e', isError: true);
      Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
