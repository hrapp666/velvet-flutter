// ============================================================================
// EmptyState · v25 · 统一空态占位
// ----------------------------------------------------------------------------
// 取材自 chat_list_screen 现有最佳实践:
//   - 顶部 56px 金色 hairline 装饰 (替代 Material Icons)
//   - cnHeading 中文 dashes 包围 "— xxx —"
//   - italic body subtitle
//   - 可选 CTA chip (用 RetryChip 同款 visual lang)
// awesome-design-md 5 铁律对位 (anti-template / 单 accent / radical whitespace / 4 态 / 无 emoji)
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/error_state/retry_chip.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
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
            // 金色 hairline 装饰
            Container(
              width: 56,
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
                fontSize: Vt.tmd,
                letterSpacing: 6,
                color: Vt.gold.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Vt.s12),
              Text(
                subtitle!,
                style: Vt.bodySm.copyWith(
                  color: Vt.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onCta != null && ctaLabel != null) ...[
              const SizedBox(height: Vt.s32),
              RetryChip(
                onTap: onCta,
                label: ctaLabel!,
                icon: ctaIcon ?? Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
