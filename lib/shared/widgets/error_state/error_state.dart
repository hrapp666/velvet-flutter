// ============================================================================
// ErrorState · v25 · 统一错误占位
// ----------------------------------------------------------------------------
// 替代散落各 screen 的 "加载失败 · $e" 裸文字 + 不一致 _ErrorState
// 设计:
//   - 顶部 hairline 装饰 (取代 Material Icons.error_outline 通用图标)
//   - editorial 调性: 中文 cnHeading + cnBody · 不喧哗
//   - radical whitespace: padding s32 + s24
//   - RetryChip 单一 CTA · 金色 outline
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/error_state/retry_chip.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = '此 刻 没 找 到',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Vt.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 顶部金色 hairline 装饰
            Container(
              width: 48,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Vt.gold,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: Vt.s24),
            Text(
              title,
              style: Vt.cnHeading.copyWith(
                fontSize: Vt.tlg,
                color: Vt.textSecondary,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Vt.s12),
            Text(
              message,
              style: Vt.bodySm.copyWith(
                color: Vt.textTertiary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Vt.s32),
              RetryChip(onTap: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
