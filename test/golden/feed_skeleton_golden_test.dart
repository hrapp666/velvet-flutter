// ============================================================================
// FeedSkeleton · golden screenshot baseline
// ----------------------------------------------------------------------------
// 覆盖 1 态: 6 card masonry 占位渲染
// pump 500ms 让 shimmer 渲染完整一帧。
// 用 bgPrimary 对齐生产 feed 背景(FeedSkeleton 本身透明 · parent 给底色)。
// 首次跑: flutter test --update-goldens test/golden/feed_skeleton_golden_test.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/feed_skeleton.dart';

void main() {
  testWidgets('FeedSkeleton golden', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Vt.bgPrimary),
      home: const Scaffold(
        body: SingleChildScrollView(child: FeedSkeleton()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(FeedSkeleton),
      matchesGoldenFile('feed_skeleton.png'),
    );
  });
}
