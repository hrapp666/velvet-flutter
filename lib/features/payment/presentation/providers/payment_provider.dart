// ============================================================================
// PaymentProvider · 支付配置 + 调起支付
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return PaymentRepositoryImpl(api);
});

/// 支付配置（佣金率 + provider 列表）
final paymentConfigProvider = FutureProvider<PaymentConfig>((ref) async {
  final repo = ref.read(paymentRepositoryProvider);
  return repo.getConfig();
});
