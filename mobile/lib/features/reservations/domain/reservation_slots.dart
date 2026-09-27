// Rezervasyon saat aralıkları — sunucunun döndürdüğü DOLU aralıklardan
// seçilebilir saatleri üretir.
//
// NEDEN VAR (2026-09-26): ekran saatleri ve "dolu" durumlarını koda gömülü bir
// listeden gösteriyordu; sunucu da "09:00" gibi saatleri reddediyordu (RFC3339
// bekler). Artık `GET /facilities/:id/slots` kullanılır.
//
// Saatler SİTE saatindedir (Türkiye, UTC+3, 2016'dan beri yaz saati yok):
// cihazın saat dilimi farklı olsa da tesisin açılış saati sitenin saatidir.

/// Site saat farkı (Europe/Istanbul, sabit UTC+3).
const siteUtcOffset = Duration(hours: 3);

class TimeSlot {
  final int startMinute; // gece yarısından itibaren, site saati
  final int endMinute;
  final bool available;
  const TimeSlot(this.startMinute, this.endMinute, this.available);

  String get label => '${_hhmm(startMinute)} - ${_hhmm(endMinute)}';

  /// RFC3339, site saat farkıyla: `2026-10-01T09:00:00+03:00`.
  String startRfc3339(DateTime day) => _rfc3339(day, startMinute);
  String endRfc3339(DateTime day) => _rfc3339(day, endMinute);
}

String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

String _rfc3339(DateTime day, int minute) {
  final d = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  return '${d}T${_hhmm(minute)}:00+03:00';
}

/// "08:00" → 480. Bozuk değer null.
int? parseHhmm(Object? v) {
  if (v is! String) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(v);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

/// Bir RFC3339 zaman damgasını seçilen günün site saatine göre dakikaya çevirir.
/// Gün dışına taşan değerler 0 / 1440'a sıkıştırılır.
int minuteOfSiteDay(String iso, DateTime day) {
  final t = DateTime.parse(iso).toUtc().add(siteUtcOffset);
  final dayStart = DateTime.utc(day.year, day.month, day.day);
  final m = t.difference(dayStart).inMinutes;
  return m.clamp(0, 24 * 60);
}

/// Açılıştan kapanışa `stepMinutes` uzunluğunda aralıklar üretir; dolu
/// rezervasyonlarla (önüne ve arkasına tampon eklenerek) çakışanlar ya da
/// geçmişte kalanlar seçilemez.
List<TimeSlot> buildSlots({
  required DateTime day,
  required int openMinute,
  required int closeMinute,
  required int stepMinutes,
  required List<(String, String)> busy,
  int bufferMinutes = 0,
  DateTime? now,
}) {
  if (stepMinutes <= 0 || closeMinute <= openMinute) return const [];
  final busyRanges = [
    for (final b in busy)
      (minuteOfSiteDay(b.$1, day) - bufferMinutes, minuteOfSiteDay(b.$2, day) + bufferMinutes),
  ];
  int? nowMinute;
  if (now != null) {
    final n = now.toUtc().add(siteUtcOffset);
    final sameDay = n.year == day.year && n.month == day.month && n.day == day.day;
    if (sameDay) nowMinute = n.hour * 60 + n.minute;
  }
  final out = <TimeSlot>[];
  for (var s = openMinute; s + stepMinutes <= closeMinute; s += stepMinutes) {
    final e = s + stepMinutes;
    final overlaps = busyRanges.any((r) => s < r.$2 && e > r.$1);
    final past = nowMinute != null && s <= nowMinute;
    out.add(TimeSlot(s, e, !overlaps && !past));
  }
  return out;
}
