// ============================================================================
// LoginScreen · v13 复刻 H5 editorial luxury
// ----------------------------------------------------------------------------
// VELVET 大金 + 天 鹅 绒 + 余 温 · 未 散 + 登录/注册切换 + 账号/密码字段
// 密码 显/隐 toggle + Cormorant Garamond 衬线字体 + 金色文字
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ambient/grain_overlay.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../chat/data/services/chat_socket.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _accountFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _showPassword = false;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _accountFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _accountFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    unawaited(HapticService.instance.heavy());
    final account = _accountCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (account.isEmpty || password.isEmpty) {
      setState(() => _errorText = '请填写账号和密码');
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).login(account, password);
      if (!mounted) return;
      unawaited(HapticService.instance.success());
      ChatSocket.instance.connect();
      context.go('/feed');
    } on AppException catch (e) {
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      setState(() => _errorText = e.message);
    } on Object catch (e) {
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      setState(() => _errorText = '登录失败：$e');
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
            // 顶部金色 ambient
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

            // 顶部 hairline
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

            // 主内容（ClampingScrollPhysics 禁止弹性过度滚动）
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(36, 64, 36, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // VELVET 大金 logo
                    Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: Vt.gradientGoldLogo,
                          stops: Vt.gradientGoldLogoStops,
                        ).createShader(rect),
                        child: const Text(
                          'VELVET',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cormorant Garamond',
                            fontSize: 64,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 10,
                            color: Colors.white,
                            height: 1,
                            shadows: [
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

                    // 天 鹅 绒
                    Center(
                      child: Text(
                        '天   鹅   绒',
                        style: Vt.cnDisplay.copyWith(
                          fontSize: 15,
                          letterSpacing: 8,
                          color: Vt.gold.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 钻石装饰线
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

                    // 余 温 · 未 散
                    Center(
                      child: Text(
                        '余 温 · 未 散',
                        style: Vt.cnHeading.copyWith(
                          fontSize: 18,
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

                    // Some warmth lingers.
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

                    // 登录 | 注册 切换
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
                                active: true,
                                onTap: () {},
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Vt.gold.withValues(alpha: 0.14),
                              ),
                              _ModeBtn(
                                label: '注 册',
                                active: false,
                                onTap: () => context.go('/register'),
                              ),
                            ],
                          ),
                          // 顶/底钻石装饰
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

                    // 账号
                    _Field(
                      label: '账 号',
                      controller: _accountCtrl,
                      focusNode: _accountFocus,
                      placeholder: '字母 / 数字 / 下划线',
                    ),
                    const SizedBox(height: 32),

                    // 密码
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

                    // 进 入 VELVET cta · SpringTap 包裹 · 120ms 弹性 + 金色 burst
                    SpringTap(
                      onTap: _loading ? null : _handleLogin,
                      glow: !_loading,
                      haptic: false, // _handleLogin 内部已有 haptic
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: _loading
                              ? Vt.gold.withValues(alpha: 0.04)
                              : Vt.gold.withValues(alpha: 0.06),
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
                                text: '进  入  VELVET',
                                letterSpacing: 12,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // legal
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
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Those who know, need no words.',
                        style: Vt.label.copyWith(
                          color: Vt.textTertiary,
                          fontSize: Vt.t2xs,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UI12 · editorial 胶片纹理 · 默认 intensity 0.022 保护中文可读性
            const GrainOverlay(seed: 7),
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
          child: Padding(
            padding: EdgeInsets.only(left: ls),
            child: Text(
              label,
              style: Vt.cnButton.copyWith(
                fontSize: 19,
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
            fontSize: 18,
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
