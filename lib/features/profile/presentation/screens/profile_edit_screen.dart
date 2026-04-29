// ============================================================================
// ProfileEditScreen · 编辑资料 · v5 Editorial Luxury
// ============================================================================

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart' show AppException;
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/velvet_toast.dart';
import '../../../../shared/widgets/micro/spring_tap.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moment/presentation/providers/moment_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _avatarUrl;
  String? _avatarError;
  bool _loading = false;
  bool _avatarUploading = false;
  String? _error;

  bool _hydrated = false; // 防止 provider 延迟返回时重复 hydrate

  @override
  void initState() {
    super.initState();
    final cached = ref.read(currentUserProvider).valueOrNull;
    if (cached != null) {
      _hydrateFrom(cached);
    } else {
      Future.microtask(() async {
        try {
          final repo = ref.read(authRepositoryProvider);
          final user = await repo.currentUser();
          if (!mounted || user == null) return;
          _hydrateFrom(user);
          ref.invalidate(currentUserProvider);
        } on Object catch (_) {
          // 静默原因：initState hydrate 失败就等用户手动输入 · 不阻塞 UI
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
      setState(() {
        _avatarUploading = true;
        _avatarError = null;
      });
      final repo = ref.read(uploadRepositoryProvider);
      final url = await repo.uploadFile(File(picked.path));
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _avatarError = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      VelvetToast.show(context, '头像上传失败：$e', isError: true);
      setState(() => _avatarError = '上 传 失 败 · 轻 触 重 试');
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
      final body = <String, dynamic>{
        'nickname': nickname,
        'bio': _bioCtrl.text.trim(),
      };
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        body['avatarUrl'] = _avatarUrl;
      }
      await api.dio.put<dynamic>('/api/v1/users/me', data: body);
      unawaited(HapticService.instance.success());
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      VelvetToast.show(context, '已 保 存');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.error is AppException
          ? (e.error! as AppException).message
          : (e.message ?? '保存失败');
      setState(() {
        _error = msg;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '保存失败: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vt.bgVoid,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              loading: _loading,
              onSave: _loading ? null : _save,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Vt.s24,
                  Vt.s48,
                  Vt.s24,
                  Vt.s96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _AvatarPicker(
                        avatarUrl: _avatarUrl,
                        uploading: _avatarUploading,
                        error: _avatarError != null,
                        onTap: _pickAvatar,
                      ),
                    ),
                    if (_avatarError != null) ...[
                      const SizedBox(height: Vt.s12),
                      Center(
                        child: Text(
                          _avatarError!,
                          style: Vt.cnLabel.copyWith(
                            color: Vt.statusError,
                            fontSize: Vt.t2xs,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: Vt.s12),
                      Center(
                        child: Text(
                          '— 轻 触 更 换 —',
                          style: Vt.cnLabel.copyWith(
                            color: Vt.gold.withValues(alpha: 0.5),
                            fontSize: Vt.t2xs,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Vt.s48),
                    _PeSection(
                      cnLabel: '昵 称',
                      enLabel: 'Nom de plume',
                      child: TextField(
                        controller: _nicknameCtrl,
                        style: Vt.cnBody.copyWith(
                          fontSize: Vt.tlg,
                          color: Vt.textGoldSoft,
                          letterSpacing: 2,
                        ),
                        cursorColor: Vt.gold,
                        maxLength: 32,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.only(
                            bottom: Vt.s12,
                            top: Vt.s4,
                          ),
                          hintText: '你 的 名 字',
                          hintStyle: Vt.cnBody.copyWith(
                            fontSize: Vt.tlg,
                            color: Vt.gold.withValues(alpha: 0.25),
                            letterSpacing: 2,
                          ),
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
                    ),
                    const SizedBox(height: Vt.s40),
                    _PeSection(
                      cnLabel: '简 介',
                      enLabel: 'A line about you',
                      child: TextField(
                        controller: _bioCtrl,
                        style: Vt.cnBody.copyWith(
                          color: Vt.textGoldSoft,
                          letterSpacing: 1.5,
                          height: 1.7,
                        ),
                        cursorColor: Vt.gold,
                        maxLines: 4,
                        minLines: 2,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: '一 两 句 话 · 懂 的 人 自 然 知 道',
                          hintStyle: Vt.cnBody.copyWith(
                            fontSize: Vt.tsm,
                            color: Vt.gold.withValues(alpha: 0.3),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.5,
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
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Vt.s32),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Vt.cnLabel.copyWith(
                          color: Vt.statusError,
                          fontSize: Vt.tsm,
                          letterSpacing: 2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: Vt.s48),
                    const _PageFleuron(),
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

// ────────────────────────────────────────────────────────────────────────────
// Header · 返 回 / 标题 / 保 存
// ────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool loading;
  final VoidCallback? onSave;

  const _Header({required this.loading, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Vt.s16, Vt.s12, Vt.s16, Vt.s12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Vt.gold.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.close_rounded,
                color: Vt.gold,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '编 辑 资 料',
              textAlign: TextAlign.center,
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tmd,
                letterSpacing: 8,
                color: Vt.gold,
              ),
            ),
          ),
          SpringTap(
            onTap: onSave,
            glow: !loading,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Vt.s16,
                vertical: Vt.s8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Vt.gold),
                color: Vt.gold.withValues(alpha: 0.08),
              ),
              child: loading
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
                        letterSpacing: 4,
                        color: Vt.gold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 头像 picker · 104x104 圆 · cam badge
// ────────────────────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  final String? avatarUrl;
  final bool uploading;
  final bool error;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.avatarUrl,
    required this.uploading,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  colors: [Vt.bgAmbientSoft, Vt.bgAmbientBottom],
                ),
                border: Border.all(color: Vt.gold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Vt.gold.withValues(alpha: 0.32),
                    blurRadius: 28,
                    spreadRadius: -4,
                  ),
                ],
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: Vt.gradientGold4,
                        ).createShader(rect),
                        child: Text(
                          'V',
                          style: Vt.displayMd.copyWith(
                            fontSize: Vt.t2xl,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
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
                  color: error ? Vt.statusError : Vt.gold,
                  border: Border.all(color: Vt.bgVoid, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Vt.gold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            color: Vt.bgVoid,
                          ),
                        ),
                      )
                    : Icon(
                        error ? Icons.refresh : Icons.camera_alt_outlined,
                        size: 16,
                        color: Vt.bgVoid,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// pe-section · 中文标签 + 斜体英文副标 + 内容
// ────────────────────────────────────────────────────────────────────────────

class _PeSection extends StatelessWidget {
  final String cnLabel;
  final String enLabel;
  final Widget child;

  const _PeSection({
    required this.cnLabel,
    required this.enLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              cnLabel,
              style: Vt.cnLabel.copyWith(
                fontSize: Vt.tsm,
                letterSpacing: 6,
                color: Vt.gold,
              ),
            ),
            const SizedBox(width: Vt.s12),
            Text(
              enLabel,
              style: Vt.label.copyWith(
                color: Vt.gold.withValues(alpha: 0.45),
                fontSize: Vt.t2xs,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: Vt.s12),
        child,
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// page fleuron · 收尾装饰
// ────────────────────────────────────────────────────────────────────────────

class _PageFleuron extends StatelessWidget {
  const _PageFleuron();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Vt.s40),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Vt.gold.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: Vt.s16),
          Text(
            '❦',
            style: Vt.displayMd.copyWith(
              fontSize: Vt.tlg,
              color: Vt.gold.withValues(alpha: 0.55),
              shadows: [
                Shadow(
                  color: Vt.gold.withValues(alpha: 0.4),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: Vt.s12),
          Text(
            'Curated by you',
            style: Vt.label.copyWith(
              color: Vt.textTertiary,
              fontSize: Vt.t2xs,
              letterSpacing: 5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
