// ============================================================================
// ChatDetailScreen · v16.3 ChatRepository + WebSocket 实时
// ----------------------------------------------------------------------------
// 输入消息、加载历史、滚动到底部、自己/对方气泡区分、WebSocket 实时收消息
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../../shared/widgets/motion/scroll_reveal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../../data/services/chat_socket.dart';
import '../providers/chat_provider.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int conversationId;
  /// 从列表跳过来时附带的 conversation 元数据（含 otherUserId/nickname）
  final ConversationModel? prefilledConv;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.prefilledConv,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  StreamSubscription<MessageModel>? _wsSub;

  @override
  void initState() {
    super.initState();
    // 启动 WS（如果还没连）
    ChatSocket.instance.connect();
    // 订阅实时消息
    _wsSub = ChatSocket.instance.messages.listen((msg) {
      // 只处理当前会话
      if (msg.conversationId == widget.conversationId && mounted) {
        // 让 messagesProvider 重新加载
        ref.invalidate(messagesProvider(widget.conversationId));
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    unawaited(HapticService.instance.medium());
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final otherId = widget.prefilledConv?.otherUserId;
    if (otherId == null) {
      VelvetToast.show(context, '找不到对方信息');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendInExisting(otherId, text);
      _inputCtrl.clear();
    } on Object catch (e) {
      if (mounted) {
        VelvetToast.show(context, '发送失败：$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final myId = currentUser?.id;

    return Scaffold(
      backgroundColor: Vt.bgVoid,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Column(
          children: [
            // ─── Header ───
            _HeaderBar(
              padding: padding,
              nickname: widget.prefilledConv?.otherUserNickname ?? '私 语',
            ),

            // ─── 消息列表 ───
            Expanded(
              child: switch (messagesAsync) {
                AsyncData(:final value) when value.isEmpty => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '— 还 没 有 消 息 —',
                          style: Vt.cnHeading.copyWith(
                            fontSize: Vt.tsm,
                            letterSpacing: 5,
                            color: Vt.gold.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '说一句吧',
                          style: Vt.bodySm.copyWith(
                            color: Vt.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                AsyncData(:final value) => ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: value.length,
                    itemBuilder: (context, i) {
                      final msg = value[i];
                      final isMe = myId != null && msg.senderId == myId;
                      // 每个 bubble 淡入 · 无 stagger (reverse=true, 新消息在 i=0)
                      return ScrollReveal(
                        duration: const Duration(milliseconds: 280),
                        fromOffsetY: 12,
                        child: _Bubble(msg: msg, isMe: isMe),
                      );
                    },
                  ),
                AsyncError(:final error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Vt.s32),
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
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: Vt.bodySm.copyWith(color: Vt.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                _ => const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Vt.gold,
                      ),
                    ),
                  ),
              },
            ),

            // ─── 输入区 ───
            _InputBar(
              controller: _inputCtrl,
              sending: _sending,
              onSend: _send,
              bottomPadding: padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================
class _HeaderBar extends StatelessWidget {
  final EdgeInsets padding;
  final String nickname;
  const _HeaderBar({required this.padding, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(
            top: padding.top + 12,
            left: 16,
            right: 24,
            bottom: 16,
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nickname,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: Vt.textGoldSoft,
                    shadows: [
                      Shadow(
                        color: Vt.gold.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 消息气泡（editorial L-corner 装饰，对应 H5 .bubble）
// ============================================================================
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _corner({required Alignment alignment, required Color color}) {
    final topSide = (alignment == Alignment.topLeft || alignment == Alignment.topRight)
        ? BorderSide(color: color, width: 1)
        : BorderSide.none;
    final bottomSide = (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight)
        ? BorderSide(color: color, width: 1)
        : BorderSide.none;
    final leftSide = (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
        ? BorderSide(color: color, width: 1)
        : BorderSide.none;
    final rightSide = (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
        ? BorderSide(color: color, width: 1)
        : BorderSide.none;
    return SizedBox(
      width: 12,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: topSide, bottom: bottomSide, left: leftSide, right: rightSide),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cornerColor = isMe ? Vt.gold : Vt.gold.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Vt.s8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Vt.gold.withValues(alpha: 0.10)
                          : Vt.bgPrimary.withValues(alpha: 0.7),
                      border: Border.all(
                        color: isMe
                            ? Vt.gold.withValues(alpha: 0.45)
                            : Vt.gold.withValues(alpha: 0.18),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: Vt.gold.withValues(alpha: 0.28),
                                blurRadius: 22,
                                spreadRadius: -8,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: Vt.cnBody.copyWith(
                            height: 1.7,
                            letterSpacing: 1.2,
                            color: Vt.textGoldSoft,
                          ),
                        ),
                        const SizedBox(height: Vt.s6),
                        Text(
                          _formatTime(msg.createdAt),
                          style: Vt.caption.copyWith(
                            color: Vt.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 四角 editorial L 装饰 — 金 1px
                  Positioned(
                      top: -1, left: -1, child: _corner(alignment: Alignment.topLeft, color: cornerColor)),
                  Positioned(
                      top: -1, right: -1, child: _corner(alignment: Alignment.topRight, color: cornerColor)),
                  Positioned(
                      bottom: -1, left: -1, child: _corner(alignment: Alignment.bottomLeft, color: cornerColor)),
                  Positioned(
                      bottom: -1, right: -1, child: _corner(alignment: Alignment.bottomRight, color: cornerColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 输入区
// ============================================================================
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final double bottomPadding;
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
      decoration: BoxDecoration(
        color: Vt.bgVoid.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: Vt.gold.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Vt.gold.withValues(alpha: 0.04),
                border: Border.all(
                  color: Vt.gold.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: controller,
                style: Vt.cnBody.copyWith(
                  fontSize: 15,
                  color: Vt.textGoldSoft,
                ),
                cursorColor: Vt.gold,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '说一句…',
                  hintStyle: Vt.cnBody.copyWith(
                    fontSize: 15,
                    color: Vt.gold.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SpringTap(
            onTap: sending ? null : onSend,
            glow: !sending,
            child: Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                color: sending
                    ? Vt.gold.withValues(alpha: 0.2)
                    : Vt.gold.withValues(alpha: 0.06),
                border: Border.all(color: Vt.gold),
                boxShadow: sending
                    ? null
                    : [
                        BoxShadow(
                          color: Vt.gold.withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: -6,
                        ),
                      ],
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Vt.gold,
                        ),
                      )
                    : Text(
                        '寄',
                        style: Vt.cnButton.copyWith(
                          fontSize: Vt.tmd,
                          letterSpacing: 0,
                          color: Vt.gold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
