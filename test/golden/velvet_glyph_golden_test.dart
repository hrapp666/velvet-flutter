// ============================================================================
// VelvetGlyph · golden screenshot baseline
// ----------------------------------------------------------------------------
// 覆盖 1 态: size 96 静态渲染 (shimmerProgress=null)
// 直接用 Container + bgVoid 背景 · 不套 MaterialApp(VelvetGlyph 是纯 2D CustomPaint)。
// 首次跑: flutter test --update-goldens test/golden/velvet_glyph_golden_test.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/brand/velvet_glyph.dart';

void main() {
  testWidgets('VelvetGlyph size 96 golden', (tester) async {
    await tester.pumpWidget(
      Container(
        color: Vt.bgVoid,
        child: const Center(child: VelvetGlyph(size: 96)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(VelvetGlyph),
      matchesGoldenFile('velvet_glyph_96.png'),
    );
  });
}
