// Sunucu sözleşmesine bağlanan eşleme ve hesapların testleri (2026-09-26).
//
// Bu fonksiyonlar, ekranların sunucuyla konuştuğu yerlerdir; bir tanesi
// kaydığında ekran sessizce boş kalıyor ya da her isteği reddettiriyordu.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:siteeksen_mobile/core/utils/formatters.dart';
import 'package:siteeksen_mobile/core/utils/validators.dart';
import 'package:siteeksen_mobile/features/auth/presentation/screens/activate_screen.dart';
import 'package:siteeksen_mobile/features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart';
import 'package:siteeksen_mobile/features/packages/presentation/screens/package_tracking_mobile_screen.dart';
import 'package:siteeksen_mobile/features/requests/presentation/screens/requests_screen.dart';
import 'package:siteeksen_mobile/features/reservations/domain/reservation_slots.dart';
import 'package:siteeksen_mobile/features/surveys/presentation/screens/surveys_mobile_screen.dart';

DioException _http(int code, [Object? data]) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: code, data: data),
      type: DioExceptionType.badResponse,
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('telefon', () {
    test('farklı yazımlar aynı biçime iner', () {
      for (final v in ['5551234567', '05551234567', '0555 123 45 67', '+90 555 123-45-67', '905551234567']) {
        expect(normalizePhone(v), '+905551234567', reason: v);
      }
    });
  });

  group('şifre politikası (sunucu ile aynı)', () {
    test('kısa, harfsiz, rakamsız ve telefonlu şifre reddedilir', () {
      expect(passwordPolicyError('kisa1'), isNotNull);
      expect(passwordPolicyError('12345678'), isNotNull);
      expect(passwordPolicyError('abcdefgh'), isNotNull);
      expect(passwordPolicyError('a5551234567', phone: '+905551234567'), isNotNull);
    });
    test('uygun şifre kabul edilir', () {
      expect(passwordPolicyError('Guclu123', phone: '+905551234567'), isNull);
      expect(passwordPolicyError('şifreĞ12'), isNull);
    });
  });

  group('etkinleştirme hata eşlemesi', () {
    test('400/422/429 kullanıcıya ne yapacağını söyler', () {
      expect(activationErrorMessage(_http(400)), contains('kod'));
      expect(activationErrorMessage(_http(422, {'error': 'zayıf şifre'})), 'zayıf şifre');
      expect(activationErrorMessage(_http(429)), contains('yeni kod'));
    });
  });

  group('rezervasyon saatleri', () {
    final day = DateTime(2030, 5, 10);
    test('dolu aralık ve tamponla çakışan saat seçilemez', () {
      final slots = buildSlots(
        day: day,
        openMinute: 9 * 60,
        closeMinute: 13 * 60,
        stepMinutes: 60,
        busy: [('2030-05-10T10:00:00+03:00', '2030-05-10T11:00:00+03:00')],
        bufferMinutes: 15,
      );
      expect(slots.map((s) => s.label), ['09:00 - 10:00', '10:00 - 11:00', '11:00 - 12:00', '12:00 - 13:00']);
      expect(slots.map((s) => s.available), [false, false, false, true]);
    });
    test('UTC dönen dolu aralık site saatine çevrilir', () {
      final slots = buildSlots(
        day: day, openMinute: 9 * 60, closeMinute: 11 * 60, stepMinutes: 60,
        busy: [('2030-05-10T06:00:00Z', '2030-05-10T07:00:00Z')], // = 09:00-10:00 TR
      );
      expect(slots.map((s) => s.available), [false, true]);
    });
    test('gönderilen zaman RFC3339 ve site saat farkıyla', () {
      const s = TimeSlot(9 * 60, 10 * 60, true);
      expect(s.startRfc3339(day), '2030-05-10T09:00:00+03:00');
      expect(s.endRfc3339(day), '2030-05-10T10:00:00+03:00');
    });
    test('açılış saati ayrıştırma', () {
      expect(parseHhmm('08:30'), 510);
      expect(parseHhmm('bozuk'), isNull);
    });
  });

  group('durum eşlemeleri', () {
    test('kargo: RECEIVED/NOTIFIED bekler, DELIVERED/RETURNED bitmiştir', () {
      expect(isPackageWaiting('RECEIVED'), isTrue);
      expect(isPackageWaiting('NOTIFIED'), isTrue);
      expect(isPackageWaiting('DELIVERED'), isFalse);
      expect(isPackageWaiting('RETURNED'), isFalse);
      expect(isPackageWaiting('arrived'), isFalse);
    });
    test('talep: yalnızca CLOSED tamamlanmıştır', () {
      expect(isRequestActive('RESOLVED'), isTrue);
      expect(isRequestActive('CLOSED'), isFalse);
    });
    test('ilan kategorileri sunucunun büyük harfli değerleridir', () {
      expect(bulletinCategories.keys, contains('LOST_FOUND'));
      expect(bulletinCategories.keys.every((k) => k == k.toUpperCase()), isTrue);
    });
  });

  group('sayılar', () {
    test('ondalık metin ve sayı kabul edilir', () {
      expect(toNum('1234.50'), 1234.5);
      expect(toNum(7), 7);
      expect(toNum(null), 0);
      expect(toNum('bozuk'), 0);
    });
    test('fiyat girdisi Türkçe biçimi anlar', () {
      expect(parsePriceInput('1.250,50'), 1250.5);
      expect(parsePriceInput('300'), 300);
      expect(parsePriceInput(''), isNull);
      expect(parsePriceInput('abc'), isNull);
    });
    test('anket katılımı sunucunun yüzdesini gösterir', () {
      expect(participationText('45.50', 5, 11), '5 / 11 katılım (%46)');
      expect(participationText('0.00', 0, 0), '0 oy');
    });
    test('API tarihi YYYY-MM-DD', () {
      expect(apiDate(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });
}
