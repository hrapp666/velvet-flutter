// ============================================================================
// SoundService · v25 · 品牌音效服务（占位 · API 完整）
// ----------------------------------------------------------------------------
// 当前所有方法均为 no-op。主人后续接入 audio asset 后激活。
//
// 推荐接入方案（任选其一）：
//   audioplayers ^6.x  → 成熟稳定，适合短音效
//   flutter_soloud     → 低延迟，适合游戏/实时交互音效
//
// 接入步骤（未来）：
//   1. pubspec.yaml 添加 audioplayers 或 flutter_soloud
//   2. assets/sounds/ 放入 6 个 .ogg/.mp3 文件（命名对应 ChimeType）
//   3. 将 _play(type) 从注释取消注释，实现真实播放
//   4. SoundService.instance.enabled 绑定设置页开关
//
// ChimeType 语义：
//   tap      → 轻 tap 确认音（UI button）
//   open     → 页面/弹层打开时的进入音
//   close    → 页面/弹层关闭时的退出音
//   success  → 操作成功完成音（配合 HapticService.success）
//   error    → 操作失败音（配合 HapticService.error）
//   message  → 新消息到达提示音
// ============================================================================

/// 声音类型枚举。
///
/// 对应 assets/sounds/{name}.ogg 文件（待添加）。
enum ChimeType {
  /// 轻 tap 确认音
  tap,

  /// 页面 / 弹层打开音
  open,

  /// 页面 / 弹层关闭音
  close,

  /// 操作成功完成音
  success,

  /// 操作失败音
  error,

  /// 新消息到达提示音
  message,
}

/// 全局品牌音效服务。
///
/// 当前为占位实现，所有方法均为 no-op，不抛任何异常。
///
/// 使用方式（与 HapticService 配对调用）：
/// ```dart
/// HapticService.instance.success();
/// SoundService.instance.playChime(ChimeType.success);
/// ```
///
/// 全局静音：
/// ```dart
/// SoundService.instance.enabled = false;
/// ```
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  /// 全局开关。`false` 时所有方法均为 no-op。
  bool enabled = true;

  /// 播放指定类型的品牌音效。
  ///
  /// 当前为占位 no-op，接入 audioplayers 后实现真实播放。
  Future<void> playChime(ChimeType type) async {
    if (!enabled) return;
    // TODO(owner): 接入 audioplayers 后取消注释
    // await _player.play(AssetSource('sounds/${type.name}.ogg'));
  }

  // --------------------------------------------------------------------------
  // 语义化快捷方法（对应 HapticService 7 级）
  // --------------------------------------------------------------------------

  /// 播放 tap 音效
  Future<void> tap() => playChime(ChimeType.tap);

  /// 播放 open 音效
  Future<void> open() => playChime(ChimeType.open);

  /// 播放 close 音效
  Future<void> close() => playChime(ChimeType.close);

  /// 播放 success 音效
  Future<void> success() => playChime(ChimeType.success);

  /// 播放 error 音效
  Future<void> error() => playChime(ChimeType.error);

  /// 播放 message 音效
  Future<void> message() => playChime(ChimeType.message);
}
