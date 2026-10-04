// KVKK ilgili kişi başvurusu (m.11, 2026-10-04).
//
// Sakin, kişisel verileriyle ilgili başvurusunu buradan yapar ve sonucunu izler.
// Site yönetimi kanun gereği (m.13/2) en geç 30 gün içinde ücretsiz yanıtlar.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const kvkkTypeLabels = {
  'INFO': 'Verilerim işleniyor mu, hangileri? (bilgi talebi)',
  'CORRECTION': 'Eksik/yanlış verimin düzeltilmesi',
  'ERASURE': 'Verilerimin silinmesi / yok edilmesi',
  'OBJECTION': 'Otomatik analiz sonucuna itiraz',
  'COMPENSATION': 'Zararımın giderilmesi',
  'OTHER': 'Diğer',
};

/// Başvurunun durum metni: açıksa kalan gün, sonuçlandıysa sonuç.
String kvkkStatusText(Map<dynamic, dynamic> r) {
  switch (r['status']) {
    case 'ANSWERED':
      return 'Yanıtlandı';
    case 'REJECTED':
      return 'Reddedildi';
    default:
      final left = toNum(r['days_left']).toInt();
      return left >= 0 ? 'Yanıt bekleniyor · son gün ${formatDate(r['due_date'])}' : 'Yasal süre geçti (${-left} gün)';
  }
}

class KvkkRequestsScreen extends StatefulWidget {
  const KvkkRequestsScreen({super.key});

  @override
  State<KvkkRequestsScreen> createState() => _KvkkRequestsScreenState();
}

class _KvkkRequestsScreenState extends State<KvkkRequestsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getKvkkRequests();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getKvkkRequests());
    await _future;
  }

  Future<void> _create() async {
    var type = 'INFO';
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Yeni KVKK başvurusu'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                isExpanded: true,
                items: [
                  for (final e in kvkkTypeLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'INFO'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Talebiniz', hintText: 'Kısaca açıklayın (en az 10 karakter)'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await apiClient.createKvkkRequest(type, text.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['note'] ?? 'Başvurunuz kaydedildi'}')));
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KVKK başvurularım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Başvuru yap'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Kişisel verilerinizin işlenip işlenmediğini öğrenme, düzeltilmesini ya da silinmesini isteme '
                    'haklarınız vardır (KVKK m.11). Site yönetimi başvurunuzu en geç 30 gün içinde ücretsiz yanıtlar.',
                  ),
                ),
                if (items.isEmpty)
                  const EmptyStateView(message: 'Henüz başvurunuz yok', icon: Icons.privacy_tip_outlined),
                for (final r in items)
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(kvkkTypeLabels['${r['request_type']}'] ?? '${r['request_type']}'),
                    subtitle: Text([
                      kvkkStatusText(r),
                      if ('${r['response'] ?? ''}'.isNotEmpty) 'Yanıt: ${r['response']}',
                    ].join('\n')),
                    isThreeLine: '${r['response'] ?? ''}'.isNotEmpty,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
