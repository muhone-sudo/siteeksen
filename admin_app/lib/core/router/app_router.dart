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
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/main/presentation/screens/main_screen.dart';
// Yeni Modül Ekranları
import '../../features/visitors/presentation/screens/visitor_management_screen.dart';
import '../../features/parking/presentation/screens/parking_management_screen.dart';
import '../../features/reservations/presentation/screens/reservation_management_screen.dart';
import '../../features/energy/presentation/screens/energy_dashboard_screen.dart';
import '../../features/personnel/presentation/screens/personnel_management_screen.dart';
import '../../features/inventory/presentation/screens/inventory_management_screen.dart';
import '../../features/surveys/presentation/screens/survey_management_screen.dart';
import '../../features/packages/presentation/screens/package_tracking_screen.dart';
import '../../features/assets/presentation/screens/asset_management_screen.dart';
import '../../features/contracts/presentation/screens/contract_management_screen.dart';
import '../../features/patrol/presentation/screens/patrol_control_screen.dart';
import '../../features/meetings/presentation/screens/meeting_wizard_screen.dart';
import '../../features/collection/presentation/screens/smart_collection_screen.dart';
import '../../features/bulletin/presentation/screens/bulletin_board_screen.dart';
import '../../features/banking/presentation/screens/bank_integration_screen.dart';
import '../../features/settings/presentation/screens/api_settings_screen.dart';

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
          
          // Expenses (Gider Yönetimi)
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpensesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-expense',
                builder: (context, state) => const AddExpenseScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'expense-detail',
                builder: (context, state) => ExpenseDetailScreen(
                  expenseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Ziyaretçi Yönetimi
          GoRoute(
            path: '/visitors',
            name: 'visitors',
            builder: (context, state) => const VisitorManagementScreen(),
          ),
          
          // Otopark Yönetimi
          GoRoute(
            path: '/parking',
            name: 'parking',
            builder: (context, state) => const ParkingManagementScreen(),
          ),
          
          // Rezervasyon Yönetimi
          GoRoute(
            path: '/reservations',
            name: 'reservations',
            builder: (context, state) => const ReservationManagementScreen(),
          ),
          
          // AI Enerji Dashboard
          GoRoute(
            path: '/energy',
            name: 'energy',
            builder: (context, state) => const EnergyDashboardScreen(),
          ),
          
          // Personel Yönetimi
          GoRoute(
            path: '/personnel',
            name: 'personnel',
            builder: (context, state) => const PersonnelManagementScreen(),
          ),
          
          // Stok/Envanter Yönetimi
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryManagementScreen(),
          ),
          
          // Anket/Oylama
          GoRoute(
            path: '/surveys',
            name: 'surveys',
            builder: (context, state) => const SurveyManagementScreen(),
          ),
          
          // Kargo Takibi
          GoRoute(
            path: '/packages',
            name: 'packages',
            builder: (context, state) => const PackageTrackingScreen(),
          ),
          
          // Demirbaş Yönetimi
          GoRoute(
            path: '/assets',
            name: 'assets',
            builder: (context, state) => const AssetManagementScreen(),
          ),
          
          // Sözleşme Yönetimi
          GoRoute(
            path: '/contracts',
            name: 'contracts',
            builder: (context, state) => const ContractManagementScreen(),
          ),
          
          // Tur Kontrol
          GoRoute(
            path: '/patrol',
            name: 'patrol',
            builder: (context, state) => const PatrolControlScreen(),
          ),
          
          // AI Toplantı Sihirbazı
          GoRoute(
            path: '/meetings',
            name: 'meetings',
            builder: (context, state) => const MeetingWizardScreen(),
          ),
          
          // AI Akıllı Tahsilat
          GoRoute(
            path: '/collection',
            name: 'collection',
            builder: (context, state) => const SmartCollectionScreen(),
          ),
          
          // Site İlan Panosu
          GoRoute(
            path: '/bulletin',
            name: 'bulletin',
            builder: (context, state) => const BulletinBoardScreen(),
          ),
          
          // Banka Entegrasyonu
          GoRoute(
            path: '/banking',
            name: 'banking',
            builder: (context, state) => const BankIntegrationScreen(),
          ),
          
          // API Ayarları
          GoRoute(
            path: '/api-settings',
            name: 'apiSettings',
            builder: (context, state) => const APISettingsScreen(),
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
