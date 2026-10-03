// Yönetici uygulaması menü erişimi (B26, 2026-10-03): fail-closed.

import 'package:flutter_test/flutter_test.dart';
import 'package:siteeksen_admin/features/finance/presentation/screens/create_assessment_screen.dart';
import 'package:siteeksen_admin/features/main/presentation/screens/main_screen.dart';

void main() {
  test('roller boşsa (alınamadı / sakin) hiçbir menü öğesi görünmez', () {
    expect(navVisible(const [], const [roleManager, roleBoard]), isFalse);
    expect(hasAdminAppAccess(const []), isFalse);
  });

  test('sakin/kiracı rolleri yönetici uygulamasına erişim vermez', () {
    expect(hasAdminAppAccess(const ['RESIDENT', 'TENANT', 'OWNER']), isFalse);
    expect(navVisible(const ['RESIDENT'], const [roleManager, roleBoard, roleAuditor, roleStaff]), isFalse);
  });

  test('denetçi yalnızca kendi rolüne açık öğeleri görür', () {
    expect(navVisible(const [roleAuditor], const [roleManager, roleBoard, roleAuditor]), isTrue);
    expect(navVisible(const [roleAuditor], const [roleManager, roleBoard]), isFalse);
    expect(hasAdminAppAccess(const [roleAuditor]), isTrue);
  });

  test('görevli yönetim rolüyle aynı yetkiyi almaz', () {
    expect(navVisible(const [roleStaff], const [roleManager, roleBoard]), isFalse);
    expect(hasAdminAppAccess(const [roleStaff]), isTrue);
  });

  test('tahakkuk formu sayaç bazlı/özel kalemi seçtirmez', () {
    expect(distributableCategory('EQUAL'), isTrue);
    expect(distributableCategory('SHARE_RATIO'), isTrue);
    expect(distributableCategory('AREA_M2'), isTrue);
    expect(distributableCategory('METER_READING'), isFalse);
    expect(distributableCategory('CUSTOM'), isFalse);
    expect(distributableCategory(null), isFalse);
  });
}
