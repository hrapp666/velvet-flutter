// ============================================================================
// Chat Providers · Riverpod
// ============================================================================

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
    final repo = ref.read(chatRepositoryProvider);
    final list = await repo.listMessages(conversationId, page: 0, size: 50);
    // 标记已读
    repo.markRead(conversationId).catchError((_) {});
    return list;
  }

  /// 发消息（适用于已有会话 — 用 conversation 的 otherUserId）
  Future<void> sendInExisting(int otherUserId, String content) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.send(otherUserId: otherUserId, content: content);
    // 重新加载
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => repo.listMessages(arg, page: 0, size: 50));
  }
}
