// Kargo kabul ve teslim (yönetim/görevli).
//
// DÜZELTME (2026-09-26): durumlar `waiting`/`delivered` aranıyordu (sunucu
// RECEIVED/NOTIFIED/DELIVERED/RETURNED); `arrived_at`, `unit` alanları yoktu;
// "Takip No" olarak kayıt kimliği gösteriliyordu; üstteki 5/12 sayıları
// uydurmaydı; kabul formu "bağlı değil" diyordu ama uç vardı.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const packageStatus = {
  'RECEIVED': ('Teslim alındı', Colors.orange),
  'NOTIFIED': ('Sakine bildirildi', Colors.blue),
  'DELIVERED': ('Teslim edildi', Colors.green),
  'RETURNED': ('İade', Colors.grey),
};

class PackageTrackingScreen extends StatefulWidget {
  const PackageTrackingScreen({super.key});

  @override
  State<PackageTrackingScreen> createState() => _PackageTrackingScreenState();
}

class _PackageTrackingScreenState extends State<PackageTrackingScreen> {
  bool _pendingOnly = true;
  final _list = GlobalKey<ApiListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kargo'),
        actions: [
          FilterChip(
            label: const Text('Bekleyenler'),
            selected: _pendingOnly,
            onSelected: (v) => setState(() => _pendingOnly = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _receive, icon: const Icon(Icons.add_box), label: const Text('Kargo kabul')),
      body: Column(children: [
        FutureBuilder<Map<String, dynamic>>(
          future: apiClient.getMap('/packages-summary'),
          builder: (context, snap) {
            final s = snap.data;
            if (s == null) return const SizedBox.shrink();
            return StatRow([
              ('Bekleyen', '${s['pending'] ?? 0}'),
              ('7 günden uzun', '${s['waiting_over_7_days'] ?? 0}'),
              ('Bildirilmemiş', '${s['not_notified'] ?? 0}'),
              ('Teslim edilen', '${s['delivered'] ?? 0}'),
            ]);
          },
        ),
        Expanded(
          child: ApiList(
            key: _list,
            token: _pendingOnly,
            load: () => apiClient.getList('/packages', query: {if (_pendingOnly) 'pending': 'true'}),
            empty: _pendingOnly ? 'Bekleyen kargo yok' : 'Kargo kaydı yok',
            itemBuilder: (context, p, reload) {
              final st = packageStatus['${p['status']}'];
              final waiting = p['status'] == 'RECEIVED' || p['status'] == 'NOTIFIED';
              return ListTile(
                title: Text('${p['unit_name'] ?? ''} · ${p['recipient_name'] ?? ''}'),
                subtitle: Text([
                  [p['carrier'], p['tracking_number']].where((v) => v != null && '$v'.isNotEmpty).join(' '),
                  'Geliş: ${formatDateTime(p['received_at'])}',
                  if (waiting && toNum(p['waiting_days']) > 0) '${toNum(p['waiting_days']).toInt()} gündür bekliyor',
                  if ((p['storage_location'] ?? '').toString().isNotEmpty) 'Yer: ${p['storage_location']}',
                  if (p['status'] == 'DELIVERED') 'Teslim: ${formatDateTime(p['delivered_at'])} (${p['delivered_to_name'] ?? ''})',
                ].where((s) => s.isNotEmpty).join('\n')),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (st != null) StatusChip(st.$1, color: st.$2),
                  if (waiting)
                    PopupMenuButton<String>(
                      onSelected: (a) async {
                        Map<String, dynamic> body = {};
                        if (a == 'deliver') {
                          final who = await askText(context, 'Teslim', 'Teslim alan kişinin adı', initial: '${p['recipient_name'] ?? ''}');
                          if (who == null) return;
                          body = {'delivered_to_name': who};
                        } else if (a == 'return') {
                          final r = await askText(context, 'İade', 'İade nedeni');
                          if (r == null) return;
                          body = {'reason': r};
                        }
                        if (!context.mounted) return;
                        if (await runAction(context, () => apiClient.post('/packages/${p['id']}/$a', body))) await reload();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'notify', child: Text('Sakine haber verildi (kaydet)')),
                        PopupMenuItem(value: 'deliver', child: Text('Teslim et')),
                        PopupMenuItem(value: 'return', child: Text('İade et')),
                      ],
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _receive() async {
    List<dynamic> units;
    try {
      units = await apiClient.getUnits();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      return;
    }
    if (!mounted) return;
    final formKey = GlobalKey<FormState>();
    final recipient = TextEditingController();
    final carrier = TextEditingController();
    final tracking = TextEditingController();
    final location = TextEditingController();
    String? unitId;
    var type = 'PACKAGE';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Kargo kabul'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: unitId,
                  decoration: const InputDecoration(labelText: 'Daire'),
                  items: [
                    for (final u in units.whereType<Map>())
                      DropdownMenuItem(value: '${u['id']}', child: Text('${u['block'] ?? ''}-${u['door_number'] ?? ''}')),
                  ],
                  onChanged: (v) => set(() => unitId = v),
                  validator: (v) => v == null ? 'Daire seçin' : null,
                ),
                TextFormField(controller: recipient, decoration: const InputDecoration(labelText: 'Alıcı adı'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                TextFormField(controller: carrier, decoration: const InputDecoration(labelText: 'Kargo firması')),
                TextFormField(controller: tracking, decoration: const InputDecoration(labelText: 'Takip numarası')),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: const [
                    DropdownMenuItem(value: 'PACKAGE', child: Text('Paket')),
                    DropdownMenuItem(value: 'ENVELOPE', child: Text('Zarf')),
                    DropdownMenuItem(value: 'LARGE', child: Text('Büyük')),
                  ],
                  onChanged: (v) => set(() => type = v ?? type),
                ),
                TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Saklama yeri')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            }, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final saved = await runAction(context, () => apiClient.post('/packages', {
            'unit_id': unitId,
            'recipient_name': recipient.text.trim(),
            if (carrier.text.trim().isNotEmpty) 'carrier': carrier.text.trim(),
            if (tracking.text.trim().isNotEmpty) 'tracking_number': tracking.text.trim(),
            'package_type': type,
            if (location.text.trim().isNotEmpty) 'storage_location': location.text.trim(),
          }));
      if (saved) await _list.currentState?.reload();
    }
    for (final c in [recipient, carrier, tracking, location]) {
      c.dispose();
    }
  }
}
