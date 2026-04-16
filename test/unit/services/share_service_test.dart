// ============================================================================
// ShareService · unit tests · v25
// ----------------------------------------------------------------------------
// 测试策略：
//   share_plus 的 Share.share 走 method channel（flutter/com.kasem.sharing），
//   无法在 unit test 里触发真实系统 UI。
//
//   因此只测 buildMomentShareText 纯函数——它覆盖了文案拼接全部逻辑，
//   是 shareMoment 真正的业务输出。platform channel 调用本身不属于
//   业务逻辑，不需要 unit test 覆盖。
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:velvet/shared/services/share_service.dart';

void main() {
  group('ShareService.buildMomentShareText', () {
    // ------------------------------------------------------------------------
    // Case 1：有 title + summary，格式完整
    // ------------------------------------------------------------------------
    test('title + summary 均存在时文本格式正确', () {
      // Arrange
      const id = 123;
      const title = 'Silk';
      const summary = '古董';

      // Act
      final text = ShareService.buildMomentShareText(id, title, summary);

      // Assert
      expect(text, contains('Silk'));
      expect(text, contains('古董'));
      expect(text, contains('velvet://moment/123'));
      expect(text, contains('Touch what was touched'));
    });

    // ------------------------------------------------------------------------
    // Case 2：无 summary（null）
    // ------------------------------------------------------------------------
    test('summary 为 null 时不多一行空内容', () {
      // Arrange & Act
      final text = ShareService.buildMomentShareText(1, 'Title', null);

      // Assert
      expect(text, contains('Title'));
      expect(text, contains('velvet://moment/1'));
      expect(text, contains('Touch what was touched'));
      // summary 是 null，文本里不应出现 summary 占位内容
      expect(text, isNot(contains('null')));
    });

    // ------------------------------------------------------------------------
    // Case 3：summary 为空字符串，等价于 null
    // ------------------------------------------------------------------------
    test('summary 为空字符串时与 null 行为一致', () {
      final withNull = ShareService.buildMomentShareText(5, 'A', null);
      final withEmpty = ShareService.buildMomentShareText(5, 'A', '');

      expect(withNull, equals(withEmpty));
    });

    // ------------------------------------------------------------------------
    // Case 4：deep-link 格式
    // ------------------------------------------------------------------------
    test('deep-link 格式为 velvet://moment/:id', () {
      final text = ShareService.buildMomentShareText(999, 'T', null);
      expect(text, contains('velvet://moment/999'));
    });

    // ------------------------------------------------------------------------
    // Case 5：署名行固定
    // ------------------------------------------------------------------------
    test('署名行固定为 — via Velvet · Touch what was touched', () {
      final text = ShareService.buildMomentShareText(0, 'x', null);
      expect(
        text,
        contains('— via Velvet · Touch what was touched'),
      );
    });

    // ------------------------------------------------------------------------
    // Case 6：summary 非空时顺序正确（title 在 summary 前）
    // ------------------------------------------------------------------------
    test('title 出现在 summary 之前', () {
      final text =
          ShareService.buildMomentShareText(42, 'MyTitle', 'MySummary');
      final titleIdx = text.indexOf('MyTitle');
      final summaryIdx = text.indexOf('MySummary');
      expect(titleIdx, lessThan(summaryIdx));
    });
  });
}
