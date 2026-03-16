import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/home/presentation/screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) return AppRoutes.splash;
      final currentPath = state.matchedLocation;

      final isLoggedIn = authState.value != null;

      final isAuthRoute =
          currentPath.startsWith('/login') ||
          currentPath.startsWith('/register');

      final isSystemRoute = currentPath == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      if (isLoggedIn && (isAuthRoute || isSystemRoute)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => const HomeScreen(),
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
    ref.listen(membershipProvider, (_, next) => notifyListeners());
  }
}
