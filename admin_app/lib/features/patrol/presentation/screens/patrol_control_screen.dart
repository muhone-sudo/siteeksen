// Devriye Kontrol Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü devriye turları ve "bugün 8/10 tur tamamlandı" gibi uydurma
// istatistikler gösteriyordu. Güvenlik turu bir denetim kaydıdır; yapılmamış bir
// turun yapılmış gibi görünmesi, olay anında yönetimin yanlış bilgiyle savunma
// yapmasına yol açar. Artık veri gerçek API'den gelir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class PatrolControlScreen extends StatefulWidget {
  const PatrolControlScreen({super.key});

  @override
  State<PatrolControlScreen> createState() => _PatrolControlScreenState();
}

class _PatrolControlScreenState extends State<PatrolControlScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  bool _loading = true;
  String? _error;
  bool _notImplemented = false;
  List<Map<String, dynamic>> _routes = const [];
  List<Map<String, dynamic>> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notImplemented = false;
    });
    try {
      final routes = await apiClient.getPatrolRoutes();
      final sessions = await apiClient.getPatrolSessions();
      if (!mounted) return;
      setState(() {
        _routes = routes.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _sessions = sessions.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notImplemented = isNotImplemented(e);
        _error = toUserMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Devriye Kontrol'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Turlar'), Tab(text: 'Oturumlar')],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Yenile'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'Devriye modülü henüz hazır değil',
          detail: 'Tur tanımları ve QR/NFC noktalı devriye oturumları sunucu '
              'tarafında gerçek veriye bağlanmadı.',
        ),
      );
    }
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    return TabBarView(
      controller: _tab,
      children: [
        _list(_routes, 'Tanımlı devriye turu yok.', Icons.route_outlined, _routeCard),
        _list(_sessions, 'Kayıtlı devriye oturumu yok.', Icons.history_rounded, _sessionCard),
      ],
    );
  }

  Widget _list(List<Map<String, dynamic>> items, String emptyMsg, IconData icon,
      Widget Function(Map<String, dynamic>) builder) {
    if (items.isEmpty) return EmptyStateView(message: emptyMsg, icon: icon);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => builder(items[i]),
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((r['name'] ?? 'Tur').toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (r['checkpoint_count'] != null)
            Text('${r['checkpoint_count']} kontrol noktası',
                style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
          if (r['description'] != null)
            Text(r['description'].toString(),
                style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final done = s['status'] == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: done ? AppleTheme.systemGreen : AppleTheme.systemOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((s['route_name'] ?? s['route_id'] ?? 'Devriye').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(formatDateTime(s['started_at']),
                    style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
              ],
            ),
          ),
          if (s['completed_checkpoints'] != null && s['total_checkpoints'] != null)
            Text('${s['completed_checkpoints']}/${s['total_checkpoints']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
