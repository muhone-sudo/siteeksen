// Site daveti başlığı (S-20, 2026-10-03).

import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/features/invitations/presentation/widgets/invitations_banner.dart';

void main() {
  test('davet başlığı site, daire ve sıfatı gösterir', () {
    expect(invitationTitle({'property_name': 'Güneş Sitesi', 'unit': 'A-3', 'role': 'OWNER'}),
        'Güneş Sitesi · A-3 (Kat maliki)');
    expect(invitationTitle({'property_name': 'Mavi Kent', 'unit': '', 'role': 'TENANT'}), 'Mavi Kent (Kiracı)');
    expect(invitationTitle({}), 'Site');
  });
}
