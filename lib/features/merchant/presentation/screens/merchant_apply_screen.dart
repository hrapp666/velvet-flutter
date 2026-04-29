// ============================================================================
// MerchantApplyScreen · 商家认证申请
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/merchant_model.dart';
import '../providers/merchant_provider.dart';

class MerchantApplyScreen extends ConsumerStatefulWidget {
  const MerchantApplyScreen({super.key});

  @override
  ConsumerState<MerchantApplyScreen> createState() => _State();
}

class _State extends ConsumerState<MerchantApplyScreen> {
  SellerType _type = SellerType.personal;
  final _shopName = TextEditingController();
  final _shopIntro = TextEditingController();
  final _realName = TextEditingController();
  final _idNo = TextEditingController();
  final _phone = TextEditingController();
  final _wechat = TextEditingController();
  final _rcvWechat = TextEditingController();
  final _rcvAlipay = TextEditingController();
  final _rcvBank = TextEditingController();
  final _rcvBankName = TextEditingController();
  bool _submitting = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  Future<void> _prefill() async {
    // 任何异常（401 / 网络 / 解析）都不能让 UI 卡在 loading
    // 同事反馈"商家认证页面一直 loading" = myMerchant() 抛出后 _loaded 永远 false
    try {
      final mAsync = await ref.read(myMerchantProvider.future);
      if (!mounted) return;
      if (mAsync != null) {
        _shopName.text = mAsync.shopName;
        _shopIntro.text = mAsync.shopIntro ?? '';
        _realName.text = mAsync.personalRealName ?? '';
        _phone.text = mAsync.contactPhone ?? '';
        _wechat.text = mAsync.contactWechat ?? '';
        _rcvWechat.text = mAsync.receiveWechat ?? '';
        _rcvAlipay.text = mAsync.receiveAlipay ?? '';
        _rcvBankName.text = mAsync.receiveBankName ?? '';
        _type = mAsync.sellerType;
      }
    } on Object catch (_) {
      // 静默原因：商家资料加载失败不阻止用户填写新申请，UI 进可编辑空表单状态
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _shopName.dispose();
    _shopIntro.dispose();
    _realName.dispose();
    _idNo.dispose();
    _phone.dispose();
    _wechat.dispose();
    _rcvWechat.dispose();
    _rcvAlipay.dispose();
    _rcvBank.dispose();
    _rcvBankName.dispose();
    super.dispose();
  }

  String? _or(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_shopName.text.trim().isEmpty) {
      _toast('请填店铺名称'); return;
    }
    if (_type == SellerType.personal) {
      if (_realName.text.trim().isEmpty) { _toast('请填真实姓名'); return; }
      if (_phone.text.trim().isEmpty) { _toast('请填联系电话'); return; }
      if (_rcvWechat.text.trim().isEmpty &&
          _rcvAlipay.text.trim().isEmpty &&
          _rcvBank.text.trim().isEmpty) {
        _toast('请至少填一个收款账号'); return;
      }
    }
    setState(() => _submitting = true);
    try {
      final m = await ref.read(myMerchantProvider.notifier).apply(
            MerchantApplyBody(
              shopName: _shopName.text.trim(),
              shopIntro: _or(_shopIntro),
              sellerType: _type,
              personalRealName: _or(_realName),
              personalIdNo: _or(_idNo),
              contactPhone: _or(_phone),
              contactWechat: _or(_wechat),
              receiveWechat: _or(_rcvWechat),
              receiveAlipay: _or(_rcvAlipay),
              receiveBankCard: _or(_rcvBank),
              receiveBankName: _or(_rcvBankName),
            ),
          );
      if (!mounted) return;
      _toast('提交成功 · 等待审核');
      if (m.status == MerchantStatus.approved) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (!mounted) return;
      _toast(userMessageOf(e, fallback: '提交失败，请稍后再试'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    VelvetToast.show(context, msg, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Vt.bgVoid,
        body: Center(
          child: CircularProgressIndicator(color: Vt.gold, strokeWidth: 1.5),
        ),
      );
    }
    final m = ref.watch(myMerchantProvider).valueOrNull;
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s24, Vt.s24, Vt.s96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40, height: 40,
                      child: Icon(Icons.close, color: Vt.gold, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Text('商 家 认 证',
                      style: Vt.cnHeading.copyWith(color: Vt.gold)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: Vt.s32),
              Center(
                child: Column(
                  children: [
                    Text('BECOME A SELLER',
                        style: Vt.label.copyWith(
                          color: Vt.gold, fontSize: Vt.t2xs, letterSpacing: 3,
                          fontStyle: FontStyle.italic,
                        )),
                    const SizedBox(height: Vt.s12),
                    Text('成 为 卖 家',
                        style: Vt.cnDisplay.copyWith(
                          color: Vt.gold, fontSize: Vt.t2xl, letterSpacing: 8,
                          shadows: [Shadow(color: Vt.gold.withValues(alpha: 0.5), blurRadius: 30)],
                        )),
                    const SizedBox(height: Vt.s12),
                    Text('完 成 认 证 · 才 能 发 布 商 品',
                        style: Vt.cnLabel.copyWith(
                          color: Vt.textTertiary, fontStyle: FontStyle.italic,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: Vt.s32),
              if (m != null) _statusBanner(m),
              _section('店 铺 信 息', 'Shop'),
              _field('店 铺 名 称', _shopName),
              _areaField('店 铺 介 绍', _shopIntro),
              _section('卖 家 类 型', 'Type'),
              Row(
                children: SellerType.values.map((t) {
                  final on = t == _type;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: t == SellerType.values.last ? 0 : Vt.s8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: Vt.s20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? Vt.gold.withValues(alpha: 0.08) : Colors.transparent,
                          border: Border.all(color: on ? Vt.gold : Vt.borderMedium),
                          boxShadow: on
                              ? [BoxShadow(color: Vt.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -4)]
                              : null,
                        ),
                        child: Text(t.label,
                            style: Vt.cnLabel.copyWith(
                              color: on ? Vt.gold : Vt.textTertiary,
                            )),
                      ),
                    ),
                  ));
                }).toList(),
              ),
              _section('真 实 资 料', 'Identity'),
              _field('真 实 姓 名', _realName),
              _field('身 份 证 号 (可选)', _idNo),
              _field('联 系 电 话', _phone, type: TextInputType.phone),
              _field('微 信 号 (可选)', _wechat),
              _section('收 款 账 号', 'Payout'),
              Text('至少填一个 · 审核后用于打款',
                  style: Vt.label.copyWith(
                    color: Vt.textTertiary, fontSize: Vt.t2xs,
                    fontStyle: FontStyle.italic,
                  )),
              const SizedBox(height: Vt.s16),
              _field('微 信 收 款', _rcvWechat),
              _field('支 付 宝 收 款', _rcvAlipay),
              _field('银 行 卡 号', _rcvBank),
              _field('开 户 银 行', _rcvBankName),
              const SizedBox(height: Vt.s48),
              SpringTap(
                onTap: _submitting ? null : _submit,
                glow: !_submitting,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: Vt.s20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _submitting
                        ? Vt.gold.withValues(alpha: 0.3)
                        : Vt.gold,
                  ),
                  child: Text(
                    _submitting ? '提 交 中' : '提 交 认 证 申 请',
                    style: Vt.cnButton.copyWith(color: Vt.bgVoid),
                  ),
                ),
              ),
              const SizedBox(height: Vt.s16),
              Text(
                '❦ 审 核 通 常 24 小 时 内 ❦\n认证后即可发布商品 · 平台收 6% 佣金',
                style: Vt.cnLabel.copyWith(
                  color: Vt.textTertiary, fontSize: Vt.t2xs,
                  fontStyle: FontStyle.italic, height: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(MerchantDto m) {
    Color color;
    String text;
    switch (m.status) {
      case MerchantStatus.approved:
        color = Vt.statusSuccess;
        text = '✓ 已 认 证 · 可 发 布 商 品';
        break;
      case MerchantStatus.rejected:
        color = Vt.statusError;
        text = '未 通 过 · ${m.reviewNote ?? "请修改后重新提交"}';
        break;
      default:
        color = Vt.gold;
        text = '审 核 中 · 通 常 24 小 时 内';
    }
    return Container(
      padding: const EdgeInsets.all(Vt.s16),
      margin: const EdgeInsets.only(bottom: Vt.s24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color),
      ),
      child: Center(
        child: Text(text, style: Vt.cnBody.copyWith(color: color)),
      ),
    );
  }

  Widget _section(String cn, String en) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Vt.s32, 0, Vt.s16),
      child: Row(
        children: [
          Text(cn, style: Vt.cnHeading.copyWith(color: Vt.gold)),
          const SizedBox(width: Vt.s12),
          Text(en,
              style: Vt.label.copyWith(
                color: Vt.textTertiary, fontSize: Vt.t2xs,
                fontStyle: FontStyle.italic, letterSpacing: 2,
              )),
          const Expanded(
            child: Divider(color: Vt.borderSubtle, indent: Vt.s16),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Vt.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Vt.cnLabel.copyWith(color: Vt.gold)),
          const SizedBox(height: Vt.s8),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Vt.borderMedium)),
            ),
            child: TextField(
              controller: c,
              keyboardType: type,
              style: Vt.bodyLg.copyWith(color: Vt.textPrimary),
              cursorColor: Vt.gold,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: Vt.s8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Vt.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Vt.cnLabel.copyWith(color: Vt.gold)),
          const SizedBox(height: Vt.s8),
          Container(
            padding: const EdgeInsets.all(Vt.s12),
            decoration: BoxDecoration(
              border: Border.all(color: Vt.borderMedium),
            ),
            child: TextField(
              controller: c,
              maxLines: 3,
              style: Vt.cnBody.copyWith(color: Vt.textPrimary),
              cursorColor: Vt.gold,
              decoration: InputDecoration(
                hintText: '一两句话介绍你的店',
                hintStyle: Vt.cnBody.copyWith(
                  color: Vt.gold.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
