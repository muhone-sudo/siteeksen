// Uygulama içi etkinlik kaydı (073, FAZ H.3). Yalnız site ayarı TAM ise gönderilir; düzey
// oturumda bir kez sorulur. Olaylar sırada toplanır, 15 sn'de bir ya da 20 olayda toplu
// gönderilir. Gönderilemeyen olay yeniden denenmez (etkinlik kaydı en iyi çaba düzeyindedir;
// zorunlu kayıtlar sunucuda tutulur).

import 'dart:async';

import '../network/api_client.dart';

class Activity {
  Activity._();

  static bool? _enabled;
  static final List<Map<String, dynamic>> _queue = [];
  static Timer? _timer;

  static Future<void> init() async {
    if (_enabled != null) return;
    try {
      _enabled = await apiClient.getActivityLevel() == 'FULL';
    } catch (_) {
      _enabled = false;
    }
  }

  static void reset() {
    _enabled = null;
    _queue.clear();
    _timer?.cancel();
    _timer = null;
  }

  static void track(String event, {String? screen, Map<String, dynamic>? details}) {
    if (_enabled != true) return;
    _queue.add({
      'event': event,
      if (screen != null) 'screen': screen,
      if (details != null) 'details': details,
      'client_at': DateTime.now().toUtc().toIso8601String(),
      'client': 'mobile',
    });
    if (_queue.length >= 20) {
      flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 15), flush);
    }
  }

  static Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = _queue.take(50).toList();
    _queue.removeRange(0, batch.length);
    try {
      await apiClient.sendActivity(batch);
    } catch (_) {}
  }
}
