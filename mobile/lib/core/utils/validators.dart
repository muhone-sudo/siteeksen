// Form doğrulamaları — sunucu kurallarının istemcideki karşılığı.
//
// Sunucu aynı kuralları zaten uygular (identity/service/account.go); burada
// amaç kullanıcıyı gereksiz bir istekten ve belirsiz bir hatadan korumaktır.

/// Şifre politikası: en az 8 karakter, en az bir harf ve bir rakam, telefon
/// numarasını içeremez. Uygunsa null döner.
String? passwordPolicyError(String password, {String? phone}) {
  if (password.length < 8) return 'Şifre en az 8 karakter olmalı';
  if (!RegExp(r'\p{L}', unicode: true).hasMatch(password)) {
    return 'Şifre en az bir harf içermeli';
  }
  if (!RegExp(r'\d').hasMatch(password)) return 'Şifre en az bir rakam içermeli';
  if (phone != null) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final local = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (local.isNotEmpty && password.contains(local)) {
      return 'Şifre telefon numaranızı içeremez';
    }
  }
  return null;
}

/// Şifre kuralının kullanıcıya gösterilen metni.
const passwordPolicyHint =
    'En az 8 karakter; en az bir harf ve bir rakam. Telefon numaranızı içeremez.';
