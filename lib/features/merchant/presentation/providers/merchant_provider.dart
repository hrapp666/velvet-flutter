// ============================================================================
// MerchantProvider · 商家认证状态
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/merchant_model.dart';
import '../../data/repositories/merchant_repository.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MerchantRepositoryImpl(api);
});

/// 我的商家资料
final myMerchantProvider =
    AsyncNotifierProvider<MyMerchantNotifier, MerchantDto?>(
  MyMerchantNotifier.new,
);

class MyMerchantNotifier extends AsyncNotifier<MerchantDto?> {
  @override
  Future<MerchantDto?> build() async {
    final repo = ref.read(merchantRepositoryProvider);
    return repo.myMerchant();
  }

  Future<MerchantDto> apply(MerchantApplyBody body) async {
    final repo = ref.read(merchantRepositoryProvider);
    final m = await repo.apply(body);
    ref.invalidateSelf();
    return m;
  }
}
