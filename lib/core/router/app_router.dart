import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/router/app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Lógica de redirecionamento será conectada ao authStateProvider na Fase 2
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login — em breve')),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Cadastro — em breve')),
        ),
      ),
      GoRoute(
        path: AppRoutes.peopleList,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Lista de membros — em breve')),
        ),
      ),
      GoRoute(
        path: AppRoutes.peopleDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return Scaffold(
            body: Center(child: Text('Detalhe do membro $id — em breve')),
          );
        },
      ),
    ],
  );
});