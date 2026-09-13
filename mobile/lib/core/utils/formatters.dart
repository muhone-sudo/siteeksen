// Para ve tarih biçimlendirme.
//
// NEDEN VAR (2026-09-09 denetim bulgusu):
// `intl` paketi pubspec'te kurulu ama hiç kullanılmıyordu; biçimlendirme elle
// yapılıyor ve YANLIŞ sonuç veriyordu (örn. `12.450.00` — Türkçe'de binlik ayıracı
// nokta, ondalık ayıracı virgüldür: `12.450,00`). Para ekranlarında bu, tutarın
// yanlış okunmasına yol açar.
//
// Tüm para/tarih biçimlendirmesi buradan geçmelidir.

import 'package:intl/intl.dart';

final NumberFormat _tryFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

final NumberFormat _numberFormat = NumberFormat.decimalPattern('tr_TR');

final DateFormat _dateFormat = DateFormat('d MMMM y', 'tr_TR');
final DateFormat _dateTimeFormat = DateFormat('d MMMM y HH:mm', 'tr_TR');

/// Türk Lirası biçimlendirmesi: `1234.5` → `₺1.234,50`
String formatTry(num? amount) => _tryFormat.format(amount ?? 0);

/// Binlik ayıraçlı sayı: `1234.5` → `1.234,5`
String formatNumber(num? value) => _numberFormat.format(value ?? 0);

/// `2026-02-15T00:00:00Z` → `15 Şubat 2026`
String formatDate(Object? value) {
  final d = _parseDate(value);
  return d == null ? '—' : _dateFormat.format(d);
}

/// `2026-02-15T14:30:00Z` → `15 Şubat 2026 14:30`
String formatDateTime(Object? value) {
  final d = _parseDate(value);
  return d == null ? '—' : _dateTimeFormat.format(d.toLocal());
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    // Sunucu boş tarihi sıfır zaman damgası olarak dönebiliyor.
    if (value.isEmpty || value.startsWith('0001-01-01')) return null;
    return DateTime.tryParse(value);
  }
  return null;
}
