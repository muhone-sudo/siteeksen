// DASK poliçem (FAZ 7.2).

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:siteeksen_mobile/features/dask/presentation/screens/dask_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  test('DASK satırı durum ve poliçeyi gösterir', () {
    expect(daskSubtitle({'state': 'MISSING'}), 'Poliçe girilmemiş');
    expect(daskSubtitle({'state': 'EXPIRING', 'policy_no': 'D-1', 'end_date': '2026-10-24'}), startsWith('Bitiyor · D-1 · bitiş '));
  });
}