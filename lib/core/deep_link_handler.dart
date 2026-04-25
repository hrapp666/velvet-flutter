/// 解析外来 Uri → go_router 可直接 navigate 的 path
///
/// 支持：
///   velvet://moment/123    → /moment/123
///   velvet://user/456      → /user/456
///   velvet://chat/789      → /chat/789
///   velvet://recommend     → /feed?tab=recommend
///   https://velvet.app/moment/123 → /moment/123（Universal Link · 域名购入后激活）
///
/// 安全策略:
///   1. scheme/host 双白名单 (velvet:// 或 https://velvet.app)
///   2. resource 必须命中固定枚举,不放任意 segment
///   3. ID 必须是 19 位以内纯数字 (Java Long 范围),
///      防止 `../admin`、 `<script>`、URL-encoded 攻击渗入路由
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Velvet 业务 ID 都是 Java `Long`,signed 最大 19 位数字
  static final _idRegex = RegExp(r'^\d{1,19}$');

  /// Resource 白名单 → 内部路由模板
  /// 模板里的 `{id}` 被 [_safeId] 验证后的纯数字替换
  static const _resourceRoutes = <String, String>{
    'moment': '/moment/{id}',
    'user': '/user/{id}',
    'chat': '/chat/{id}',
  };

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
    if (host == 'recommend') {
      return '/feed?tab=recommend';
    }
    final template = _resourceRoutes[host];
    if (template == null) return null;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;
    final id = _safeId(segments.first);
    if (id == null) return null;
    return template.replaceFirst('{id}', id);
  }

  // https://velvet.app/moment/123 → pathSegments=['moment','123']
  static String? _handleHttpsLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length < 2) return null;
    final template = _resourceRoutes[segments[0]];
    if (template == null) return null;
    final id = _safeId(segments[1]);
    if (id == null) return null;
    return template.replaceFirst('{id}', id);
  }

  /// 校验 segment 是 Velvet 业务 ID:纯数字 + 长度 ≤19
  /// 拒掉 `../`、URL-encoded、字母数字混杂、超长输入
  static String? _safeId(String raw) {
    return _idRegex.hasMatch(raw) ? raw : null;
  }
}
