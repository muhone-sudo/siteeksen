// Site daveti başlığı (S-20, 2026-10-03).

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:siteeksen_mobile/core/utils/formatters.dart';

import 'package:siteeksen_mobile/features/invitations/presentation/widgets/invitations_banner.dart';
import 'package:siteeksen_mobile/features/kvkk/presentation/screens/kvkk_requests_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  test('davet başlığı site, daire ve sıfatı gösterir', () {
    expect(invitationTitle({'property_name': 'Güneş Sitesi', 'unit': 'A-3', 'role': 'OWNER'}),
        'Güneş Sitesi · A-3 (Kat maliki)');
    expect(invitationTitle({'property_name': 'Mavi Kent', 'unit': '', 'role': 'TENANT'}), 'Mavi Kent (Kiracı)');
    expect(invitationTitle({}), 'Site');
  });

  test('devir bakiyesi dönem adıyla değil açıklamasıyla gösterilir', () {
    expect(assessmentLabel({'period': '2026-06', 'kind': 'OPENING', 'description': 'Önceki yönetimden devir'}), 'Önceki yönetimden devir');
    expect(assessmentLabel({'period': '2026-06', 'kind': 'OPENING'}), 'Devir bakiyesi');
    expect(assessmentLabel({'period': '2026-06', 'kind': 'REGULAR'}), 'Haziran 2026');
    expect(assessmentLabel({'period': '2026-13'}), '2026-13');
  });

  test('KVKK başvuru durumu kalan günü ya da sonucu söyler', () {
    expect(kvkkStatusText({'status': 'ANSWERED'}), 'Yanıtlandı');
    expect(kvkkStatusText({'status': 'OPEN', 'days_left': -2, 'due_date': '2026-10-01'}), 'Yasal süre geçti (2 gün)');
    expect(kvkkStatusText({'status': 'OPEN', 'days_left': 5, 'due_date': '2026-10-10'}), startsWith('Yanıt bekleniyor'));
  });
}
