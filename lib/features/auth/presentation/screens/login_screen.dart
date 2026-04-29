// ============================================================================
// LoginScreen · v5 Editorial Luxury · 像素级对齐 H5 #login
// ----------------------------------------------------------------------------
// 4 角 1px L 装饰 + 顶部 VELVET · MMXXVI eyebrow + VELVET 大金 + 天 鹅 绒
// + diamond hairline + 余 温 · 未 散 + Touch what was touched + mode-row
// + 双语 field-label (账号 Account / 密码 Pass)
// 0 圆角铁律 · CTA 直角 + 1px gold border + gold→ivory 渐变 hover ready
// ============================================================================

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  /// 是否显示 Apple Sign-In · 仅 iOS 设备
  bool get _showAppleSignIn => !kIsWeb && Platform.isIOS;

  Future<void> _handleAppleLogin() async {
    if (_loading) return;
    unawaited(HapticService.instance.heavy());
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AppException(
          type: AppErrorType.unauthorized,
          message: 'Apple 未返回身份凭证',
        );
      }
      // Apple 仅首次返回 fullName · 拼为昵称兜底
      String? nickname;
      final given = credential.givenName;
      final family = credential.familyName;
      if ((given != null && given.isNotEmpty) ||
          (family != null && family.isNotEmpty)) {
        nickname = '${family ?? ''}${given ?? ''}'.trim();
        if (nickname.isEmpty) nickname = null;
      }
      await ref.read(authNotifierProvider.notifier).loginWithApple(
            identityToken: identityToken,
            nickname: nickname,
          );
      if (!mounted) return;
      unawaited(HapticService.instance.success());
      unawaited(ChatSocket.instance.connect());
      context.go('/feed');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      // 用户主动取消 · 不报错
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      unawaited(HapticService.instance.error());
      setState(() => _errorText = 'Apple 登录失败：${e.message}');
    } on AppException catch (e) {
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      setState(() => _errorText = e.message);
    } on Object catch (e) {
      if (!mounted) return;
      unawaited(HapticService.instance.error());
      setState(() => _errorText = 'Apple 登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      unawaited(ChatSocket.instance.connect());
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
                padding: const EdgeInsets.fromLTRB(36, 56, 36, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // VELVET · MMXXVI eyebrow (H5 .login-eyebrow line 66)
                    Center(
                      child: Text(
                        'VELVET  ·  MMXXVI',
                        style: Vt.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 5,
                          color: Vt.gold.withValues(alpha: 0.4),
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // VELVET 大金 logo
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
                            shadows: [
                              Shadow(
                                color: Vt.gold.withValues(alpha: 0.42),
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
                        '天 鹅 绒',
                        style: Vt.cnCaption.copyWith(
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

                    // Some warmth lingers.
                    Center(
                      child: Text(
                        'Some warmth lingers.',
                        style: Vt.label.copyWith(
                          color: Vt.textSecondary.withValues(alpha: 0.7),
                          fontSize: Vt.tsm,
                          letterSpacing: 0.5,
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
                      labelEn: 'Account',
                      controller: _accountCtrl,
                      focusNode: _accountFocus,
                      placeholder: '字母 / 数字 / 下划线',
                    ),
                    const SizedBox(height: 32),

                    // 密码
                    _Field(
                      label: '密 码',
                      labelEn: 'Pass',
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
                                text: '进 入  VELVET',
                                letterSpacing: 0.5,
                              ),
                      ),
                    ),
                    if (_showAppleSignIn) ...[
                      const SizedBox(height: 28),

                      // 钻石分隔
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Vt.gold.withValues(alpha: 0.28),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              '或',
                              style: Vt.cnLabel.copyWith(
                                fontSize: Vt.tsm,
                                letterSpacing: 0.5,
                                color: Vt.gold.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Vt.gold.withValues(alpha: 0.28),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Apple Sign-In · 金线 · 与 VELVET CTA 同款 chiaroscuro
                      SpringTap(
                        onTap: _loading ? null : _handleAppleLogin,
                        glow: !_loading,
                        haptic: false,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: Vt.gold.withValues(alpha: 0.04),
                            border: Border.all(
                              color: Vt.gold.withValues(alpha: 0.85),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apple,
                                size: 22,
                                color: Vt.gold,
                                shadows: [
                                  Shadow(
                                    color: Vt.gold.withValues(alpha: 0.45),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '使 用  Apple  继 续',
                                style: Vt.cnButton.copyWith(
                                  fontSize: Vt.tmd,
                                  letterSpacing: 0.5,
                                  color: Vt.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // legal
                    Center(
                      child: Text(
                        '懂 的 人  ·  不 必 多 言',
                        style: Vt.cnCaption.copyWith(
                          fontSize: Vt.tsm,
                          letterSpacing: 0.5,
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
                          fontSize: Vt.txs,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 四角 1px 金色 L 装饰 (H5 #login .corner-leaf · Hermès/Bottega)
            const Positioned(
                top: 12, left: 12, child: _LCorner(corner: _Corner.topLeft)),
            const Positioned(
                top: 12, right: 12, child: _LCorner(corner: _Corner.topRight)),
            const Positioned(
                bottom: 12,
                left: 12,
                child: _LCorner(corner: _Corner.bottomLeft)),
            const Positioned(
                bottom: 12,
                right: 12,
                child: _LCorner(corner: _Corner.bottomRight)),

            // UI12 · editorial 胶片纹理 · 默认 intensity 0.022 保护中文可读性
            const GrainOverlay(seed: 7),
          ],
        ),
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// 编辑式 1px 金色 L 角装饰（24x24 · 仅 2 边）
class _LCorner extends StatelessWidget {
  final _Corner corner;
  const _LCorner({required this.corner});

  @override
  Widget build(BuildContext context) {
    final color = Vt.gold.withValues(alpha: 0.30);
    final side = BorderSide(color: color, width: 1);
    final none = BorderSide.none;
    final isTop = corner == _Corner.topLeft || corner == _Corner.topRight;
    final isLeft = corner == _Corner.topLeft || corner == _Corner.bottomLeft;
    return SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? side : none,
            bottom: !isTop ? side : none,
            left: isLeft ? side : none,
            right: !isLeft ? side : none,
          ),
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
    final ls = active ? 0.5 : 0.4;
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

class _Field extends StatelessWidget {
  final String label;
  final String? labelEn;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.label,
    this.labelEn,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final en = labelEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: focused ? 8 : 6, bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Vt.cnLabel.copyWith(
                  fontSize: Vt.tsm,
                  letterSpacing: focused ? 0.5 : 0.4,
                  color:
                      focused ? Vt.goldLight : Vt.gold.withValues(alpha: 0.85),
                ),
                child: Text(label),
              ),
              if (en != null) ...[
                const SizedBox(width: 12),
                // 双语英文小字 italic (H5 .field-label .en)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    en.toUpperCase(),
                    style: Vt.label.copyWith(
                      fontSize: Vt.txs,
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Vt.gold.withValues(alpha: focused ? 0.7 : 0.5),
                    ),
                  ),
                ),
              ],
            ],
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
