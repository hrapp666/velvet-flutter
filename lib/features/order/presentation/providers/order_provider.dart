// ============================================================================
// OrderProvider · 订单状态
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return OrderRepositoryImpl(api);
});

/// 我的订单（按买家或卖家侧）
final myOrdersProvider = AsyncNotifierProvider.family<
    MyOrdersNotifier, List<OrderDto>, OrderSide>(
  MyOrdersNotifier.new,
);

class MyOrdersNotifier
    extends FamilyAsyncNotifier<List<OrderDto>, OrderSide> {
  @override
  Future<List<OrderDto>> build(OrderSide side) async {
    final repo = ref.read(orderRepositoryProvider);
    final page = await repo.listMine(side, page: 0, size: 30);
    return page.content;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> cancel(int orderId) async {
    await ref.read(orderRepositoryProvider).cancel(orderId);
    ref.invalidateSelf();
  }

  Future<void> ship(int orderId, {String? trackingNo, String? sellerNote}) async {
    await ref
        .read(orderRepositoryProvider)
        .ship(orderId, trackingNo: trackingNo, sellerNote: sellerNote);
    ref.invalidateSelf();
  }

  Future<void> confirm(int orderId) async {
    await ref.read(orderRepositoryProvider).confirm(orderId);
    ref.invalidateSelf();
  }
}
