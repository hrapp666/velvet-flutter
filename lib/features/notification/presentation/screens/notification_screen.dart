// ============================================================================
// NotificationScreen · v2 H5 Editorial Luxury 对齐
// ----------------------------------------------------------------------------
// 对照 H5 styles.css §2370-2438 .notif-item / .notif-empty / .header
// 视觉锚点：VELVET mark + 通知 est + 返回 link · item 24x32 + 38x38 0角icon
//          (gold-50 边 + gold-04 底 + glow) + cn t (w300) + cn italic c
// ============================================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  String _iconFor(String type) {
    switch (type) {
      case 'LIKE':
        return '♥';
      case 'FAVORITE':
        return '✦';
      case 'FOLLOW':
        return '◇';
      case 'COMMENT':
        return '§';
      case 'DM':
        return '✉';
      default:
        return '·';
    }
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${t.month}-${t.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.paddingOf(context);
    final async = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Stack(
        children: [
          // 全屏暗金 ambient（H5 #notifications + radial gradient ambient）
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.5),
                  radius: 1.4,
                  colors: Vt.gradientAmbient,
                ),
              ),
            ),
          ),
          // 顶部金光 ambient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.0,
                    colors: [
                      Vt.gold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 主体
          RefreshIndicator(
            color: Vt.gold,
            backgroundColor: Vt.bgVoid,
            onRefresh: () =>
                ref.read(notificationListProvider.notifier).refresh(),
            child: switch (async) {
              AsyncData(:final value) when value.isEmpty =>
                _emptyState(padding),
              AsyncData(:final value) => ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    padding.top + 110,
                    0,
                    padding.bottom + 80,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  itemCount: value.length,
                  itemBuilder: (context, i) {
                    final n = value[i];
                    return _NotifTile(
                      notif: n,
                      icon: _iconFor(n.type),
                      time: _formatTime(n.createdAt),
                    );
                  },
                ),
              AsyncError(:final error) =>
                _errorState(padding, userMessageOf(error, fallback: '通知加载失败')),
              _ => Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: padding.top + 120),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Vt.gold,
                      ),
                    ),
                  ),
                ),
            },
          ),

          // Editorial header
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _NotifHeader(),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(EdgeInsets padding) {
    return ListView(
      padding: EdgeInsets.only(top: padding.top + 200),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        Center(
          child: Column(
            children: [
              // H5 .notif-empty::before — ❦ serif 衬线 t-2xl gold opacity .45
              Text(
                '❦',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: Vt.t2xl,
                  color: Vt.gold.withValues(alpha: 0.45),
                  shadows: [
                    Shadow(
                      color: Vt.gold.withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '暂 无 通 知',
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.txl,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.36 * Vt.txl,
                  color: Vt.goldLight,
                  shadows: [
                    Shadow(
                      color: Vt.gold.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '懂的人 · 自会来敲你的门',
                style: Vt.cnBody.copyWith(
                  fontSize: Vt.tsm,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.10 * Vt.tsm,
                  color: Vt.textTertiary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState(EdgeInsets padding, String error) {
    return ListView(
      padding: EdgeInsets.only(top: padding.top + 200),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 32, color: Vt.gold.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text(
                  '— 加 载 失 败 —',
                  style: Vt.cnHeading.copyWith(
                    fontSize: Vt.tsm,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Editorial Header — H5 .header pattern: VELVET mark + 通知 est + 返回 link
// ============================================================================
class _NotifHeader extends StatelessWidget {
  const _NotifHeader();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: padding.top + 14,
            left: 24,
            right: 24,
            bottom: 18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Vt.bgVoid.withValues(alpha: 0.88),
                Vt.bgVoid.withValues(alpha: 0.55),
                Colors.transparent,
              ],
              stops: const [0, 0.6, 1],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 返回 ←
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Text(
                          '←',
                          style: Vt.headingLg.copyWith(
                            fontSize: Vt.tlg,
                            fontWeight: FontWeight.w300,
                            color: Vt.gold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // VELVET mark
                  Text(
                    'VELVET',
                    style: Vt.headingLg.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: Vt.txl,
                      letterSpacing: 8,
                      color: Vt.goldLight,
                      shadows: [
                        Shadow(
                          color: Vt.gold.withValues(alpha: 0.55),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Vt.gold.withValues(alpha: 0.30),
                  ),
                  Text(
                    '通 知',
                    style: Vt.cnLabel.copyWith(
                      fontSize: Vt.txs,
                      letterSpacing: 0.28 * Vt.txs,
                      color: Vt.gold.withValues(alpha: 0.78),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
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
// NotifTile — 对照 H5 .notif-item §2373
// padding 24x32 · 38x38 0角 icon (gold-50 边 + gold-04 底 + glow)
// cn t · cn italic c · serif italic time
// ============================================================================
class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final String icon;
  final String time;
  const _NotifTile({
    required this.notif,
    required this.icon,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // H5 .notif-item: padding 24px 32px · border-bottom 1px gold-15
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Vt.gold.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // icon — H5 .notif-icon: 38x38 · 0 圆角 · gold-50 边 · gold-04 底 · glow
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Vt.gold.withValues(alpha: 0.04),
              border: Border.all(
                color: Vt.gold.withValues(alpha: 0.50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Vt.gold.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(
              icon,
              style: Vt.headingMd.copyWith(
                fontSize: Vt.tlg,
                fontWeight: FontWeight.w400,
                color: Vt.gold,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // text 列：t（标题）+ c（内容 italic）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notif.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Vt.cnBody.copyWith(
                    fontSize: Vt.tmd,
                    fontWeight: FontWeight.w300,
                    color: Vt.textGoldSoft,
                    letterSpacing: 0.04 * Vt.tmd,
                    height: 1.5,
                  ),
                ),
                if (notif.content?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    notif.content!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Vt.cnBody.copyWith(
                      fontSize: Vt.tsm,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: Vt.textTertiary,
                      letterSpacing: 0.04 * Vt.tsm,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // time — serif italic gold opacity .55
          Text(
            time,
            style: Vt.bodySm.copyWith(
              fontSize: Vt.t2xs,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
              color: Vt.textTertiary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
