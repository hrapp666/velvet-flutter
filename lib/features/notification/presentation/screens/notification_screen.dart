// ============================================================================
// NotificationScreen · 通知中心
// ============================================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Stack(
          children: [
            // 金色 ambient
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
                AsyncData(:final value) => ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      padding.top + 110,
                      0,
                      padding.bottom + 80,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    itemCount: value.length,
                    separatorBuilder: (_, __) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: Vt.s24),
                      child: Container(
                        height: 1,
                        color: Vt.gold.withValues(alpha: 0.08),
                      ),
                    ),
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
                  _errorState(padding, error.toString()),
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

            // Header
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: padding.top + 16,
                      left: 20,
                      right: 32,
                      bottom: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Vt.bgVoid.withValues(alpha: 0.85),
                      border: Border(
                        bottom: BorderSide(
                          color: Vt.gold.withValues(alpha: 0.18),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Vt.gold,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '通  知',
                          style: Vt.cnDisplay.copyWith(
                            letterSpacing: 8,
                            color: Vt.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Vt.gold.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'NOTICE',
                          style: Vt.label.copyWith(
                            color: Vt.textTertiary,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              Container(
                width: 56,
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Vt.gold,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '— 暂 无 通 知 —',
                style: Vt.cnHeading.copyWith(
                  fontSize: Vt.tmd,
                  letterSpacing: 6,
                  color: Vt.gold.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '懂的人 · 自会来敲你的门',
                style: Vt.bodySm.copyWith(
                  color: Vt.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState(EdgeInsets padding, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: padding.top + 120, left: 32, right: 32),
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
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Vt.gold, width: 1),
            ),
            child: Text(
              icon,
              style: Vt.headingMd.copyWith(
                fontWeight: FontWeight.w500,
                color: Vt.gold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Vt.cnBody.copyWith(
                    color: Vt.textGoldSoft,
                    height: 1.4,
                    letterSpacing: 0.5,
                  ),
                ),
                if (notif.content?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    notif.content!,
                    style: Vt.cnBody.copyWith(
                      color: Vt.textSecondary,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          Text(
            time,
            style: Vt.bodySm.copyWith(
              color: Vt.textTertiary,
              fontSize: Vt.t2xs,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
