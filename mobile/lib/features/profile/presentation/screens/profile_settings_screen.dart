import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Profil Ayarları Ekranı - Apple Tarzı
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _biometricEnabled = false;

  final Map<String, dynamic> _userData = {
    'name': 'Ahmet Yılmaz',
    'email': 'ahmet.yilmaz@email.com',
    'phone': '0532 123 4567',
    'unit': 'D.105',
    'building': 'A Blok',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppleTheme.systemBlue.withOpacity(0.12),
                    child: Text(
                      _userData['name'].toString().substring(0, 1),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: AppleTheme.systemBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_userData['name'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${_userData['building']} • ${_userData['unit']}',
                    style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Profili Düzenle'),
                  ),
                ],
              ),
            ),
          ),

          // Contact Info
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'İletişim Bilgileri'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: [
                  ListItem(
                    icon: Icons.email_rounded,
                    title: 'E-posta',
                    subtitle: _userData['email'] as String,
                    iconColor: AppleTheme.systemBlue,
                    onTap: () {},
                  ),
                  ListItem(
                    icon: Icons.phone_rounded,
                    title: 'Telefon',
                    subtitle: _userData['phone'] as String,
                    iconColor: AppleTheme.systemGreen,
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),

          // Notifications
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Bildirimler'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Bildirimleri', style: TextStyle(fontSize: 16)),
                    subtitle: Text('Site duyuruları ve güncellemeler', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    activeColor: AppleTheme.systemGreen,
                  ),
                  Container(height: 0.5, margin: const EdgeInsets.only(left: 16), color: AppleTheme.opaqueSeparator),
                  SwitchListTile(
                    title: const Text('E-posta Bildirimleri', style: TextStyle(fontSize: 16)),
                    subtitle: Text('Fatura ve aidat bildirimleri', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    value: _emailNotificationsEnabled,
                    onChanged: (value) => setState(() => _emailNotificationsEnabled = value),
                    activeColor: AppleTheme.systemGreen,
                  ),
                ],
              ),
            ),
          ),

          // Security
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Güvenlik'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: [
                  ListItem(
                    icon: Icons.lock_rounded,
                    title: 'Şifre Değiştir',
                    iconColor: AppleTheme.systemOrange,
                    onTap: () {},
                  ),
                  SwitchListTile(
                    title: const Text('Biyometrik Giriş', style: TextStyle(fontSize: 16)),
                    subtitle: Text('Parmak izi veya Face ID ile giriş', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    value: _biometricEnabled,
                    onChanged: (value) => setState(() => _biometricEnabled = value),
                    activeColor: AppleTheme.systemGreen,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: AppleTheme.systemPurple, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // More Options
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Diğer'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: [
                  ListItem(icon: Icons.help_rounded, title: 'Yardım ve Destek', iconColor: AppleTheme.systemBlue, onTap: () {}),
                  ListItem(icon: Icons.description_rounded, title: 'Kullanım Koşulları', iconColor: AppleTheme.systemGray, onTap: () {}),
                  ListItem(icon: Icons.privacy_tip_rounded, title: 'Gizlilik Politikası', iconColor: AppleTheme.systemGray, onTap: () {}, showDivider: false),
                ],
              ),
            ),
          ),

          // Logout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(context),
                  icon: const Icon(Icons.logout_rounded, color: AppleTheme.systemRed),
                  label: const Text('Çıkış Yap', style: TextStyle(color: AppleTheme.systemRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppleTheme.systemRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // App Version
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Text('SiteEksen v1.0.0', style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Çıkış Yap', style: TextStyle(color: AppleTheme.systemRed)),
          ),
        ],
      ),
    );
  }
}
