import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/church/presentation/screens/church_tab_screen.dart';
import 'package:client/features/church/presentation/screens/church_public_profile_screen.dart';
import 'package:client/features/church/presentation/screens/church_search_screen.dart';
import 'package:client/features/church/presentation/screens/register_church_screen.dart';
import 'package:client/features/home/presentation/screens/calendar_screen.dart';
import 'package:client/features/home/presentation/screens/feed_screen.dart';
import 'package:client/features/home/presentation/screens/home_screen.dart';
import 'package:client/features/menu/presentation/screens/menu_screen.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _authRoutes = <String>{AppRoutes.login, AppRoutes.register};

final _systemRoutes = <String>{AppRoutes.splash};

final _protectedRoutes = <String>{
  AppRoutes.homeFeed,
  AppRoutes.homeCalendar,
  AppRoutes.homeChurch,
  AppRoutes.homeMenu,
  AppRoutes.registerChurch,
  AppRoutes.churchSearch,
  AppRoutes.churchPublicProfile,
};

final _membershipRequiredRoutes = <String>{};

final _memberRoutes = <String>{};

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellFeedNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-feed',
);
final _shellCalendarNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-calendar',
);
final _shellChurchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-church',
);
final _shellMenuNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-menu',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();

  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) return AppRoutes.splash;

      final currentPath = state.matchedLocation;
      final isLoggedIn = authState.value != null;
      final isAuthRoute = _isAuthRoute(currentPath);
      final isSystemRoute = _isSystemRoute(currentPath);
      final isProtectedRoute = _isProtectedRoute(currentPath);

      if (!isLoggedIn && currentPath == AppRoutes.splash) {
        return AppRoutes.login;
      }

      if (!isLoggedIn && isProtectedRoute) return AppRoutes.login;

      if (isLoggedIn && (isAuthRoute || isSystemRoute)) {
        return AppRoutes.homeFeed;
      }

      if (isLoggedIn) {
        final permissionsAsync = ref.read(sessionPermissionsProvider);
        final permissions = permissionsAsync.asData?.value;

        if (permissions != null) {
          if (_membershipRequiredRoutes.contains(currentPath) &&
              !permissions.hasMembership) {
            return AppRoutes.homeFeed;
          }

          if (_memberRoutes.contains(currentPath) && !permissions.isMember) {
            return AppRoutes.homeFeed;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellFeedNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeFeed,
                name: AppRoutes.homeFeedName,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellCalendarNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeCalendar,
                name: AppRoutes.homeCalendarName,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellChurchNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeChurch,
                name: AppRoutes.homeChurchName,
                builder: (context, state) => const ChurchTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellMenuNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homeMenu,
                name: AppRoutes.homeMenuName,
                builder: (context, state) => const MenuScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.registerChurch,
        name: AppRoutes.registerChurchName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterChurchScreen(),
      ),
      GoRoute(
        path: AppRoutes.churchSearch,
        name: AppRoutes.churchSearchName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChurchSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.churchPublicProfile,
        name: AppRoutes.churchPublicProfileName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final churchId = state.pathParameters['id']!;
          return ChurchPublicProfileScreen(churchId: churchId);
        },
      ),
    ],
  );
});

bool _isAuthRoute(String location) => _authRoutes.contains(location);

bool _isSystemRoute(String location) => _systemRoutes.contains(location);

bool _isProtectedRoute(String location) => _protectedRoutes.contains(location);

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
    ref.listen(sessionPermissionsProvider, (_, next) => notifyListeners());
  }
}
