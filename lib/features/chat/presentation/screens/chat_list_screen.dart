// ============================================================================
// ChatListScreen · v13 真接 ChatRepository
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state/empty_state.dart';
import '../../../../shared/widgets/micro/glow_pulse.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../../shared/widgets/skeleton/chat_list_skeleton.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟';
    if (diff.inHours < 24) return '${diff.inHours} 小时';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${t.month}-${t.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.paddingOf(context);
    final convsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      extendBodyBehindAppBar: true,
      body: Stack(
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
                ref.read(conversationListProvider.notifier).refresh(),
            child: switch (convsAsync) {
              AsyncData(:final value) when value.isEmpty => Padding(
                  padding: EdgeInsets.only(top: padding.top + 120),
                  child: const EmptyState(
                    title: '— 还 没 有 私 语 —',
                    subtitle: '懂的人 · 自然会来找你',
                  ),
                ),
              AsyncData(:final value) => ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    padding.top + 110,
                    0,
                    padding.bottom + 100,
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
                    final c = value[i];
                    return ScrollReveal(
                      // 前 8 条 stagger 50ms · 后续 400ms 兜底
                      delay: Duration(milliseconds: (i * 50).clamp(0, 400)),
                      duration: const Duration(milliseconds: 450),
                      fromOffsetY: 20,
                      child: _ConvTile(conv: c, formatTime: _formatTime),
                    );
                  },
                ),
              AsyncError(:final error) => _errorState(padding, error.toString()),
              _ => const ChatListSkeleton(),
            },
          ),

          // 顶部毛玻璃 header
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
                    left: 32,
                    right: 32,
                    bottom: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Vt.bgVoid.withValues(alpha: 0.85),
                        Vt.bgVoid.withValues(alpha: 0.5),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Vt.gold.withValues(alpha: 0.18),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '私  语',
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
                        'NOTES',
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
    );
  }

  // _emptyState 已迁移到 lib/shared/widgets/empty_state/empty_state.dart

  Widget _errorState(EdgeInsets padding, String error) {
    return ListView(
      padding: EdgeInsets.only(top: padding.top + 200),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        Center(
          child: Column(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final String Function(DateTime?) formatTime;
  const _ConvTile({required this.conv, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticService.instance.selection());
        context.push('/chat/${conv.id}', extra: conv);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            // 头像 — 金边
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  colors: [Vt.bgAmbientSoft, Vt.bgAmbientBottom],
                ),
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  conv.otherUserNickname.isNotEmpty
                      ? conv.otherUserNickname.substring(0, 1)
                      : '·',
                  style: Vt.headingLg.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Vt.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 名字 + 最后消息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUserNickname,
                          style: Vt.headingSm.copyWith(
                            color: Vt.textGoldSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatTime(conv.lastMessageAt),
                        style: Vt.bodySm.copyWith(
                          color: Vt.textTertiary,
                          fontSize: Vt.t2xs,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conv.lastMessageContent ?? '— 暂无消息 —',
                    style: Vt.cnBody.copyWith(
                      color: Vt.textSecondary,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 未读 dot · GlowPulse 呼吸光晕 · "有人找你"的仪式感
            if (conv.unread > 0) ...[
              const SizedBox(width: 12),
              const GlowPulse(
                maxOpacity: 0.55,
                maxBlur: 14,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Vt.gold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
