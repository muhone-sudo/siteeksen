// Kargolarım (sakin — yalnızca kendi dairesinin paketleri).
//
// DÜZELTME (2026-09-26): ekran `arrived`/`in_transit`/`picked_up` durumlarını
// ve var olmayan alanları (`arrived_at`, `sender_name`…) arıyordu; sunucu
// RECEIVED/NOTIFIED/DELIVERED/RETURNED döndüğü için HER PAKET GİZLİ kalıyordu.
// Eksik alanlar '12:00', 'Bugün', 'Yakında' gibi uydurma değerlerle
// dolduruluyordu. Artık sunucunun alanları olduğu gibi gösterilir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Paket durumu → (etiket, bekliyor mu).
const packageStatusLabels = {
  'RECEIVED': 'Yönetimde bekliyor',
  'NOTIFIED': 'Yönetimde bekliyor (bildirildi)',
  'DELIVERED': 'Teslim edildi',
  'RETURNED': 'İade edildi',
};

/// Teslim alınmayı bekleyen paket mi?
bool isPackageWaiting(Object? status) => status == 'RECEIVED' || status == 'NOTIFIED';

class PackageTrackingMobileScreen extends StatefulWidget {
  const PackageTrackingMobileScreen({super.key});

  @override
  State<PackageTrackingMobileScreen> createState() => _PackageTrackingMobileScreenState();
}

class _PackageTrackingMobileScreenState extends State<PackageTrackingMobileScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getPackages();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getPackages());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kargolarım')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final all = snap.data!.whereType<Map>().toList();
          if (all.isEmpty) {
            return const EmptyStateView(message: 'Kayıtlı paketiniz yok', icon: Icons.local_shipping_outlined);
          }
          final waiting = all.where((p) => isPackageWaiting(p['status'])).toList();
          final done = all.where((p) => !isPackageWaiting(p['status'])).toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              children: [
                if (waiting.isNotEmpty) ...[
                  _header(context, 'Teslim almanızı bekleyen (${waiting.length})'),
                  for (final p in waiting) _tile(context, p),
                ],
                if (done.isNotEmpty) ...[
                  _header(context, 'Geçmiş'),
                  for (final p in done) _tile(context, p),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _tile(BuildContext context, Map p) {
    final status = '${p['status'] ?? ''}';
    final waiting = isPackageWaiting(status);
    final days = toNum(p['waiting_days']).toInt();
    final lines = <String>[
      packageStatusLabels[status] ?? status,
      'Geliş: ${formatDateTime(p['received_at'])}',
      if (waiting && days > 0) '$days gündür bekliyor',
      if (waiting && (p['storage_location'] ?? '').toString().isNotEmpty) 'Yer: ${p['storage_location']}',
      if (!waiting && parseApiDate(p['delivered_at']) != null)
        'Teslim: ${formatDateTime(p['delivered_at'])}${(p['delivered_to_name'] ?? '').toString().isNotEmpty ? ' (${p['delivered_to_name']})' : ''}',
      if ((p['tracking_number'] ?? '').toString().isNotEmpty) 'Takip no: ${p['tracking_number']}',
    ];
    return ListTile(
      leading: Icon(waiting ? Icons.inventory_2 : Icons.check_circle_outline, color: waiting ? Colors.orange : Colors.green),
      title: Text([p['carrier'], p['recipient_name']].where((v) => v != null && '$v'.isNotEmpty).join(' · ')),
      subtitle: Text(lines.join('\n')),
      isThreeLine: true,
    );
  }
}
