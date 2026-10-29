import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_reporter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tarih biçimleri (formatters.dart, tr_TR) yerel veri yüklenmeden LocaleDataException atar.
  await initializeDateFormatting('tr_TR');

  // Yakalanmayan hatalar API'ye bildirilir (3.6).
  installErrorReporting('admin_app', (r) async => apiClient.post('/client-errors', r));
  runApp(const ProviderScope(child: SiteEksenAdminApp()));
}

class SiteEksenAdminApp extends ConsumerWidget {
  const SiteEksenAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'SiteEksen Yönetici',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
