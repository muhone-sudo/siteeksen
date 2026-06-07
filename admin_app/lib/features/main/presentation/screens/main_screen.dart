import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

// Yönetim tarafı roller — backend pkg/middleware/auth.go ile aynı değerler
const String roleManager = 'MANAGER';
const String roleAuditor = 'AUDITOR';
const String roleStaff = 'STAFF';

class MainScreen extends StatefulWidget {
  final Widget child;
  
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<String> _roles = [];

  // allowedRoles boşsa herkes görür; doluysa sadece listedeki roller görür.
  static final List<_NavItem> _allNavItems = [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard', path: '/'),
    _NavItem(icon: Icons.people, label: 'Sakinler', path: '/residents', allowedRoles: [roleManager, roleAuditor]),
    _NavItem(icon: Icons.account_balance_wallet, label: 'Finans', path: '/finance', allowedRoles: [roleManager, roleAuditor]),
    _NavItem(icon: Icons.speed, label: 'Sayaçlar', path: '/meters'),
    _NavItem(icon: Icons.campaign, label: 'Duyurular', path: '/announcements'),
  ];

  List<_NavItem> get _navItems =>
      _allNavItems.where((item) => item.isVisibleFor(_roles)).toList();

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final roles = await apiClient.getCurrentUserRoles();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      if (_selectedIndex >= _navItems.length) _selectedIndex = 0;
    });
  }

  // Rol bilgisi henüz yüklenmemişse (örn. ilk frame) varsayılan olarak göster;
  // yüklendiğinde sadece izin verilen rollerden biri varsa göster.
  bool _canSee(List<String> allowedRoles) {
    if (_roles.isEmpty) return true;
    return _roles.any((r) => allowedRoles.contains(r));
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].path);
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulamadan çık'),
        content: const Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _onItemTapped(0);
        } else {
          _confirmExit();
        }
      },
      child: Scaffold(
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
      ),
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
          if (_canSee([roleManager, roleAuditor]))
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Sakinler'),
              onTap: () {
                Navigator.pop(context);
                context.go('/residents');
              },
            ),
          if (_canSee([roleManager, roleAuditor]))
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
          if (_canSee([roleManager, roleAuditor]))
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
  final List<String>? allowedRoles;

  _NavItem({required this.icon, required this.label, required this.path, this.allowedRoles});

  bool isVisibleFor(List<String> roles) {
    if (allowedRoles == null || allowedRoles!.isEmpty) return true;
    if (roles.isEmpty) return true; // rol bilgisi henüz yüklenmedi — flicker'ı önle
    return roles.any((r) => allowedRoles!.contains(r));
  }
}
