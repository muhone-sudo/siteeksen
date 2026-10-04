// Tadilat izni ekranı (FAZ 7.5, 2026-10-04).

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:siteeksen_mobile/features/renovation/presentation/screens/renovations_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  test('tadilat izni durum metni gerekçeyi ve çalışma saatini gösterir', () {
    expect(renovationStatusText({'status': 'PENDING'}), 'Yönetim onayı bekleniyor');
    expect(renovationStatusText({'status': 'APPROVED', 'work_hours': 'Hafta içi 09:00-18:00'}),
        'Onaylandı · çalışma saatleri: Hafta içi 09:00-18:00');
    expect(renovationStatusText({'status': 'APPROVED'}), 'Onaylandı');
    expect(renovationStatusText({'status': 'REJECTED', 'decision_note': 'Ruhsat yok'}), 'Reddedildi: Ruhsat yok');
    expect(renovationStatusText({'status': 'STOPPED', 'stop_reason': 'Proje dışı'}), 'Durduruldu: Proje dışı');
    expect(renovationStatusText({'status': 'COMPLETED', 'deposit_amount': 0}), 'Tamamlandı');
    expect(renovationStatusText({'status': 'COMPLETED', 'deposit_amount': 1000, 'deposit_refunded': 500}),
        contains('teminat iadesi'));
  });

  test('ortak yer ve dış cephe kapsamı 4/5 rıza uyarısı taşır', () {
    expect(renovationScopeHints['FACADE'], contains('beşte dördünün'));
    expect(renovationScopeHints['STRUCTURAL'], contains('İmar K. m.21'));
    expect(renovationScopeLabels.keys, ['INTERIOR', 'STRUCTURAL', 'COMMON_AREA', 'FACADE']);
  });
}