// ============================================================================
// Notification providers
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationRepositoryImpl(api);
});

// 通知列表
final notificationListProvider = AsyncNotifierProvider.autoDispose<
    NotificationListNotifier, List<NotificationModel>>(
  NotificationListNotifier.new,
);

class NotificationListNotifier
    extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    final list = await repo.list(page: 0, size: 50);
    // 自动标记全部已读
    repo.markAllRead().catchError((_) {});
    // 拉取未读数后（因为我们刚 markAllRead，会变 0）
    ref.invalidate(unreadCountProvider);
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(notificationRepositoryProvider).list(page: 0, size: 50));
  }
}

// 未读数（feed 顶部小红点用）
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.unreadCount();
});
