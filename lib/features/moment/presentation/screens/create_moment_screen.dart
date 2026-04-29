// ============================================================================
// CreateMomentScreen · 发布动态页
// ----------------------------------------------------------------------------
// 视觉策略：
//   - 顶部：返回 X + 标题"私 藏 上 架" + 右上发布按钮（金色 outline + 文字）
//   - 媒体网格：3 列方块，左上角"+"添加，已添加图右上 X 删除
//   - 标题字段：单行 + 光标金色
//   - 描述字段：多行 + 自适应高度
//   - 价格 + 同城开关（金色 toggle）
//   - 标签：chip 选择器
//   - 全部使用 Vt 系统
// ============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/moment_model.dart';
import '../providers/moment_provider.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final List<String> _selectedTags = [];
  final List<String> _mediaUrls = []; // 真实 finalUrl 列表
  bool _isForSale = true;
  bool _localOnly = false;
  bool _publishing = false;
  bool _uploading = false;

  // ── 同城 / 地理坐标 (E1) ──
  /// 用户实际坐标（toggle 同城后请求）
  double? _publishLat;
  double? _publishLng;
  bool _locating = false;
  String? _geoError;

  static const _availableTags = [
    '诚信交易', '面交', '同城', '可议', '不议', '全新', '九成新',
    '私藏', '只给懂的人', '稀缺', '故事款', '原主自用',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
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

  /// 请求定位（同城 toggle on 时自动调）
  Future<void> _pickGeoForPublish() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _geoError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _geoError = '系 统 定 位 已 关 闭';
          _locating = false;
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _geoError = '需 要 定 位 权 限';
          _locating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _publishLat = pos.latitude;
        _publishLng = pos.longitude;
        _locating = false;
        _geoError = null;
      });
    } on Object catch (_) {
      // 静默原因:Geolocator 抛 PlatformException 含平台细节 · 不向用户暴露
      if (!mounted) return;
      setState(() {
        _geoError = '定 位 失 败 · 请 检 查 权 限';
        _locating = false;
      });
    }
  }

  /// 同城 toggle 切换：on → 自动请求定位；off → 清空坐标
  void _onLocalOnlyChanged(bool v) {
    setState(() {
      _localOnly = v;
      if (!v) {
        _publishLat = null;
        _publishLng = null;
        _geoError = null;
      }
    });
    if (v) _pickGeoForPublish();
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
      final priceText = _priceCtrl.text.trim();
      final priceCents =
          (_isForSale && priceText.isNotEmpty) ? (int.tryParse(priceText) ?? 0) * 100 : null;

      final body = CreateMomentBody(
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        content: content,
        hasItem: _isForSale && priceCents != null && priceCents > 0,
        itemPriceCents: priceCents,
        tags: List<String>.from(_selectedTags),
        mediaUrls: List<String>.from(_mediaUrls), // 真实 mediaUrls 链接
        location: _localOnly ? _locationCtrl.text.trim() : null,
        // 同城 toggle on + 定位成功时一起 POST，让 nearby 能查
        latitude: _localOnly ? _publishLat : null,
        longitude: _localOnly ? _publishLng : null,
      );

      final repo = ref.read(momentRepositoryProvider);
      await repo.create(body);

      // 刷新 feed
      await ref.read(feedProvider.notifier).refresh();

      if (!mounted) return;
      unawaited(HapticService.instance.success());
      VelvetToast.show(context, '发布成功 ✦');
      context.go('/feed');
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
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded, color: Vt.textPrimary),
                  ),
                ),
                const SizedBox(width: Vt.s12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Vt.statusWaiting, Vt.gold],
                    stops: [0, 0.8],
                  ).createShader(bounds),
                  child: Text(
                    'VELVET',
                    style: Vt.headingSm.copyWith(
                      color: Colors.white,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
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
                    '上 架 一 件',
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
                            '立 即 上 架',
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
                bottom: padding.bottom + Vt.s40,
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

                  const SizedBox(height: Vt.s16),

                  // ─── 是否售卖 ───
                  _ToggleRow(
                    label: '挂出价格',
                    value: _isForSale,
                    onChanged: (v) => setState(() => _isForSale = v),
                  ),

                  if (_isForSale) ...[
                    const SizedBox(height: Vt.s16),
                    _SectionLabel(label: '期望价格'),
                    const SizedBox(height: Vt.s8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('¥', style: Vt.price.copyWith(fontSize: Vt.tlg)),
                        const SizedBox(width: Vt.s8),
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: Vt.priceLg,
                            cursorColor: Vt.gold,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: Vt.priceLg.copyWith(color: Vt.textTertiary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(height: 1, color: Vt.borderHairline),
                    const SizedBox(height: Vt.s12),
                    // ─── 平台抽佣 6% · 担保交易 ───
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _priceCtrl,
                      builder: (_, value, __) {
                        final price = double.tryParse(value.text) ?? 0;
                        final fee = price * 0.06;
                        return Row(
                          children: [
                            Text(
                              '平台抽佣 6% · 担保交易',
                              style: Vt.bodySm.copyWith(
                                color: Vt.textTertiary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              price > 0 ? '¥ ${fee.toStringAsFixed(2)}' : '— —',
                              style: Vt.bodySm.copyWith(
                                color: Vt.gold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: Vt.s32),

                  // ─── 仅同城 ───
                  _ToggleRow(
                    label: '仅限同城',
                    value: _localOnly,
                    onChanged: _onLocalOnlyChanged,
                  ),

                  if (_localOnly) ...[
                    const SizedBox(height: Vt.s16),
                    _SectionLabel(label: '城市'),
                    const SizedBox(height: Vt.s8),
                    TextField(
                      controller: _locationCtrl,
                      style: Vt.bodyLg.copyWith(color: Vt.textPrimary),
                      cursorColor: Vt.gold,
                      decoration: InputDecoration(
                        hintText: '选择城市',
                        hintStyle: Vt.bodyLg.copyWith(color: Vt.textTertiary),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Vt.gold,
                          size: 18,
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 28),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Container(height: 1, color: Vt.borderHairline),

                    // ─ 地理坐标状态 (E1) ─
                    const SizedBox(height: Vt.s12),
                    _GeoStatusRow(
                      lat: _publishLat,
                      lng: _publishLng,
                      locating: _locating,
                      error: _geoError,
                      onRetry: _pickGeoForPublish,
                    ),
                  ],

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
                            '买家在平台付款 · 平台担保 · 卖家发货后放款\n禁止私下交易 · 禁止留下任何第三方联系方式',
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
// 同城坐标状态行 (E1) — 4 状态：定位中 / 已锁定 / 失败 / 未触发
// 设计原则（Vt.* token 单一真相源 + 4 态都有视觉反馈）
// ============================================================================
class _GeoStatusRow extends StatelessWidget {
  final double? lat;
  final double? lng;
  final bool locating;
  final String? error;
  final VoidCallback onRetry;

  const _GeoStatusRow({
    required this.lat,
    required this.lng,
    required this.locating,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // 状态优先级：locating > error > located > idle
    final Widget body;
    final Color borderColor;
    // hoist field → local (Dart flow analysis 不能 promote widget field)
    final localLat = lat;
    final localLng = lng;
    final localError = error;

    if (locating) {
      borderColor = Vt.gold.withValues(alpha: 0.5);
      body = Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.4, color: Vt.gold),
          ),
          const SizedBox(width: Vt.s12),
          Text(
            '正 在 寻 你 …',
            style: Vt.cnLabel.copyWith(
              color: Vt.gold,
              letterSpacing: 4,
              fontSize: Vt.tsm,
            ),
          ),
        ],
      );
    } else if (localError != null) {
      borderColor = Vt.warn.withValues(alpha: 0.5);
      body = Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Vt.warn, size: 16),
          const SizedBox(width: Vt.s8),
          Expanded(
            child: Text(
              localError,
              style: Vt.bodySm.copyWith(color: Vt.textSecondary),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              '重 试',
              style: Vt.cnLabel.copyWith(
                color: Vt.gold,
                letterSpacing: 3,
                fontSize: Vt.txs,
              ),
            ),
          ),
        ],
      );
    } else if (localLat != null && localLng != null) {
      borderColor = Vt.gold;
      body = Row(
        children: [
          Icon(Icons.near_me_rounded, color: Vt.gold, size: 14),
          const SizedBox(width: Vt.s8),
          Expanded(
            child: Text(
              '已 锁 定 · ${localLat.toStringAsFixed(4)}, ${localLng.toStringAsFixed(4)}',
              style: Vt.label.copyWith(
                color: Vt.gold,
                fontSize: Vt.txs,
                letterSpacing: 1.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Icon(Icons.refresh_rounded,
                color: Vt.gold.withValues(alpha: 0.6), size: 14),
          ),
        ],
      );
    } else {
      borderColor = Vt.borderSubtle;
      body = Row(
        children: [
          Icon(Icons.location_searching_rounded,
              color: Vt.textTertiary, size: 14),
          const SizedBox(width: Vt.s8),
          Expanded(
            child: Text(
              '尚 未 标 记 位 置',
              style: Vt.bodySm.copyWith(color: Vt.textTertiary),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              '获 取',
              style: Vt.cnLabel.copyWith(
                color: Vt.gold,
                letterSpacing: 3,
                fontSize: Vt.txs,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Vt.s12, vertical: Vt.s12),
      decoration: BoxDecoration(
        color: Vt.bgElevated,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: body,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Vt.s8),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Vt.bodyLg.copyWith(color: Vt.textPrimary)),
            ),
            // 自定义金色 toggle
            AnimatedContainer(
              duration: Vt.fast,
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? Vt.gold.withValues(alpha: 0.3) : Vt.bgElevated,
                borderRadius: BorderRadius.circular(Vt.rPill),
                border: Border.all(
                  color: value ? Vt.gold : Vt.borderSubtle,
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: Vt.fast,
                curve: Vt.curveDefault,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: value ? Vt.gold : Vt.textTertiary,
                    shape: BoxShape.circle,
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: Vt.gold.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
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
