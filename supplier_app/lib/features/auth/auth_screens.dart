// Giriş ve tedarikçi kaydı (076, FAZ M1): kayıt önce telefona gelen kodla doğrulanır; hesap durumu ancak ondan sonra
// açıklanır (NEW: ad + şifre; EXISTING: mevcut şifre, hesaba tedarikçi rolü eklenir; INACTIVE: şifre belirlenir).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/data_state.dart';

class _Frame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Frame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.storefront, size: 56, color: Color(0xFF2563EB)),
                  const SizedBox(height: 8),
                  Text('SiteEksen Tedarikçi', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  Text(title, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ...children,
                ]),
              ),
            ),
          ),
        ),
      );
}

void _error(BuildContext context, Object e) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e)), backgroundColor: Theme.of(context).colorScheme.error));

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(), _password = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      await apiClient.login(_phone.text.trim(), _password.text);
      if (mounted) context.go('/talepler');
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Frame(title: 'Usta & Hizmet tedarikçi girişi', children: [
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon numarası')),
        TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre'), onSubmitted: (_) => _login()),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'Bekleyin…' : 'Giriş yap')),
        TextButton(onPressed: () => context.go('/kayit'), child: const Text('Hesabınız yok mu? Tedarikçi olarak kaydolun')),
      ]);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phone = TextEditingController(), _code = TextEditingController();
  final _first = TextEditingController(), _last = TextEditingController(), _email = TextEditingController();
  final _pw = TextEditingController(), _pw2 = TextEditingController();
  bool _sent = false, _busy = false, _terms = false;
  String? _state, _token, _next;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final r = await apiClient.signupRequest(_phone.text.trim());
        if (!mounted) return;
        setState(() => _sent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['message'] ?? 'Kod gönderildi'}')));
      });

  Future<void> _verify() => _run(() async {
        final r = await apiClient.signupVerify(_phone.text.trim(), _code.text.trim().toUpperCase());
        setState(() {
          _state = '${r['state']}';
          _token = '${r['signup_token']}';
          _next = '${r['next'] ?? ''}';
        });
      });

  Future<void> _complete() async {
    if (_state != 'EXISTING' && _pw.text != _pw2.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifreler aynı değil')));
      return;
    }
    await _run(() async {
        await apiClient.signupComplete({
          'phone': _phone.text.trim(),
          'signup_token': _token,
          'password': _pw.text,
          'terms_accepted': _terms,
          if (_state == 'NEW') ...{'first_name': _first.text.trim(), 'last_name': _last.text.trim(), 'email': _email.text.trim()},
        });
        if (mounted) context.go('/hesap');
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return _Frame(title: 'Tedarikçi kaydı — telefonunuzu doğrulayın', children: [
        TextField(controller: _phone, enabled: !_sent, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon numarası')),
        if (_sent) TextField(controller: _code, decoration: const InputDecoration(labelText: 'SMS ile gelen kod (8 karakter)')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : (_sent ? _verify : _send), child: Text(_sent ? 'Kodu doğrula' : 'Kod gönder')),
        TextButton(onPressed: () => context.go('/giris'), child: const Text('Zaten kayıtlı mısınız? Giriş yapın')),
      ]);
    }
    final existing = _state == 'EXISTING';
    return _Frame(title: 'Tedarikçi kaydı', children: [
      Text(_next ?? ''),
      const SizedBox(height: 8),
      if (_state == 'NEW') ...[
        TextField(controller: _first, decoration: const InputDecoration(labelText: 'Ad')),
        TextField(controller: _last, decoration: const InputDecoration(labelText: 'Soyad')),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta (isteğe bağlı)')),
      ],
      TextField(controller: _pw, obscureText: true, decoration: InputDecoration(labelText: existing ? 'Mevcut şifreniz' : 'Şifre')),
      if (!existing) TextField(controller: _pw2, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre (tekrar)')),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _terms,
        onChanged: (v) => setState(() => _terms = v ?? false),
        title: const Text('Usta & Hizmet tedarikçi üyelik koşullarını ve kişisel verilerimin bu kapsamda işlenmesini kabul ediyorum.'),
      ),
      FilledButton(onPressed: _busy || !_terms ? null : _complete, child: Text(existing ? 'Tedarikçi panelini hesabıma ekle' : 'Hesabımı aç')),
    ]);
  }
}
