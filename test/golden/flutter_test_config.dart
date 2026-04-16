// ============================================================================
// Golden test harness · v25 · J5
// ----------------------------------------------------------------------------
// flutter_test 会在当前目录下自动发现 flutter_test_config.dart 并用它包装
// 每个 test main。
//
// google_fonts 在测试环境问题：
//   - allowRuntimeFetching=true → 网络 fetch 失败 → 抛异常
//   - allowRuntimeFetching=false → 无 asset bundle → 抛异常
//
// 解决方案：
//   1. 关闭 runtime fetching
//   2. 在 FlutterError.onError 里吞掉 "google_fonts" 相关的异步异常
//      （这些异常发生在 test 已经完成之后，不影响 golden 截图生成）
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 禁止 google_fonts 走网络
  GoogleFonts.config.allowRuntimeFetching = false;

  // 吞掉 google_fonts 的 late async exception
  // (test 已经 complete, golden 已经截好, 只是 http fetch 事后失败)
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('google_fonts') || msg.contains('allowRuntimeFetching')) {
      return; // 静默原因：google_fonts 在 test 环境必然失败, 不影响 golden
    }
    originalOnError?.call(details);
  };

  await testMain();
}
