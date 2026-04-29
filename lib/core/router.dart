import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_handler.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/chat/data/models/chat_models.dart';
import '../features/chat/presentation/screens/chat_detail_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/merchant/presentation/screens/merchant_apply_screen.dart';
import '../features/moment/presentation/screens/create_moment_screen.dart';
import '../features/moment/presentation/screens/favorites_screen.dart';
import '../features/moment/presentation/screens/feed_screen.dart';
import '../features/moment/presentation/screens/moment_detail_screen.dart';
import '../features/moment/presentation/screens/search_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';
import '../features/admin/presentation/screens/admin_screen.dart';
import '../features/order/presentation/screens/orders_screen.dart';
import '../features/profile/presentation/screens/about_screen.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/user_public_screen.dart';
import '../shared/theme/design_tokens.dart';
import '../shared/widgets/main_scaffold.dart';
import '../shared/widgets/motion/cinematic_page.dart';

// 公开路径白名单（无需登录可访问）
const _publicPaths = <String>{
  '/splash',
  '/onboarding',
  '/login',
  '/register',
};

bool _isPublic(String location) {
  for (final p in _publicPaths) {
    if (location == p ||
        location.startsWith('$p/') ||
        location.startsWith('$p?')) {
      return true;
    }
  }
  return false;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final uri = state.uri;

      // 1. deep link 转换（保持原有行为）
      if (uri.scheme == 'velvet' ||
          (uri.scheme == 'https' && uri.host == 'velvet.app')) {
        return DeepLinkHandler.routeFor(uri);
      }

      // 2. 公开路径直接放行
      final loc = state.matchedLocation;
      if (_isPublic(loc)) return null;

      // 3. 检查登录态 · 仅 AsyncData(null) 视为未登录
      // loading/error 不跳，避免冷启动 splash 闪烁
      final authState = ref.read(authNotifierProvider);
      final isLoggedOut =
          authState is AsyncData<UserProfile?> && authState.value == null;
      if (isLoggedOut) {
        return '/login';
      }
      return null;
    },
    routes: [
      // ─── 启动 / 引导 / 认证 ───
      GoRoute(path: '/splash', pageBuilder: (_, __) => _noAnim(const SplashScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (_, __) => _noAnim(const OnboardingScreen())),
      GoRoute(path: '/login', pageBuilder: (_, __) => _noAnim(const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (_, __) => _noAnim(const RegisterScreen())),

      // ─── 主框架 ───
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/feed', pageBuilder: (_, __) => _noAnim(const FeedScreen())),
          GoRoute(path: '/search', pageBuilder: (_, __) => _noAnim(const SearchScreen())),
          GoRoute(path: '/publish', pageBuilder: (_, __) => _noAnim(const CreateMomentScreen())),
          GoRoute(path: '/chats', pageBuilder: (_, __) => _noAnim(const ChatListScreen())),
          GoRoute(path: '/profile', pageBuilder: (_, __) => _noAnim(const ProfileScreen())),
        ],
      ),

      // ─── 详情页（带 id 参数 · 用 tryParse 防恶意 deep link 抛 FormatException） ───
      GoRoute(
        path: '/moment/:id',
        pageBuilder: (_, state) => CinematicPage(
          key: state.pageKey,
          child: MomentDetailScreen(
            momentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const NotificationScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (_, state) => CinematicPage(
          key: state.pageKey,
          child: const ProfileEditScreen(),
        ),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (_, state) => CinematicPage(
          key: state.pageKey,
          child: UserPublicScreen(
            userId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (_, state) {
          final extra = state.extra;
          return CinematicPage(
            key: state.pageKey,
            child: ChatDetailScreen(
              conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              prefilledConv: extra is ConversationModel ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (_, state) => CinematicPage(
          key: state.pageKey,
          child: const OrdersScreen(),
        ),
      ),
      GoRoute(
        path: '/merchant/apply',
        pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const MerchantApplyScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const AboutScreen()),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const FavoritesScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const AdminScreen()),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: Vt.bgPrimary,
      body: Center(
        child: Text('未找到页面: ${state.uri}', style: Vt.bodyMd),
      ),
    ),
  );
});

// 监听 authNotifierProvider 状态变化 · 触发 GoRouter redirect 重新评估
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AsyncValue<UserProfile?>>(
      authNotifierProvider,
      (prev, next) {
        // 登录/登出/用户切换都要触发 refresh
        final prevId = prev?.value?.id;
        final nextId = next.value?.id;
        if (prevId != nextId) {
          notifyListeners();
        }
      },
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<UserProfile?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

CustomTransitionPage<void> _noAnim(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (_, animation, __, c) => FadeTransition(
      opacity: animation,
      child: c,
    ),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

