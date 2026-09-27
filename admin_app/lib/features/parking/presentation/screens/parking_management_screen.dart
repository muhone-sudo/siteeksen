// Otopark yönetimi.
//
// DÜZELTME (2026-09-26): bölgeler, 120/65/55 doluluk sayıları ve "son
// hareketler" plakaları KODA GÖMÜLÜYDÜ; araç listesinde daire yerine kimlik ve
// var olmayan `is_inside` gösteriliyordu. Artık bölgeler, araçlar ve giriş/çıkış
// kayıtları sunucudan gelir; giriş/çıkış kaydedilebilir (ücret TAHSİL EDİLMEZ).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

class ParkingManagementScreen extends StatefulWidget {
  const ParkingManagementScreen({super.key});

  @override
  State<ParkingManagementScreen> createState() => _ParkingManagementScreenState();
}

class _ParkingManagementScreenState extends State<ParkingManagementScreen> {
  final _logs = GlobalKey<ApiListState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Otopark'),
          bottom: const TabBar(tabs: [Tab(text: 'İçeride'), Tab(text: 'Araçlar'), Tab(text: 'Bölgeler')]),
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _entry, icon: const Icon(Icons.login), label: const Text('Giriş')),
        body: TabBarView(children: [
          ApiList(
            key: _logs,
            load: () => apiClient.getList('/parking-logs', query: {'inside': 'true'}),
            empty: 'İçeride araç yok',
            itemBuilder: (context, l, reload) => ListTile(
              leading: Icon(l['is_resident'] == true ? Icons.home : Icons.directions_car),
              title: Text('${l['plate'] ?? ''}'),
              subtitle: Text([
                '${l['zone_name'] ?? ''}',
                'Giriş: ${formatDateTime(l['entry_at'])}',
                l['is_resident'] == true ? 'Sakin aracı' : 'Misafir',
              ].where((s) => s.isNotEmpty).join(' · ')),
              trailing: TextButton(
                onPressed: () async {
                  if (await runAction(context, () => apiClient.post('/parking-logs/${l['id']}/exit'))) await reload();
                },
                child: const Text('Çıkış'),
              ),
            ),
          ),
          ApiList(
            load: () => apiClient.getList('/vehicles'),
            empty: 'Kayıtlı araç yok',
            itemBuilder: (context, v, _) => ListTile(
              title: Text('${v['plate'] ?? ''}'),
              subtitle: Text([
                '${v['unit_name'] ?? ''}',
                [v['brand'], v['model'], v['color']].where((x) => x != null && '$x'.isNotEmpty).join(' '),
                if ((v['parking_spot'] ?? '').toString().isNotEmpty) 'Yer: ${v['parking_spot']}',
              ].where((s) => s.isNotEmpty).join(' · ')),
              trailing: v['is_active'] == false ? const StatusChip('Pasif', color: Colors.grey) : null,
            ),
          ),
          ApiList(
            load: () => apiClient.getList('/parking-zones'),
            empty: 'Otopark bölgesi tanımlı değil',
            itemBuilder: (context, z, _) => ListTile(
              title: Text('${z['name'] ?? ''}'),
              subtitle: Text([
                'Dolu ${toNum(z['occupied_count']).toInt()} / ${toNum(z['capacity']).toInt()}',
                'Boş ${toNum(z['available_spots']).toInt()}',
                if (z['is_paid'] == true) 'Ücretli (${formatTry(toNum(z['hourly_fee']))}/saat)',
              ].join(' · ')),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _entry() async {
    final plate = await askText(context, 'Araç girişi', 'Plaka');
    if (plate == null || !mounted) return;
    final ok = await runAction(context, () async {
      final r = await apiClient.post('/parking-logs/entry', {'plate': plate.toUpperCase(), 'entry_method': 'MANUAL'});
      return {...r, 'message': r['is_resident_vehicle'] == true ? 'Giriş kaydedildi (sakin aracı)' : 'Giriş kaydedildi (misafir)'};
    });
    if (ok) await _logs.currentState?.reload();
  }
}
