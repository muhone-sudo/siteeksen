import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/resident_home_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/finance/presentation/screens/dues_payment_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/visitors/presentation/screens/visitor_preregister_screen.dart';
import '../../features/reservations/presentation/screens/create_reservation_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart';
import '../../features/surveys/presentation/screens/surveys_mobile_screen.dart';
import '../../features/packages/presentation/screens/package_tracking_mobile_screen.dart';
import '../../features/energy/presentation/screens/energy_consumption_mobile_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/assets/presentation/screens/assets_screen.dart';

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
            builder: (context, state) => const ResidentHomeScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
            routes: [
              GoRoute(
                path: 'payment',
                name: 'duesPayment',
                builder: (context, state) => const DuesPaymentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/requests',
            name: 'requests',
            builder: (context, state) => const RequestsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createRequest',
                builder: (context, state) => const CreateRequestScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),
      
      // Standalone Routes
      GoRoute(
        path: '/announcements',
        name: 'announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/visitor-preregister',
        name: 'visitorPreregister',
        builder: (context, state) => const VisitorPreRegisterScreen(),
      ),
      GoRoute(
        path: '/reservation',
        name: 'createReservation',
        builder: (context, state) => const CreateReservationScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      
      // İlan Panosu
      GoRoute(
        path: '/bulletin',
        name: 'bulletin',
        builder: (context, state) => const BulletinBoardMobileScreen(),
      ),
      
      // Anketler
      GoRoute(
        path: '/surveys',
        name: 'surveys',
        builder: (context, state) => const SurveysMobileScreen(),
      ),
      
      // Kargo Takip
      GoRoute(
        path: '/packages',
        name: 'packages',
        builder: (context, state) => const PackageTrackingMobileScreen(),
      ),
      
      // Enerji Tüketimi
      GoRoute(
        path: '/energy',
        name: 'energy',
        builder: (context, state) => const EnergyConsumptionMobileScreen(),
      ),
      
      // Belgeler
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      
      // Demirbaşlar
      GoRoute(
        path: '/assets',
        name: 'assets',
        builder: (context, state) => const AssetsScreen(),
      ),
    ],
    redirect: (context, state) {
      // TODO: Auth durumuna göre yönlendirme
      return null;
    },
  );
});
