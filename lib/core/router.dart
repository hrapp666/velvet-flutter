import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_handler.dart';

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
import '../features/wallet/presentation/screens/wallet_screen.dart';
import '../shared/theme/design_tokens.dart';
import '../shared/widgets/main_scaffold.dart';
import '../shared/widgets/motion/cinematic_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final uri = state.uri;
    if (uri.scheme == 'velvet' ||
        (uri.scheme == 'https' && uri.host == 'velvet.app')) {
      return DeepLinkHandler.routeFor(uri);
    }
    return null;
  },
  routes: [
    // ─── 启动 / 引导 / 认证（全部 pageBuilder · 统一 fade 过渡 · 不走 Material 默认 zoom）───
    GoRoute(path: '/splash', pageBuilder: (_, __) => _noAnim(const SplashScreen())),
    GoRoute(path: '/onboarding', pageBuilder: (_, __) => _noAnim(const OnboardingScreen())),
    GoRoute(path: '/login', pageBuilder: (_, __) => _noAnim(const LoginScreen())),
    GoRoute(path: '/register', pageBuilder: (_, __) => _noAnim(const RegisterScreen())),

    // ─── 主框架（5 tab 底部导航）───
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/feed', pageBuilder: (_, __) => _noAnim(const FeedScreen())),
        GoRoute(path: '/discover', pageBuilder: (_, __) => _noAnim(const _DiscoverPlaceholder())),
        GoRoute(path: '/publish', pageBuilder: (_, __) => _noAnim(const CreateMomentScreen())),
        GoRoute(path: '/chats', pageBuilder: (_, __) => _noAnim(const ChatListScreen())),
        GoRoute(path: '/profile', pageBuilder: (_, __) => _noAnim(const ProfileScreen())),
      ],
    ),

    // ─── 详情页（无底部导航）· CinematicPage 电影级切换 ───
    GoRoute(
      path: '/moment/:id',
      pageBuilder: (_, state) => CinematicPage(
        key: state.pageKey,
        child: MomentDetailScreen(
          momentId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (_, state) => CinematicPage(key: state.pageKey, child: const SearchScreen()),
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
          userId: int.parse(state.pathParameters['id'] ?? '0'),
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
            conversationId: int.parse(state.pathParameters['id'] ?? '0'),
            prefilledConv: extra is ConversationModel ? extra : null,
          ),
        );
      },
    ),
    // ─── v22 商业闭环页面 ───
    GoRoute(
      path: '/wallet',
      pageBuilder: (_, state) => CinematicPage(
        key: state.pageKey,
        child: const WalletScreen(),
      ),
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

// 占位：收藏页（待做）
class _DiscoverPlaceholder extends StatelessWidget {
  const _DiscoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vt.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline_rounded, color: Vt.gold, size: 48),
            const SizedBox(height: Vt.s16),
            Text('收藏', style: Vt.displayMd.copyWith(fontSize: Vt.txl, letterSpacing: 4)),
            const SizedBox(height: Vt.s8),
            Text('SAVED FOR LATER', style: Vt.caption),
          ],
        ),
      ),
    );
  }
}
