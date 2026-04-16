// ============================================================================
// WithdrawScreen · 申请提现
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../data/models/wallet_model.dart';
import '../providers/wallet_provider.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key, required this.wallet});
  final WalletDto wallet;

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  WithdrawMethod _method = WithdrawMethod.wechat;
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final yuan = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (yuan < 10) {
      _toast('金额至少 ¥10');
      return;
    }
    if (_accountCtrl.text.trim().isEmpty) {
      _toast('请填写收款账号');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('请填写真实姓名');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(myWithdrawalsProvider.notifier)
          .requestWithdraw(WithdrawRequestBody(
            amountCents: (yuan * 100).round(),
            method: _method,
            account: _accountCtrl.text.trim(),
            accountName: _nameCtrl.text.trim(),
          ));
      if (!mounted) return;
      _toast('提现申请已提交');
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    VelvetToast.show(context, msg, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallet;
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Vt.s24, Vt.s16, Vt.s24, Vt.s48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 40, height: 40,
                      child: Icon(Icons.close, color: Vt.gold, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Text('申 请 提 现', style: Vt.cnHeading.copyWith(color: Vt.gold)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: Vt.s32),
              _label('提 现 方 式', 'Method'),
              const SizedBox(height: Vt.s12),
              Row(
                children: WithdrawMethod.values
                    .map((m) => Expanded(child: _methodBtn(m)))
                    .toList(),
              ),
              const SizedBox(height: Vt.s32),
              _label('金 额', 'Amount'),
              const SizedBox(height: Vt.s12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: Vt.s8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Vt.borderMedium),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('¥', style: Vt.headingLg.copyWith(color: Vt.gold)),
                    const SizedBox(width: Vt.s12),
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: Vt.displayMd.copyWith(color: Vt.gold, fontWeight: FontWeight.w500),
                        cursorColor: Vt.gold,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: Vt.displayMd.copyWith(color: Vt.gold.withValues(alpha: 0.25)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Vt.s12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '最 低 ¥10 · 可提现 ¥${w.balanceYuan.toStringAsFixed(2)}',
                      style: Vt.cnLabel.copyWith(color: Vt.textTertiary, fontSize: 10),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _amountCtrl.text = w.balanceYuan.toStringAsFixed(2);
                    },
                    child: Text('全 部 提 现',
                        style: Vt.cnLabel.copyWith(color: Vt.gold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: Vt.s24),
              _label('收 款 账 号', 'Account'),
              const SizedBox(height: Vt.s12),
              _textField(_accountCtrl, '微信号 / 支付宝 / 银行卡号'),
              const SizedBox(height: Vt.s24),
              _label('真 实 姓 名', 'Real Name'),
              const SizedBox(height: Vt.s12),
              _textField(_nameCtrl, '与收款账号一致'),
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
                    _submitting ? '提 交 中' : '确 认 提 交',
                    style: Vt.cnButton.copyWith(color: Vt.bgVoid),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String cn, String en) {
    return Row(
      children: [
        Text(cn, style: Vt.cnLabel.copyWith(color: Vt.gold)),
        const SizedBox(width: Vt.s8),
        Text(en,
            style: Vt.label.copyWith(
              color: Vt.textTertiary, fontSize: 10,
              fontStyle: FontStyle.italic, letterSpacing: 2,
            )),
      ],
    );
  }

  Widget _methodBtn(WithdrawMethod m) {
    final on = m == _method;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        margin: const EdgeInsets.only(right: Vt.s8),
        padding: const EdgeInsets.symmetric(vertical: Vt.s16),
        decoration: BoxDecoration(
          color: on ? Vt.gold.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(color: on ? Vt.gold : Vt.borderMedium),
          boxShadow: on
              ? [BoxShadow(color: Vt.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -4)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          m.label,
          style: Vt.cnLabel.copyWith(color: on ? Vt.gold : Vt.textTertiary),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Vt.borderMedium)),
      ),
      child: TextField(
        controller: ctrl,
        style: Vt.bodyLg.copyWith(color: Vt.textPrimary),
        cursorColor: Vt.gold,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Vt.cnBody.copyWith(
            color: Vt.gold.withValues(alpha: 0.3),
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: Vt.s12, horizontal: Vt.s4),
          isDense: true,
        ),
      ),
    );
  }
}
