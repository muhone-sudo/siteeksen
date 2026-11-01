// SiteEksen Tedarikçi (FAZ M9, K15): Usta & Hizmet tedarikçilerinin uygulaması — web panelindeki /tedarikci alanının
// karşılığı. Talepler, teklif ve yazışma, işletmeler, bakiye ve paket, hesap ve belgeler.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';
import 'features/account/account_screens.dart';
import 'features/auth/auth_screens.dart';
import 'features/businesses/business_screens.dart';
import 'features/requests/request_screens.dart';
import 'features/wallet/wallet_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final signedIn = await apiClient.hasSession();
  runApp(SupplierApp(signedIn: signedIn));
}

class SupplierApp extends StatefulWidget {
  final bool signedIn;
  const SupplierApp({super.key, required this.signedIn});

  @override
  State<SupplierApp> createState() => _SupplierAppState();
}

class _SupplierAppState extends State<SupplierApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.signedIn ? '/talepler' : '/giris',
    routes: [
      GoRoute(path: '/giris', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/kayit', builder: (context, state) => const SignupScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/talepler',
            builder: (context, state) => const RequestsScreen(),
            routes: [GoRoute(path: ':id', builder: (context, state) => RequestScreen(id: state.pathParameters['id']!))],
          ),
          GoRoute(
            path: '/isletmeler',
            builder: (context, state) => const BusinessesScreen(),
            routes: [GoRoute(path: ':id', builder: (context, state) => BusinessScreen(id: state.pathParameters['id']!))],
          ),
          GoRoute(path: '/bakiye', builder: (context, state) => const WalletScreen()),
          GoRoute(
            path: '/hesap',
            builder: (context, state) => const AccountScreen(),
            routes: [
              GoRoute(path: 'bildirimler', builder: (context, state) => const NotificationsScreen()),
              GoRoute(path: 'puanlar', builder: (context, state) => const ReviewsScreen()),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SiteEksen Tedarikçi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2563EB), useMaterial3: true),
      routerConfig: _router,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    );
  }
}

class HomeShell extends StatelessWidget {
  final String location;
  final Widget child;
  const HomeShell({super.key, required this.location, required this.child});

  static const _tabs = ['/talepler', '/isletmeler', '/bakiye', '/hesap'];

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Talepler'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'İşletmelerim'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Bakiye'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hesabım'),
        ],
      ),
    );
  }
}
