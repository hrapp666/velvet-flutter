// ============================================================================
// VelvetToast · v25 审计 P0
// ----------------------------------------------------------------------------
// 替代 Material SnackBar 白盒 · 全局统一 toast 样式
// 深色毛玻璃背景 + 金色 accent + editorial 字体
// ============================================================================

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 显示 Velvet 风格 toast (替代 ScaffoldMessenger.showSnackBar 的 Material 白盒).
///
/// 用法:
/// ```dart
/// VelvetToast.show(context, '操作成功');
/// VelvetToast.show(context, '操作失败', isError: true);
/// ```
class VelvetToast {
  VelvetToast._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        isError: isError,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: Vt.s24,
      right: Vt.s24,
      bottom: bottom + Vt.s48,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Vt.rSm),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Vt.s20,
                  vertical: Vt.s16,
                ),
                decoration: BoxDecoration(
                  color: Vt.bgElevated.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(Vt.rSm),
                  border: Border.all(
                    color: widget.isError
                        ? Vt.warn.withValues(alpha: 0.4)
                        : Vt.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.message,
                  style: Vt.bodySm.copyWith(
                    color: widget.isError ? Vt.warn : Vt.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
