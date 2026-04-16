// ============================================================================
// Feed · 动态主页（视觉锚点 #2 — 核心页）
// ----------------------------------------------------------------------------
// 视觉策略：
//   - Pinterest masonry 双列瀑布流（变高卡片）
//   - 顶部毛玻璃 sticky header (Velvet logo + 搜索 + 通知 + 我)
//   - 卡片：图 + vignette + 价格(Marcellus SC) + 卖家 (Manrope) + 心动数
//   - 标签 chip 行：全部 / 关注 / 同城 / 最新
//   - 底部 FAB：发布按钮（樱花粉发光）
//   - 整体黑天鹅绒底 + 1% 酒红
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/feed_skeleton.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';
import '../widgets/moment_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _selectedTab = 0;
  final ScrollController _scrollCtrl = ScrollController();

  // ── 同城 tab 状态 ─────────────────────────
  /// 用户当前位置（首次进同城 tab 时请求）
  double? _userLat;
  double? _userLng;
  bool _locatingInProgress = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 仅普通 feedProvider tab (0 全部 / 1 关注) 走分页 loadMore
    // 2 同城 / 3 推荐 都是一次性返回，不需要 loadMore
    final isPagedFeed = _selectedTab == 0 || _selectedTab == 1;
    if (isPagedFeed &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    unawaited(HapticService.instance.selection());
    switch (_selectedTab) {
      case 2:
        // 同城 tab refresh = 重新定位
        await _requestLocation(force: true);
      case 3:
        // 推荐 tab refresh = 重新请求
        await ref.read(recommendedMomentsProvider.notifier).refresh();
      default:
        await ref.read(feedProvider.notifier).refresh();
    }
  }

  /// 请求位置权限并获取当前坐标
  Future<void> _requestLocation({bool force = false}) async {
    if (!force && _userLat != null && _userLng != null) return;
    if (_locatingInProgress) return;

    setState(() {
      _locatingInProgress = true;
      _locationError = null;
    });

    try {
      // 1. 检查 location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = '系 统 定 位 已 关 闭';
          _locatingInProgress = false;
        });
        return;
      }

      // 2. 请求权限
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = '需 要 定 位 权 限 才 能 看 同 城';
          _locatingInProgress = false;
        });
        return;
      }

      // 3. 获取位置
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locatingInProgress = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = '定位失败：$e';
        _locatingInProgress = false;
      });
    }
  }

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    if (i == 2) {
      _requestLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    // 同城 tab：watch nearby provider；其他 tab：watch feed provider
    final List<MomentModel>? nearbyValue;
    final Object? nearbyError;
    final bool nearbyLoading;
    if (_selectedTab == 2 && _userLat != null && _userLng != null) {
      final nearbyAsync = ref.watch(nearbyFeedProvider((
        lat: _userLat!,
        lng: _userLng!,
        radiusKm: 20,
      )));
      nearbyValue = nearbyAsync.value;
      nearbyError = nearbyAsync.error;
      nearbyLoading = nearbyAsync.isLoading;
    } else {
      nearbyValue = null;
      nearbyError = null;
      nearbyLoading = false;
    }

    final feedAsync = ref.watch(feedProvider);
    // 推荐 tab · 只在选中时才实际触发 provider build (autoDispose 空闲释放)
    final recommendedAsync = _selectedTab == 3
        ? ref.watch(recommendedMomentsProvider)
        : null;

    return Scaffold(
      backgroundColor: Vt.bgPrimary,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // ─── 主滚动 ───
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: Vt.gold,
            backgroundColor: Vt.bgElevated,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top + 96)),
                const SliverToBoxAdapter(child: SizedBox(height: 56)),

                // Feed 内容（按 tab 路由）
                ..._buildFeedSlivers(
                  isNearby: _selectedTab == 2,
                  isRecommended: _selectedTab == 3,
                  feedAsync: feedAsync,
                  nearbyValue: nearbyValue,
                  nearbyError: nearbyError,
                  nearbyLoading: nearbyLoading,
                  recommendedAsync: recommendedAsync,
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // ─── Sticky Header（毛玻璃）───
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _GlassHeader(topPadding: padding.top),
          ),

          // ─── Tab 选择行 ───
          Positioned(
            left: 0,
            right: 0,
            top: padding.top + 96,
            child: _TabRow(
              selectedIndex: _selectedTab,
              onChanged: _onTabChanged,
            ),
          ),

          // ─── 底部发布 FAB ───
          Positioned(
            right: Vt.s24,
            bottom: padding.bottom + Vt.s24,
            child: const _PublishFab(),
          ),
        ],
      ),
    );
  }

  /// 同城 tab：定位中 / 定位失败 / 定位成功 → 渲染对应 sliver
  /// 推荐 tab：渲染 recommendedAsync
  /// 其他 tab：直接渲染 feedAsync
  List<Widget> _buildFeedSlivers({
    required bool isNearby,
    required bool isRecommended,
    required AsyncValue<List<MomentModel>> feedAsync,
    required List<MomentModel>? nearbyValue,
    required Object? nearbyError,
    required bool nearbyLoading,
    required AsyncValue<List<MomentModel>>? recommendedAsync,
  }) {
    if (isNearby) {
      // 1. 还没拿到坐标 → 显示定位状态
      if (_userLat == null || _userLng == null) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _LocationGate(
              loading: _locatingInProgress,
              error: _locationError,
              onRetry: () => _requestLocation(force: true),
            ),
          ),
        ];
      }
      // 2. 同城列表
      if (nearbyError != null) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: nearbyError.toString(),
              onRetry: () => _requestLocation(force: true),
            ),
          ),
        ];
      }
      if (nearbyValue == null || nearbyLoading) {
        return [
          const SliverToBoxAdapter(child: FeedSkeleton()),
        ];
      }
      if (nearbyValue.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NearbyEmptyState(),
          ),
        ];
      }
      return [_buildMasonry(nearbyValue, isNearby: true)];
    }

    // 推荐 tab
    if (isRecommended && recommendedAsync != null) {
      return switch (recommendedAsync) {
        AsyncData(:final value) when value.isEmpty => [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: '— 还 没 懂 你 的 品 味 —',
                subtitle: '多点几个心动，让时间帮你找知己',
              ),
            ),
          ],
        AsyncData(:final value) => [_buildMasonry(value, isNearby: false)],
        AsyncError(:final error) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(message: error.toString(), onRetry: _onRefresh),
            ),
          ],
        _ => [
            const SliverToBoxAdapter(child: FeedSkeleton()),
          ],
      };
    }

    // 普通 tab
    return switch (feedAsync) {
      AsyncData(:final value) when value.isEmpty => [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: '— 还 没 有 故 事 —',
              subtitle: '点底部 + 来挂第一件',
            ),
          ),
        ],
      AsyncData(:final value) => [_buildMasonry(value, isNearby: false)],
      AsyncError(:final error) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(message: error.toString(), onRetry: _onRefresh),
          ),
        ],
      _ => [
          const SliverToBoxAdapter(child: FeedSkeleton()),
        ],
    };
  }

  Widget _buildMasonry(List<MomentModel> value, {required bool isNearby}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s12),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: Vt.s12,
        crossAxisSpacing: Vt.s12,
        childCount: value.length,
        itemBuilder: (context, i) {
          final m = value[i];
          return ScrollReveal(
            // 前 10 张线性 stagger 60ms · 之后统一 600ms 防 200 条延迟炸裂
            delay: Duration(milliseconds: (i * 60).clamp(0, 600)),
            duration: const Duration(milliseconds: 500),
            fromOffsetY: 30,
            child: MomentCard(
              momentId: m.id,
              title: m.title ?? m.content,
              sellerName: m.userNickname,
              sellerAvatar: m.userAvatarUrl ?? '',
              priceCents: m.itemPriceCents ?? 0,
              likeCount: m.likeCount,
              coverHeight: 240.0 + (m.id * 31 % 5) * 60,
              coverColor: _coverFor(m.id),
              location: m.location ?? '',
              imageUrl: m.mediaUrls.isNotEmpty ? m.mediaUrls.first : null,
              liked: m.liked,
              distanceLabel: isNearby ? m.distanceLabel : null,
              onTap: () => context.push('/moment/${m.id}'),
              onLike: () => ref.read(feedProvider.notifier).toggleLike(m.id),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 同城 tab · 定位 gate（请求权限 / 失败提示）
// ============================================================================
class _LocationGate extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  const _LocationGate({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              loading ? Icons.my_location_rounded : Icons.location_on_outlined,
              size: 38,
              color: Vt.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: Vt.s24),
            Text(
              loading ? '— 正 在 寻 找 你 —' : '— 同  城  在  哪  里 —',
              style: Vt.cnHeading.copyWith(
                color: Vt.gold,
                letterSpacing: 6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Vt.s16),
            if (error != null)
              Text(
                error!,
                style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '需 要 定 位 权 限 · 才 能 看 见 附 近 的 私 藏',
                style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: Vt.s32),
            if (!loading)
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Vt.s32, vertical: Vt.s12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Vt.gold),
                    color: Vt.gold.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    '允  许  定  位',
                    style: Vt.cnButton.copyWith(
                      color: Vt.gold,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: Vt.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined,
              size: 38, color: Vt.gold.withValues(alpha: 0.5)),
          const SizedBox(height: Vt.s16),
          Text(
            '— 同 城 暂 无 私 藏 —',
            style: Vt.cnHeading.copyWith(
              color: Vt.gold.withValues(alpha: 0.85),
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: Vt.s8),
          Text(
            '懂 的 人 · 还 没 来 你 这 一 带',
            style: Vt.bodySm.copyWith(color: Vt.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 毛玻璃 Header
// ============================================================================
class _GlassHeader extends StatelessWidget {
  final double topPadding;
  const _GlassHeader({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: Vt.glassBlur, sigmaY: Vt.glassBlur),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding + Vt.s12,
            left: Vt.s20,
            right: Vt.s20,
            bottom: Vt.s12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Vt.bgPrimary.withValues(alpha: 0.85),
                Vt.bgPrimary.withValues(alpha: 0.6),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Vt.borderHairline, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo wordmark
              Text(
                'VELVET',
                style: Vt.displayMd.copyWith(
                  fontSize: 22,
                  letterSpacing: 4.0,
                  color: Vt.textPrimary,
                  shadows: [
                    Shadow(
                      color: Vt.gold.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 钻石分割
              Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 4,
                  height: 4,
                  color: Vt.gold,
                ),
              ),
              const Spacer(),
              // 搜索按钮
              _IconBtn(
                icon: Icons.search_rounded,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(width: Vt.s8),
              // 通知按钮
              _IconBtn(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: Vt.s8),
              // 个人入口
              _IconBtn(
                icon: Icons.person_outline_rounded,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vt.glassFill,
          shape: BoxShape.circle,
          border: Border.all(color: Vt.glassBorder, width: 1),
        ),
        child: Icon(icon, color: Vt.textPrimary, size: 18),
      ),
    );
  }
}

// ============================================================================
// Tab 选择行（极简文字 tab + 单一下划线）
// ============================================================================
class _TabRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _TabRow({required this.selectedIndex, required this.onChanged});

  static const _tabs = ['全部', '关注', '同城', '推荐'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Vt.bgPrimary.withValues(alpha: 0.7),
            Vt.bgPrimary.withValues(alpha: 0),
          ],
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Vt.s20),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: Vt.s24),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () {
              unawaited(HapticService.instance.light());
              onChanged(i);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Vt.fast,
                  style: Vt.headingSm.copyWith(
                    color: selected ? Vt.textPrimary : Vt.textTertiary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  child: Text(_tabs[i]),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: Vt.normal,
                  curve: Vt.curveCinematic,
                  width: selected ? 24 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Vt.gold,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Vt.gold.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 发布 FAB（樱花粉发光球）
// ============================================================================
class _PublishFab extends StatelessWidget {
  const _PublishFab();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/publish'),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Vt.goldIvory, Vt.gold, Vt.goldDeepest],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.55),
              blurRadius: 32,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.3),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Vt.bgVoid,
          size: 30,
        ),
      ),
    );
  }
}

// ============================================================================
// 空 / 加载 / 错误状态
// ============================================================================
// _EmptyState 已迁移到 lib/shared/widgets/empty_state/empty_state.dart
// feed_screen 内引用改为 EmptyState(title:..., subtitle:...)

// _ErrorState 已迁移到 lib/shared/widgets/error_state/error_state.dart
// feed_screen 内引用改为 ErrorState(message: ..., onRetry: ...)

Color _coverFor(int id) {
  return Vt.moodCoverVariants[id.abs() % Vt.moodCoverVariants.length];
}

