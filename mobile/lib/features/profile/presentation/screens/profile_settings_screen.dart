// Profil ve Ayarlar Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13, todo 0.C.2):
//   - Kullanıcı bilgileri koda gömülüydü ("Ahmet Yılmaz", "0532 123 4567").
//   - Bildirim anahtarları yalnızca `setState` yapıyordu: kullanıcı ayarı değiştirdiğini
//     sanıyor, hiçbir yere kaydedilmiyordu (uygulama kapanınca kayboluyordu).
//   - "Şifre Değiştir", "Yardım", "Kullanım Koşulları" gibi öğelerin `onTap`'ı boştu.
//   - "Çıkış Yap" onay diyaloğu yalnızca diyaloğu kapatıyor, OTURUMU KAPATMIYORDU.
//
// Bu sürümde: gerçek kullanıcı bilgisi, gerçekten kaydedilen biyometrik tercihi,
// sunucuda karşılığı olmayan ayarlar için açık "henüz hazır değil" bildirimi ve
// gerçekten çalışan çıkış.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_actions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _user;

  /// Cihaz üzerinde gerçekten saklanan tek tercih. Diğer ayarların sunucu
  /// karşılığı henüz yok (bkz. NotImplementedNotice).
  bool _biometricEnabled = false;

  /// Bağlı olunan siteler/daireler (`GET /users/me/properties`).
  List<dynamic> _properties = const [];

  /// Bildirim tercihleri (`GET /notification-preferences`). Kayıt yoksa
  /// işlemsel bildirimler AÇIK, ticari ileti KAPALI sayılır (6563 s. Kanun m.6).
  Map<String, bool> _prefs = {};
  String? _prefsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await apiClient.getCurrentUser();
      final biometric = await apiClient.isBiometricEnabled();
      final properties = await apiClient.getUserProperties();
      Map<String, bool> prefs = {};
      String? prefsError;
      try {
        final res = await apiClient.getNotificationPreferences();
        for (final p in ApiClient.listOf(res)) {
          if (p is Map) prefs['${p['channel']}:${p['category']}'] = p['enabled'] == true;
        }
      } catch (e) {
        prefsError = toUserMessage(e);
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _biometricEnabled = biometric;
        _properties = properties;
        _prefs = prefs;
        _prefsError = prefsError;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = toUserMessage(e);
        _loading = false;
      });
    }
  }

  String get _fullName {
    final first = (_user?['first_name'] as String?)?.trim() ?? '';
    final last = (_user?['last_name'] as String?)?.trim() ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    return full.isEmpty ? 'Sakin' : full;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(),
        const SectionTitle(title: 'İletişim Bilgileri'),
        _buildContactInfo(),
        const SectionTitle(title: 'Güvenlik'),
        _buildSecurity(),
        const SectionTitle(title: 'Bildirimler'),
        _buildNotificationPrefs(),
        const SectionTitle(title: 'Yasal'),
        _buildLegal(),
        _buildLogoutButton(),
        Center(
          child: Text('SiteEksen v1.0.0',
              style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppleTheme.systemBlue.withValues(alpha: 0.12),
            child: Text(
              _fullName.characters.first.toUpperCase(),
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: AppleTheme.systemBlue),
            ),
          ),
          const SizedBox(height: 16),
          Text(_fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          // users.roles yalnızca platform rolü taşır; sakinin görmesi gereken
          // bağlı olduğu site ve dairedir.
          for (final p in _properties.whereType<Map>())
            Text(
              [p['property_name'], p['unit_name']].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
              style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          ListItem(
            icon: Icons.email_rounded,
            title: 'E-posta',
            subtitle: (_user?['email'] as String?) ?? 'Kayıtlı değil',
            iconColor: AppleTheme.systemBlue,
            onTap: () => _notYetEditable('E-posta'),
          ),
          ListItem(
            icon: Icons.phone_rounded,
            title: 'Telefon',
            subtitle: (_user?['phone'] as String?) ?? 'Kayıtlı değil',
            iconColor: AppleTheme.systemGreen,
            onTap: () => _notYetEditable('Telefon'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurity() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Biyometrik Giriş', style: TextStyle(fontSize: 16)),
            subtitle: Text(
              'Parmak izi veya Face ID ile giriş (bu cihazda saklanır)',
              style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
            ),
            value: _biometricEnabled,
            activeThumbColor: AppleTheme.systemGreen,
            onChanged: (value) async {
              // Tercih gerçekten güvenli depoya yazılır.
              await apiClient.setBiometricEnabled(value);
              if (!mounted) return;
              setState(() => _biometricEnabled = value);
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppleTheme.systemPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: AppleTheme.systemPurple, size: 20),
            ),
          ),
          ListItem(
            icon: Icons.lock_rounded,
            title: 'Şifre Değiştir',
            iconColor: AppleTheme.systemOrange,
            onTap: () => showChangePasswordDialog(context, phone: _user?['phone'] as String?),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLegal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          ListItem(
            icon: Icons.privacy_tip_rounded,
            title: 'KVKK Aydınlatma Metni',
            iconColor: AppleTheme.systemGray,
            onTap: () => context.pushNamed('kvkkConsent'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout_rounded, color: AppleTheme.systemRed),
          label: const Text('Çıkış Yap',
              style: TextStyle(color: AppleTheme.systemRed)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppleTheme.systemRed),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  static const _channels = {
    'IN_APP': 'Uygulama içi',
    'PUSH': 'Anlık bildirim',
    'SMS': 'SMS',
    'EMAIL': 'E-posta',
  };

  bool _prefValue(String channel, String category) =>
      _prefs['$channel:$category'] ?? (category == 'TRANSACTIONAL');

  Future<void> _setPref(String channel, String category, bool enabled) async {
    try {
      await apiClient.setNotificationPreference(channel: channel, category: category, enabled: enabled);
      if (!mounted) return;
      setState(() => _prefs['$channel:$category'] = enabled);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tercih kaydedilemedi: ${toUserMessage(e)}')));
    }
  }

  Widget _buildNotificationPrefs() {
    if (_prefsError != null) {
      return NotImplementedNotice(title: 'Bildirim tercihleri alınamadı', detail: _prefsError);
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          for (final e in _channels.entries)
            SwitchListTile(
              title: Text(e.value, style: const TextStyle(fontSize: 16)),
              subtitle: Text(
                e.key == 'IN_APP'
                    ? 'Aidat, duyuru, kargo gibi hizmet bildirimleri'
                    : 'Sağlayıcı henüz bağlı değil; açık olsa da bildirim kuyrukta bekler',
                style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
              ),
              value: _prefValue(e.key, 'TRANSACTIONAL'),
              onChanged: (v) => _setPref(e.key, 'TRANSACTIONAL', v),
            ),
          SwitchListTile(
            title: const Text('Tanıtım ve kampanya iletileri', style: TextStyle(fontSize: 16)),
            subtitle: Text(
              'Açarsanız ticari elektronik ileti almaya onay vermiş olursunuz (6563 s. Kanun m.6). '
              'İstediğiniz zaman kapatabilirsiniz.',
              style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
            ),
            value: _prefValue('IN_APP', 'COMMERCIAL'),
            onChanged: (v) => _setPref('IN_APP', 'COMMERCIAL', v),
          ),
        ],
      ),
    );
  }

  /// Sunucuda karşılığı olmayan düzenleme işlemleri için dürüst bildirim.
  /// Sessizce hiçbir şey yapmak, kullanıcıya dokunuşunun işe yaradığını düşündürür.
  void _notYetEditable(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what güncelleme henüz sunucu tarafında hazır değil.'),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap',
                style: TextStyle(color: AppleTheme.systemRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await performLogout(context);
  }
}
