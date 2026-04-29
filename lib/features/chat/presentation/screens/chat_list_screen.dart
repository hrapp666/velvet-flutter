// ============================================================================
// ChatListScreen · v14 H5 Editorial Luxury 对齐
// ----------------------------------------------------------------------------
// 对照 H5 styles.css §3330-3425 .chat-row / .chats-list / .header
// 视觉锚点：VELVET mark + 私语 est + 返回 link + 24x28 row + 56 圆头像
//          (gold 边 + radial 暗金底) + 8px gold dot 呼吸 + L 角 hover 装饰
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/editorial/page_fleuron.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 顶部金色 ambient（H5 #chats radial 暗金底）
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

          // 主体列表
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
              AsyncData(:final value) => ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    padding.top + 110,
                    0,
                    padding.bottom + 100,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  // +1 给 page-fleuron 章节封底
                  itemCount: value.length + 1,
                  itemBuilder: (context, i) {
                    if (i == value.length) {
                      return const PageFleuron(caption: 'Velvet · Whispers');
                    }
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
              AsyncError(:final error) => _errorState(padding, userMessageOf(error, fallback: '会话加载失败')),
              _ => const ChatListSkeleton(),
            },
          ),

          // 顶部 editorial header — H5 .header pattern (VELVET mark + 私语 est + 返回 link)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _EditorialHeader(),
          ),
        ],
      ),
    );
  }

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
                  fontSize: Vt.tmd,
                  letterSpacing: 0.5,
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

// ============================================================================
// Editorial Header — H5 .header pattern
// VELVET mark (Cormorant w500 t-xl) | 竖线 | 私 语 (cn t-xs) | spacer
// 底部 24px inset gold-30 渐变细线
// ============================================================================
class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader();

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
                  // VELVET mark (Cormorant w500, ivory→gold shader 替代为单色)
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
                  // 竖线分隔
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Vt.gold.withValues(alpha: 0.30),
                  ),
                  // 私 语 est
                  Text(
                    '私 语',
                    style: Vt.cnLabel.copyWith(
                      fontSize: Vt.tsm,
                      letterSpacing: 0.5,
                      color: Vt.gold.withValues(alpha: 0.78),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              // header-line — 底部 24px inset gold-30 渐变
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
// ConvTile — 对照 H5 .chat-row §3364
// padding 24x28 · 56 gold 圆头像 · serif name + italic when + cn last + dot
// ============================================================================
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
      child: Container(
        // H5 .chat-row: padding 24px 28px · border-bottom 1px gold-15
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
            // 头像 — H5 .chat-avatar (56x56 圆形 gold-50 边 radial 暗金底)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.4, -0.4),
                  colors: [Vt.bgVoidEmber, Vt.bgPureBlack],
                ),
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.50),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Vt.gold.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  conv.otherUserNickname.isNotEmpty
                      ? conv.otherUserNickname.substring(0, 1)
                      : '·',
                  style: Vt.headingLg.copyWith(
                    fontSize: Vt.txl,
                    fontWeight: FontWeight.w500,
                    color: Vt.gold,
                    shadows: [
                      Shadow(
                        color: Vt.gold.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // 名字 + 时间 + 最后一条
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // top 行：name + when (baseline 对齐)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUserNickname,
                          style: Vt.headingLg.copyWith(
                            fontSize: Vt.tlg,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.04 * Vt.tlg,
                            color: Vt.textGoldSoft,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatTime(conv.lastMessageAt),
                        style: Vt.bodySm.copyWith(
                          fontSize: Vt.txs,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.3,
                          color: Vt.textTertiary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // last 行：cn body w300 · 1 line ellipsis
                  Text(
                    conv.lastMessageContent ?? '— 暂无消息 —',
                    style: Vt.cnBody.copyWith(
                      fontSize: Vt.tsm,
                      fontWeight: FontWeight.w300,
                      color: Vt.textTertiary,
                      letterSpacing: 0.04 * Vt.tsm,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 未读 dot — GlowPulse 呼吸（H5 §3416 .chat-row .dot 2s glow）
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
