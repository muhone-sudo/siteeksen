import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daha Fazla'),
      ),
      body: ListView(
        children: [
          // Kullanıcı Kartı
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Text(
                    'AY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmet Yılmaz',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text(
                        'Güneş Sitesi • A-3',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Menü Öğeleri
          _MenuItem(
            icon: Icons.announcement_outlined,
            title: 'Duyurular',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.directions_car_outlined,
            title: 'Araçlarım',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.local_shipping_outlined,
            title: 'Kargo Takibi',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.event_outlined,
            title: 'Rezervasyonlar',
            onTap: () {},
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Kapalı',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          _MenuItem(
            icon: Icons.people_outline,
            title: 'Yönetim Kadrosu',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.bar_chart,
            title: 'Tüketim Raporları',
            onTap: () {},
          ),

          const Divider(height: 32),

          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.info_outline,
            title: 'Hakkında',
            onTap: () {},
          ),

          const Divider(height: 32),

          _MenuItem(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),

          const SizedBox(height: 20),

          // Versiyon
          Center(
            child: Text(
              'SiteEksen v1.0.0',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Logout işlemi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
