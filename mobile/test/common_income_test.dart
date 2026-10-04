// Ortak alan geliri payım (FAZ 7.6).

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:siteeksen_mobile/core/utils/formatters.dart';
import 'package:siteeksen_mobile/features/common_income/presentation/screens/common_income_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  test('kuruş tutarı TL olarak gösterilir', () {
    expect(kurusText(123456), formatTry(1234.56));
    expect(kurusText(null), formatTry(0));
  });
}