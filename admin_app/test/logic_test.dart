// Yönetici uygulamasının sunucu sözleşmesine bağlı saf mantığı.
//
// Bu fonksiyonlar sunucunun döndürdüğü/beklediği değerleri çevirir; bir değer
// yanlış eşlenirse ekran sessizce yanlış durum gösterir ya da sunucu isteği
// reddeder (ör. ISO zaman damgası yerine YYYY-MM-DD).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteeksen_admin/core/network/api_client.dart';
import 'package:siteeksen_admin/core/utils/formatters.dart';
import 'package:siteeksen_admin/features/bulletin/presentation/screens/bulletin_board_screen.dart';
import 'package:siteeksen_admin/features/collection/presentation/screens/smart_collection_screen.dart';
import 'package:siteeksen_admin/features/contracts/presentation/screens/contract_management_screen.dart';
import 'package:siteeksen_admin/features/energy/presentation/screens/energy_dashboard_screen.dart';
import 'package:siteeksen_admin/features/finance/presentation/screens/payments_screen.dart';
import 'package:siteeksen_admin/features/meters/presentation/screens/meter_reading_screen.dart';
import 'package:siteeksen_admin/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:siteeksen_admin/features/surveys/presentation/screens/survey_management_screen.dart';
import 'package:siteeksen_admin/features/visitors/presentation/screens/visitor_management_screen.dart';

void main() {
  group('biçimlendirme', () {
    test('apiDate sunucunun beklediği YYYY-MM-DD biçimini üretir', () {
      expect(apiDate(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('periodLabel dönemi Türkçe ay adına çevirir', () {
      expect(periodLabel('2026-03'), 'Mart 2026');
      expect(periodLabel('2026-12-01'), 'Aralık 2026');
      expect(periodLabel('2026-13'), '2026-13');
      expect(periodLabel(null), '—');
    });

    test('sıfır zaman damgası tarih sayılmaz', () {
      expect(parseApiDate('0001-01-01T00:00:00Z'), isNull);
      expect(formatDate('0001-01-01T00:00:00Z'), '—');
      expect(parseApiDate('2026-02-15T10:00:00Z'), isNotNull);
    });

    test('toNum metin ve sayı tutarları kabul eder', () {
      expect(toNum('1234.50'), 1234.5);
      expect(toNum('12,5'), 12.5);
      expect(toNum(7), 7);
      expect(toNum(null), 0);
      expect(toNum('abc'), 0);
    });

    test('normalizePhone farklı yazımları aynı numaraya indirir', () {
      expect(normalizePhone('0555 123 45 67'), '+905551234567');
      expect(normalizePhone('+90 555 123 4567'), '+905551234567');
      expect(normalizePhone('5551234567'), '+905551234567');
    });
  });

  test('ApiClient.listOf {data:[...]} ve düz diziyi kabul eder', () {
    expect(ApiClient.listOf({'data': [1, 2]}), [1, 2]);
    expect(ApiClient.listOf([3]), [3]);
    expect(ApiClient.listOf({'error': 'x'}), isEmpty);
    expect(ApiClient.listOf(null), isEmpty);
  });

  test('normalizeReading Türkçe ondalık yazımı sunucu biçimine çevirir', () {
    expect(normalizeReading('1.234,5'), '1234.5');
    expect(normalizeReading('1234,5'), '1234.5');
    expect(normalizeReading(' 1234.5 '), '1234.5');
    expect(normalizeReading('12a'), isNull);
    expect(normalizeReading(''), isNull);
    expect(normalizeReading('-3'), isNull);
  });

  test('nextRequestStatus yalnızca sunucunun kabul ettiği geçişi önerir', () {
    expect(nextRequestStatus('OPEN'), 'IN_PROGRESS');
    expect(nextRequestStatus('IN_PROGRESS'), 'RESOLVED');
    // RESOLVED → CLOSED sakin onayıdır; yönetim kapatamaz.
    expect(nextRequestStatus('RESOLVED'), isNull);
    expect(nextRequestStatus('CLOSED'), isNull);
  });

  test('initialOf boş adda çökmez', () {
    expect(initialOf('ayşe'), 'A');
    expect(initialOf(''), '?');
    expect(initialOf(null), '?');
    expect(initialOf('  '), '?');
  });

  group('durum eşlemeleri sunucu değerlerini tanır', () {
    void known((String, Color) Function(Object?) fn, List<String> values) {
      for (final v in values) {
        expect(fn(v).$1, isNot(v), reason: '$v etiketlenmemiş');
      }
      // Bilinmeyen değer gizlenmez, olduğu gibi gösterilir.
      expect(fn('XYZ').$1, 'XYZ');
    }

    test('ödeme', () => known(paymentStatus, ['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED']));
    test('sözleşme', () => known(contractStatus, ['ACTIVE', 'EXPIRED', 'TERMINATED', 'DRAFT']));
    test('ilan', () => known(bulletinStatus, ['PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'CLOSED']));
    test('anket', () => known(surveyStatus, ['DRAFT', 'ACTIVE', 'ENDED', 'CANCELLED']));
    test('tahsilat riski', () => known(riskCategory, ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']));

    test('ödeme yöntemi', () {
      for (final m in ['CREDIT_CARD', 'SAVED_CARD', 'BANK_TRANSFER', 'CASH']) {
        expect(paymentMethodLabel(m), isNot(m));
      }
    });

    test('sözleşme türleri sunucunun CHECK listesiyle aynı', () {
      expect(contractTypes.keys.toSet(), {'RENTAL', 'SERVICE', 'MAINTENANCE', 'EMPLOYMENT', 'INSURANCE', 'OTHER'});
    });

    test('anket türlerinde genel kurul yok', () {
      expect(surveyTypes.keys.toSet(), {'POLL', 'SURVEY', 'VOTE'});
    });

    test('tahsilat önerileri sunucunun ürettiği değerleri kapsar', () {
      expect(suggestedActions.keys.toSet(), {'NONE', 'EARLY_REMINDER', 'INSTALLMENT', 'PERSONAL_CONTACT', 'LEGAL_REVIEW'});
    });
  });

  test('trendText önceki dönem sıfırken yüzde uydurmaz', () {
    expect(trendText({'direction': 'UP', 'change_pct': null}), '↑ (önceki dönem 0)');
    expect(trendText({'direction': 'FLAT', 'change_pct': null}), '→ değişim yok');
    expect(trendText({'direction': 'DOWN', 'change_pct': '-12.5'}), '↓ %12,5');
    expect(trendText(null), '—');
  });
}
