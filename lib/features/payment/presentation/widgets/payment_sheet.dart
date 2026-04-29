// ============================================================================
// PaymentSheet · 选择付款方式的 bottom sheet
// ============================================================================

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/api/api_client.dart';
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
  PaymentProvider? _selected;
  bool _submitting = false;

  /// iOS 上架要求：所有数字内容购买必须走 Apple IAP，禁止显示其他通道
  /// Android / Web 维持原有 wechat / alipay / mock 选项
  bool get _isIos => !kIsWeb && Platform.isIOS;

  /// 计算可见的支付方式:
  ///   - iOS：仅 APPLE_IAP（App Store 审核合规 · Guideline 3.1.1）
  ///   - Android / Web：优先 server 配置；release 屏蔽 mock
  List<PaymentProvider> _visibleProviders(PaymentConfig? cfg) {
    if (_isIos) {
      return const [PaymentProvider.apple];
    }
    final base = (cfg != null && cfg.providers.isNotEmpty)
        ? cfg.providers
        : PaymentProvider.values;
    return base
        .where((p) => p != PaymentProvider.apple) // 非 iOS 隐藏 Apple
        .where((p) => !kReleaseMode || p != PaymentProvider.mock)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final configAsync = ref.watch(paymentConfigProvider);
    final rate = configAsync.valueOrNull?.commissionRate ?? 0.06;
    final commission = (o.priceCents * rate).round();
    final sellerNet = (o.priceCents - commission) / 100.0;
    final providers = _visibleProviders(configAsync.valueOrNull);
    // 默认选第一个可见 provider · mock 在 release 已被过滤
    if (_selected == null || !providers.contains(_selected)) {
      _selected = providers.isNotEmpty ? providers.first : null;
    }

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
                      shadows: [Shadow(color: Vt.gold.withValues(alpha: 0.5), blurRadius: 30)],
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
            if (providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Vt.s16),
                child: Text(
                  '暂 无 可 用 支 付 方 式 · 请 稍 后 再 试',
                  style: Vt.cnBody.copyWith(color: Vt.textTertiary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...providers.map(_methodTile),
            const SizedBox(height: Vt.s24),
            SpringTap(
              onTap: (_submitting || _selected == null) ? null : _submit,
              glow: !_submitting && _selected != null,
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
            if (p == PaymentProvider.apple)
              Text('iOS 唯 一',
                  style: Vt.label.copyWith(
                    color: Vt.gold, fontSize: Vt.t2xs,
                    fontStyle: FontStyle.italic,
                  )),
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
      case PaymentProvider.apple:
        return 'A';
      case PaymentProvider.wechat:
        return '微';
      case PaymentProvider.alipay:
        return '支';
      case PaymentProvider.mock:
        return '◎';
    }
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final created = await repo.createPayment(
        orderId: widget.order.id,
        provider: selected,
      );
      if (selected == PaymentProvider.apple) {
        await _runAppleIap(orderId: widget.order.id, payload: created.payload);
      } else if (selected == PaymentProvider.mock) {
        await repo.mockMarkPaid(widget.order.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      // 用 userMessageOf 过滤敏感异常对象 · 不让支付路径泄露内部细节
      final msg = userMessageOf(e, fallback: '付款失败，请稍后再试');
      if (msg.isNotEmpty) {
        VelvetToast.show(context, msg, isError: true);
      }
      Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 拉起 StoreKit 付款 sheet · 完成后上传 receipt 给后端校验。
  /// payload 来自后端 createPayment 返回的 productId JSON。
  Future<void> _runAppleIap({
    required int orderId,
    required String? payload,
  }) async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      throw const _AppleIapException('App Store 不可用，请稍后再试');
    }
    final productId = _extractProductId(payload);
    if (productId == null) {
      throw const _AppleIapException('商品标识缺失，请联系客服');
    }
    final response = await iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      throw const _AppleIapException('商品未上架，请稍后再试');
    }

    // 监听 purchaseStream → 完成后上传 receipt
    final completer = Completer<void>();
    StreamSubscription<List<PurchaseDetails>>? sub;
    sub = iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            try {
              await ref.read(paymentRepositoryProvider).verifyAppleReceipt(
                    orderId: orderId,
                    receipt: p.verificationData.serverVerificationData,
                    transactionId: p.purchaseID,
                  );
              if (p.pendingCompletePurchase) {
                await iap.completePurchase(p);
              }
              if (!completer.isCompleted) completer.complete();
            } on Object catch (e) {
              if (!completer.isCompleted) completer.completeError(e);
            }
          } else if (p.status == PurchaseStatus.error) {
            if (!completer.isCompleted) {
              completer.completeError(_AppleIapException(
                  p.error?.message ?? 'StoreKit 付款失败'));
            }
          } else if (p.status == PurchaseStatus.canceled) {
            if (!completer.isCompleted) {
              completer.completeError(const _AppleIapException('付款已取消'));
            }
          }
        }
      },
      onError: (Object e, _) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
        applicationUserName: _extractApplicationUsername(payload),
      );
      // 数字商品（订单挂载）走 consumable
      final ok = await iap.buyConsumable(purchaseParam: purchaseParam);
      if (!ok) {
        throw const _AppleIapException('无法发起付款');
      }
      await completer.future.timeout(const Duration(minutes: 3));
    } finally {
      await sub.cancel();
    }
  }

  String? _extractProductId(String? payload) =>
      _extractJsonString(payload, 'productId');

  String? _extractApplicationUsername(String? payload) =>
      _extractJsonString(payload, 'applicationUsername');

  /// 简易 JSON 字段抽取 · 后端返回的 payload 是固定结构平铺 string，
  /// 不引入 dart:convert 依赖避免上层不必要的 widget 重建
  String? _extractJsonString(String? payload, String key) {
    if (payload == null || payload.isEmpty) return null;
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]+)"');
    return pattern.firstMatch(payload)?.group(1);
  }
}

class _AppleIapException implements Exception {
  const _AppleIapException(this.message);
  final String message;
  @override
  String toString() => message;
}
