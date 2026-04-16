// ============================================================================
// Skeleton 6 widget · v25 · A2
// ----------------------------------------------------------------------------
// 验证渲染 + 数量 · 不验证视觉(那是 golden test 的活,v26 加 baseline)
// pumpAndSettle 不能用(Shimmer.repeat 永不 settle)· 用 pump(Duration)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/widgets/skeleton/chat_list_skeleton.dart';
import 'package:velvet/shared/widgets/skeleton/feed_skeleton.dart';
import 'package:velvet/shared/widgets/skeleton/orders_skeleton.dart';
import 'package:velvet/shared/widgets/skeleton/search_skeleton.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';
import 'package:velvet/shared/widgets/skeleton/wallet_skeleton.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('SkeletonBox base widget', () {
    testWidgets('SkeletonBox 渲染 · 默认宽 + 指定高', (tester) async {
      await tester.pumpWidget(_harness(const SizedBox(
        width: 200,
        child: SkeletonBox(height: 40),
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('SkeletonAvatar 渲染 · 圆形', (tester) async {
      await tester.pumpWidget(_harness(const SkeletonAvatar(size: 48)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonAvatar), findsOneWidget);
    });

    testWidgets('SkeletonTextLine 渲染 · 部分宽度', (tester) async {
      await tester.pumpWidget(_harness(const SizedBox(
        width: 200,
        child: SkeletonTextLine(widthFactor: 0.6, height: 12),
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonTextLine), findsOneWidget);
    });
  });

  group('FeedSkeleton', () {
    testWidgets('渲染 6 个 masonry card', (tester) async {
      // FeedSkeleton 使用 MasonryGridView · 在 box 上下文(SingleChildScrollView)
      await tester.pumpWidget(_harness(const FeedSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FeedSkeleton), findsOneWidget);
      // 6 个 cover SkeletonBox + 6 × 2 text line + 6 avatar 等 · 至少 6 cover
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(6));
    });
  });

  group('ChatListSkeleton', () {
    testWidgets('渲染 6 行 + 头像', (tester) async {
      await tester.pumpWidget(_harness(const ChatListSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ChatListSkeleton), findsOneWidget);
      expect(find.byType(SkeletonAvatar), findsNWidgets(6));
    });
  });

  group('OrdersSkeleton', () {
    testWidgets('渲染 5 个订单卡', (tester) async {
      await tester.pumpWidget(_harness(const OrdersSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OrdersSkeleton), findsOneWidget);
      // 5 个卡 · 每个有 thumbnail + 2 text + 2 tag = 5 thumbnails
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(5));
    });
  });

  group('WalletSkeleton', () {
    testWidgets('渲染 hero + 4 quick action + 4 流水', (tester) async {
      await tester.pumpWidget(_harness(const WalletSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WalletSkeleton), findsOneWidget);
      // 至少 1 hero balance + 4 quick action box + 4 transaction icon
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(8));
    });
  });

  group('SearchSkeleton', () {
    testWidgets('渲染 8 个 grid item', (tester) async {
      await tester.pumpWidget(_harness(const SizedBox(
        width: 400,
        height: 800,
        child: SearchSkeleton(),
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SearchSkeleton), findsOneWidget);
      // GridView builder 只渲染可见区 · 至少 4 (2 列 × 2 行 visible)
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(4));
    });
  });

  group('Shimmer 不破坏 dispose', () {
    testWidgets('navigation away 不 crash · Shimmer ticker 安全 dispose',
        (tester) async {
      await tester.pumpWidget(_harness(const FeedSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));

      // 替换整棵 widget tree · 强制 FeedSkeleton 走 dispose
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: Text('REPLACED'))),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('REPLACED'), findsOneWidget);
      expect(find.byType(FeedSkeleton), findsNothing);
    });
  });
}
