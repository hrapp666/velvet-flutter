// ============================================================================
// ReconnectBackoff 单元测试
// ============================================================================
//
// 使用 fake_async 控制时间，只测纯逻辑类 ReconnectBackoff，
// 不依赖 WebSocketChannel，无网络调用。

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velvet/features/chat/data/services/chat_socket.dart';
import 'package:velvet/features/chat/data/models/chat_models.dart';

void main() {
  group('ReconnectBackoff', () {
    // ------------------------------------------------------------------
    // Test 1: 10 次 fail 后进入 failed 状态，不再 retry
    // ------------------------------------------------------------------
    test('10 次调用后 nextDelay 返回 null，isFailed 为 true', () {
      final backoff = ReconnectBackoff();

      for (var i = 0; i < 10; i++) {
        final delay = backoff.nextDelay();
        expect(
          delay,
          isNotNull,
          reason: 'attempt $i 应该返回有效延迟',
        );
      }

      // 第 11 次
      expect(backoff.nextDelay(), isNull);
      expect(backoff.isFailed, isTrue);
    });

    // ------------------------------------------------------------------
    // Test 2: 退避序列 1s/2s/4s/8s/16s/32s/32s/32s/32s/32s
    // ------------------------------------------------------------------
    test('退避序列符合 min(1<<attempt, 32) 秒', () {
      final backoff = ReconnectBackoff();
      final expected = [1, 2, 4, 8, 16, 32, 32, 32, 32, 32];

      for (final secs in expected) {
        final delay = backoff.nextDelay();
        expect(
          delay,
          equals(Duration(seconds: secs)),
          reason: '期望 ${secs}s，实际 $delay',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 3: reset() 后计数器归零，序列重新从 1s 开始
    // ------------------------------------------------------------------
    test('reset 后退避序列从头开始', () {
      final backoff = ReconnectBackoff();

      // 推进 3 次
      backoff.nextDelay(); // 1s
      backoff.nextDelay(); // 2s
      backoff.nextDelay(); // 4s
      expect(backoff.attempt, equals(3));

      backoff.reset();
      expect(backoff.attempt, equals(0));
      expect(backoff.isFailed, isFalse);

      // 序列重新从 1s 开始
      expect(backoff.nextDelay(), equals(const Duration(seconds: 1)));
      expect(backoff.nextDelay(), equals(const Duration(seconds: 2)));
    });

    // ------------------------------------------------------------------
    // Test 4: 自定义 maxAttempts 和 capSeconds
    // ------------------------------------------------------------------
    test('自定义 maxAttempts=3 capSeconds=4 时序列为 1s/2s/4s 然后 null', () {
      final backoff = ReconnectBackoff(maxAttempts: 3, capSeconds: 4);

      expect(backoff.nextDelay(), equals(const Duration(seconds: 1)));
      expect(backoff.nextDelay(), equals(const Duration(seconds: 2)));
      expect(backoff.nextDelay(), equals(const Duration(seconds: 4)));
      expect(backoff.nextDelay(), isNull);
      expect(backoff.isFailed, isTrue);
    });

    // ------------------------------------------------------------------
    // Test 5: cap 生效 — 第 6 次以后永远是 32s，不超过 cap
    // ------------------------------------------------------------------
    test('capSeconds=32 从第 6 次起全部 32s', () {
      final backoff = ReconnectBackoff();

      // 消耗前 5 次 (1/2/4/8/16)
      for (var i = 0; i < 5; i++) {
        backoff.nextDelay();
      }

      // 第 6～10 次都应是 32s
      for (var i = 5; i < 10; i++) {
        final delay = backoff.nextDelay();
        expect(
          delay,
          equals(const Duration(seconds: 32)),
          reason: 'attempt $i 应 cap 为 32s',
        );
      }
    });
  });

  // -----------------------------------------------------------------------
  // Timer 行为测试（用 fake_async 控制时间）
  // -----------------------------------------------------------------------
  group('ReconnectBackoff with fake_async timers', () {
    // ------------------------------------------------------------------
    // Test 6: 用 fake_async 模拟完整退避序列 timer 触发时机
    // ------------------------------------------------------------------
    test('fake_async 验证退避 timer 在正确时刻触发', () {
      fakeAsync((async) {
        final backoff = ReconnectBackoff(maxAttempts: 4, capSeconds: 8);
        final fired = <int>[];

        void scheduleNext() {
          final delay = backoff.nextDelay();
          if (delay == null) return;
          Timer(delay, () {
            fired.add(delay.inSeconds);
            scheduleNext();
          });
        }

        scheduleNext();

        // t=0: 等 1s
        async.elapse(const Duration(seconds: 1));
        expect(fired, equals([1]));

        // t=1+: 等 2s
        async.elapse(const Duration(seconds: 2));
        expect(fired, equals([1, 2]));

        // t=3+: 等 4s
        async.elapse(const Duration(seconds: 4));
        expect(fired, equals([1, 2, 4]));

        // t=7+: 等 8s（cap）
        async.elapse(const Duration(seconds: 8));
        expect(fired, equals([1, 2, 4, 8]));

        // 已 4 次，backoff.isFailed=true，不再调度
        expect(backoff.isFailed, isTrue);
        async.elapse(const Duration(seconds: 100));
        expect(fired.length, equals(4)); // 不再增加
      });
    });

    // ------------------------------------------------------------------
    // Test 7: reset 后 timer 序列从 1s 重新开始
    // ------------------------------------------------------------------
    test('fake_async 验证 reset 后 timer 序列重置', () {
      fakeAsync((async) {
        final backoff = ReconnectBackoff(maxAttempts: 10, capSeconds: 32);
        final fired = <int>[];

        // 推进 3 步
        for (var i = 0; i < 3; i++) {
          final delay = backoff.nextDelay()!;
          Timer(Duration.zero, () => fired.add(delay.inSeconds));
        }
        async.flushTimers();
        expect(fired, equals([1, 2, 4]));

        // reset 后重新从 1s 开始
        backoff.reset();
        fired.clear();

        for (var i = 0; i < 3; i++) {
          final delay = backoff.nextDelay()!;
          Timer(Duration.zero, () => fired.add(delay.inSeconds));
        }
        async.flushTimers();
        expect(fired, equals([1, 2, 4]));
      });
    });
  });

  // -----------------------------------------------------------------------
  // WsConnectionState enum sanity checks
  // -----------------------------------------------------------------------
  group('WsConnectionState', () {
    test('enum 包含所有预期值', () {
      expect(WsConnectionState.values, containsAll([
        WsConnectionState.disconnected,
        WsConnectionState.connecting,
        WsConnectionState.connected,
        WsConnectionState.reconnecting,
        WsConnectionState.failed,
      ]));
    });

    test('StreamController 广播去重：相同状态不 emit 重复', () async {
      // 模拟 _setState 去重逻辑
      final controller = StreamController<WsConnectionState>.broadcast();
      final emitted = <WsConnectionState>[];
      controller.stream.listen(emitted.add);

      WsConnectionState current = WsConnectionState.disconnected;
      void setState(WsConnectionState next) {
        if (current == next) return;
        current = next;
        controller.add(next);
      }

      setState(WsConnectionState.connecting);
      setState(WsConnectionState.connecting); // 重复，不 emit
      setState(WsConnectionState.connected);
      setState(WsConnectionState.connected);  // 重复，不 emit
      setState(WsConnectionState.reconnecting);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, equals([
        WsConnectionState.connecting,
        WsConnectionState.connected,
        WsConnectionState.reconnecting,
      ]));

      await controller.close();
    });
  });
}
