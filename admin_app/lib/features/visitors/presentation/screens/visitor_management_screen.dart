// Ziyaretçi yönetimi (yönetim/görevli).
//
// DÜZELTME (2026-09-26): ekran `name`, `phone`, `unit`, `time` gibi var olmayan
// alanları okuyordu; ad boş gelince `substring(0,1)` ile ÇÖKÜYORDU. Durum
// süzgeçleri `inside`/`left` arıyordu (sunucu EXPECTED/CHECKED_IN/…); giriş ve
// çıkış düğmelerinin işleyicisi boştu, üstteki 12/3/2/7 sayıları uydurmaydı.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const visitorStatusLabels = {
  'EXPECTED': ('Bekleniyor', Colors.blue),
  'CHECKED_IN': ('İçeride', Colors.green),
  'CHECKED_OUT': ('Çıktı', Colors.grey),
  'CANCELLED': ('İptal', Colors.red),
  'NO_SHOW': ('Gelmedi', Colors.orange),
};

/// Ad ya da boş değer için güvenli baş harf (boş dizgede `substring` çökmesin).
String initialOf(Object? name) {
  final s = '${name ?? ''}'.trim();
  return s.isEmpty ? '?' : s.characters.first.toUpperCase();
}

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  String? _status = 'EXPECTED';
  final _listKey = GlobalKey<ApiListState>();

  Future<List<dynamic>> _load() => apiClient.getList('/visitors', query: {'status': _status});

  Future<void> _act(Map v, String action) async {
    final ok = await runAction(context, () => apiClient.post('/visitors/${v['id']}/$action'));
    if (ok) await _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ziyaretçiler')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.person_add), label: const Text('Kayıt')),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: apiClient.getMap('/visitors/summary'),
            builder: (context, snap) {
              final s = snap.data;
              if (s == null) return const SizedBox.shrink();
              return StatRow([
                ('İçeride', '${s['currently_inside'] ?? 0}'),
                ('Bugün beklenen', '${s['today_expected'] ?? 0}'),
                ('Bugün giriş', '${s['today_checked_in'] ?? 0}'),
                ('Bugün çıkış', '${s['today_checked_out'] ?? 0}'),
              ]);
            },
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final e in [null, ...visitorStatusLabels.keys])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e == null ? 'Tümü' : visitorStatusLabels[e]!.$1),
                      selected: _status == e,
                      onSelected: (_) => setState(() => _status = e),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ApiList(
              key: _listKey,
              token: _status,
              load: _load,
              empty: 'Ziyaretçi kaydı yok',
              itemBuilder: (context, v, reload) {
                final st = visitorStatusLabels['${v['status']}'];
                final when = v['checked_in_at'] ?? v['expected_at'] ?? v['created_at'];
                return ListTile(
                  leading: CircleAvatar(child: Text(initialOf(v['visitor_name']))),
                  title: Text('${v['visitor_name'] ?? ''}'),
                  subtitle: Text([
                    '${v['unit_name'] ?? 'Daire belirtilmemiş'}',
                    formatDateTime(when),
                    if ((v['vehicle_plate'] ?? '').toString().isNotEmpty) '${v['vehicle_plate']}',
                    if ((v['visitor_phone'] ?? '').toString().isNotEmpty) '${v['visitor_phone']}',
                  ].join(' · ')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (st != null) StatusChip(st.$1, color: st.$2),
                    PopupMenuButton<String>(
                      onSelected: (a) => _act(v, a),
                      itemBuilder: (_) => [
                        if (v['status'] == 'EXPECTED') const PopupMenuItem(value: 'check-in', child: Text('Giriş yaptı')),
                        if (v['status'] == 'CHECKED_IN') const PopupMenuItem(value: 'check-out', child: Text('Çıkış yaptı')),
                        if (v['status'] == 'EXPECTED') const PopupMenuItem(value: 'cancel', child: Text('İptal et')),
                      ],
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    List<dynamic> units;
    try {
      units = await apiClient.getUnits();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      return;
    }
    if (!mounted) return;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final plate = TextEditingController();
    final purpose = TextEditingController();
    String? unitId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Ziyaretçi kaydı'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null),
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
                TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
                TextFormField(controller: plate, decoration: const InputDecoration(labelText: 'Plaka')),
                TextFormField(controller: purpose, decoration: const InputDecoration(labelText: 'Ziyaret nedeni')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final saved = await runAction(context, () => apiClient.post('/visitors', {
            'visitor_name': name.text.trim(),
            'unit_id': unitId,
            if (phone.text.trim().isNotEmpty) 'visitor_phone': phone.text.trim(),
            if (plate.text.trim().isNotEmpty) 'vehicle_plate': plate.text.trim().toUpperCase(),
            if (purpose.text.trim().isNotEmpty) 'visit_reason': purpose.text.trim(),
          }));
      if (saved) await _listKey.currentState?.reload();
    }
    for (final c in [name, phone, plate, purpose]) {
      c.dispose();
    }
  }
}
