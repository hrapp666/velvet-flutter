// ============================================================================
// PageFleuron · 章节封底（H5 styles.css §209-244 .page-fleuron）
//   ┃          1px × 36px 渐变金竖线
//   ─── ❦ ─── 1px 横线 + 居中 fleuron
//   <caption>  italic 11px gold-50%
// ============================================================================
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

class PageFleuron extends StatelessWidget {
  final String caption;
  const PageFleuron({super.key, required this.caption});

  @override
  Widget build(BuildContext context) {
    final goldA45 = Vt.gold.withValues(alpha: 0.45);
    final goldA40 = Vt.gold.withValues(alpha: 0.40);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 1,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, goldA45],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 72),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, goldA40, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '❦',
                style: Vt.headingSm.copyWith(
                  fontSize: Vt.txl,
                  color: Vt.gold.withValues(alpha: 0.6),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 72),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, goldA40, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: Vt.caption.copyWith(
              fontSize: Vt.t2xs,
              fontStyle: FontStyle.italic,
              color: Vt.gold.withValues(alpha: 0.5),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
