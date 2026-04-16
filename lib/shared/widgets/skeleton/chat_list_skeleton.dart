// ============================================================================
// ChatListSkeleton · v25 · chat_list_screen 占位
// ----------------------------------------------------------------------------
// 6 行 · 头像 + 名字 + 最后消息 + 时间 · 间距对位生产 chat row
// ============================================================================

import 'package:flutter/material.dart';

import 'package:velvet/shared/theme/design_tokens.dart';
import 'package:velvet/shared/widgets/skeleton/skeleton_box.dart';

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: Vt.s16,
          vertical: Vt.s24,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: Vt.s24),
        itemBuilder: (_, __) => const _ChatRowSkeleton(),
      ),
    );
  }
}

class _ChatRowSkeleton extends StatelessWidget {
  const _ChatRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        SkeletonAvatar(size: 48),
        SizedBox(width: Vt.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonTextLine(widthFactor: 0.4, height: 14),
              SizedBox(height: Vt.s8),
              SkeletonTextLine(widthFactor: 0.7, height: 11),
            ],
          ),
        ),
        SizedBox(width: Vt.s12),
        SkeletonBox(width: 36, height: 10, radius: Vt.rXxs),
      ],
    );
  }
}
