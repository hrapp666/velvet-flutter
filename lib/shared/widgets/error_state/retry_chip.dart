// ============================================================================
// RetryChip · v25 · 金色重试按钮
// ----------------------------------------------------------------------------
// 替代散落各 screen 的 GestureDetector + Container + "重试" 字符串
// awesome-design-md 4 态对位:
//   default  · gold outline border + transparent fill
//   hover    · gold fill 8% alpha (web/desktop)
//   pressed  · gold fill 16% alpha (ripple)
//   disabled · textDisabled gray border
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:velvet/l10n/app_localizations.dart';
import 'package:velvet/shared/services/haptic_service.dart';
import 'package:velvet/shared/theme/design_tokens.dart';

class RetryChip extends StatelessWidget {
  final VoidCallback? onTap;

  /// 显式 label · 传 null 时走 l10n.retryButton fallback 再到 '重 试'
  final String? label;
  final IconData icon;

  const RetryChip({
    super.key,
    required this.onTap,
    this.label,
    this.icon = Icons.refresh_rounded,
  });

  @override
  Widget build(BuildContext context) {
    // Capture into local · 让 Dart 推断 promote 到非 null
    final cb = onTap;
    final accent = cb == null ? Vt.textDisabled : Vt.gold;
    final resolvedLabel =
        label ?? AppLocalizations.of(context)?.retryButton ?? '重 试';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: cb == null
            ? null
            : () {
                unawaited(HapticService.instance.light());
                cb();
              },
        borderRadius: BorderRadius.circular(Vt.rPill),
        hoverColor: Vt.gold.withValues(alpha: 0.08),
        highlightColor: Vt.gold.withValues(alpha: 0.16),
        splashColor: Vt.gold.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Vt.s24,
            vertical: Vt.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Vt.rPill),
            border: Border.all(color: accent, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: Vt.s8),
              Text(
                resolvedLabel,
                style: Vt.button.copyWith(
                  color: accent,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
