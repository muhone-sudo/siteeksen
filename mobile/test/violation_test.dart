// Kural ihlali ekranı (FAZ 7.5, 2026-10-04).

import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/features/violations/presentation/screens/violations_screen.dart';

void main() {
  test('ihlal durum metni kademeyi gösterir', () {
    expect(violationStatusText({'status': 'OPEN', 'stage': 'NONE'}), 'Yönetim değerlendiriyor');
    expect(violationStatusText({'status': 'VERIFIED', 'stage': 'WRITTEN_WARNING'}), 'Yazılı uyarı');
    expect(violationStatusText({'status': 'VERIFIED', 'stage': 'LEGAL'}), 'Hukuki yol (KMK m.33)');
    expect(violationStatusText({'status': 'DISMISSED', 'stage': 'NONE'}), 'Doğrulanmadı');
    expect(violationStatusText({'status': 'RESOLVED', 'stage': 'VERBAL_WARNING'}), 'Kapandı');
  });

  test('bildiren alanı yalnızca kişinin kendi bildiriminde dolu gelir', () {
    expect(isOwnReport({'reported_by': 'u1'}), isTrue);
    expect(isOwnReport({'reported_by': ''}), isFalse);
    expect(isOwnReport({}), isFalse);
  });
}