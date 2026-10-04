// Yakalanmayan hata raporu (3.6).

import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/core/utils/error_reporter.dart';

void main() {
  test('rapor kısaltılır ve kişisel veri alanı taşımaz', () {
    final r = buildErrorReport(app: 'mobile', error: 'x' * 3000, stack: StackTrace.fromString('y' * 9000), fatal: true);
    expect((r['message'] as String).length, 2000);
    expect((r['stack'] as String).length, 8000);
    expect(r.keys.toSet(), {'app', 'app_version', 'platform', 'fatal', 'message', 'stack'});
  });

  test('gönderim hatası yutulur ve aynı anda tek rapor gider', () async {
    var calls = 0;
    Future<void> failing(Map<String, dynamic> _) async {
      calls++;
      throw Exception('ağ yok');
    }

    await sendErrorReport(failing, buildErrorReport(app: 'mobile', error: 'e', fatal: false));
    expect(calls, 1);
  });
}