// ============================================================================
// HapticService · v25 · 全局触觉反馈服务
// ----------------------------------------------------------------------------
// 语义化 7 级触觉分类（从轻到重）：
//
//   selection()  → selectionClick    checkbox / tab 切换 / list hover
//                   最轻，无冲击感，仅"选中"质感
//
//   light()      → lightImpact       button tap / chip 选中
//                   轻冲击，确认用户点击但不打断节奏
//
//   medium()     → mediumImpact      confirm action / toggle 开关
//                   中等冲击，明确告知操作已执行
//
//   heavy()      → heavyImpact       大 CTA / 发布 / 危险操作
//                   重冲击，重要操作的物理锚点
//
//   success()    → lightImpact × 2 (间隔 50ms)
//                   双节奏"完成感"，比单次更有仪式感
//                   轻×2 避免过度惊扰，保持 Velvet 克制风格
//
//   warning()    → mediumImpact × 2 (间隔 80ms)
//                   节奏稍慢，提醒用户注意但不恐慌
//
//   error()      → heavyImpact × 2 (间隔 100ms)
//                   最明显的节奏，不可忽略的物理警告
//
// 使用建议：
//   - 不要在 build() 里调用
//   - 在 onTap / onPressed 回调第一行调用，发生在业务逻辑之前
//   - success/warning/error 在 async 操作结果确定后调用
//   - 设置页面暴露 HapticService.instance.enabled 给用户控制
//
// 平台说明：
//   iOS  → Taptic Engine 原生支持全部 7 级
//   Android 9+ → HapticFeedback 内部自动降级到最近档
//   Android < 9 / web → 静默降级，HapticFeedback 内部处理，无需额外判断
// ============================================================================

import 'package:flutter/services.dart';

/// 全局触觉反馈服务。
///
/// 使用方式：
/// ```dart
/// HapticService.instance.light();
/// HapticService.instance.success();
/// ```
///
/// 静默所有触觉（例如设置页开关）：
/// ```dart
/// HapticService.instance.enabled = false;
/// ```
class HapticService {
  HapticService._();

  static final HapticService instance = HapticService._();

  /// 全局开关。`false` 时所有方法均为 no-op。
  /// 未来设置页面通过此字段持久化用户偏好。
  bool enabled = true;

  // --------------------------------------------------------------------------
  // 7 级语义方法
  // --------------------------------------------------------------------------

  /// 最轻触感：checkbox / tab 切换 / list hover
  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// 轻冲击：button tap / chip 选中
  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// 中等冲击：confirm action / toggle 开关
  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 重冲击：大 CTA / 发布 / 危险操作确认
  Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// 成功反馈：lightImpact × 2（间隔 50ms）
  ///
  /// 双节奏"完成感"，比单次更有仪式感。
  /// 轻×2 保持 Velvet 克制风格，不过度惊扰。
  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// 警告反馈：mediumImpact × 2（间隔 80ms）
  ///
  /// 节奏稍慢，提醒注意但不恐慌。
  Future<void> warning() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// 错误反馈：heavyImpact × 2（间隔 100ms）
  ///
  /// 最明显的节奏，不可忽略的物理警告。
  Future<void> error() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
