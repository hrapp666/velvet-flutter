// ============================================================================
// Feed · 动态主页（视觉锚点 #2 — 核心页）
// ----------------------------------------------------------------------------
// 视觉策略：
//   - Pinterest masonry 双列瀑布流（变高卡片）
//   - 顶部毛玻璃 sticky header (Velvet logo + 搜索 + 通知 + 我)
//   - 卡片：图 + vignette + 分享者 (Manrope) + 心动数（v26 苹果合规：纯分享，无价格）
//   - 标签 chip 行：全部 / 关注 / 同城 / 最新
//   - 底部 FAB：发布按钮（樱花粉发光）
//   - 整体黑天鹅绒底 + 1% 酒红
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/editorial/page_fleuron.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/error_state/error_state.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/feed_skeleton.dart';
import '../../../chat/data/models/chat_models.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';
import '../../../../l10n/app_localizations.dart';
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
  // 标记权限是否永久拒绝 · UI 据此展示"前往设置"按钮
  bool _permanentlyDenied = false;
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
    // 仅 0=全部 走分页 loadMore；1=同城 一次性返回不分页（H5 同城单页）
    final isPagedFeed = _selectedTab == 0;
    if (isPagedFeed &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    unawaited(HapticService.instance.selection());
    if (_selectedTab == 1) {
      // 同城 tab refresh = 重新定位
      await _requestLocation(force: true);
    } else {
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
      _permanentlyDenied = false;
    });

    try {
      // 1. 检查 location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = '系 统 定 位 已 关 闭 · 前 往 系 统 设 置 开 启';
          _locatingInProgress = false;
        });
        return;
      }

      // 2. 请求权限
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = '定 位 已 被 永 久 拒 绝 · 请 在 系 统 设 置 中 开 启';
          _permanentlyDenied = true;
          _locatingInProgress = false;
        });
        return;
      }
      if (perm == LocationPermission.denied) {
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
    } on Object catch (_) {
      // 静默原因:Geolocator PlatformException 含平台细节 · 用户友好文案兜底
      if (!mounted) return;
      setState(() {
        _locationError = '定 位 失 败 · 请 检 查 权 限';
        _locatingInProgress = false;
      });
    }
  }

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    if (i == 1) {
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
    if (_selectedTab == 1 && _userLat != null && _userLng != null) {
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                SliverToBoxAdapter(child: SizedBox(height: padding.top + 67)),
                const SliverToBoxAdapter(child: SizedBox(height: 56)),

                // Feed 内容（按 tab 路由）
                ..._buildFeedSlivers(
                  isNearby: _selectedTab == 1,
                  feedAsync: feedAsync,
                  nearbyValue: nearbyValue,
                  nearbyError: nearbyError,
                  nearbyLoading: nearbyLoading,
                ),

                // H5 章节封底 · inline CTA + page-fleuron（仅在全部 tab 显示）
                if (_selectedTab == 0) ...[
                  const SliverToBoxAdapter(child: _PublishInlineCta()),
                  const SliverToBoxAdapter(
                    child: PageFleuron(caption: 'Velvet · Private Collection'),
                  ),
                ],

                // 底部为 tabbar 留白
                SliverToBoxAdapter(child: SizedBox(height: padding.bottom + 96)),
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

          // ─── Tab 选择行 · 紧贴 header 底以建立连贯单元 ───
          Positioned(
            left: 0,
            right: 0,
            top: padding.top + 67,
            child: _TabRow(
              selectedIndex: _selectedTab,
              onChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 同城 tab：定位中 / 定位失败 / 定位成功 → 渲染对应 sliver
  /// 全部 tab：渲染 feedAsync
  List<Widget> _buildFeedSlivers({
    required bool isNearby,
    required AsyncValue<List<MomentModel>> feedAsync,
    required List<MomentModel>? nearbyValue,
    required Object? nearbyError,
    required bool nearbyLoading,
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
              permanentlyDenied: _permanentlyDenied,
              onRetry: () => _requestLocation(force: true),
              onOpenSettings: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        ];
      }
      // 2. 同城列表
      if (nearbyError != null) {
        // userMessageOf 把 DioException/AppException 转成给用户看的中文文案
        final errMsg = userMessageOf(nearbyError, fallback: '附 近 加 载 失 败');
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: errMsg.isEmpty ? '附 近 加 载 失 败' : errMsg,
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
      // 同城坐标 banner · 让用户看见定位是真实生效的(不再"摆设")
      final locationBanner = SliverToBoxAdapter(
        child: _NearbyLocationBanner(
          lat: _userLat!,
          lng: _userLng!,
          radiusKm: 20,
          count: nearbyValue.length,
          onRelocate: () => _requestLocation(force: true),
        ),
      );
      if (nearbyValue.isEmpty) {
        return [
          locationBanner,
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NearbyEmptyState(),
          ),
        ];
      }
      return [locationBanner, _buildMasonry(nearbyValue, isNearby: true)];
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
            child: ErrorState(message: userMessageOf(error, fallback: '加载失败，请下拉重试'), onRetry: _onRefresh),
          ),
        ],
      _ => [
          const SliverToBoxAdapter(child: FeedSkeleton()),
        ],
    };
  }

  Widget _buildMasonry(List<MomentModel> value, {required bool isNearby}) {
    // v5 editorial 单列 — 已抛弃 Pinterest masonry 双列（H5 真相源已迁移到单列）
    return SliverList.builder(
      itemCount: value.length,
      itemBuilder: (context, i) {
        final m = value[i];
        // 标题 fallback: title 不存在时取 content 的首句
        final cardTitle = (m.title?.isNotEmpty ?? false)
            ? m.title!
            : (m.content.length > 28
                ? '${m.content.substring(0, 28)}…'
                : m.content);
        // content lead: 如果 title 已经从 content 抽出，lead 用剩余部分
        final cardContent = (m.title?.isNotEmpty ?? false) ? m.content : '';
        return ScrollReveal(
          // 前 10 张线性 stagger 60ms · 之后统一 600ms 防 200 条延迟炸裂
          delay: Duration(milliseconds: (i * 60).clamp(0, 600)),
          duration: const Duration(milliseconds: 500),
          fromOffsetY: 30,
          child: MomentCard(
            momentId: m.id,
            title: cardTitle,
            content: cardContent,
            sellerName: m.userNickname,
            sellerAvatar: m.userAvatarUrl ?? '',
            likeCount: m.likeCount,
            indexInFeed: i,
            coverColor: _coverFor(m.id),
            location: m.location ?? '',
            createdAt: m.createdAt,
            imageUrl: m.mediaUrls.isNotEmpty ? m.mediaUrls.first : null,
            mediaUrls: m.mediaUrls,
            liked: m.favorited,
            distanceLabel: isNearby ? m.distanceLabel : null,
            tags: m.tags,
            onTap: () => context.push('/moment/${m.id}'),
            onLike: () => ref.read(feedProvider.notifier).toggleFavorite(m.id),
            onChat: () => context.push(
              '/chat/0',
              extra: ConversationModel(
                id: 0,
                otherUserId: m.userId,
                otherUserNickname: m.userNickname,
                otherUserAvatarUrl: m.userAvatarUrl,
                unread: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 同城 tab · 定位 gate（请求权限 / 失败提示）
// ============================================================================
class _LocationGate extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool permanentlyDenied;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  const _LocationGate({
    required this.loading,
    required this.error,
    required this.permanentlyDenied,
    required this.onRetry,
    required this.onOpenSettings,
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
              loading ? '— 正 在 寻 找 你 —' : '— 同 城 在 哪 里 —',
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
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: Vt.gold,
                ),
              )
            else if (permanentlyDenied)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onOpenSettings,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Vt.s32, vertical: Vt.s12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Vt.gold),
                        color: Vt.gold.withValues(alpha: 0.08),
                      ),
                      child: Text(
                        '前 往 系 统 设 置',
                        style: Vt.cnButton.copyWith(
                          color: Vt.gold,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Vt.s12),
                  GestureDetector(
                    onTap: onRetry,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Vt.s12, vertical: Vt.s8),
                      child: Text(
                        '已 在 设 置 中 开 启 · 重 试',
                        style: Vt.bodySm.copyWith(
                          color: Vt.gold.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
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
                    '允 许 定 位',
                    style: Vt.cnButton.copyWith(
                      color: Vt.gold,
                      letterSpacing: 6,
                    ),
                  ),
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

// 同城定位 banner · 显示真实坐标 + 半径 + 数量 · 让"同城"不再是摆设
class _NearbyLocationBanner extends StatelessWidget {
  final double lat;
  final double lng;
  final double radiusKm;
  final int count;
  final VoidCallback onRelocate;

  const _NearbyLocationBanner({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.count,
    required this.onRelocate,
  });

  String _fmt(double v) {
    final hemi = v >= 0 ? '°' : '°';
    return '${v.abs().toStringAsFixed(2)}$hemi';
  }

  @override
  Widget build(BuildContext context) {
    final latLabel =
        '${_fmt(lat)} ${lat >= 0 ? 'N' : 'S'}  ·  ${_fmt(lng)} ${lng >= 0 ? 'E' : 'W'}';
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Vt.s24, Vt.s12, Vt.s24, Vt.s8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Vt.s16, vertical: Vt.s12),
        decoration: BoxDecoration(
          color: Vt.gold.withValues(alpha: 0.04),
          border: Border.all(color: Vt.gold.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(Icons.my_location_rounded,
                size: 14, color: Vt.gold.withValues(alpha: 0.85)),
            const SizedBox(width: Vt.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latLabel,
                    style: Vt.label.copyWith(
                      color: Vt.gold,
                      letterSpacing: 1.5,
                      fontSize: Vt.t2xs,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${radiusKm.toStringAsFixed(0)} km 内 · 找 到 $count 件',
                    style: Vt.cnLabel.copyWith(
                      color: Vt.textSecondary,
                      letterSpacing: 2.5,
                      fontSize: Vt.t2xs,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRelocate,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Vt.s8),
                child: Text(
                  '重 新 定 位',
                  style: Vt.cnLabel.copyWith(
                    color: Vt.gold,
                    letterSpacing: 2,
                    fontSize: Vt.t2xs,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          // H5 editorial: 顶部仅居中 VELVET wordmark + 装饰 fleuron · 不挂功能按钮
          // v28: FittedBox 兜底极窄屏 · soft 行高保证 T 不撞下一行
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'VELVET',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: Vt.headingMd.copyWith(
                    fontSize: Vt.tlg,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.2,
                    height: 1.0,
                    color: Vt.textPrimary,
                    shadows: [
                      Shadow(
                        color: Vt.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '❦',
                style: Vt.headingSm.copyWith(
                  fontSize: Vt.tsm,
                  color: Vt.gold.withValues(alpha: 0.55),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    // H5 styles.css §1233-1283 .feed-subtabs：仅 2 个 tab
    // v25-I1: Labels driven by l10n so locale switch takes effect immediately.
    final l10n = AppLocalizations.of(context);
    // v32: 同城 tab 因定位实测无效已下线 · 仅保留"全部"
    final _tabs = [
      l10n?.feedTabAll ?? '全部',
    ];
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
// 发一件 inline CTA · 替代浮动 FAB（H5 index.html L188 .cta）
// ============================================================================
class _PublishInlineCta extends StatelessWidget {
  const _PublishInlineCta();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: GestureDetector(
            onTap: () {
              unawaited(HapticService.instance.light());
              context.push('/publish');
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Vt.gold.withValues(alpha: 0.55), width: 1),
              ),
              child: Text(
                '发 一 件',
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.tsm,
                  color: Vt.gold,
                  letterSpacing: Vt.tsm * 0.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
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

