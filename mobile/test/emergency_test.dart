// Acil durum ekranı (FAZ 7.3, 2026-10-04).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/features/emergency/presentation/screens/emergency_screen.dart';

void main() {
  test('çevrimdışı bilgi kartı önbellekten okunur; bozuk önbellek yok sayılır', () {
    final raw = jsonEncode({
      'points': [
        {'kind': 'ASSEMBLY_AREA', 'name': 'Toplanma alanı', 'location': 'Otopark'}
      ],
      'contacts': [],
    });
    expect(emergencyInfoFromCache(raw)?['points'], hasLength(1));
    expect(emergencyInfoFromCache('bozuk{'), isNull);
    expect(emergencyInfoFromCache(null), isNull);
    expect(emergencyInfoFromCache(jsonEncode({'x': 1})), isNull);
  });

  test('durum bildirimi metni', () {
    expect(safetyStatusLabel('SAFE'), 'Güvende olduğunuzu bildirdiniz');
    expect(safetyStatusLabel('NEED_HELP'), 'Yardım talebiniz iletildi');
    expect(safetyStatusLabel(''), 'Henüz durum bildirmediniz');
    expect(emergencyPointLabels['GAS_VALVE'], 'Gaz vanası');
  });
}