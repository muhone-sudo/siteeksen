// Yönetici uygulaması ana iskeleti: alt gezinme + yan menü.
//
// DÜZELTME (2026-09-26):
//   - "Çıkış Yap" yalnızca giriş ekranına gidiyordu; jetonlar cihazda kalıyor,
//     biyometrik giriş oturumu geri açıyordu. Artık sunucuda da kapatılır.
//   - Menü başlığında sabit "Mavi Kent Sitesi" yazıyordu; gerçek site gösterilir.
//   - Modüllerin çoğu menüde yoktu (ziyaretçi, kargo, personel…); hepsi eklendi
//     ve sunucudaki rol kurallarına göre süzülür.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_actions.dart';
import '../../../../core/network/api_client.dart';

// Yönetim tarafı roller — backend pkg/middleware/auth.go ile aynı değerler
const String roleManager = 'MANAGER';
const String roleBoard = 'BOARD_MEMBER';
const String roleAuditor = 'AUDITOR';
const String roleStaff = 'STAFF';

const _mgmt = [roleManager, roleBoard];
const _mgmtAudit = [roleManager, roleBoard, roleAuditor];
const _mgmtStaff = [roleManager, roleBoard, roleStaff];
const _all = [roleManager, roleBoard, roleAuditor, roleStaff];

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  final List<String> roles;
  const _NavItem(this.icon, this.label, this.path, this.roles);
}

/// Menü grupları. Roller sunucudaki `RequireRole` kurallarıyla aynıdır;
/// yetkisiz ekrana götürmek her istekte 403 demekti.
const _groups = <(String, List<_NavItem>)>[
  ('Genel', [
    _NavItem(Icons.dashboard, 'Özet', '/', _all),
    _NavItem(Icons.people, 'Sakinler', '/residents', _all),
    _NavItem(Icons.support_agent, 'Talepler', '/requests', [roleManager, roleBoard, roleAuditor, roleStaff]),
    _NavItem(Icons.campaign, 'Duyurular', '/announcements', _all),
  ]),
  ('Mali', [
    _NavItem(Icons.account_balance_wallet, 'Finans', '/finance', _mgmtAudit),
    _NavItem(Icons.receipt_long, 'Giderler', '/expenses', _mgmtAudit),
    _NavItem(Icons.trending_up, 'Tahsilat riski', '/collection', _mgmtAudit),
    _NavItem(Icons.description, 'Sözleşmeler', '/contracts', _mgmtAudit),
    _NavItem(Icons.gavel, 'Yönetişim (KMK)', '/governance', _mgmtAudit),
    _NavItem(Icons.account_balance, 'Banka', '/banking', _mgmt),
  ]),
  ('Operasyon', [
    _NavItem(Icons.person_pin, 'Ziyaretçiler', '/visitors', _mgmtStaff),
    _NavItem(Icons.local_shipping, 'Kargo', '/packages', _mgmtStaff),
    _NavItem(Icons.local_parking, 'Otopark', '/parking', _mgmtStaff),
    _NavItem(Icons.event, 'Rezervasyonlar', '/reservations', _mgmtAudit),
    _NavItem(Icons.speed, 'Sayaçlar', '/meters', _all),
    _NavItem(Icons.bolt, 'Tüketim analizi', '/energy', _all),
    _NavItem(Icons.security, 'Devriye', '/patrol', _all),
    _NavItem(Icons.inventory, 'Stok', '/inventory', _all),
    _NavItem(Icons.chair, 'Demirbaş', '/assets', _all),
    _NavItem(Icons.badge, 'Personel', '/personnel', _all),
  ]),
  ('Topluluk', [
    _NavItem(Icons.poll, 'Anketler', '/surveys', _mgmt),
    _NavItem(Icons.dashboard_customize, 'İlan panosu', '/bulletin', _mgmt),
  ]),
];

const _bottomItems = [
  _NavItem(Icons.dashboard, 'Özet', '/', _all),
  _NavItem(Icons.people, 'Sakinler', '/residents', _all),
  _NavItem(Icons.account_balance_wallet, 'Finans', '/finance', _mgmtAudit),
  _NavItem(Icons.support_agent, 'Talepler', '/requests', _all),
  _NavItem(Icons.campaign, 'Duyurular', '/announcements', _all),
];

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<String> _roles = [];
  String _siteName = '';

  bool _visible(_NavItem item) => _roles.isEmpty || _roles.any(item.roles.contains);

  List<_NavItem> get _navItems => _bottomItems.where(_visible).toList();

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final roles = await apiClient.getCurrentUserRoles();
    var site = '';
    try {
      final props = await apiClient.getUserProperties();
      final names = props.whereType<Map>().map((p) => '${p['property_name'] ?? ''}').where((n) => n.isNotEmpty).toSet();
      site = names.join(', ');
    } catch (_) {
      // Site adı alınamazsa başlıkta gösterilmez; uydurma ad yazılmaz.
    }
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _siteName = site;
      if (_selectedIndex >= _navItems.length) _selectedIndex = 0;
    });
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Çık')),
        ],
      ),
    );
    if (shouldExit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
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
        bottomNavigationBar: items.length < 2
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex.clamp(0, items.length - 1),
                onDestinationSelected: _onItemTapped,
                destinations: [for (final i in items) NavigationDestination(icon: Icon(i.icon), label: i.label)],
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
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.person, size: 30)),
                const SizedBox(height: 12),
                const Text('Yönetim', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (_siteName.isNotEmpty) Text(_siteName, style: const TextStyle(color: Colors.white70)),
                if (_roles.isNotEmpty)
                  Text(_roles.join(' · '), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          for (final (title, entries) in _groups) ...[
            if (entries.any(_visible))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(title, style: Theme.of(context).textTheme.labelMedium),
              ),
            for (final e in entries.where(_visible))
              ListTile(
                leading: Icon(e.icon),
                title: Text(e.label),
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  context.go(e.path);
                },
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Şifre Değiştir'),
            onTap: () {
              Navigator.pop(context);
              showChangePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await performLogout(context);
            },
          ),
        ],
      ),
    );
  }
}
