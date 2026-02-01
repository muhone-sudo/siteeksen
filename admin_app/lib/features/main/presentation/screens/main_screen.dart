import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard', path: '/'),
    _NavItem(icon: Icons.people, label: 'Sakinler', path: '/residents'),
    _NavItem(icon: Icons.account_balance_wallet, label: 'Finans', path: '/finance'),
    _NavItem(icon: Icons.speed, label: 'Sayaçlar', path: '/meters'),
    _NavItem(icon: Icons.campaign, label: 'Duyurular', path: '/announcements'),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35),
                ),
                SizedBox(height: 12),
                Text(
                  'Yönetici Paneli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mavi Kent Sitesi',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Sakinler'),
            onTap: () {
              Navigator.pop(context);
              context.go('/residents');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Finans'),
            onTap: () {
              Navigator.pop(context);
              context.go('/finance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Sayaçlar'),
            onTap: () {
              Navigator.pop(context);
              context.go('/meters');
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Duyurular'),
            onTap: () {
              Navigator.pop(context);
              context.go('/announcements');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Talepler'),
            onTap: () {
              Navigator.pop(context);
              context.go('/requests');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Raporlar'),
            onTap: () {
              Navigator.pop(context);
              context.go('/reports');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Logout
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;

  _NavItem({required this.icon, required this.label, required this.path});
}
