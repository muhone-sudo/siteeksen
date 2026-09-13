// "Daha Fazla" menüsü.
//
// NEDEN YENİDEN YAZILDI (2026-09-13, todo 0.C.2/0.C.4):
//   - Kullanıcı kartı sabitti: her kullanıcıya "AY / Ahmet Yılmaz / Güneş Sitesi • A-3".
//   - 10 menü öğesinin `onTap`'ı BOŞTU; dokunmak hiçbir şey yapmıyordu.
//   - "Çıkış Yap" düğmesi onay diyaloğu gösteriyor, sonra `// TODO: Logout işlemi`
//     diyerek HİÇBİR ŞEY YAPMIYORDU — kullanıcı çıkış yaptığını sanıyor, oturumu açık kalıyordu.
//     Bu, ortak kullanılan bir cihazda doğrudan güvenlik sorunudur.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/data_state.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Map<String, dynamic>? _user;
  String? _error;
  bool _loading = true;

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
      if (!mounted) return;
      setState(() {
        _user = user;
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

  String get _initials {
    final parts = _fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daha Fazla')),
      body: ListView(
        children: [
          _buildUserCard(context),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.announcement_outlined,
            title: 'Duyurular',
            onTap: () => context.pushNamed('announcements'),
          ),
          _MenuItem(
            icon: Icons.poll_outlined,
            title: 'Anketler',
            onTap: () => context.pushNamed('surveys'),
          ),
          _MenuItem(
            icon: Icons.campaign_outlined,
            title: 'İlan Panosu',
            onTap: () => context.pushNamed('bulletin'),
          ),
          _MenuItem(
            icon: Icons.local_shipping_outlined,
            title: 'Kargo Takibi',
            onTap: () => context.pushNamed('packages'),
          ),
          _MenuItem(
            icon: Icons.event_outlined,
            title: 'Rezervasyon Oluştur',
            onTap: () => context.pushNamed('createReservation'),
          ),
          _MenuItem(
            icon: Icons.person_add_outlined,
            title: 'Ziyaretçi Ön Kaydı',
            onTap: () => context.pushNamed('visitorPreregister'),
          ),
          _MenuItem(
            icon: Icons.bar_chart,
            title: 'Tüketim',
            onTap: () => context.pushNamed('energy'),
          ),
          _MenuItem(
            icon: Icons.folder_copy_outlined,
            title: 'Belgeler',
            onTap: () => context.pushNamed('documents'),
          ),
          _MenuItem(
            icon: Icons.chair_outlined,
            title: 'Demirbaşlar',
            onTap: () => context.pushNamed('assets'),
          ),
          const Divider(height: 32),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Profil ve Ayarlar',
            onTap: () => context.pushNamed('profile'),
          ),
          _MenuItem(
            icon: Icons.info_outline,
            title: 'Hakkında',
            onTap: () => _showAbout(context),
          ),
          const Divider(height: 32),
          _MenuItem(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'SiteEksen v1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: LoadingView(),
      );
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              _initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  (_user?['phone'] as String?) ?? (_user?['email'] as String?) ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Profili düzenle',
            onPressed: () => context.pushNamed('profile'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SiteEksen',
      applicationVersion: '1.0.0',
      children: const [
        Text('Kat Mülkiyeti Kanunu (634) uyumlu site yönetim uygulaması.'),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Jetonlar cihazdan gerçekten silinir.
    await apiClient.clearToken();
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.goNamed('login');
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
