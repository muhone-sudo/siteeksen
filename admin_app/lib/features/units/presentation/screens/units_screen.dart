// Bağımsız bölümler (FAZ H.7, panel /dashboard/units ile eşit): ekleme, düzenleme, toplu ekleme ve
// borcu yoktur belgesi. Arsa payı KMK m.20 gider dağıtımının temelidir; değişiklik yalnız SONRAKİ
// tahakkukları etkiler. Net kullanım alanı daire/dükkân/ofiste zorunludur (ısıtmanın sabit payı).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _types = [('APARTMENT', 'Daire'), ('SHOP', 'Dükkân'), ('OFFICE', 'Ofis'), ('PARKING', 'Otopark'), ('STORAGE', 'Depo')];
const _occupancy = {
  'TENANT_OCCUPIED': ('Kiracı oturuyor', Colors.blue),
  'OWNER_OCCUPIED': ('Malik oturuyor', Colors.green),
  'VACANT': ('Boş', Colors.grey),
  'UNREGISTERED': ('Kayıtsız', Colors.red),
};
const _areaRequired = ['APARTMENT', 'SHOP', 'OFFICE'];

/// "1.234,5" ve "1234.5" ikisi de kabul edilir: virgül varsa nokta binlik ayracıdır.
num? _num(String s) {
  final t = s.trim();
  return num.tryParse(t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t);
}

/// Toplu satır: `blok;kat;kapı;arsa payı;net m²;brüt m²` (ayraç ; ya da sekme). Hatalı satır varsa hiçbiri gönderilmez.
(List<Map<String, dynamic>>, List<String>) parseUnits(String text) {
  final units = <Map<String, dynamic>>[];
  final errors = <String>[];
  final lines = text.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
    final p = [...line.split(RegExp(r'[;\t]')), '', '', '', '', '', ''];
    final row = i + 1;
    final floor = p[1].trim().isEmpty ? 0 : int.tryParse(p[1].trim());
    final share = _num(p[3]);
    final net = _num(p[4]);
    if (p[2].trim().isEmpty) {
      errors.add('$row. satır: kapı numarası yok');
    } else if (floor == null) {
      errors.add('$row. satır: kat tam sayı olmalı');
    } else if (share == null || share <= 0) {
      errors.add('$row. satır: arsa payı sıfırdan büyük olmalı');
    } else if (net == null || net <= 0) {
      errors.add('$row. satır: net kullanım alanı (m²) sıfırdan büyük olmalı');
    } else {
      final u = <String, dynamic>{'block': p[0].trim(), 'floor': floor, 'door_number': p[2].trim(), 'share_ratio': share, 'net_area_m2': net};
      if (p[5].trim().isNotEmpty) {
        final a = _num(p[5]);
        if (a == null || a < 0) {
          errors.add('$row. satır: brüt alan geçersiz');
          continue;
        }
        u['gross_area_m2'] = a;
      }
      units.add(u);
    }
  }
  return (units, errors);
}

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _edit([Map<String, dynamic>? u]) async {
    bool needArea(Map<String, dynamic> v) => _areaRequired.contains(v['unit_type'] ?? 'APARTMENT');
    if (await formAction(context, u == null ? 'Bölüm ekle' : 'Bölümü düzenle', [
      FSpec('block', 'Blok', initial: u?['block'], hint: 'Bloksuz yapılarda boş bırakın'),
      FSpec('door_number', 'Kapı no', initial: u?['door_number'], required: true),
      FSpec('floor', 'Kat', type: FType.integer, initial: u?['floor'] ?? 0),
      FSpec('share_ratio', 'Arsa payı', type: FType.decimal, initial: u?['share_ratio'], required: true, hint: 'Tapudaki pay (120 / 10000 için 120)'),
      FSpec('unit_type', 'Tür', type: FType.select, options: _types, initial: u?['unit_type'] ?? 'APARTMENT'),
      FSpec('net_area_m2', 'Net kullanım alanı (m²)', type: FType.decimal, initial: toNum(u?['net_area_m2']) > 0 ? u!['net_area_m2'] : null,
          hint: 'Daire/dükkân/ofiste zorunlu; ısıtmanın sabit payı buna göre dağıtılır'),
      FSpec('gross_area_m2', 'Brüt m²', type: FType.decimal, initial: toNum(u?['gross_area_m2']) > 0 ? u!['gross_area_m2'] : null),
      FSpec('is_commercial', 'Ticari bölüm', type: FType.toggle, initial: u?['is_commercial'] ?? false),
      if (u != null)
        FSpec('owner_occupied', 'Kiracı yokken malik oturuyor', type: FType.toggle, initial: u['owner_occupied'] ?? true,
            hint: 'Kapalıysa boş daire sayılır; kullanım ve malik giderlerinin tamamı malike düşer'),
    ], (v) {
      if (needArea(v) && !(toNum(v['net_area_m2']) > 0)) throw StateError('Net kullanım alanı bu bölüm türünde zorunlu');
      final body = {'block': '', ...v};
      return u == null ? apiClient.post('/units', {'units': [body]}) : apiClient.patch('/units/${u['id']}', body);
    }, success: u == null ? 'Bölüm eklendi' : 'Bölüm güncellendi')) {
      await _list.currentState?.reload();
    }
  }

  Future<void> _bulk() async {
    final v = await showForm(context, 'Toplu bölüm ekle', const [
      FSpec('text', 'Bölümler', type: FType.multiline, required: true, hint: 'A;0;1;120,5;82;95'),
    ], note: 'Her satıra bir bölüm: blok;kat;kapı;arsa payı;net m²;brüt m² (Excel\'den kopyalanan sekmeli satırlar da olur). Bir satır bile hatalıysa hiçbiri eklenmez.', submit: 'Denetle');
    if (v == null || !mounted) return;
    final (units, errors) = parseUnits('${v['text']}');
    if (errors.isNotEmpty || units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.isEmpty ? 'Eklenecek bölüm yok' : errors.take(10).join(' · '))));
      return;
    }
    final total = units.fold<num>(0, (a, u) => a + (u['share_ratio'] as num));
    if (!await confirm(context, 'Toplu ekleme', '${units.length} bölüm eklenecek, toplam arsa payı ${formatNumber(total)}.', ok: 'Ekle') || !mounted) return;
    if (await runAction(context, () async {
      final r = await apiClient.post('/units', {'units': units});
      return {...r, 'message': '${r['created'] ?? units.length} bölüm eklendi'};
    })) {
      await _list.currentState?.reload();
    }
  }

  Future<void> _clearance(Map u) async {
    try {
      final r = await apiClient.post('/finance/clearance-certificates', {'unit_id': u['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Borcu yoktur belgesi üretildi (geçerlilik ${formatDate(r['expires_at'])}). ${r['note'] ?? ''}')));
      await openDownload(context, '/finance/clearance-certificates/${r['id']}/pdf', 'borcu-yoktur-belgesi.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bağımsız bölümler'), actions: [
        if (_canWrite) IconButton(tooltip: 'Toplu ekle', icon: const Icon(Icons.playlist_add), onPressed: _bulk),
      ]),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Bölüm')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/units'),
        empty: 'Henüz bağımsız bölüm yok',
        header: (all) {
          final missing = all.where((u) => u['owner_missing'] == true).map((u) => '${(u['block'] ?? '').toString().isEmpty ? '' : '${u['block']}-'}${u['door_number']}').toList();
          return Column(children: [
            StatRow([
              ('Bölüm', '${all.length}'),
              ('Toplam arsa payı', formatNumber(all.fold<num>(0, (a, u) => a + toNum(u['share_ratio'])))),
              ('Ticari', '${all.where((u) => u['is_commercial'] == true).length}'),
              ('Boş', '${all.where((u) => u['occupancy'] == 'VACANT').length}'),
              ('Kayıtsız', '${all.where((u) => u['occupancy'] == 'UNREGISTERED').length}'),
            ]),
            if (missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Maliki kayıtlı olmayan daireler: ${missing.join(', ')} — malik giderleri yönetimde bekler; maliki kaydedin.',
                    style: const TextStyle(color: Colors.orange)),
              ),
          ]);
        },
        itemBuilder: (context, u, reload) {
          final occ = _occupancy[u['occupancy']];
          final noArea = _areaRequired.contains(u['unit_type']) && !(toNum(u['net_area_m2']) > 0);
          return ListTile(
            title: Text('${(u['block'] ?? '').toString().isEmpty ? '' : '${u['block']}-'}${u['door_number']} · ${_types.firstWhere((t) => t.$1 == u['unit_type'], orElse: () => ('', '${u['unit_type']}')).$2}'
                '${u['is_commercial'] == true ? ' · Ticari' : ''}'),
            subtitle: Text([
              'Kat ${u['floor']} · arsa payı ${formatNumber(toNum(u['share_ratio']))}',
              noArea ? 'Net m² EKSİK' : 'Net ${formatNumber(toNum(u['net_area_m2']))} m²${toNum(u['gross_area_m2']) > 0 ? ' · brüt ${formatNumber(toNum(u['gross_area_m2']))} m²' : ''}',
            ].join('\n'), style: noArea ? const TextStyle(color: Colors.red) : null),
            isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (occ != null) StatusChip(occ.$1, color: occ.$2),
              if (_canWrite)
                RowMenu([
                  ('Düzenle', () => _edit(u)),
                  ('Borcu yoktur belgesi', () => _clearance(u)),
                ]),
            ]),
          );
        },
      ),
    );
  }
}
