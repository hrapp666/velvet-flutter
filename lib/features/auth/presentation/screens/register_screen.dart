// ============================================================================
// RegisterScreen · v13 复刻 H5
// ============================================================================

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ambient/grain_overlay.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../chat/data/services/chat_socket.dart';
import '../../../safety/safety_dialogs.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _accountCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _accountFocus = FocusNode();
  final _nicknameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _showPassword = false;
  bool _loading = false;
  String? _errorText;

  /// 18+ 合规 · 生日必选
  DateTime? _birthday;

  /// 用户协议勾选
  bool _agreedTerms = false;

  @override
  void initState() {
    super.initState();
    _accountFocus.addListener(() => setState(() {}));
    _nicknameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    // 默认 25 岁位置 · 范围 1925 - 18 年前
    final initial = _birthday ?? DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(1925, 1, 1);
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选 择 你 的 出 生 日 期',
      cancelText: '取 消',
      confirmText: '确 认',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Vt.gold,
              onPrimary: Vt.bgVoid,
              surface: Vt.bgElevated,
              onSurface: Vt.textPrimary,
            ),
            dialogBackgroundColor: Vt.bgElevated,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _birthday = picked;
        _errorText = null;
      });
    }
  }

  String _formatBirthday(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}  ·  $mm  ·  $dd';
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    _accountFocus.dispose();
    _nicknameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    unawaited(HapticService.instance.heavy());
    final account = _accountCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (account.isEmpty || nickname.isEmpty || password.isEmpty) {
      setState(() => _errorText = '请填写所有字段');
      return;
    }
    if (account.length < 3 ||
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(account)) {
      setState(() => _errorText = '账号 3-32 位字母数字下划线');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorText = '密码至少 6 位');
      return;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      setState(() => _errorText = '密码需包含字母和数字');
      return;
    }
    if (_birthday == null) {
      setState(() => _errorText = '请选择出生日期');
      return;
    }
    // 18+ 客户端预检（后端 final gate）
    final now = DateTime.now();
    final age = now.year -
        _birthday!.year -
        ((now.month < _birthday!.month ||
                (now.month == _birthday!.month && now.day < _birthday!.day))
            ? 1
            : 0);
    if (age < 18) {
      setState(() => _errorText = '抱歉 · 需年满 18 周岁');
      return;
    }
    if (!_agreedTerms) {
      setState(() => _errorText = '请同意用户协议和隐私政策');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).register(
            account,
            password,
            nickname,
            birthday: _birthday!,
            agreedTerms: _agreedTerms,
          );
      if (!mounted) return;
      ChatSocket.instance.connect();
      context.go('/feed');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _errorText = '注册失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.68),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 0.9,
                      colors: [
                        Vt.gold.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: padding.top + 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Vt.gold,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Vt.gold.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              // ClampingScrollPhysics: 禁止 iOS 弹性过度滚动 · 主人反馈"注册页竟然能滑动"
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(36, 64, 36, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: Vt.gradientGoldLogo,
                          stops: Vt.gradientGoldLogoStops,
                        ).createShader(rect),
                        child: Text(
                          'VELVET',
                          textAlign: TextAlign.center,
                          style: Vt.displayHero.copyWith(
                            color: Colors.white,
                            letterSpacing: 10,
                            shadows: const [
                              Shadow(
                                color: Color(0x6BC9A961),
                                blurRadius: 56,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '天   鹅   绒',
                        style: Vt.cnCaption.copyWith(
                          letterSpacing: 8,
                          color: Vt.gold.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: SizedBox(
                        width: 56,
                        height: 1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Vt.gold,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Vt.gold.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: 0.785,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(color: Vt.gold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        '余 温 · 未 散',
                        style: Vt.cnHeading.copyWith(
                          fontSize: Vt.tmd,
                          color: Vt.gold,
                          shadows: [
                            Shadow(
                              color: Vt.gold.withValues(alpha: 0.45),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Some warmth lingers.',
                        style: Vt.label.copyWith(
                          color: Vt.textSecondary.withValues(alpha: 0.7),
                          fontSize: Vt.txs,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Vt.gold.withValues(alpha: 0.2),
                          ),
                          bottom: BorderSide(
                            color: Vt.gold.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              _ModeBtn(
                                label: '登 录',
                                active: false,
                                onTap: () => context.go('/login'),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Vt.gold.withValues(alpha: 0.14),
                              ),
                              _ModeBtn(
                                label: '注 册',
                                active: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const Positioned(
                            top: -2,
                            left: 0,
                            right: 0,
                            child: Center(child: _Diamond()),
                          ),
                          const Positioned(
                            bottom: -2,
                            left: 0,
                            right: 0,
                            child: Center(child: _Diamond()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    _Field(
                      label: '账 号',
                      controller: _accountCtrl,
                      focusNode: _accountFocus,
                      placeholder: '字母 / 数字 / 下划线',
                    ),
                    const SizedBox(height: 32),
                    _Field(
                      label: '昵 称',
                      controller: _nicknameCtrl,
                      focusNode: _nicknameFocus,
                      placeholder: '夜里 · 别人怎么叫你',
                    ),
                    const SizedBox(height: 32),
                    _Field(
                      label: '密 码',
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      placeholder: '6 位以上 · 字母 + 数字',
                      obscure: !_showPassword,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _showPassword
                                ? Vt.gold.withValues(alpha: 0.18)
                                : Vt.gold.withValues(alpha: 0.06),
                            border: Border.all(color: Vt.gold),
                          ),
                          child: Text(
                            _showPassword ? '隐' : '显',
                            style: Vt.cnLabel.copyWith(
                              fontSize: Vt.tsm,
                              letterSpacing: 2,
                              color: Vt.gold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 生日 · 18+ 合规
                    _BirthdayField(
                      birthday: _birthday,
                      formattedLabel:
                          _birthday == null ? null : _formatBirthday(_birthday!),
                      onTap: _pickBirthday,
                    ),
                    const SizedBox(height: 28),
                    // 协议勾选
                    _TermsCheck(
                      agreed: _agreedTerms,
                      onToggle: () => setState(() {
                        _agreedTerms = !_agreedTerms;
                        if (_agreedTerms) _errorText = null;
                      }),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: Vt.bodySm.copyWith(
                          color: Vt.warn,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    // 创 建 账 号 cta · SpringTap 包裹 · 金色 burst 仪式感
                    SpringTap(
                      onTap: _loading ? null : _handleRegister,
                      glow: !_loading,
                      haptic: false, // _handleRegister 内部有 haptic
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Vt.gold.withValues(alpha: 0.06),
                          border: Border.all(color: Vt.gold),
                          boxShadow: [
                            BoxShadow(
                              color: Vt.gold.withValues(alpha: 0.35),
                              blurRadius: 32,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Vt.gold,
                                  ),
                                ),
                              )
                            : _LuxCenter(
                                text: '创  建  账  号',
                                letterSpacing: 12,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        '懂  的  人  ·  不  必  多  言',
                        style: Vt.cnCaption.copyWith(
                          fontSize: Vt.txs,
                          letterSpacing: 3,
                          color: Vt.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UI12 · editorial 胶片纹理 · 默认 intensity 0.022 保护中文可读性
            const GrainOverlay(seed: 11),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ls = active ? 12.0 : 10.0;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          alignment: Alignment.center,
          // 用 padding-left = letterSpacing 数学居中
          child: Padding(
            padding: EdgeInsets.only(left: ls),
            child: Text(
              label,
              style: Vt.cnButton.copyWith(
                fontSize: Vt.tmd,
                letterSpacing: ls,
                color: active ? Vt.gold : Vt.textTertiary,
                shadows: active
                    ? [
                        Shadow(
                          color: Vt.gold.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 数学居中的中文按钮文字
/// letter-spacing 让最后一个字符右侧多出空白 → 视觉偏左
/// 用 padding-left = letterSpacing 来精确补偿
class _LuxCenter extends StatelessWidget {
  final String text;
  final double letterSpacing;
  const _LuxCenter({required this.text, required this.letterSpacing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: letterSpacing),
        child: Text(
          text,
          style: Vt.cnButton.copyWith(
            fontSize: Vt.tmd,
            letterSpacing: letterSpacing,
            color: Vt.gold,
          ),
        ),
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Vt.gold,
          boxShadow: [
            BoxShadow(
              color: Vt.gold.withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// 生日字段 · 点击弹出 date picker · 18+ 合规
class _BirthdayField extends StatelessWidget {
  final DateTime? birthday;
  final String? formattedLabel;
  final VoidCallback onTap;
  const _BirthdayField({
    required this.birthday,
    required this.formattedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = birthday != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 14),
          child: Text(
            '生 日',
            style: Vt.cnLabel.copyWith(
              fontSize: Vt.tsm,
              letterSpacing: 5,
              color: Vt.gold.withValues(alpha: 0.82),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.only(bottom: 14, top: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: filled
                      ? Vt.gold
                      : Vt.gold.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formattedLabel ?? '年  满  十  八  ·  点  击  选  择',
                    style: filled
                        ? Vt.input.copyWith(letterSpacing: 3)
                        : Vt.inputPlaceholder,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Vt.gold.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 用户协议 + 隐私政策勾选
class _TermsCheck extends StatefulWidget {
  final bool agreed;
  final VoidCallback onToggle;
  const _TermsCheck({required this.agreed, required this.onToggle});

  @override
  State<_TermsCheck> createState() => _TermsCheckState();
}

class _TermsCheckState extends State<_TermsCheck> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => showLegalDocument(context, LegalDoc.terms);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => showLegalDocument(context, LegalDoc.privacy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: widget.agreed
                    ? Vt.gold.withValues(alpha: 0.22)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.agreed
                      ? Vt.gold
                      : Vt.gold.withValues(alpha: 0.35),
                ),
              ),
              child: widget.agreed
                  ? const Icon(Icons.check, size: 12, color: Vt.gold)
                  : null,
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '我  已  阅  读  并  同  意  ',
                      style: Vt.cnCaption.copyWith(
                        fontSize: Vt.txs,
                        letterSpacing: 2,
                        color: Vt.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: '《用户协议》',
                      style: Vt.cnCaption.copyWith(
                        fontSize: Vt.txs,
                        letterSpacing: 1,
                        color: Vt.gold,
                      ),
                      recognizer: _termsTap,
                    ),
                    TextSpan(
                      text: '  与  ',
                      style: Vt.cnCaption.copyWith(
                        fontSize: Vt.txs,
                        letterSpacing: 2,
                        color: Vt.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: '《隐私政策》',
                      style: Vt.cnCaption.copyWith(
                        fontSize: Vt.txs,
                        letterSpacing: 1,
                        color: Vt.gold,
                      ),
                      recognizer: _privacyTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: focused ? 8 : 6, bottom: 14),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: Vt.cnLabel.copyWith(
              fontSize: Vt.tsm,
              letterSpacing: focused ? 7 : 5,
              color: focused
                  ? Vt.gold
                  : Vt.gold.withValues(alpha: 0.82),
            ),
            child: Text(label),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscure,
                obscuringCharacter: '·',
                style: Vt.input,
                cursorColor: Vt.gold,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 14, top: 6),
                  hintText: placeholder,
                  hintStyle: Vt.inputPlaceholder,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Vt.gold.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Vt.gold, width: 1),
                  ),
                ),
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 8),
              suffix!,
            ],
          ],
        ),
      ],
    );
  }
}
