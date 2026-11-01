import 'package:flutter_test/flutter_test.dart';
import 'package:siteeksen_supplier/features/requests/request_screens.dart';

void main() {
  test('kabul ücreti metni: dahil talep hakkı ya da bakiyeden ücret', () {
    expect(feeText({'fee_kurus': 5625, 'uses_included': true}), 'Paketinizdeki talep hakkından düşer');
    expect(feeText({'fee_kurus': 5625, 'uses_included': false}), contains('56,25'));
    expect(feeText({'fee_kurus': 0, 'uses_included': true, 'accepted_at': '2026-10-31'}), 'Paket hakkından düştü');
    expect(feeText({'fee_kurus': 10000, 'uses_included': false, 'accepted_at': '2026-10-31'}), contains('ödendi'));
  });
}
