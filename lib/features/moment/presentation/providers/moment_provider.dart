// ============================================================================
// MomentProvider · 动态状态管理
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/moment_model.dart';
import '../../data/repositories/comment_repository.dart';
import '../../data/repositories/moment_repository.dart';
import '../../data/repositories/upload_repository.dart';

final momentRepositoryProvider = Provider<MomentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MomentRepositoryImpl(api);
});

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return UploadRepository(api);
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CommentRepositoryImpl(api);
});

// ── 评论 Provider ────────────────────────────────────
final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<CommentModel>, int>(
  CommentsNotifier.new,
);

class CommentsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CommentModel>, int> {
  @override
  Future<List<CommentModel>> build(int momentId) async {
    final repo = ref.read(commentRepositoryProvider);
    return repo.list(momentId, page: 0, size: 30);
  }

  Future<void> send(String content) async {
    final momentId = arg;
    final repo = ref.read(commentRepositoryProvider);
    await repo.create(momentId, content);
    // 重新加载
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.list(momentId, page: 0, size: 30));
  }
}

// ── 同城 / 附近 Provider ──────────────────────────────
/// 用 (lat, lng) 二元组作 family 参数
typedef NearbyArg = ({double lat, double lng, double radiusKm});

final nearbyFeedProvider = AsyncNotifierProvider.autoDispose
    .family<NearbyFeedNotifier, List<MomentModel>, NearbyArg>(
  NearbyFeedNotifier.new,
);

class NearbyFeedNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MomentModel>, NearbyArg> {
  @override
  Future<List<MomentModel>> build(NearbyArg arg) async {
    final repo = ref.read(momentRepositoryProvider);
    return repo.listNearby(
      lat: arg.lat,
      lng: arg.lng,
      radiusKm: arg.radiusKm,
      page: 0,
      size: 30,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(momentRepositoryProvider);
      return repo.listNearby(
        lat: arg.lat,
        lng: arg.lng,
        radiusKm: arg.radiusKm,
        page: 0,
        size: 30,
      );
    });
  }
}

// ── Feed 列表 Provider ──────────────────────────────
final feedProvider = AsyncNotifierProvider.autoDispose<FeedNotifier, List<MomentModel>>(
  FeedNotifier.new,
);

class FeedNotifier extends AutoDisposeAsyncNotifier<List<MomentModel>> {
  int _page = 0;
  bool _hasMore = true;

  @override
  Future<List<MomentModel>> build() async {
    // ref.keepAlive() · 切 tab 不销毁缓存
    // 同事反馈"每次切到首页都会触发刷新状态" = ShellRoute + autoDispose 让
    // FeedScreen 卸载时 provider 也被 dispose,回来时 build() 重新拉数据
    // keepAlive 让 list 在 tab 切换间保持,下拉手势仍可 refresh()
    ref.keepAlive();
    _page = 0;
    _hasMore = true;
    final repo = ref.read(momentRepositoryProvider);
    final result = await repo.listPublic(page: 0, size: 20);
    _hasMore = !result.last;
    return result.content;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(momentRepositoryProvider);
      _page++;
      final result = await repo.listPublic(page: _page, size: 20);
      _hasMore = !result.last;
      return [...current, ...result.content];
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 0;
      _hasMore = true;
      final repo = ref.read(momentRepositoryProvider);
      final result = await repo.listPublic(page: 0, size: 20);
      _hasMore = !result.last;
      return result.content;
    });
  }

  /// 本地立即更新点赞状态（乐观更新），后台调 API
  Future<void> toggleLike(int momentId) async {
    final current = state.value;
    if (current == null) return;

    // 乐观更新
    state = AsyncValue.data(current.map((m) {
      if (m.id != momentId) return m;
      final newLiked = !m.liked;
      return MomentModel(
        id: m.id,
        userId: m.userId,
        userNickname: m.userNickname,
        userAvatarUrl: m.userAvatarUrl,
        title: m.title,
        content: m.content,
        coverUrl: m.coverUrl,
        mediaUrls: m.mediaUrls,
        hasItem: m.hasItem,
        itemPriceCents: m.itemPriceCents,
        itemAttributes: m.itemAttributes,
        tags: m.tags,
        location: m.location,
        visibility: m.visibility,
        status: m.status,
        viewCount: m.viewCount,
        likeCount: m.likeCount + (newLiked ? 1 : -1),
        favoriteCount: m.favoriteCount,
        commentCount: m.commentCount,
        chatCount: m.chatCount,
        liked: newLiked,
        favorited: m.favorited,
        createdAt: m.createdAt,
      );
    }).toList());

    // 后台调 API
    try {
      await ref.read(momentRepositoryProvider).toggleLike(momentId);
    } on Object catch (_) {
      // 静默原因：乐观更新已先行，失败回滚 = 拉整页重建，不阻塞用户
      unawaited(refresh());
    }
  }

  /// 本地立即更新收藏状态（乐观更新），后台调 API
  /// H5 端已统一 like/favorite 语义为收藏 · feed 心形 = favorite
  Future<void> toggleFavorite(int momentId) async {
    final current = state.value;
    if (current == null) return;

    // 乐观更新
    state = AsyncValue.data(current.map((m) {
      if (m.id != momentId) return m;
      final newFavorited = !m.favorited;
      return MomentModel(
        id: m.id,
        userId: m.userId,
        userNickname: m.userNickname,
        userAvatarUrl: m.userAvatarUrl,
        title: m.title,
        content: m.content,
        coverUrl: m.coverUrl,
        mediaUrls: m.mediaUrls,
        hasItem: m.hasItem,
        itemPriceCents: m.itemPriceCents,
        itemAttributes: m.itemAttributes,
        tags: m.tags,
        location: m.location,
        visibility: m.visibility,
        status: m.status,
        viewCount: m.viewCount,
        likeCount: m.likeCount,
        favoriteCount: m.favoriteCount + (newFavorited ? 1 : -1),
        commentCount: m.commentCount,
        chatCount: m.chatCount,
        liked: m.liked,
        favorited: newFavorited,
        createdAt: m.createdAt,
      );
    }).toList());

    // 后台调 API · 失败回滚 + 让收藏列表重新加载
    try {
      await ref.read(momentRepositoryProvider).toggleFavorite(momentId);
    } on Object catch (_) {
      // 静默原因：乐观更新已先行，失败回滚 = 拉整页重建，不阻塞用户
      unawaited(refresh());
    }
  }
}

// ── 详情 Provider ────────────────────────────────────
final momentDetailProvider =
    FutureProvider.autoDispose.family<MomentModel, int>((ref, id) async {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.getById(id);
});

// ── 推荐 Provider (B1 · content-based tag jaccard) ────
final recommendedMomentsProvider =
    AsyncNotifierProvider.autoDispose<RecommendedNotifier, List<MomentModel>>(
  RecommendedNotifier.new,
);

class RecommendedNotifier extends AutoDisposeAsyncNotifier<List<MomentModel>> {
  static const int _limit = 20;

  @override
  Future<List<MomentModel>> build() async {
    final repo = ref.read(momentRepositoryProvider);
    return repo.listRecommended(limit: _limit);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(momentRepositoryProvider);
      return repo.listRecommended(limit: _limit);
    });
  }
}
