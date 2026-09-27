// Duyurular (sakin).
//
// DÜZELTME (2026-09-26): ekran var olmayan `date`/`time`/`type` alanlarını
// okuyordu — her satır "Belirtilmemiş" tarihli ve varsayılan simgeliydi; hata
// da "duyuru yok" olarak yutuluyordu; okundu bilgisi sunucuya hiç gitmiyordu.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Duyuru kategorisi → (etiket, simge).
const announcementCategories = <String, (String, IconData)>{
  'GENERAL': ('Genel', Icons.info_outline),
  'MAINTENANCE': ('Bakım/Arıza', Icons.build_outlined),
  'FINANCIAL': ('Mali', Icons.account_balance_wallet_outlined),
  'EMERGENCY': ('Acil', Icons.warning_amber_rounded),
  'ASSEMBLY': ('Genel Kurul', Icons.groups_outlined),
};

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getAnnouncements();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getAnnouncements());
    await _future;
  }

  Future<void> _open(Map a) async {
    // Okundu kaydı başarısız olsa da duyuru gösterilir; kayıt bir sonraki
    // açılışta yeniden denenir (is_read false kalır).
    if (a['is_read'] != true) {
      apiClient.markAnnouncementRead('${a['id']}').then((_) {
        if (mounted) setState(() => a['is_read'] = true);
      }).catchError((_) {});
    }
    final cat = announcementCategories['${a['category']}'];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('${a['title'] ?? ''}', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text([
              if (cat != null) cat.$1,
              formatDateTime(a['published_at'] ?? a['created_at']),
              if ((a['created_by_name'] ?? '').toString().isNotEmpty) '${a['created_by_name']}',
            ].join(' · '), style: Theme.of(ctx).textTheme.bodySmall),
            const Divider(height: 24),
            Text('${a['content'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyurular')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList()
            ..sort((a, b) => (b['is_pinned'] == true ? 1 : 0).compareTo(a['is_pinned'] == true ? 1 : 0));
          if (items.isEmpty) return const EmptyStateView(message: 'Duyuru yok', icon: Icons.campaign_outlined);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = items[i];
                final cat = announcementCategories['${a['category']}'];
                final unread = a['is_read'] != true;
                final urgent = a['category'] == 'EMERGENCY';
                return ListTile(
                  leading: Icon(cat?.$2 ?? Icons.info_outline, color: urgent ? Colors.red : null),
                  title: Text('${a['title'] ?? ''}',
                      style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
                  subtitle: Text([
                    if (a['is_pinned'] == true) 'Sabitlenmiş',
                    if (cat != null) cat.$1,
                    formatDate(a['published_at'] ?? a['created_at']),
                  ].join(' · ')),
                  trailing: unread ? const Icon(Icons.circle, size: 10, color: Colors.blue) : null,
                  onTap: () => _open(a),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
