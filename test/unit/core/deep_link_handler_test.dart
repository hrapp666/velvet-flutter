import 'package:flutter_test/flutter_test.dart';
import 'package:velvet/core/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler.routeFor', () {
    // ── custom scheme: velvet:// ──────────────────────────────────────────

    test('velvet://moment/123 → /moment/123', () {
      // Arrange
      final uri = Uri.parse('velvet://moment/123');
      // Act
      final result = DeepLinkHandler.routeFor(uri);
      // Assert
      expect(result, '/moment/123');
    });

    test('velvet://user/456 → /user/456', () {
      final uri = Uri.parse('velvet://user/456');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, '/user/456');
    });

    test('velvet://chat/789 → /chat/789', () {
      final uri = Uri.parse('velvet://chat/789');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, '/chat/789');
    });

    test('velvet://recommend → /feed?tab=recommend', () {
      final uri = Uri.parse('velvet://recommend');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, '/feed?tab=recommend');
    });

    test('velvet://unknown → null', () {
      final uri = Uri.parse('velvet://unknown/99');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, isNull);
    });

    // ── universal link: https://velvet.app ───────────────────────────────

    test('https://velvet.app/moment/123 → /moment/123', () {
      final uri = Uri.parse('https://velvet.app/moment/123');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, '/moment/123');
    });

    test('https://evil.com/moment/123 → null (untrusted host)', () {
      final uri = Uri.parse('https://evil.com/moment/123');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, isNull);
    });

    test('https://velvet.app/ → null (path too short)', () {
      final uri = Uri.parse('https://velvet.app/');
      final result = DeepLinkHandler.routeFor(uri);
      expect(result, isNull);
    });
  });
}
