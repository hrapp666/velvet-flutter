// ============================================================================
// Chat Providers · Riverpod
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

/// 乐观插入用的临时 id 起点 · 真实后端 id 一定 >0
const int _kOptimisticIdBase = -1000000;
int _optimisticIdSeed = _kOptimisticIdBase;
int _nextOptimisticId() => --_optimisticIdSeed;

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
  ///
  /// 流程:
  /// 1. 立即把 optimistic message 追加到本地 state(用户秒看到自己发的话 · 不闪屏)
  /// 2. POST 后端
  /// 3. 后端成功 → 后台静默 reload 一次拿真实 id+timestamp(不弹 loading)
  /// 4. 后端失败 → 回滚 optimistic 消息 + 抛错给 UI 提示
  Future<void> sendInExisting(int otherUserId, String content) async {
    final repo = ref.read(chatRepositoryProvider);

    // 1) 乐观插入 — 立即在 UI 显示(占位会话 arg<=0 也走这条路 · 不再延迟到列表刷新)
    final me = await ref.read(currentUserProvider.future);
    final optimistic = MessageModel(
      id: _nextOptimisticId(),
      conversationId: arg,
      senderId: me?.id ?? 0,
      senderNickname: me?.nickname ?? '',
      type: 'TEXT',
      content: content,
      mediaUrl: null,
      refMomentId: null,
      createdAt: DateTime.now(),
    );
    // 后端返回顺序:newest-first(value[0] 最新) · 乐观消息 prepend 到队首
    final prev = state.valueOrNull ?? const <MessageModel>[];
    state = AsyncValue.data([optimistic, ...prev]);

    // 2) POST 真发
    final MessageModel sent;
    try {
      sent = await repo.send(otherUserId: otherUserId, content: content);
    } on Object catch (e, st) {
      // 回滚 optimistic 消息
      state = AsyncValue.data(
        (state.valueOrNull ?? const <MessageModel>[])
            .where((m) => m.id != optimistic.id)
            .toList(),
      );
      Error.throwWithStackTrace(e, st);
    }

    // 3) 用后端真实 message 替换 optimistic(保留位置 · 拿到真实 id+时间戳)
    final cur = state.valueOrNull ?? const <MessageModel>[];
    state = AsyncValue.data([
      for (final m in cur)
        if (m.id == optimistic.id) sent else m,
    ]);

    // 4) 真实会话 → 后台静默 reload 拿全量历史; 占位会话 → 刷会话列表让新会话出现
    if (arg > 0) {
      try {
        final fresh = await repo.listMessages(arg, page: 0, size: 50);
        state = AsyncValue.data(fresh);
      } on Object catch (_) {
        // 静默原因:reload 失败留着 optimistic→sent 替换结果,WS push 或下次进入自动收敛
      }
    } else {
      // 占位会话:后端首条消息会建会话 · 刷列表让新会话项可见
      ref.invalidate(conversationListProvider);
    }
  }

  /// WS push 实时收消息 · 直接 append 到当前 state · 不触发 REST reload
  /// 关键修复:之前 chat_detail_screen 用 ref.invalidate 导致每条 push 都
  /// 把整个列表切到 AsyncValue.loading + 全量 reload + 50 个 ScrollReveal
  /// 重新初始化 AnimationController → 主线程冻结 + "卡死" 体感
  void addRemoteMessage(MessageModel msg) {
    if (msg.conversationId != arg) return;
    final prev = state.valueOrNull;
    if (prev == null) return;
    // 按 id 去重 · 真实 id 一定 >0 · 后端 echo 自己消息时也走这里
    if (prev.any((m) => m.id == msg.id && m.id > 0)) return;
    // 如果是自己刚发的(senderId 匹配 + content 匹配 optimistic),替换 optimistic
    final replaceIdx = prev.indexWhere(
      (m) => m.id < 0 &&
          m.senderId == msg.senderId &&
          m.content == msg.content,
    );
    if (replaceIdx >= 0) {
      final next = [...prev]..[replaceIdx] = msg;
      state = AsyncValue.data(next);
      return;
    }
    // 后端 newest-first · WS push 是新消息 → prepend 到队首
    state = AsyncValue.data([msg, ...prev]);
  }
}
