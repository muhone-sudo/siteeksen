import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_reporter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Türkçe tarih/para biçimlendirmesi için yerel veriyi yükle.
  // Bu yapılmazsa `DateFormat('...', 'tr_TR')` çalışma zamanında hata fırlatır.
  initializeDateFormatting('tr_TR');
  // Yakalanmayan hatalar API'ye bildirilir (3.6).
  installErrorReporting('mobile', apiClient.reportClientError);
  runApp(
    const ProviderScope(
      child: SiteEksenApp(),
    ),
  );
}

class SiteEksenApp extends ConsumerWidget {
  const SiteEksenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SiteEksen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
