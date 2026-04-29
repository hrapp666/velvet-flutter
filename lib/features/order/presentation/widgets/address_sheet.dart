// ============================================================================
// AddressSheet · 收货地址 + 下单 bottom sheet · H5 1:1
// ----------------------------------------------------------------------------
// H5 truth source: app.js openAddrSheet() / submitAddrAndOrder()
//   - 字段: 收货人 (≤32) · 手机号 11 位 ^1\d{10}$ · 收货地址 (≤200)
//   - 校验失败 toast: '请填写收货人' / '手机号格式不正确' / '请填写收货地址'
//   - 提交按钮: '确 认 下 单' (默认) / '下 单 中' (loading)
//   - 成功: 关闭 sheet → 调用 onSubmitted(order) (上层打开 PaymentSheet)
//   - 持久化 key: 'velvet_shipping_addr' (SharedPreferences JSON)
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

const String _kAddrPrefsKey = 'velvet_shipping_addr';

/// 展示收货地址 sheet,提交成功返回 OrderDto,取消/失败返回 null。
Future<OrderDto?> showAddressSheet(
  BuildContext context, {
  required int momentId,
}) async {
  return await showModalBottomSheet<OrderDto>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _AddressSheetBody(momentId: momentId),
  );
}

class _AddressSheetBody extends ConsumerStatefulWidget {
  const _AddressSheetBody({required this.momentId});
  final int momentId;

  @override
  ConsumerState<_AddressSheetBody> createState() => _AddressSheetBodyState();
}

class _AddressSheetBodyState extends ConsumerState<_AddressSheetBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addrCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addrCtrl = TextEditingController();
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kAddrPrefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      _nameCtrl.text = (map['name'] as String?) ?? '';
      _phoneCtrl.text = (map['phone'] as String?) ?? '';
      _addrCtrl.text = (map['address'] as String?) ?? '';
    } on Object catch (_) {
      // 静默原因:本地缓存解析失败不影响输入,用户重新填即可
    }
  }

  Future<void> _saveAddress(String name, String phone, String addr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kAddrPrefsKey,
        jsonEncode({'name': name, 'phone': phone, 'address': addr}),
      );
    } on Object catch (_) {
      // 静默原因:持久化失败不阻塞下单,下次重填即可
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final addr = _addrCtrl.text.trim();

    if (name.isEmpty) {
      VelvetToast.show(context, '请填写收货人', isError: true);
      return;
    }
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      VelvetToast.show(context, '手机号格式不正确', isError: true);
      return;
    }
    if (addr.isEmpty) {
      VelvetToast.show(context, '请填写收货地址', isError: true);
      return;
    }

    setState(() => _submitting = true);
    unawaited(HapticService.instance.medium());

    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.create(
        widget.momentId,
        shippingName: name,
        shippingPhone: phone,
        shippingAddress: addr,
      );
      await _saveAddress(name, phone, addr);
      if (!mounted) return;
      Navigator.of(context).pop(order);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // 用 userMessageOf 过滤敏感异常对象 · 防止 DioException 字符串泄露给用户
      final msg = userMessageOf(e, fallback: '下单失败，请稍后重试');
      if (msg.isNotEmpty) {
        VelvetToast.show(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Vt.rXxl)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.4,
                colors: [Vt.bgAmbientSoft, Vt.bgVoid],
              ),
              border: Border(
                top: BorderSide(color: Vt.gold.withValues(alpha: 0.4)),
              ),
            ),
            padding: EdgeInsets.only(
              left: Vt.s20,
              right: Vt.s20,
              top: Vt.s20,
              bottom: padding.bottom + Vt.s20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 顶部 grab handle ───
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Vt.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: Vt.s16),

                // ─── 标题 + 关闭按钮 ───
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '填 写 收 货 地 址',
                        style: Vt.cnHeading.copyWith(
                          fontSize: Vt.tlg,
                          color: Vt.gold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    SpringTap(
                      onTap: () => Navigator.of(context).pop(),
                      pressedScale: 0.88,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Vt.glassFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: Vt.glassBorder),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Vt.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Vt.s20),

                // ─── 收货人 ───
                _AddrField(
                  label: '收 货 人',
                  controller: _nameCtrl,
                  hintText: '请填写收货人姓名',
                  maxLength: 32,
                ),
                const SizedBox(height: Vt.s16),

                // ─── 手机号 ───
                _AddrField(
                  label: '手 机 号',
                  controller: _phoneCtrl,
                  hintText: '11 位手机号',
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: Vt.s16),

                // ─── 收货地址 (textarea) ───
                _AddrField(
                  label: '收 货 地 址',
                  controller: _addrCtrl,
                  hintText: '省市区 + 详细地址',
                  maxLength: 200,
                  maxLines: 2,
                ),
                const SizedBox(height: Vt.s24),

                // ─── 确 认 下 单 ───
                SpringTap(
                  onTap: _submitting ? null : () => unawaited(_submit()),
                  glow: !_submitting,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Vt.rPill),
                      gradient: LinearGradient(
                        colors: _submitting
                            ? [
                                Vt.gold.withValues(alpha: 0.4),
                                Vt.goldDark.withValues(alpha: 0.4),
                              ]
                            : const [Vt.gold, Vt.goldDark],
                      ),
                      boxShadow: _submitting
                          ? null
                          : [
                              BoxShadow(
                                color: Vt.gold.withValues(alpha: 0.5),
                                blurRadius: 28,
                                spreadRadius: -4,
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        _submitting ? '下 单 中' : '确 认 下 单',
                        style: Vt.button.copyWith(
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Vt.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddrField extends StatelessWidget {
  const _AddrField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Vt.cnLabel.copyWith(
            fontSize: Vt.txs,
            color: Vt.textSecondary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: Vt.s8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Vt.rSm),
            border: Border.all(color: Vt.gold.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            cursorColor: Vt.gold,
            style: Vt.cnBody.copyWith(
              fontSize: Vt.tmd,
              color: Vt.textPrimary,
              fontWeight: FontWeight.w300,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Vt.cnBody.copyWith(
                fontSize: Vt.tmd,
                color: Vt.textTertiary,
                fontWeight: FontWeight.w300,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Vt.s16,
                vertical: Vt.s12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
