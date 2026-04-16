// ============================================================================
// WalletProvider · 钱包/提现状态
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return WalletRepositoryImpl(api);
});

/// 我的钱包
final myWalletProvider = AsyncNotifierProvider<MyWalletNotifier, WalletDto>(
  MyWalletNotifier.new,
);

class MyWalletNotifier extends AsyncNotifier<WalletDto> {
  @override
  Future<WalletDto> build() async {
    final repo = ref.read(walletRepositoryProvider);
    return repo.myWallet();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(walletRepositoryProvider);
      return repo.myWallet();
    });
  }
}

/// 我的提现记录
final myWithdrawalsProvider =
    AsyncNotifierProvider<MyWithdrawalsNotifier, List<WithdrawalDto>>(
  MyWithdrawalsNotifier.new,
);

class MyWithdrawalsNotifier extends AsyncNotifier<List<WithdrawalDto>> {
  @override
  Future<List<WithdrawalDto>> build() async {
    final repo = ref.read(walletRepositoryProvider);
    final page = await repo.myWithdrawals(page: 0, size: 30);
    return page.content;
  }

  Future<WithdrawalDto> requestWithdraw(WithdrawRequestBody body) async {
    final repo = ref.read(walletRepositoryProvider);
    final wd = await repo.requestWithdraw(body);
    // 刷新钱包 + 列表
    ref.invalidate(myWalletProvider);
    ref.invalidateSelf();
    return wd;
  }
}
