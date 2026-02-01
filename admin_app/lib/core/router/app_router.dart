import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/residents/presentation/screens/residents_screen.dart';
import '../../features/residents/presentation/screens/resident_detail_screen.dart';
import '../../features/residents/presentation/screens/add_resident_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/finance/presentation/screens/create_assessment_screen.dart';
import '../../features/finance/presentation/screens/payments_screen.dart';
import '../../features/meters/presentation/screens/meters_screen.dart';
import '../../features/meters/presentation/screens/meter_reading_screen.dart';
import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/announcements/presentation/screens/create_announcement_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/main/presentation/screens/main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main Shell
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          
          // Residents
          GoRoute(
            path: '/residents',
            name: 'residents',
            builder: (context, state) => const ResidentsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-resident',
                builder: (context, state) => const AddResidentScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'resident-detail',
                builder: (context, state) => ResidentDetailScreen(
                  residentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Finance
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
            routes: [
              GoRoute(
                path: 'assessments/create',
                name: 'create-assessment',
                builder: (context, state) => const CreateAssessmentScreen(),
              ),
              GoRoute(
                path: 'payments',
                name: 'payments',
                builder: (context, state) => const PaymentsScreen(),
              ),
            ],
          ),
          
          // Meters
          GoRoute(
            path: '/meters',
            name: 'meters',
            builder: (context, state) => const MetersScreen(),
            routes: [
              GoRoute(
                path: 'reading',
                name: 'meter-reading',
                builder: (context, state) => const MeterReadingScreen(),
              ),
            ],
          ),
          
          // Announcements
          GoRoute(
            path: '/announcements',
            name: 'announcements',
            builder: (context, state) => const AnnouncementsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-announcement',
                builder: (context, state) => const CreateAnnouncementScreen(),
              ),
            ],
          ),
          
          // Requests
          GoRoute(
            path: '/requests',
            name: 'requests',
            builder: (context, state) => const RequestsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'request-detail',
                builder: (context, state) => RequestDetailScreen(
                  requestId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Reports
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // TODO: Auth kontrolü
      // final isLoggedIn = ref.read(authProvider).isLoggedIn;
      // final isLoginRoute = state.matchedLocation == '/login';
      // if (!isLoggedIn && !isLoginRoute) return '/login';
      // if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
  );
});
