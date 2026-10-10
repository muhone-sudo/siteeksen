import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/data_state.dart';

/// Sunucunun durum koduna göre kullanıcıya ne yapacağını söyler.
String activationErrorMessage(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final serverMsg = data is Map && data['error'] is String ? data['error'] as String : null;
    switch (code) {
      case 400:
        return 'Telefon ya da kod hatalı, kod kullanılmış veya süresi dolmuş.';
      case 422:
        return serverMsg ?? passwordPolicyHint;
      case 429:
        return 'Kod çok sayıda hatalı deneme nedeniyle kilitlendi. SMS ile yeni kod isteyin ya da site yönetiminden alın.';
    }
  }
  return toUserMessage(e);
}

/// Hesap etkinleştirme / şifre sıfırlama.
///
/// Kodu iki yoldan alırsınız: "Kodu SMS ile gönder" (kayıtlı numaranıza, e-postanız
/// kayıtlıysa oraya da; 15 dk geçerli — B3) ya da site yönetiminden (7 gün geçerli).
/// Kod tek kullanımlıktır ve 5 hatalı denemede kilitlenir. Şifre belirlenince açık
/// bütün oturumlarınız kapanır.
class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key});

  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  static String activationError(Object e) => activationErrorMessage(e);

  /// Kodu kayıtlı numaraya gönderir. Sunucu numaranın kayıtlı olup olmadığını söylemez;
  /// aynı numara için 60 saniyede bir istenebilir.
  Future<void> _sendCode() async {
    if (!isValidPhone(_phone.text)) {
      setState(() => _error = 'Önce geçerli bir telefon numarası girin (yurt dışı numara +ülke kodu ile)');
      return;
    }
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final res = await apiClient.requestPasswordReset(phone: normalizePhone(_phone.text));
      final wait = (res['retry_after_sec'] as num?)?.toInt() ?? 60;
      if (!mounted) return;
      setState(() {
        _info = '${res['message'] ?? 'Kod gönderildi.'}';
        _cooldown = wait;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || _cooldown <= 1) {
          t.cancel();
          if (mounted) setState(() => _cooldown = 0);
          return;
        }
        setState(() => _cooldown--);
      });
    } catch (e) {
      final data = e is DioException ? e.response?.data : null;
      if (mounted) {
        setState(() => _error = data is Map && data['error'] is String ? data['error'] as String : toUserMessage(e));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await apiClient.activateAccount(
        phone: normalizePhone(_phone.text),
        code: _code.text,
        newPassword: _password.text,
      );
      await apiClient.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreniz belirlendi. Şimdi giriş yapabilirsiniz.')),
      );
      context.go('/login');
    } catch (e) {
      setState(() => _error = activationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Belirle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Telefon numaranızı girip kodu SMS ile isteyin ya da site yönetiminin '
                  'size ilettiği kodu kullanın; ardından yeni şifrenizi belirleyin.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon Numarası', hintText: '0555 123 45 67 · yurt dışı: +49 …', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || !isValidPhone(v) ? 'Geçerli bir telefon numarası girin (yurt dışı numara +ülke kodu ile)' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cooldown > 0 ? null : _sendCode,
                    child: Text(_cooldown > 0 ? 'Yeniden gönder (${_cooldown}s)' : 'Kodu SMS ile gönder'),
                  ),
                ),
                if (_info != null) ...[
                  Text(_info!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Kod', prefixIcon: Icon(Icons.key)),
                  validator: (v) => v == null || v.trim().length < 6 ? 'SMS ile gelen ya da yönetimden aldığınız kodu girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni Şifre', prefixIcon: Icon(Icons.lock), helperText: passwordPolicyHint, helperMaxLines: 2),
                  validator: (v) => passwordPolicyError(v ?? '', phone: _phone.text),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password2,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni Şifre (tekrar)', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _password.text ? 'Şifreler aynı değil' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Şifremi Belirle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
