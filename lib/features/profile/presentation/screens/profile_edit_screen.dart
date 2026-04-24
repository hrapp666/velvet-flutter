// ============================================================================
// ProfileEditScreen · 编辑资料
// ============================================================================

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart' show AppException;
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moment/presentation/providers/moment_provider.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _avatarUrl;
  bool _loading = false;
  bool _avatarUploading = false;
  String? _error;

  bool _hydrated = false;  // 防止 provider 延迟返回时重复 hydrate

  @override
  void initState() {
    super.initState();
    // 先同步 hydrate(如果 provider 已 cache)
    final cached = ref.read(currentUserProvider).valueOrNull;
    if (cached != null) {
      _hydrateFrom(cached);
    } else {
      // autoDispose 场景 · 主动 refresh 一次
      Future.microtask(() async {
        try {
          final repo = ref.read(authRepositoryProvider);
          final user = await repo.currentUser();
          if (!mounted || user == null) return;
          _hydrateFrom(user);
          // 同时 invalidate provider · 让 profile_screen 拿到刚 fetch 的
          ref.invalidate(currentUserProvider);
        } on Object catch (_) {
          // 静默原因:initState hydrate 失败就等用户手动输入 · 不阻塞 UI
        }
      });
    }
  }

  void _hydrateFrom(UserProfile user) {
    if (_hydrated) return;
    _hydrated = true;
    setState(() {
      _nicknameCtrl.text = user.nickname;
      _bioCtrl.text = user.bio ?? '';
      _avatarUrl = user.avatarUrl;
    });
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_avatarUploading) return;
    unawaited(HapticService.instance.medium());
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _avatarUploading = true);
      final repo = ref.read(uploadRepositoryProvider);
      final url = await repo.uploadFile(File(picked.path));
      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } on Object catch (e) {
      if (!mounted) return;
      VelvetToast.show(context, '头像上传失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _save() async {
    unawaited(HapticService.instance.medium());
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = '昵称不能为空');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      // 只发真的改过的字段 · 防止 null 把现有 avatar 覆盖成 null
      final body = <String, dynamic>{
        'nickname': nickname,
        'bio': _bioCtrl.text.trim(),
      };
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        body['avatarUrl'] = _avatarUrl;
      }
      await api.dio.put<dynamic>('/api/v1/users/me', data: body);
      unawaited(HapticService.instance.success());
      // 刷新 currentUser
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      VelvetToast.show(context, '已  保  存');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      // 提取真的错误消息:e.error 是 AppException(interceptor 注入)
      final msg = e.error is AppException
          ? (e.error as AppException).message
          : (e.message ?? '保存失败');
      setState(() {
        _error = msg;
        _loading = false;
      });
    } on Object catch (e) {
      // 兜底:任何其他异常都要解锁按钮 · 防止 _loading stuck
      if (!mounted) return;
      setState(() {
        _error = '保存失败: $e';
        _loading = false;
      });
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
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: Vt.gradientAmbient,
          ),
        ),
        child: Stack(
          children: [
            // 金色 ambient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 0.9,
                      colors: [
                        Vt.gold.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(36, 24, 36, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 顶部
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              color: Vt.gold,
                              size: 22,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '编  辑  资  料',
                            textAlign: TextAlign.center,
                            style: Vt.cnHeading.copyWith(
                              letterSpacing: 6,
                              color: Vt.gold,
                            ),
                          ),
                        ),
                        SpringTap(
                          onTap: _loading ? null : _save,
                          glow: !_loading,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Vt.gold),
                              color: Vt.gold.withValues(alpha: 0.08),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.2,
                                      color: Vt.gold,
                                    ),
                                  )
                                : Text(
                                    '保 存',
                                    style: Vt.cnLabel.copyWith(
                                      fontSize: Vt.tsm,
                                      letterSpacing: 3,
                                      color: Vt.gold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // 头像 · 居中显示 · 右下角 camera badge 用 Positioned 不影响居中
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: SizedBox(
                          width: 116,
                          height: 116,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  center: Alignment(-0.3, -0.3),
                                  colors: [
                                    Vt.bgAmbientSoft,
                                    Vt.bgAmbientBottom,
                                  ],
                                ),
                                border: Border.all(
                                  color: Vt.gold,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Vt.gold.withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: -4,
                                  ),
                                ],
                                image: _avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _avatarUrl == null
                                  ? Center(
                                      child: Text(
                                        'V',
                                        style: Vt.displayMd.copyWith(
                                          fontSize: Vt.t2xl,
                                          fontWeight: FontWeight.w500,
                                          color: Vt.gold
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Vt.gold,
                                  border: Border.all(
                                    color: Vt.bgVoid,
                                    width: 2,
                                  ),
                                ),
                                child: _avatarUploading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.2,
                                          color: Vt.bgVoid,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16,
                                        color: Vt.bgVoid,
                                      ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 昵称字段
                    Text(
                      '昵  称',
                      style: Vt.cnLabel.copyWith(
                        fontSize: Vt.tsm,
                        letterSpacing: 5,
                        color: Vt.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameCtrl,
                      style: Vt.input,
                      cursorColor: Vt.gold,
                      maxLength: 32,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.only(bottom: 14, top: 6),
                        hintText: '你的名字',
                        hintStyle: Vt.inputPlaceholder,
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Vt.gold.withValues(alpha: 0.22),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Vt.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // bio 字段
                    Text(
                      '简  介',
                      style: Vt.cnLabel.copyWith(
                        fontSize: Vt.tsm,
                        letterSpacing: 5,
                        color: Vt.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bioCtrl,
                      style: Vt.cnBody.copyWith(
                        color: Vt.textGoldSoft,
                        letterSpacing: 1,
                      ),
                      cursorColor: Vt.gold,
                      maxLines: 4,
                      minLines: 2,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: '一两句话 · 懂的人自然知道',
                        hintStyle: Vt.cnBody.copyWith(
                          fontSize: Vt.tsm,
                          color: Vt.gold.withValues(alpha: 0.35),
                          fontStyle: FontStyle.italic,
                        ),
                        counterStyle: Vt.label.copyWith(
                          color: Vt.textTertiary,
                          fontSize: Vt.t2xs,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Vt.gold.withValues(alpha: 0.22),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Vt.gold),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Vt.bodySm.copyWith(
                          color: Vt.warn,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
