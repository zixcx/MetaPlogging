import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/auth/presentation/pages/find_account_page.dart';
import 'package:meta_plogging/features/auth/presentation/pages/landing_page.dart';
import 'package:meta_plogging/features/auth/presentation/pages/login_page.dart';
import 'package:meta_plogging/features/auth/presentation/pages/register_page.dart';
import 'package:meta_plogging/features/auth/presentation/providers/auth_provider.dart';
import 'package:meta_plogging/features/feed/presentation/pages/feed_page.dart';
import 'package:meta_plogging/features/home/presentation/pages/home_page.dart';
import 'package:meta_plogging/features/plogging/presentation/pages/all_sessions_page.dart';
import 'package:meta_plogging/features/plogging/presentation/pages/plogging_page.dart';
import 'package:meta_plogging/features/plogging/presentation/pages/session_detail_page.dart';
import 'package:meta_plogging/features/profile/presentation/pages/profile_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // ref.watch 대신 redirect 콜백 안에서 ref.read 사용 —
  // auth 상태 변경 시 GoRouter 인스턴스가 재생성되지 않도록 방지.
  // refreshListenable이 redirect를 재평가하는 역할을 담당.
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final path = state.uri.path;
      final isOnAuthPath = path.startsWith('/auth');

      if (!isLoggedIn && !isOnAuthPath) return AppRoutes.landing;
      if (isLoggedIn && isOnAuthPath) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.findAccount,
        builder: (context, state) => const FindAccountPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.feed,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FeedPage()),
          ),
          GoRoute(
            path: AppRoutes.plogging,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PloggingPage()),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const AllSessionsPage(),
              ),
              GoRoute(
                path: 'sessions/:id',
                builder: (context, state) => SessionDetailPage(
                  sessionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
    ],
  );
});

class AppRoutes {
  static const String home = '/';
  static const String feed = '/feed';
  static const String plogging = '/plogging';
  static const String allSessions = '/plogging/history';
  static String sessionDetail(String id) => '/plogging/sessions/$id';
  static const String profile = '/profile';

  static const String landing = '/auth/landing';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String findAccount = '/auth/find-account';
}

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

/// Main shell with branded bottom navigation bar.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIdx = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF2A4035)
                  : const Color(0xFFE5F0E8),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: NavigationBar(
            selectedIndex: selectedIdx,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            animationDuration: const Duration(milliseconds: 200),
            height: 54,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_rounded, size: 26),
                selectedIcon: Icon(Icons.home_rounded, size: 26),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_rounded, size: 26),
                selectedIcon: Icon(Icons.article_rounded, size: 26),
                label: '피드',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_run_rounded, size: 26),
                selectedIcon: Icon(Icons.directions_run_rounded, size: 26),
                label: '플로깅',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded, size: 26),
                selectedIcon: Icon(Icons.person_rounded, size: 26),
                label: '프로필',
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.feed)) return 1;
    if (location.startsWith(AppRoutes.plogging)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.feed);
      case 2:
        context.go(AppRoutes.plogging);
      case 3:
        context.go(AppRoutes.profile);
    }
  }
}
