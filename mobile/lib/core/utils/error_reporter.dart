// Yakalanmayan hata raporlama (todo 3.6, 2026-10-04).
//
// Firebase Crashlytics yok (S-10/S-15). Yakalanmayan Flutter ve platform
// hataları kendi API'mize (`POST /client-errors`) bildirilir. Bildirim asla
// yeni bir hata fırlatmaz ve kendini tetiklemez; oturum yoksa sessizce düşer
// (sunucu 401 döner). Kişisel veri gönderilmez: yalnızca hata metni ve yığın izi
// (kısaltılmış), uygulama sürümü ve platform.

import 'package:flutter/foundation.dart';

const _appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

String _cut(String s, int n) => s.length <= n ? s : s.substring(0, n);

/// Rapor gövdesi; metin 2000, yığın 8000 karaktere kısaltılır (sunucu sınırı).
Map<String, dynamic> buildErrorReport({required String app, required Object error, StackTrace? stack, required bool fatal}) => {
      'app': app,
      'app_version': _appVersion,
      'platform': defaultTargetPlatform.name,
      'fatal': fatal,
      'message': _cut(error.toString(), 2000),
      if (stack != null) 'stack': _cut(stack.toString(), 8000),
    };

bool _sending = false;

/// Gönderici: bir rapor yolda iken yenisini göndermez (döngüye giren hata ağı boğmasın).
Future<void> sendErrorReport(Future<void> Function(Map<String, dynamic>) send, Map<String, dynamic> report) async {
  if (_sending) return;
  _sending = true;
  try {
    await send(report);
  } catch (_) {
    // Hata raporu gönderilemezse yapılacak bir şey yok; uygulama akışı etkilenmez.
  } finally {
    _sending = false;
  }
}

/// Uygulama başında bir kez çağrılır.
void installErrorReporting(String app, Future<void> Function(Map<String, dynamic>) send) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    sendErrorReport(send, buildErrorReport(app: app, error: details.exception, stack: details.stack, fatal: false));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    sendErrorReport(send, buildErrorReport(app: app, error: error, stack: stack, fatal: true));
    return false; // varsayılan işleme (günlük) devam etsin
  };
}