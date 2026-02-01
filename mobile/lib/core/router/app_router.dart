import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/requests',
            name: 'requests',
            builder: (context, state) => const RequestsScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // TODO: Auth durumuna göre yönlendirme
      return null;
    },
  );
});
