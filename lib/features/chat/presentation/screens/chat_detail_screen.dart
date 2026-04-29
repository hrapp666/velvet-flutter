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

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../safety/safety_dialogs.dart';
import '../../data/models/chat_models.dart';
import '../../data/services/chat_socket.dart';
import '../providers/chat_provider.dart';

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
  StreamSubscription<WsConnectionState>? _wsStateSub;
  WsConnectionState _wsState = WsConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _wsState = ChatSocket.instance.currentState;
    // 启动 WS（如果还没连）
    unawaited(ChatSocket.instance.connect());
    // 订阅实时消息 · append-only 不触发 REST reload
    // 关键修复:之前用 ref.invalidate 导致每条 push 全量重载 + ScrollReveal
    // 重新初始化 50 个 AnimationController → 卡死。改为直接 append。
    _wsSub = ChatSocket.instance.messages.listen((msg) {
      if (msg.conversationId == widget.conversationId && mounted) {
        ref
            .read(messagesProvider(widget.conversationId).notifier)
            .addRemoteMessage(msg);
      }
    });
    // 订阅连接状态 — UI 暴露 reconnecting / failed
    _wsStateSub = ChatSocket.instance.connectionState.listen((s) {
      if (mounted) setState(() => _wsState = s);
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsStateSub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 举报对方 / 拉黑对方（Apple UGC 1.2 合规）
  Future<void> _showSafetySheet(int otherUserId, String? nickname) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetCtx) {
        final padding = MediaQuery.paddingOf(sheetCtx);
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Vt.rLg)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: Vt.bgElevated.withValues(alpha: 0.92),
              padding: EdgeInsets.only(
                top: Vt.s16,
                bottom: padding.bottom + Vt.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetTile(
                    sheetCtx,
                    icon: Icons.flag_outlined,
                    label: '举 报 对 方',
                    value: 'report',
                  ),
                  _buildSheetTile(
                    sheetCtx,
                    icon: Icons.block_outlined,
                    label: '拉 黑 对 方',
                    value: 'block',
                  ),
                  _buildSheetTile(
                    sheetCtx,
                    icon: Icons.close,
                    label: '取 消',
                    value: null,
                    muted: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'report':
        await showReportDialog(
          context,
          ref,
          targetType: ReportTargetType.chat,
          targetId: widget.conversationId,
        );
      case 'block':
        final blocked = await showBlockDialog(
          context,
          ref,
          userId: otherUserId,
          nickname: nickname,
        );
        if (blocked && mounted) {
          context.pop();
        }
    }
  }

  Widget _buildSheetTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required String label,
    required String? value,
    bool muted = false,
  }) {
    return InkWell(
      onTap: () => Navigator.of(sheetCtx).pop(value),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Vt.s24, vertical: Vt.s16),
        child: Row(
          children: [
            Icon(icon,
                color: muted ? Vt.textTertiary : Vt.gold, size: 20),
            const SizedBox(width: Vt.s16),
            Expanded(
              child: Text(
                label,
                style: Vt.cnBody.copyWith(
                  color: muted ? Vt.textTertiary : Vt.textPrimary,
                  letterSpacing: 0.5,
                  fontSize: Vt.tmd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    // 先清输入框 — 乐观插入瞬间消息已经在气泡列表显示
    // 不能等 await sendInExisting 返回才 clear · 否则气泡有了但输入框还留着字
    _inputCtrl.clear();
    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendInExisting(otherId, text);
    } on Object catch (e) {
      if (mounted) {
        // 失败 → 把文字还给输入框 · 让主人能直接重发(微信/iMessage 同款体验)
        _inputCtrl.text = text;
        _inputCtrl.selection = TextSelection.collapsed(offset: text.length);
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
              onMoreTap: () {
                final otherId = widget.prefilledConv?.otherUserId;
                if (otherId == null) {
                  VelvetToast.show(context, '缺少对方信息', isError: true);
                  return;
                }
                _showSafetySheet(
                  otherId,
                  widget.prefilledConv?.otherUserNickname,
                );
              },
            ),

            // ─── WS 连接状态 ───
            _WsBanner(
              state: _wsState,
              onRetry: ChatSocket.instance.manualRetry,
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
                            fontSize: Vt.tmd,
                            letterSpacing: 0.5,
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
                      // reverse:true · value[0] = 最新 · 渲染在底部
                      final msg = value[i];
                      final isMe = myId != null && msg.senderId == myId;
                      // 关键修复:移除 ScrollReveal 包装 · 之前每次 list rebuild
                      // 50 个 bubble 同时 init AnimationController → 主线程冻结
                      // 用 ValueKey(msg.id) 让 ListView 按 id 复用 element
                      return KeyedSubtree(
                        key: ValueKey<int>(msg.id),
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
                              fontSize: Vt.tmd,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userMessageOf(error, fallback: '消息加载失败'),
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
  final VoidCallback onMoreTap;
  const _HeaderBar({
    required this.padding,
    required this.nickname,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // 对照 H5 §3446 .chat-header
    // - 渐变深底 + blur 16 + saturate 1.4
    // - 居中 cn 标题 + ::after 32px 渐变细线
    // - chat-deco ❦ 小衬线装饰
    // - bottom: -1px radial 金色 glow line
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                padding.top + 18,
                20,
                18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Vt.bgPureBlack,
                    Vt.bgVoid.withValues(alpha: 0.97),
                    Vt.bgVoid.withValues(alpha: 0.90),
                  ],
                  stops: const [0, 0.6, 1],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Vt.gold.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          '←',
                          style: Vt.headingLg.copyWith(
                            fontSize: Vt.txl,
                            fontWeight: FontWeight.w300,
                            color: Vt.gold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 标题列 — 居中 + ::after 渐变细线
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          nickname,
                          textAlign: TextAlign.center,
                          style: Vt.cnHeading.copyWith(
                            fontSize: Vt.tmd,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.32 * Vt.tmd, // 0.32em
                            color: Vt.gold,
                            shadows: [
                              Shadow(
                                color: Vt.gold.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // 标题下细线 32x1 gold-50% 渐变
                        Container(
                          width: 32,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Vt.gold.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // chat-deco ❦ + more · 双语义合一
                  GestureDetector(
                    onTap: onMoreTap,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          '❦',
                          style: Vt.headingLg.copyWith(
                            fontSize: Vt.tlg,
                            fontWeight: FontWeight.w400,
                            color: Vt.gold.withValues(alpha: 0.7),
                            shadows: [
                              Shadow(
                                color: Vt.gold.withValues(alpha: 0.65),
                                blurRadius: 16,
                              ),
                            ],
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // header bottom radial glow line
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.2,
              right: MediaQuery.sizeOf(context).width * 0.2,
              bottom: -1,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Vt.gold.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
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

  /// L 角装饰 — 12x12，由两条边构成 L 形
  /// alignment 决定保留哪两条边（朝向气泡内部的两条不画）
  Widget _corner({required Alignment alignment, required Color color}) {
    // H5 .bubble::before / ::after：12x12 + border 1px，
    // 移除朝向气泡内的两条 border（保留朝外的两条）
    BorderSide side(bool keep) =>
        keep ? BorderSide(color: color, width: 1) : BorderSide.none;

    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    return SizedBox(
      width: 12,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: side(isTop),
            bottom: side(!isTop),
            left: side(isLeft),
            right: side(!isLeft),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // H5 §3494 .bubble: rgba(201,169,97,.45) opacity .7
    // H5 §3542 .bubble.me: rgba(201,169,97,.7) opacity .85
    final cornerColor = isMe
        ? Vt.gold.withValues(alpha: 0.7 * 0.85)
        : Vt.gold.withValues(alpha: 0.45 * 0.7);

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
                maxWidth: MediaQuery.sizeOf(context).width * 0.76,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      // H5 §3497/§3529: 对方 2/16/16/16 · 自己 16/2/16/16
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 16 : 2),
                        topRight: Radius.circular(isMe ? 2 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      // H5: 对方 rgba(12,10,6,.92) · 自己 暗金渐变
                      color: isMe ? null : Vt.bgPrimary.withValues(alpha: 0.92),
                      gradient: isMe
                          ? const LinearGradient(
                              begin: Alignment(-0.3, -1),
                              end: Alignment(0.5, 1),
                              colors: Vt.gradientChatBubbleMe,
                              stops: [0, 0.5, 1],
                            )
                          : null,
                      border: Border.all(
                        color: isMe
                            ? Vt.gold.withValues(alpha: 0.55)
                            : Vt.gold.withValues(alpha: 0.22),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: Vt.gold.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: -6,
                              ),
                              const BoxShadow(
                                color: Color(0xB3000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                                spreadRadius: -4,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: Vt.cnBody.copyWith(
                            // H5: 对方 rgba(232,214,178,.9) · 自己 #FAF4E6
                            color: isMe
                                ? Vt.goldIvory
                                : const Color(0xE6E8D6B2),
                            height: 1.95,
                            letterSpacing: 0.3,
                            shadows: isMe
                                ? [
                                    Shadow(
                                      color: Vt.gold.withValues(alpha: 0.18),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: Vt.s12),
                        Align(
                          // H5 §3565: me 时间右对齐 · 对方左对齐
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            _formatTime(msg.createdAt),
                            style: Vt.caption.copyWith(
                              fontSize: Vt.txs,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                              color: Vt.gold.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // L 角装饰 — H5 是对角双角不是四角
                  // 对方气泡 (.bubble:not(.me))：左上 + 右下
                  // 自己气泡 (.bubble.me)：右上 + 左下
                  if (isMe) ...[
                    Positioned(
                      top: -1,
                      right: -1,
                      child: _corner(
                        alignment: Alignment.topRight,
                        color: cornerColor,
                      ),
                    ),
                    Positioned(
                      bottom: -1,
                      left: -1,
                      child: _corner(
                        alignment: Alignment.bottomLeft,
                        color: cornerColor,
                      ),
                    ),
                  ] else ...[
                    Positioned(
                      top: -1,
                      left: -1,
                      child: _corner(
                        alignment: Alignment.topLeft,
                        color: cornerColor,
                      ),
                    ),
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: _corner(
                        alignment: Alignment.bottomRight,
                        color: cornerColor,
                      ),
                    ),
                  ],
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
// WS 连接状态条
// ============================================================================
class _WsBanner extends StatelessWidget {
  final WsConnectionState state;
  final VoidCallback onRetry;
  const _WsBanner({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // 静默 connecting / reconnecting / disconnected 三态 · 避免主人看到 banner 闪烁
    // 只在真正 failed (10 次重连耗尽) 时才提示用户，给重试入口
    if (state != WsConnectionState.failed) {
      return const SizedBox.shrink();
    }
    const label = '消 息 暂 不 实 时';
    const color = Vt.statusError;
    return GestureDetector(
      onTap: onRetry,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: Vt.s16, vertical: Vt.s8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 14, color: color),
            const SizedBox(width: Vt.s8),
            Flexible(
              child: Text(
                label,
                style: Vt.cnLabel.copyWith(
                  color: color,
                  fontSize: Vt.tsm,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Vt.s12),
            Text(
              '点 此 重 连',
              style: Vt.cnLabel.copyWith(
                color: Vt.gold,
                fontSize: Vt.tsm,
                letterSpacing: 0.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
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
          // H5 §3590 .chat-input：border-bottom only · 52px tall · 无背景
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Vt.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: TextField(
                controller: controller,
                style: Vt.cnBody.copyWith(
                  color: Vt.textGoldSoft,
                  letterSpacing: 0.3,
                ),
                cursorColor: Vt.gold,
                minLines: 1,
                maxLines: 1,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '说 一 句 …',
                  hintStyle: Vt.cnBody.copyWith(
                    color: Vt.gold.withValues(alpha: 0.28),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
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
          // H5 §3610 .chat-send：52x52 + L 角装饰（左上+右下）
          SpringTap(
            onTap: sending ? null : onSend,
            glow: !sending,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sending
                          ? Vt.gold.withValues(alpha: 0.2)
                          : Vt.gold.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Vt.gold.withValues(alpha: 0.55),
                      ),
                      boxShadow: sending
                          ? null
                          : [
                              BoxShadow(
                                color: Vt.gold.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: -6,
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
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
                  // L 角装饰：左上 + 右下
                  Positioned(
                    top: -1,
                    left: -1,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.7),
                            ),
                            left: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.7),
                            ),
                            right: BorderSide(
                              color: Vt.gold.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
