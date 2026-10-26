// Otopark yönetimi.
//
// DÜZELTME (2026-09-26): bölgeler, 120/65/55 doluluk sayıları ve "son
// hareketler" plakaları KODA GÖMÜLÜYDÜ; araç listesinde daire yerine kimlik ve
// var olmayan `is_inside` gösteriliyordu. Artık bölgeler, araçlar ve giriş/çıkış
// kayıtları sunucudan gelir; giriş/çıkış kaydedilebilir (ücret TAHSİL EDİLMEZ).
// FAZ H.7: araç kaydı/pasife alma, plaka sorgu ve geçiş cihazları panelle eşit.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _ownerTypes = [('RESIDENT', 'Sakin'), ('VISITOR', 'Ziyaretçi'), ('STAFF', 'Personel'), ('SERVICE', 'Servis')];
const _vehicleTypes = [('CAR', 'Otomobil'), ('MOTORCYCLE', 'Motosiklet'), ('TRUCK', 'Kamyonet')];
const _deviceKinds = [('PTS_CAMERA', 'Plaka tanıma kamerası'), ('BARRIER', 'Bariyer'), ('TURNSTILE', 'Turnike'), ('INTERCOM', 'Kapı telefonu'), ('OTHER', 'Diğer')];

String _label(List<(String, String)> list, Object? v) => list.firstWhere((e) => e.$1 == v, orElse: () => ('', '$v')).$2;

class ParkingManagementScreen extends StatefulWidget {
  const ParkingManagementScreen({super.key});

  @override
  State<ParkingManagementScreen> createState() => _ParkingManagementScreenState();
}

class _ParkingManagementScreenState extends State<ParkingManagementScreen> {
  final _logs = GlobalKey<ApiListState>();
  final _vehicles = GlobalKey<ApiListState>();
  final _devices = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Otopark'),
          actions: [IconButton(tooltip: 'Plaka sorgula', icon: const Icon(Icons.search), onPressed: _lookup)],
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'İçeride'), Tab(text: 'Araçlar'), Tab(text: 'Bölgeler'), Tab(text: 'Cihazlar')]),
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
            key: _vehicles,
            load: () => apiClient.getList('/vehicles'),
            empty: 'Kayıtlı araç yok',
            header: (_) => Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(onPressed: _addVehicle, icon: const Icon(Icons.add), label: const Text('Araç kaydet')),
              ),
            ),
            itemBuilder: (context, v, reload) => ListTile(
              title: Text('${v['plate'] ?? ''}'),
              subtitle: Text([
                '${v['unit_name'] ?? ''}',
                v['owner_name'] ?? _label(_ownerTypes, v['owner_type']),
                [v['brand'], v['model'], v['color']].where((x) => x != null && '$x'.isNotEmpty).join(' '),
                if ((v['parking_spot'] ?? '').toString().isNotEmpty) 'Yer: ${v['parking_spot']}',
              ].where((s) => '$s'.isNotEmpty).join(' · ')),
              trailing: v['is_active'] == false
                  ? const StatusChip('Pasif', color: Colors.grey)
                  : RowMenu([
                      ('Pasife al', () async {
                        if (await confirmAction(context, 'Aracı pasife al', '${v['plate']} pasife alınsın mı? Geçmiş otopark hareketleri korunur.',
                            () => apiClient.delete('/vehicles/${v['id']}'), ok: 'Pasife al')) {
                          await reload();
                        }
                      }),
                    ]),
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
          ApiList(
            key: _devices,
            load: () => apiClient.getList('/access-devices'),
            empty: 'Kayıtlı cihaz yok',
            header: (_) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_canWrite)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlinedButton.icon(onPressed: _addDevice, icon: const Icon(Icons.add), label: const Text('Cihaz ekle')),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Çevrimdışı olayları'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _Incidents())),
              ),
            ]),
            itemBuilder: (context, x, reload) => ListTile(
              leading: Icon(x['is_active'] != true ? Icons.block : (x['online'] == true ? Icons.wifi : Icons.wifi_off),
                  color: x['is_active'] != true ? Colors.grey : (x['online'] == true ? Colors.green : Colors.red)),
              title: Text('${x['name'] ?? ''}'),
              subtitle: Text([
                _label(_deviceKinds, x['kind']),
                if ((x['location'] ?? '').toString().isNotEmpty) '${x['location']}',
                x['last_seen_at'] != null ? 'Son sinyal ${formatDateTime(x['last_seen_at'])}' : 'Hiç sinyal yok',
                '${x['heartbeat_interval_sec']} sn aralık · ${x['offline_after_sec']} sn eşik',
                if ((x['last_status'] ?? '').toString().isNotEmpty) 'Durum: ${x['last_status']}',
              ].join('\n')),
              isThreeLine: true,
              trailing: _canWrite && x['is_active'] == true
                  ? RowMenu([
                      ('Pasife al', () async {
                        if (await confirmAction(context, 'Cihazı pasife al', '${x['name']} pasife alınsın mı?',
                            () => apiClient.delete('/access-devices/${x['id']}'), ok: 'Pasife al')) {
                          await reload();
                        }
                      }),
                    ])
                  : null,
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

  Future<void> _lookup() async {
    final plate = await askText(context, 'Plaka sorgula', 'Plaka');
    if (plate == null || !mounted) return;
    try {
      final v = await apiClient.getMap('/vehicles/plate/${Uri.encodeComponent(plate.toUpperCase())}');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${v['plate']}'),
          content: Text([
            _label(_ownerTypes, v['owner_type']),
            if ((v['unit_name'] ?? '').toString().isNotEmpty) 'Daire: ${v['unit_name']}',
            if ((v['owner_name'] ?? '').toString().isNotEmpty) 'Sahip: ${v['owner_name']}',
            [v['brand'], v['model'], v['color']].where((x) => x != null && '$x'.isNotEmpty).join(' '),
            if ((v['parking_spot'] ?? '').toString().isNotEmpty) 'Park yeri: ${v['parking_spot']}',
          ].where((s) => s.isNotEmpty).join('\n')),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _addVehicle() async {
    final units = await unitOptions();
    if (!mounted) return;
    if (await formAction(context, 'Araç kaydet', [
      const FSpec('plate', 'Plaka', required: true, hint: '34 ABC 123'),
      FSpec('unit_id', 'Daire', type: FType.select, options: units),
      const FSpec('owner_type', 'Sahip türü', type: FType.select, options: _ownerTypes, initial: 'RESIDENT', required: true),
      const FSpec('owner_name', 'Sahip adı'),
      const FSpec('vehicle_type', 'Araç türü', type: FType.select, options: _vehicleTypes, initial: 'CAR', required: true),
      const FSpec('parking_spot', 'Park yeri'),
      const FSpec('brand', 'Marka'),
      const FSpec('model', 'Model'),
      const FSpec('color', 'Renk'),
    ], (v) => apiClient.post('/vehicles', {...v, 'plate': '${v['plate']}'.toUpperCase()}), success: 'Araç kaydedildi')) {
      await _vehicles.currentState?.reload();
    }
  }

  Future<void> _addDevice() async {
    final v = await showForm(context, 'Geçiş cihazı ekle', const [
      FSpec('name', 'Ad', required: true),
      FSpec('kind', 'Tür', type: FType.select, options: _deviceKinds, initial: 'PTS_CAMERA', required: true),
      FSpec('location', 'Konum'),
      FSpec('heartbeat_interval_sec', 'Sinyal aralığı (sn)', type: FType.integer, initial: 60, hint: 'Çevrimdışı eşiği bunun 3 katıdır'),
    ]);
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.post('/access-devices', v);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cihaz anahtarı'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText('${r['device_key'] ?? ''}', style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text('${r['note'] ?? 'Anahtar yalnız şimdi gösterilir.'}', style: const TextStyle(fontSize: 12)),
          ]),
          actions: [
            TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: '${r['device_key'] ?? ''}')), child: const Text('Kopyala')),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
      await _devices.currentState?.reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }
}

class _Incidents extends StatelessWidget {
  const _Incidents();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çevrimdışı olayları')),
      body: ApiList(
        load: () => apiClient.getList('/access-devices/incidents'),
        empty: 'Olay yok',
        itemBuilder: (context, x, _) => ListTile(
          leading: Icon(x['recovered_at'] == null ? Icons.error : Icons.check_circle, color: x['recovered_at'] == null ? Colors.red : Colors.green),
          title: Text('${x['device_name'] ?? ''}'),
          subtitle: Text([
            'Son sinyal ${formatDateTime(x['last_seen_at'])}',
            'Fark edildi ${formatDateTime(x['detected_at'])}',
            x['recovered_at'] == null ? 'Açık' : 'Düzeldi ${formatDateTime(x['recovered_at'])}',
          ].join('\n')),
          isThreeLine: true,
        ),
      ),
    );
  }
}
