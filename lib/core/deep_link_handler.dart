/// 解析外来 Uri → go_router 可直接 navigate 的 path
///
/// 支持：
///   velvet://moment/123    → /moment/123
///   velvet://user/456      → /user/456
///   velvet://chat/789      → /chat/789
///   velvet://recommend     → /feed?tab=recommend
///   https://velvet.app/moment/123 → /moment/123（Universal Link · 域名购入后激活）
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Parse incoming [uri] into a route path.
  /// Returns null when the uri is unsupported or malformed.
  static String? routeFor(Uri uri) {
    if (uri.scheme == 'velvet') {
      return _handleCustomScheme(uri);
    }
    if (uri.scheme == 'https' && uri.host == 'velvet.app') {
      return _handleHttpsLink(uri);
    }
    return null;
  }

  // velvet://moment/123 → host='moment', pathSegments=['123']
  static String? _handleCustomScheme(Uri uri) {
    final host = uri.host;
    final segments = uri.pathSegments;
    switch (host) {
      case 'moment':
        return segments.isNotEmpty ? '/moment/${segments.first}' : null;
      case 'user':
        return segments.isNotEmpty ? '/user/${segments.first}' : null;
      case 'chat':
        return segments.isNotEmpty ? '/chat/${segments.first}' : null;
      case 'recommend':
        return '/feed?tab=recommend';
      default:
        return null;
    }
  }

  // https://velvet.app/moment/123 → pathSegments=['moment','123']
  static String? _handleHttpsLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length < 2) return null;
    final resource = segments[0];
    final id = segments[1];
    switch (resource) {
      case 'moment':
        return '/moment/$id';
      case 'user':
        return '/user/$id';
      case 'chat':
        return '/chat/$id';
      default:
        return null;
    }
  }
}
