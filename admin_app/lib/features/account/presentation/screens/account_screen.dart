// Hesabım (FAZ H.7, panel /dashboard/account ve kenar çubuğundaki site seçimiyle eşit): şifre, telefon ve
// e-posta değişikliği; site değiştirme ve yeni site oluşturma. Şifre ve telefon değişince sunucu bütün
// oturumları kapatır. Site rolleri jetondadır: site değişince yeni jeton alınır.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_actions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _siteTypes = [('SITE', 'Site'), ('APARTMENT', 'Apartman'), ('BUILDING', 'Bina')];

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _codeFlow(BuildContext context, {required String title, required String field, required String label, required Future<Map<String, dynamic>> Function(Map<String, dynamic> v) request, required Future<Map<String, dynamic>> Function(String code) confirmCode, required bool logoutAfter}) async {
    final v = await showForm(context, title, [
      FSpec(field, label, required: true, hint: field == 'phone' ? 'Yurt dışı numara +ülke kodu ile' : null),
      const FSpec('password', 'Mevcut şifre', type: FType.password, required: true),
    ], submit: 'Kod gönder');
    if (v == null || !context.mounted) return;
    if (!await runAction(context, () => request(v))) return;
    if (!context.mounted) return;
    final code = await askText(context, 'Gelen kodu girin', 'Kod');
    if (code == null || !context.mounted) return;
    if (await runAction(context, () => confirmCode(code.toUpperCase())) && logoutAfter && context.mounted) {
      await apiClient.logout();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _switch(BuildContext context, String id) async {
    try {
      await apiClient.post('/users/me/active-property', {'property_id': id});
      if (!await apiClient.refreshSession()) throw StateError('Yeni site için oturum yenilenemedi; yeniden giriş yapın');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site değiştirildi')));
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(children: [
        ListTile(leading: const Icon(Icons.password), title: const Text('Şifre değiştir'), subtitle: const Text('Bütün cihazlardaki oturumlar kapanır'), onTap: () => showChangePasswordDialog(context)),
        ListTile(
          leading: const Icon(Icons.phone_iphone),
          title: const Text('Telefon numarası değiştir'),
          subtitle: const Text('Kod yeni numaraya SMS ile gider; onayda bütün oturumlar kapanır'),
          onTap: () => _codeFlow(context, title: 'Telefon numarası', field: 'phone', label: 'Yeni numara', request: (v) => apiClient.post('/users/me/phone/request', v), confirmCode: (c) => apiClient.post('/users/me/phone/confirm', {'code': c}), logoutAfter: true),
        ),
        ListTile(
          leading: const Icon(Icons.alternate_email),
          title: const Text('E-posta değiştir'),
          subtitle: const Text('Kod yeni adrese gider'),
          onTap: () => _codeFlow(context, title: 'E-posta adresi', field: 'email', label: 'Yeni e-posta', request: (v) => apiClient.post('/users/me/email', v), confirmCode: (c) => apiClient.post('/users/me/email/confirm', {'code': c}), logoutAfter: false),
        ),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Çıkış yap'), onTap: () => performLogout(context)),
        const Divider(),
        ListTile(
          title: const Text('Sitelerim', style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: TextButton.icon(
            icon: const Icon(Icons.add_business),
            label: const Text('Yeni site'),
            onPressed: () async {
              final v = await showForm(context, 'Yeni site', const [
                FSpec('name', 'Ad', required: true),
                FSpec('type', 'Tür', type: FType.select, options: _siteTypes, initial: 'SITE', required: true),
                FSpec('address', 'Adres', required: true),
                FSpec('city', 'İl', required: true),
                FSpec('district', 'İlçe'),
              ], submit: 'Oluştur');
              if (v == null || !context.mounted) return;
              try {
                final p = await apiClient.post('/users/me/properties', v);
                if (context.mounted) await _switch(context, '${p['id']}');
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
              }
            },
          ),
        ),
        FutureBuilder<List<dynamic>>(
          future: apiClient.getUserProperties(),
          builder: (context, s) {
            if (s.hasError) return ListTile(title: Text(errorText(s.error!)));
            if (!s.hasData) return const LinearProgressIndicator();
            final seen = <String>{};
            final sites = [for (final p in s.data!.whereType<Map>()) if (seen.add('${p['property_id']}')) p];
            return Column(children: [
              for (final p in sites)
                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text('${p['property_name'] ?? ''}'),
                  subtitle: Text('${p['role'] ?? ''}'),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => _switch(context, '${p['property_id']}'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
