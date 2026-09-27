// Taleplerim (sakin — yalnızca kendi talepleri, `GET /requests`).
//
// DÜZELTME (2026-09-26): liste KODA GÖMÜLÜYDÜ: "Tamamlanmış" sekmesinde uydurma
// bir TLP-2025-0089 talebi, "Güncel" sekmesinde her zaman "talebiniz yok"
// yazıyordu. "Yeni Talep" penceresi Gönder'e basınca hiçbir istek atmadan
// kapanıyordu. Artık liste sunucudan gelir; yeni talep gerçek oluşturma
// ekranına gider.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const requestStatusLabels = {
  'OPEN': 'Açık',
  'IN_PROGRESS': 'İşlemde',
  'RESOLVED': 'Çözüldü — onayınızı bekliyor',
  'CLOSED': 'Kapandı',
};

const requestPriorityLabels = {'LOW': 'Düşük', 'NORMAL': 'Normal', 'HIGH': 'Yüksek', 'URGENT': 'Acil'};

/// Güncel sekmesinde görünen durumlar (kapanmamış olanlar).
bool isRequestActive(Object? status) => status != 'CLOSED';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getRequests();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getRequests());
    await _future;
  }

  Future<void> _confirm(Map r, bool approved) async {
    try {
      await apiClient.confirmRequestResolution('${r['id']}', approved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approved ? 'Talebi onayladınız; kapatıldı.' : 'Talep yeniden yönetime iletildi.'),
      ));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Taleplerim'),
          bottom: const TabBar(tabs: [Tab(text: 'Güncel'), Tab(text: 'Tamamlanmış')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.pushNamed('createRequest');
            if (mounted) await _reload();
          },
          icon: const Icon(Icons.add),
          label: const Text('Yeni Talep'),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingView();
            if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
            final all = snap.data!.whereType<Map>().toList();
            final active = all.where((r) => isRequestActive(r['status'])).toList();
            final done = all.where((r) => !isRequestActive(r['status'])).toList();
            return TabBarView(children: [
              _list(active, 'Açık talebiniz yok. Yönetime iletmek istediğiniz bir konu için yeni talep oluşturun.'),
              _list(done, 'Kapanmış talebiniz yok.'),
            ]);
          },
        ),
      ),
    );
  }

  Widget _list(List<Map> items, String empty) {
    if (items.isEmpty) return EmptyStateView(message: empty);
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final r = items[i];
          final status = '${r['status'] ?? ''}';
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text('${r['title'] ?? ''}'),
                  subtitle: Text([
                    '${r['ticket_number'] ?? ''}',
                    requestStatusLabels[status] ?? status,
                    requestPriorityLabels['${r['priority']}'] ?? '',
                    formatDate(r['created_at']),
                  ].where((s) => s.isNotEmpty).join(' · ')),
                ),
                if ((r['description'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('${r['description']}', maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                if (status == 'RESOLVED')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: () => _confirm(r, false), child: const Text('Devam ediyor')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(onPressed: () => _confirm(r, true), child: const Text('Sorunum çözüldü')),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
