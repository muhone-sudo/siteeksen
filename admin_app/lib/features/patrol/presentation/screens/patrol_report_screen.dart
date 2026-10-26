// Devriye raporları (075, FAZ H.5): dönem özeti, tur listesi ve tur ayrıntısı (harita üzerinde iz,
// noktalar ve okutma denemeleri). Harita OpenStreetMap karolarıyla çizilir.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import 'patrol_control_screen.dart' show patrolStatus;

class PatrolReportScreen extends StatefulWidget {
  const PatrolReportScreen({super.key});

  @override
  State<PatrolReportScreen> createState() => _PatrolReportScreenState();
}

class _PatrolReportScreenState extends State<PatrolReportScreen> {
  int _days = 30;
  Map<String, dynamic> _summary = {};

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<dynamic>> _load() async {
    final res = await apiClient.getMap('/patrol-reports', query: {'from': _date(DateTime.now().subtract(Duration(days: _days)))});
    if (mounted) setState(() => _summary = Map<String, dynamic>.from((res['summary'] as Map?) ?? {}));
    return (res['data'] as List?) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devriye raporları'), actions: [
        PopupMenuButton<int>(
          initialValue: _days,
          onSelected: (v) => setState(() => _days = v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 7, child: Text('Son 7 gün')),
            PopupMenuItem(value: 30, child: Text('Son 30 gün')),
            PopupMenuItem(value: 90, child: Text('Son 90 gün')),
          ],
        ),
      ]),
      body: ApiList(
        token: _days,
        load: _load,
        empty: 'Bu dönemde tur yok',
        header: (_) => Column(children: [
          StatRow([
            ('Tur', '${_summary['total'] ?? 0}'),
            ('Tamam', '${_summary['completed'] ?? 0}'),
            ('Eksik', '${_summary['incomplete'] ?? 0}'),
            ('Ort. süre', '${_summary['avg_duration_minutes'] ?? 0} dk'),
          ]),
          StatRow([
            ('Reddedilen okutma', '${_summary['rejected_attempts'] ?? 0}'),
            ('Şüpheli', '${_summary['suspicious_scans'] ?? 0}'),
          ]),
          for (final t in ((_summary['top_rejections'] as List?) ?? []).whereType<Map>())
            ListTile(dense: true, leading: const Icon(Icons.block, color: Colors.red), title: Text('${t['checkpoint']}: ${t['reason_text'] ?? t['reason']}'), trailing: Text('${t['count']}')),
        ]),
        itemBuilder: (context, p, _) {
          final st = patrolStatus['${p['status']}'];
          return ListTile(
            title: Text('${p['route_name']} · ${p['guard_name']}'),
            subtitle: Text('${formatDateTime(p['started_at'])} · nokta ${p['checkpoints_visited']}/${p['checkpoints_expected']}'
                '${toNum(p['rejected_attempts']) > 0 ? ' · ${p['rejected_attempts']} red' : ''}'
                '${toNum(p['suspicious_scans']) > 0 ? ' · ${p['suspicious_scans']} şüpheli' : ''}'
                '${toNum(p['exempt_scans']) > 0 ? ' · ${p['exempt_scans']} muaf' : ''}'),
            trailing: st == null ? null : StatusChip(st.$1, color: st.$2),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatrolDetailScreen(id: '${p['id']}'))),
          );
        },
      ),
    );
  }
}

class PatrolDetailScreen extends StatelessWidget {
  final String id;
  const PatrolDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tur raporu')),
      body: ApiObject(
        load: () => apiClient.getMap('/patrols/$id/report'),
        builder: (context, r, _) {
          final p = Map<String, dynamic>.from((r['patrol'] as Map?) ?? {});
          final s = Map<String, dynamic>.from((r['stats'] as Map?) ?? {});
          final track = ((r['track'] as List?) ?? []).whereType<Map>().toList();
          final cps = ((r['checkpoints'] as List?) ?? []).whereType<Map>().where((c) => c['latitude'] != null).toList();
          final attempts = ((r['attempts'] as List?) ?? []).whereType<Map>().toList();
          final gaps = ((r['gaps'] as List?) ?? []).whereType<Map>().toList();
          final line = [for (final t in track) LatLng(toNum(t['latitude']).toDouble(), toNum(t['longitude']).toDouble())];
          final center = line.isNotEmpty
              ? line.first
              : cps.isNotEmpty
                  ? LatLng(toNum(cps.first['latitude']).toDouble(), toNum(cps.first['longitude']).toDouble())
                  : null;
          return ListView(children: [
            ListTile(
              title: Text('${p['route_name']} · ${p['guard_name']}'),
              subtitle: Text('${formatDateTime(p['started_at'])} → ${p['completed_at'] != null ? formatDateTime(p['completed_at']) : 'devam ediyor'}\n'
                  'Nokta ${p['checkpoints_visited'] ?? 0}/${p['checkpoints_expected'] ?? 0} · ${p['actual_duration_minutes'] ?? '—'} dk (beklenen ${p['expected_duration_minutes'] ?? '—'})'),
              isThreeLine: true,
            ),
            StatRow([
              ('Red', '${s['rejected_attempts'] ?? 0}'),
              ('Şüpheli', '${s['suspicious_scans'] ?? 0}'),
              ('Muaf', '${s['exempt_scans'] ?? 0}'),
              ('Kesinti', '${s['track_gaps'] ?? 0}'),
            ]),
            StatRow([
              ('İz noktası', '${s['track_points'] ?? 0}'),
              ('Sahte konum', '${s['mocked_track_points'] ?? 0}'),
              ('Yürünen', '${s['track_distance_m'] ?? 0} m'),
            ]),
            if (center != null)
              SizedBox(
                height: 320,
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 17),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.siteeksen.admin'),
                    if (line.length > 1) PolylineLayer(polylines: [Polyline(points: line, strokeWidth: 4, color: Colors.blue)]),
                    CircleLayer(circles: [
                      for (final c in cps)
                        CircleMarker(
                          point: LatLng(toNum(c['latitude']).toDouble(), toNum(c['longitude']).toDouble()),
                          radius: toNum(c['radius_m']).toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.green.withValues(alpha: 0.2),
                          borderColor: Colors.green,
                          borderStrokeWidth: 2,
                        ),
                    ]),
                    MarkerLayer(markers: [
                      for (final a in attempts.where((a) => a['latitude'] != null))
                        Marker(
                          point: LatLng(toNum(a['latitude']).toDouble(), toNum(a['longitude']).toDouble()),
                          width: 18,
                          height: 18,
                          child: Icon(a['accepted'] == true ? Icons.check_circle : Icons.cancel,
                              size: 18, color: a['accepted'] == true ? (a['suspicious'] == true ? Colors.orange : Colors.green) : Colors.red),
                        ),
                    ]),
                  ],
                ),
              )
            else
              const ListTile(title: Text('Haritada gösterilecek konum yok')),
            const ListTile(dense: true, title: Text('Harita © OpenStreetMap katkıcıları', style: TextStyle(fontSize: 11))),
            if (gaps.isNotEmpty) ...[
              const ListTile(title: Text('Takip kesintileri', style: TextStyle(fontWeight: FontWeight.w600))),
              for (final g in gaps) ListTile(dense: true, title: Text('${formatDateTime(g['from'])} – ${formatDateTime(g['to'])} (${g['minutes']} dk)')),
            ],
            const ListTile(title: Text('Okutma denemeleri', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final a in attempts)
              ListTile(
                dense: true,
                leading: Icon(a['accepted'] == true ? Icons.check_circle : Icons.cancel, color: a['accepted'] == true ? Colors.green : Colors.red),
                title: Text('${a['checkpoint'] == '' ? 'Tanınmayan QR' : a['checkpoint']} · ${a['method']}'),
                subtitle: Text([
                  formatDateTime(a['at']),
                  if (a['accepted'] != true) '${a['reason_text'] ?? a['reason']}',
                  if (a['distance_m'] != null) '${toNum(a['distance_m']).round()} m',
                  if (a['accuracy_m'] != null) '±${toNum(a['accuracy_m']).round()} m',
                  if (a['suspicious'] == true) 'şüpheli hız',
                  if (a['location_exempt'] == true) 'konum muaf',
                  if (a['is_mocked'] == true) 'sahte konum',
                ].join(' · ')),
              ),
          ]);
        },
      ),
    );
  }
}
