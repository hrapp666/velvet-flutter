// ============================================================================
// CreateMomentScreen · 发布动态页（v26 苹果合规：纯分享，无支付）
// ----------------------------------------------------------------------------
// 视觉策略：
//   - 顶部：返回 X + 标题"分 享 好 物" + 右上发布按钮（金色 outline + 文字）
//   - 媒体网格：3 列方块，左上角"+"添加，已添加图右上 X 删除
//   - 标题字段：单行 + 光标金色
//   - 描述字段：多行 + 自适应高度
//   - 同城开关（金色 toggle）+ 标签 chip 选择器
//   - 全部使用 Vt 系统
// ============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  final List<String> _selectedTags = [];
  final List<String> _mediaUrls = []; // 真实 finalUrl 列表
  bool _publishing = false;
  bool _uploading = false;

  static const _availableTags = [
    '好物推荐', '线下体验', '拍摄分享', '首次亮相', '全新', '九成新',
    '私藏', '只给懂的人', '稀缺', '故事款', '原主自用',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMedia() async {
    if (_mediaUrls.length >= 9) return;
    if (_uploading) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(
        imageQuality: 85,
        limit: 9 - _mediaUrls.length,
      );
      if (picked.isEmpty) return;
      setState(() => _uploading = true);
      final repo = ref.read(uploadRepositoryProvider);
      for (final xfile in picked) {
        try {
          final url = await repo.uploadFile(File(xfile.path));
          if (!mounted) return;
          setState(() => _mediaUrls.add(url));
        } on Object catch (e) {
          if (!mounted) return;
          // 用 userMessageOf 过滤异常对象 · 不向用户暴露内部细节
          final msg = userMessageOf(e, fallback: '上传失败，请重试');
          if (msg.isNotEmpty) {
            VelvetToast.show(context, msg, isError: true);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaUrls.removeAt(index));
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _publish() async {
    unawaited(HapticService.instance.heavy());
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      VelvetToast.show(context, '描述不能为空');
      return;
    }
    setState(() => _publishing = true);
    try {
      // v34 · 同城/定位入口已下线 · 仅保留纯文本+图片分享
      final body = CreateMomentBody(
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        content: content,
        tags: List<String>.from(_selectedTags),
        mediaUrls: List<String>.from(_mediaUrls),
      );

      final repo = ref.read(momentRepositoryProvider);
      await repo.create(body);

      // 刷新 feed
      await ref.read(feedProvider.notifier).refresh();

      if (!mounted) return;
      unawaited(HapticService.instance.success());
      // v26 苹果合规：先审后发，明确告知用户审核中
      VelvetToast.show(context, '已提交，审核通过后展示 ✦');
      context.go('/profile');
    } on AppException catch (e) {
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      VelvetToast.show(context, '发布失败：${e.message}', isError: true);
    } on Object catch (_) {
      // 静默原因：上面已捕获 AppException，这里是 unknown 兜底，向用户隐藏内部细节
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      VelvetToast.show(context, '发布失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // 键盘高度 · TextField 在中下部，键盘弹出时需让滚动区底部留足空间避免遮挡
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Vt.bgPrimary,
      body: Column(
        children: [
          // ─ Header ─
          Container(
            padding: EdgeInsets.only(
              top: padding.top + Vt.s12,
              left: Vt.s16,
              right: Vt.s16,
              bottom: Vt.s12,
            ),
            decoration: BoxDecoration(
              color: Vt.bgPrimary,
              border: Border(
                bottom: BorderSide(color: Vt.borderHairline, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    unawaited(HapticService.instance.light());
                    // bottom-tab 进 /create 时 stack 空 · pop 无效 → fallback 到 feed
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/feed');
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded, color: Vt.textPrimary),
                  ),
                ),
                const SizedBox(width: Vt.s12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Vt.statusWaiting, Vt.gold],
                        stops: [0, 0.8],
                      ).createShader(bounds),
                      child: Text(
                        'VELVET',
                        maxLines: 1,
                        softWrap: false,
                        style: Vt.headingSm.copyWith(
                          color: Colors.white,
                          letterSpacing: 3.5,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Vt.s12),
                Container(
                  width: 1,
                  height: 14,
                  color: Vt.gold.withValues(alpha: 0.3),
                ),
                const SizedBox(width: Vt.s12),
                Expanded(
                  child: Text(
                    '分 享 好 物',
                    style: Vt.headingSm.copyWith(
                      color: Vt.gold.withValues(alpha: 0.82),
                      letterSpacing: 3,
                      fontSize: Vt.txs,
                    ),
                  ),
                ),
                SpringTap(
                  onTap: _publishing ? null : _publish,
                  glow: !_publishing,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Vt.s14, vertical: Vt.s8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Vt.gold, Vt.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(Vt.rPill),
                      boxShadow: _publishing ? null : [
                        BoxShadow(
                          color: Vt.gold.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: _publishing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '立 即 分 享',
                            style: Vt.button.copyWith(
                              color: Colors.white,
                              fontSize: Vt.tsm,
                              letterSpacing: 0.6,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ─ 内容 ─
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: Vt.s20,
                right: Vt.s20,
                top: Vt.s24,
                // 键盘弹出时把键盘高度算进底部 padding · 避免输入框被遮挡
                bottom: padding.bottom + Vt.s40 + keyboard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 媒体网格 ───
                  _SectionLabel(label: '图片 / 视频'),
                  const SizedBox(height: Vt.s12),
                  _MediaGrid(
                    items: _mediaUrls,
                    onAdd: _addMedia,
                    onRemove: _removeMedia,
                  ),

                  const SizedBox(height: Vt.s32),

                  // ─── 标题 ───
                  _SectionLabel(label: '标题（可选）'),
                  const SizedBox(height: Vt.s8),
                  TextField(
                    controller: _titleCtrl,
                    style: Vt.headingMd.copyWith(color: Vt.textPrimary),
                    cursorColor: Vt.gold,
                    decoration: InputDecoration(
                      hintText: '一句话说明白',
                      hintStyle: Vt.headingMd.copyWith(color: Vt.textTertiary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLength: 32,
                  ),
                  Container(height: 1, color: Vt.borderHairline),

                  const SizedBox(height: Vt.s24),

                  // ─── 描述 ───
                  _SectionLabel(label: '描述'),
                  const SizedBox(height: Vt.s8),
                  TextField(
                    controller: _contentCtrl,
                    style: Vt.bodyLg.copyWith(color: Vt.textPrimary, height: 1.6),
                    cursorColor: Vt.gold,
                    maxLines: 6,
                    minLines: 3,
                    decoration: InputDecoration(
                      hintText: '细细说说这件好物的故事…',
                      hintStyle: Vt.bodyLg.copyWith(color: Vt.textTertiary, height: 1.6),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLength: 2000,
                  ),

                  // v32: 同城/定位入口下线（实测定位无效，先移除）
                  const SizedBox(height: Vt.s32),

                  // ─── 标签 ───
                  _SectionLabel(label: '标签'),
                  const SizedBox(height: Vt.s12),
                  Wrap(
                    spacing: Vt.s8,
                    runSpacing: Vt.s8,
                    children: _availableTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: AnimatedContainer(
                          duration: Vt.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Vt.gold.withValues(alpha: 0.15)
                                : Vt.bgElevated,
                            borderRadius: BorderRadius.circular(Vt.rPill),
                            border: Border.all(
                              color: selected ? Vt.gold : Vt.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: Vt.bodySm.copyWith(
                              color: selected ? Vt.gold : Vt.textSecondary,
                              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: Vt.s48),

                  // ─── 提示 ───
                  Container(
                    padding: const EdgeInsets.all(Vt.s16),
                    decoration: BoxDecoration(
                      color: Vt.bgElevated,
                      borderRadius: BorderRadius.circular(Vt.rMd),
                      border: Border.all(color: Vt.borderHairline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: Vt.gold),
                        const SizedBox(width: Vt.s8),
                        Expanded(
                          child: Text(
                            '只 分 享 好 物 · 不 涉 及 任 何 交 易\n请 勿 在 描 述 中 留 下 第 三 方 联 系 方 式',
                            style: Vt.bodySm.copyWith(
                              color: Vt.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Vt.label.copyWith(
        color: Vt.gold,
        letterSpacing: 1.6,
        fontSize: Vt.t2xs,
      ),
    );
  }
}

// ============================================================================
// 媒体网格（3 列 + 添加按钮 + 删除按钮）
// ============================================================================
class _MediaGrid extends StatelessWidget {
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _MediaGrid({
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final showAddButton = items.length < 9;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Vt.s8,
        crossAxisSpacing: Vt.s8,
      ),
      itemCount: items.length + (showAddButton ? 1 : 0),
      itemBuilder: (context, index) {
        if (showAddButton && index == items.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: Vt.bgElevated,
                borderRadius: BorderRadius.circular(Vt.rSm),
                border: Border.all(
                  color: Vt.borderSubtle,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Vt.textTertiary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length}/9',
                    style: Vt.label.copyWith(color: Vt.textTertiary),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Vt.rSm),
              child: Image.network(
                items[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: Vt.bgElevated,
                    borderRadius: BorderRadius.circular(Vt.rSm),
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Vt.gold.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Vt.bgVoid.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Vt.borderMedium, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Vt.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
