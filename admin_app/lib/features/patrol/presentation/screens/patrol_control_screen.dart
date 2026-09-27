// Devriye (tur) kontrolü.
//
// DÜZELTME (2026-09-26): ekran var olmayan `/patrol-sessions` yoluna gidiyordu
// ve iki çağrı tek try bloğunda olduğu için BÜTÜN ekran hata veriyordu;
// güzergâhta `checkpoint_count`, turda `completed_checkpoints` alanları yoktu.
// Tur başlatma ve okutma görevlinin cihazından yapılır (NFC/QR); burada izlenir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const patrolStatus = {
  'IN_PROGRESS': ('Devam ediyor', Colors.blue),
  'COMPLETED': ('Tamamlandı', Colors.green),
  'INCOMPLETE': ('Eksik', Colors.red),
};

class PatrolControlScreen extends StatelessWidget {
  const PatrolControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devriye'),
          bottom: const TabBar(tabs: [Tab(text: 'Turlar'), Tab(text: 'Güzergâhlar')]),
        ),
        body: TabBarView(children: [
          ApiList(
            load: () => apiClient.getList('/patrols', query: {'limit': 100}),
            empty: 'Tur kaydı yok',
            header: (_) => FutureBuilder<Map<String, dynamic>>(
              future: apiClient.getMap('/patrols-summary'),
              builder: (context, snap) {
                final s = snap.data?['summary'];
                if (s is! Map) return const SizedBox.shrink();
                return Column(children: [
                  StatRow([
                    ('Son 7 gün', '${s['patrols_last_7_days'] ?? 0}'),
                    ('Eksik', '${s['incomplete'] ?? 0}'),
                    ('Şüpheli hızlı', '${s['suspiciously_fast'] ?? 0}'),
                    ('Bildirilen sorun', '${s['issues_reported'] ?? 0}'),
                  ]),
                  if (snap.data?['warning'] is String)
                    Padding(padding: const EdgeInsets.all(12), child: Text('${snap.data!['warning']}')),
                ]);
              },
            ),
            itemBuilder: (context, p, _) {
              final st = patrolStatus['${p['status']}'];
              return ListTile(
                title: Text('${p['route_name'] ?? 'Güzergâhsız tur'} · ${p['guard_name'] ?? ''}'),
                subtitle: Text([
                  formatDateTime(p['started_at']),
                  'Nokta: ${toNum(p['checkpoints_visited']).toInt()}/${toNum(p['checkpoints_expected']).toInt()}',
                  if (p['actual_duration_minutes'] != null) '${toNum(p['actual_duration_minutes']).toInt()} dk (beklenen ${toNum(p['expected_duration_minutes']).toInt()})',
                  if (toNum(p['issues_reported']) > 0) '${toNum(p['issues_reported']).toInt()} sorun',
                  if (p['too_fast'] == true) 'Beklenenden kısa sürdü — denetleyin',
                ].join(' · ')),
                trailing: st == null ? null : StatusChip(st.$1, color: st.$2),
              );
            },
          ),
          ApiList(
            load: () => apiClient.getList('/patrol-routes'),
            empty: 'Güzergâh tanımlı değil (web panelinden tanımlanır)',
            itemBuilder: (context, r, _) {
              final cps = ApiClient.listOf(r['checkpoints']);
              return ListTile(
                title: Text('${r['name'] ?? ''}'),
                subtitle: Text('${cps.length} nokta · ${toNum(r['expected_duration_minutes']).toInt()} dk '
                    '(tolerans ${toNum(r['tolerance_minutes']).toInt()} dk)'),
                trailing: r['is_active'] == false ? const StatusChip('Pasif', color: Colors.grey) : null,
              );
            },
          ),
        ]),
      ),
    );
  }
}
