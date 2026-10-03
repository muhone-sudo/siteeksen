// Belge indirmenin güvenlik kuralları (2026-10-03).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/features/documents/domain/document_file.dart';

String sha256Hex(List<int> b) => sha256.convert(b).toString();

void main() {
  group('sha256Matches', () {
    final bytes = utf8.encode('karar defteri');
    // 64 haneli ama BAŞKA bir içeriğin özeti.
    final other = sha256.convert(utf8.encode('başka belge')).toString();

    test('doğru özet kabul edilir (büyük harf/boşluk tolere edilir)', () {
      final real = sha256Hex(bytes);
      expect(sha256Matches(bytes, real), isTrue);
      expect(sha256Matches(bytes, ' ${real.toUpperCase()} '), isTrue);
    });

    test('yanlış, eksik ya da kısaltılmış özetle dosya açılmaz', () {
      expect(sha256Matches(bytes, other), isFalse);
      expect(sha256Matches(bytes, null), isFalse);
      expect(sha256Matches(bytes, ''), isFalse);
      expect(sha256Matches(bytes, sha256Hex(bytes).substring(0, 32)), isFalse);
    });

    test('tek bayt değişirse eşleşmez (yarım/bozuk indirme)', () {
      final real = sha256Hex(bytes);
      expect(sha256Matches(bytes.sublist(1), real), isFalse);
    });
  });

  group('safeFileName', () {
    test('yol ayırıcılar ve üst dizin atlanamaz', () {
      expect(safeFileName('../../etc/passwd'), isNot(contains('/')));
      expect(safeFileName('../../etc/passwd'), isNot(startsWith('.')));
      expect(safeFileName(r'a\b:c*d?.pdf'), 'a_b_c_d_.pdf');
    });

    test('Türkçe harfler ve uzantı korunur', () {
      expect(safeFileName('2026 İşletme Projesi Ğ.pdf'), '2026 İşletme Projesi Ğ.pdf');
    });

    test('boş ya da yalnızca geçersiz karakterli ad yedek ada döner', () {
      expect(safeFileName(null), 'belge');
      expect(safeFileName('   '), 'belge');
      expect(safeFileName('///'), 'belge');
      expect(safeFileName('...'), 'belge');
    });

    test('uzun ad kısaltılır, uzantı korunur', () {
      final s = safeFileName('${'a' * 300}.pdf');
      expect(s.length, 100);
      expect(s, endsWith('.pdf'));
    });
  });
}
