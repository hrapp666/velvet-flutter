// ============================================================================
// Chat Providers · Riverpod
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ChatRepositoryImpl(api);
});

// 会话列表
final conversationListProvider = AsyncNotifierProvider.autoDispose<
    ConversationListNotifier, List<ConversationModel>>(
  ConversationListNotifier.new,
);

class ConversationListNotifier
    extends AutoDisposeAsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    // keepAlive 让会话列表在 tab 切换间保持,refresh() 仍可手动刷新
    ref.keepAlive();
    final repo = ref.read(chatRepositoryProvider);
    return repo.listConversations(page: 0, size: 50);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(chatRepositoryProvider)
        .listConversations(page: 0, size: 50));
  }
}

// 某会话的消息列表 (family by conversationId)
final messagesProvider = AsyncNotifierProvider.autoDispose
    .family<MessagesNotifier, List<MessageModel>, int>(MessagesNotifier.new);

class MessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, int> {
  @override
  Future<List<MessageModel>> build(int conversationId) async {
    // 占位会话（从动态详情进入但还未发送过消息）→ 直接空列表，不调后端
    if (conversationId <= 0) return const <MessageModel>[];
    final repo = ref.read(chatRepositoryProvider);
    final list = await repo.listMessages(conversationId, page: 0, size: 50);
    // 标记已读 · fire-and-forget
    // 静默原因:markRead 失败不影响消息展示 · 下次进入会重试
    unawaited(repo.markRead(conversationId).catchError((_) {}));
    return list;
  }

  /// 发消息（适用于已有会话 — 用 conversation 的 otherUserId）
  Future<void> sendInExisting(int otherUserId, String content) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.send(otherUserId: otherUserId, content: content);
    // 占位会话首条消息 → 后端会自动建会话，刷新列表让用户在会话列表里看到
    if (arg <= 0) {
      ref.invalidate(conversationListProvider);
      return;
    }
    // 已有会话 → 重新加载消息
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => repo.listMessages(arg, page: 0, size: 50));
  }
}
