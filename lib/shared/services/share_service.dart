// ============================================================================
// ShareService · v25 · 系统分享 wrapper
// ----------------------------------------------------------------------------
// 封装 share_plus 的 Share.share + shareXFiles。
// 未来加 analytics / 日志只改这里，调用方无感知。
//
// 设计决策：
//   1. buildMomentShareText 是 @visibleForTesting static，不是 private：
//      纯函数无副作用，可直接 unit test 文本格式，不依赖 Share 平台 channel。
//      private 会导致测试只能走 integration test 路线（需真实系统 UI）。
//
//   2. unawaited(HapticService.instance.light())：
//      触觉反馈是 fire-and-forget 的 UI 增强，不是业务路径。
//      如果 await，用户会感受到轻微 jank（先等震动再弹分享菜单）。
//      unawaited 让震动与系统弹框并发，符合 Velvet 克制流畅风格。
//
//   3. 不在此处加 Firebase Analytics 记录 share event：
//      Firebase SDK 当前被 pubspec 注释（TODO）以避免 build 冲突。
//      ShareService 作为 pure platform wrapper 应保持单一职责；
//      analytics 是横切关注点，应由调用方（Provider 层）在结果回调里注入，
//      不耦合进 Service 本身。
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:velvet/shared/services/haptic_service.dart';

/// 全局系统分享服务。
///
/// 使用：
/// ```dart
/// await ShareService.instance.shareMoment(
///   momentId: 123,
///   title: 'Silk',
///   summary: '古董',
/// );
/// ```
class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();

  // --------------------------------------------------------------------------
  // 公开 API
  // --------------------------------------------------------------------------

  /// 分享一段文本，触发系统分享菜单。
  ///
  /// 返回 [ShareResult] 携带用户选择的平台（iOS 上可用，Android 通常为 unknown）。
  Future<ShareResult> shareText({
    required String text,
    String? subject,
  }) async {
    unawaited(HapticService.instance.light());
    return Share.share(text, subject: subject);
  }

  /// 分享 moment：组合 title + content + deep-link。
  ///
  /// Deep-link 格式：`velvet://moment/:id`（买 velvet.app 域名后可改为 https）。
  Future<ShareResult> shareMoment({
    required int momentId,
    required String title,
    String? summary,
  }) {
    return shareText(
      text: buildMomentShareText(momentId, title, summary),
      subject: title,
    );
  }

  /// 分享图片文件（如 moment cover 本地缓存路径）。
  Future<ShareResult> shareImage({
    required String filePath,
    String? caption,
  }) async {
    unawaited(HapticService.instance.light());
    final xfile = XFile(filePath);
    return Share.shareXFiles([xfile], text: caption);
  }

  // --------------------------------------------------------------------------
  // 可测试纯函数（@visibleForTesting）
  // --------------------------------------------------------------------------

  /// 构建 moment 分享文本。
  ///
  /// 独立于 [Share] platform channel，可直接在 unit test 里断言格式。
  @visibleForTesting
  static String buildMomentShareText(
    int momentId,
    String title,
    String? summary,
  ) {
    final link = 'velvet://moment/$momentId';
    final buf = StringBuffer()..writeln(title);
    if (summary != null && summary.isNotEmpty) {
      buf.writeln(summary);
    }
    buf.writeln();
    buf.writeln(link);
    buf.write('— via Velvet · Touch what was touched');
    return buf.toString();
  }
}
