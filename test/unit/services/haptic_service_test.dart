// ============================================================================
// HapticService · unit tests · v25
// ----------------------------------------------------------------------------
// 验证 7 级触觉语义 + enabled 开关 + success() 双脉冲 50ms 间隔
//
// 技术：
//   - HapticFeedback 通过 SystemChannels.platform (flutter/platform) 发起调用
//     方法名: "HapticFeedback.vibrate"，参数: feedback type 字符串
//   - Mock: setMockMethodCallHandler on 'flutter/platform'
//   - success() 间隔验证: 记录两次调用时间戳，断言间隔 >= 40ms
// ============================================================================

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velvet/shared/services/haptic_service.dart';

/// flutter/platform channel 上 HapticFeedback 调用的方法名
const _kVibrateMethod = 'HapticFeedback.vibrate';

/// 从 MethodCall arguments 提取 feedback type 字符串
/// HapticFeedback.vibrate(type) 直接把 type.toString() 当 arguments 传
/// 不是 Map · 是 String like "HapticFeedbackType.lightImpact"
String _feedbackType(MethodCall call) {
  return call.arguments as String;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 记录每次 platform channel 调用的 feedback type
  final List<String> _calls = [];

  setUp(() {
    _calls.clear();
    HapticService.instance.enabled = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == _kVibrateMethod) {
          _calls.add(_feedbackType(call));
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // --------------------------------------------------------------------------
  // Test 1: selection() 触发 selectionClick
  // --------------------------------------------------------------------------
  test('selection() 触发 HapticFeedback.selectionClick', () async {
    await HapticService.instance.selection();

    expect(_calls, hasLength(1));
    expect(_calls.first, contains('selectionClick'));
  });

  // --------------------------------------------------------------------------
  // Test 2: enabled = false 时方法无效果
  // --------------------------------------------------------------------------
  test('enabled = false 时所有方法为 no-op', () async {
    HapticService.instance.enabled = false;

    await HapticService.instance.selection();
    await HapticService.instance.light();
    await HapticService.instance.medium();
    await HapticService.instance.heavy();
    await HapticService.instance.success();
    await HapticService.instance.warning();
    await HapticService.instance.error();

    expect(_calls, isEmpty);
  });

  // --------------------------------------------------------------------------
  // Test 3: success() 触发 2 次 lightImpact，间隔 >= 50ms
  // --------------------------------------------------------------------------
  test('success() 触发 2 次 lightImpact，间隔 >= 50ms', () async {
    final List<DateTime> timestamps = [];

    // 重新 mock，额外记录时间戳
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == _kVibrateMethod) {
          _calls.add(_feedbackType(call));
          timestamps.add(DateTime.now());
        }
        return null;
      },
    );

    await HapticService.instance.success();

    expect(_calls, hasLength(2));
    expect(_calls[0], contains('lightImpact'));
    expect(_calls[1], contains('lightImpact'));

    final gap = timestamps[1].difference(timestamps[0]);
    // 允许 ±10ms 误差，实际等待 50ms，断言 >= 40ms
    expect(
      gap.inMilliseconds,
      greaterThanOrEqualTo(40),
      reason: 'success() 双脉冲间隔应 >= 40ms（目标 50ms）',
    );
  });

  // --------------------------------------------------------------------------
  // Test 4: 默认 enabled = true
  // --------------------------------------------------------------------------
  test('默认 enabled = true，light() 触发 lightImpact', () async {
    expect(HapticService.instance.enabled, isTrue);

    await HapticService.instance.light();

    expect(_calls, hasLength(1));
    expect(_calls.first, contains('lightImpact'));
  });

  // --------------------------------------------------------------------------
  // 额外覆盖：其余方法的 channel 调用验证
  // --------------------------------------------------------------------------
  group('其他方法 channel 调用验证', () {
    test('medium() → mediumImpact × 1', () async {
      await HapticService.instance.medium();

      expect(_calls, hasLength(1));
      expect(_calls.first, contains('mediumImpact'));
    });

    test('heavy() → heavyImpact × 1', () async {
      await HapticService.instance.heavy();

      expect(_calls, hasLength(1));
      expect(_calls.first, contains('heavyImpact'));
    });

    test('warning() → mediumImpact × 2', () async {
      await HapticService.instance.warning();

      expect(_calls, hasLength(2));
      expect(_calls[0], contains('mediumImpact'));
      expect(_calls[1], contains('mediumImpact'));
    });

    test('error() → heavyImpact × 2', () async {
      await HapticService.instance.error();

      expect(_calls, hasLength(2));
      expect(_calls[0], contains('heavyImpact'));
      expect(_calls[1], contains('heavyImpact'));
    });
  });

  // --------------------------------------------------------------------------
  // enabled 运行时切换
  // --------------------------------------------------------------------------
  test('enabled 可以在运行时切换', () async {
    HapticService.instance.enabled = false;
    await HapticService.instance.light();
    expect(_calls, isEmpty);

    HapticService.instance.enabled = true;
    await HapticService.instance.light();
    expect(_calls, hasLength(1));
  });
}
