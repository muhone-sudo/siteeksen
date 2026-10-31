import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/activity.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unread = 0;
  Timer? _unreadTimer;
  GoRouterDelegate? _delegate;
  String _lastLocation = '';

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _unreadTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadUnread());
    Activity.init().then((_) => Activity.track('session.start'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _delegate = GoRouter.of(context).routerDelegate;
      _delegate!.addListener(_onRoute);
      _onRoute();
    });
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    _delegate?.removeListener(_onRoute);
    super.dispose();
  }

  // Ekran geçişi: TAM düzeyde işlem kaydına gider; bildirim ekranından dönünce rozet tazelenir.
  void _onRoute() {
    final loc = _delegate?.currentConfiguration.uri.path ?? '';
    if (loc.isEmpty || loc == _lastLocation) return;
    if (_lastLocation.contains('notifications')) _loadUnread();
    _lastLocation = loc;
    Activity.track('screen.view', screen: loc);
  }

  Future<void> _loadUnread() async {
    try {
      final n = await apiClient.getUnreadNotificationCount();
      if (mounted && n != _unread) setState(() => _unread = n);
    } catch (_) {}
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
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          context.go('/');
        } else {
          _confirmExit();
        }
      },
      child: Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/finance');
              break;
            case 2:
              context.go('/requests');
              break;
            case 3:
              context.go('/usta');
              break;
            case 4:
              context.go('/more');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finans',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Talepler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Usta & Hizmet',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text(_unread > 99 ? '99+' : '$_unread'),
              child: const Icon(Icons.more_horiz_outlined),
            ),
            selectedIcon: const Icon(Icons.more_horiz),
            label: 'Daha Fazla',
          ),
        ],
      ),
      ),
    );
  }
}
