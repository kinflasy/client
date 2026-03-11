import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) return AppRoutes.splash;

      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!isLoggedIn &&
          !isAuthRoute &&
          state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.login;
      }

      if (!isLoggedIn && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isAuthRoute) return AppRoutes.peopleList;
      if (isLoggedIn && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.peopleList;
      }

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
        path: AppRoutes.peopleList,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Lista de pessoas'),
            actions: [
              Consumer(
                builder: (context, ref, _) => IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                ),
              ),
            ],
          ),
          body: const Center(child: Text('Lista de pessoas — em breve')),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Detalhe ${state.pathParameters['id']} — em breve'),
              ),
            ),
          ),
        ],
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
  }
}
