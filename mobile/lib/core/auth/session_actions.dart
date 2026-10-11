// Oturum işlemleri — çıkış ve şifre değiştirme tek yerde.
//
// NEDEN (2026-09-26): çıkış yalnızca cihazdaki jetonu siliyordu; sunucudaki
// yenileme jetonu 7 gün geçerli kalıyordu. Çalınan ya da başka cihazda kalan
// jeton "çıkış yaptım" sanan kullanıcının oturumunu açık tutuyordu.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/data_state.dart';

/// Sunucuda oturumu kapatır, cihazı temizler ve girişe döner. Sunucu iptali
/// yapılamadıysa bunu kullanıcıya söyler (sessizce "çıkıldı" demez).
Future<void> performLogout(BuildContext context) async {
  final revoked = await apiClient.logout();
  if (!context.mounted) return;
  if (!revoked) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunucudaki oturum kapatılamadı'),
        content: const Text(
          'Bu cihazdaki oturum kapatıldı, ancak sunucuya ulaşılamadığı için oturumunuz '
          'sunucuda iptal edilemedi. Başka bir cihazda açık oturumunuz olabilir; '
          'şüpheleniyorsanız şifrenizi değiştirin.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }
  if (context.mounted) context.go('/login');
}

/// Şifre değiştirme penceresi. Başarılıysa bütün oturumlar kapanır ve
/// kullanıcı giriş ekranına gönderilir.
Future<void> showChangePasswordDialog(BuildContext context, {String? phone}) async {
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final again = TextEditingController();
  String? error;
  bool busy = false;

  final changed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ),
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mevcut şifre'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Mevcut şifre gerekli' : null,
                ),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni şifre', helperText: passwordPolicyHint, helperMaxLines: 3),
                  validator: (v) => passwordPolicyError(v ?? '', phone: phone),
                ),
                TextFormField(
                  controller: again,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni şifre (tekrar)'),
                  validator: (v) => v != next.text ? 'Şifreler aynı değil' : null,
                ),
                const SizedBox(height: 12),
                const Text('Şifre değişince bu cihaz dahil bütün oturumlarınız kapatılır.',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await apiClient.changePassword(current.text, next.text);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      setState(() {
                        busy = false;
                        error = _passwordError(e);
                      });
                    }
                  },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    ),
  );
  current.dispose();
  next.dispose();
  again.dispose();
  if (changed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Şifreniz değiştirildi. Yeni şifrenizle giriş yapın.')),
    );
    context.go('/login');
  }
}

String _passwordError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    final msg = data is Map && data['error'] is String ? data['error'] as String : null;
    if (e.response?.statusCode == 400) return 'Mevcut şifre hatalı.';
    if (e.response?.statusCode == 422) return msg ?? passwordPolicyHint;
  }
  return toUserMessage(e);
}

/// Sunucunun hata metnini (varsa) döner.
String _serverError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return toUserMessage(e);
}

/// Kendi e-posta değişikliği (B4, 065): 1) yeni adres + mevcut şifre → kod yeni adrese gider;
/// 2) kod → adres değişir. Başarıda true.
Future<bool> showChangeEmailDialog(BuildContext context, {String? current}) async {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController(text: current ?? '');
  final password = TextEditingController();
  final code = TextEditingController();
  String? error;
  String? info;
  bool busy = false;
  bool codeSent = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('E-posta adresi'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              if (!codeSent) ...[
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Yeni e-posta'),
                  validator: (v) => v == null || !RegExp(r'^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$').hasMatch(v.trim()) ? 'Geçerli bir e-posta girin' : null,
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mevcut şifre'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Mevcut şifre gerekli' : null,
                ),
                const SizedBox(height: 12),
                const Text('Yeni adresinize doğrulama kodu gönderilir; adres kodu girince değişir.', style: TextStyle(fontSize: 12)),
              ] else ...[
                if (info != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(info!, style: const TextStyle(fontSize: 13))),
                TextFormField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'E-postayla gelen kod'),
                  validator: (v) => v == null || v.trim().length < 6 ? 'Kodu girin' : null,
                ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      if (!codeSent) {
                        final res = await apiClient.requestEmailChange(password.text, email.text);
                        setState(() {
                          busy = false;
                          codeSent = true;
                          info = '${res['message'] ?? 'Kod gönderildi.'}';
                        });
                      } else {
                        await apiClient.confirmEmailChange(code.text);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      }
                    } catch (e) {
                      setState(() {
                        busy = false;
                        error = _serverError(e);
                      });
                    }
                  },
            child: Text(codeSent ? 'Onayla' : 'Kod gönder'),
          ),
        ],
      ),
    ),
  );
  email.dispose();
  password.dispose();
  code.dispose();
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta adresiniz doğrulandı ve güncellendi.')));
  }
  return ok == true;
}
/// Kendi telefon değişikliği (B4): 1) yeni numara + mevcut şifre → kod yeni numaraya SMS;
/// 2) kod → numara değişir, bütün oturumlar kapanır ve kullanıcı yeni numarasıyla giriş yapar.
Future<void> showChangePhoneDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final phone = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String? error;
  String? info;
  bool busy = false;
  bool codeSent = false;
  final changed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Telefon numarası'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              if (!codeSent) ...[
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Yeni numara', hintText: '0555 123 45 67 · yurt dışı: +49 …'),
                  validator: (v) => v == null || !isValidPhone(v) ? 'Geçerli bir numara girin (yurt dışı +ülke kodu ile)' : null,
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mevcut şifre'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Mevcut şifre gerekli' : null,
                ),
                const SizedBox(height: 12),
                const Text('Yeni numaranıza SMS ile doğrulama kodu gönderilir.', style: TextStyle(fontSize: 12)),
              ] else ...[
                if (info != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(info!, style: const TextStyle(fontSize: 13))),
                TextFormField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'SMS ile gelen kod'),
                  validator: (v) => v == null || v.trim().length < 6 ? 'Kodu girin' : null,
                ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      if (!codeSent) {
                        final res = await apiClient.requestPhoneChange(password.text, normalizePhone(phone.text));
                        setState(() {
                          busy = false;
                          codeSent = true;
                          info = '${res['message'] ?? 'Kod gönderildi.'}';
                        });
                      } else {
                        await apiClient.confirmPhoneChange(code.text);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      }
                    } catch (e) {
                      setState(() {
                        busy = false;
                        error = _serverError(e);
                      });
                    }
                  },
            child: Text(codeSent ? 'Onayla' : 'Kod gönder'),
          ),
        ],
      ),
    ),
  );
  phone.dispose();
  password.dispose();
  code.dispose();
  if (changed == true && context.mounted) {
    // Sunucu bütün oturumları kapattı; cihazdaki jetonlar da temizlenir.
    await apiClient.clearToken();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telefon numaranız değişti. Yeni numaranızla giriş yapın.')),
    );
    context.go('/login');
  }
}
