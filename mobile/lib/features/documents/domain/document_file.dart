// Belge indirmenin saf (cihazdan bağımsız) kuralları — test edilebilir olsun diye ayrı.

import 'package:crypto/crypto.dart';

/// İndirilen baytların sunucunun bildirdiği SHA-256 ile eşleşip eşleşmediği.
///
/// Sunucu her indirmede `X-Document-SHA256` başlığını gönderir. Başlık yoksa ya
/// da eşleşmiyorsa dosya AÇILMAZ: yarım inmiş ya da yolda değişmiş bir karar
/// tutanağını "belge" diye göstermek, hiç göstermemekten kötüdür.
bool sha256Matches(List<int> bytes, String? expectedHex) {
  final want = expectedHex?.trim().toLowerCase() ?? '';
  if (want.length != 64) return false;
  return sha256.convert(bytes).toString() == want;
}

/// Sunucudan gelen dosya adını cihazda güvenle yazılabilir hâle getirir.
///
/// Dosya adı yükleyenin verdiği addır; `../` ya da yol ayırıcı içerirse uygulama
/// dizini dışına yazmaya çalışılabilir. Ayırıcılar ve denetim karakterleri
/// atılır, uzunluk sınırlanır, uzantı korunur (dosyayı açacak uygulama uzantıyla
/// seçilir). Türkçe harfler korunur.
String safeFileName(String? name, {String fallback = 'belge'}) {
  var s = (name ?? '').replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F\x7F]'), '_').trim();
  // Baştaki noktalar gizli dosya / üst dizin oluşturmasın.
  s = s.replaceFirst(RegExp(r'^\.+'), '');
  if (s.isEmpty || RegExp(r'^_+$').hasMatch(s)) s = fallback;
  const max = 100;
  if (s.length > max) {
    final dot = s.lastIndexOf('.');
    final ext = (dot > 0 && s.length - dot <= 10) ? s.substring(dot) : '';
    s = s.substring(0, max - ext.length) + ext;
  }
  return s;
}
