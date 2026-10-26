// Acil durum ve afet (FAZ H.7, panel /dashboard/emergency ile eşit): durum bildirimi çağrısı ve
// yanıtları, toplanma alanı / kritik altyapı, acil iletişim, tatbikat raporu, sakin acil bilgi kartları.
// Bilgi kartı özel nitelikli veridir (KVKK m.6): her görüntüleme denetim kaydına yazılır.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _pointKind = [
  ('ASSEMBLY_AREA', 'Toplanma alanı'), ('WATER_VALVE', 'Ana su vanası'), ('GAS_VALVE', 'Gaz vanası'), ('ELECTRIC_PANEL', 'Elektrik panosu'),
  ('GENERATOR', 'Jeneratör'), ('FIRE_PUMP', 'Yangın pompası'), ('FIRE_CABINET', 'Yangın dolabı / tüp'), ('FIRST_AID', 'İlk yardım dolabı'),
  ('SHELTER', 'Sığınak'), ('OTHER', 'Diğer'),
];
const _contactCat = [
  ('EMERGENCY', 'Acil'), ('UTILITY', 'Altyapı arıza'), ('HOSPITAL', 'Hastane'), ('MANAGEMENT', 'Yönetim'),
  ('SECURITY', 'Güvenlik'), ('TECHNICAL', 'Teknik servis'), ('OTHER', 'Diğer'),
];
const _kind = [('FIRE', 'Yangın'), ('EARTHQUAKE', 'Deprem'), ('EVACUATION', 'Tahliye'), ('FLOOD', 'Sel'), ('OTHER', 'Diğer')];

String _l(List<(String, String)> list, Object? v) => list.firstWhere((e) => e.$1 == v, orElse: () => ('', '$v')).$2;

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _canWrite = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  void _changed() => setState(() => _token++);

  Widget _addButton(String label, Future<void> Function() onTap) => _canWrite
      ? Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(label)),
          ),
        )
      : const SizedBox.shrink();

  Future<void> _openCheck() async {
    final v = await showForm(context, 'Durum bildirimi çağrısı', const [
      FSpec('kind', 'Tür', type: FType.select, options: _kind, initial: 'EARTHQUAKE', required: true),
      FSpec('title', 'Başlık', initial: 'Deprem sonrası durum bildirimi', required: true),
    ], note: 'Bütün sakinlere "Güvendeyim / Yardım gerekiyor" yanıtı istenen bildirim gider. Yardım talepleri yönetime anında iletilir.', submit: 'Çağrı başlat');
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.post('/emergency/checks', v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Çağrı açıldı. ${(r['notification'] as Map?)?['note'] ?? ''}')));
      _changed();
      final id = (r['check'] as Map?)?['id'];
      if (id != null) await _responses('$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _responses(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Responses(id: id, canWrite: _canWrite)));
    _changed();
  }

  Future<void> _cards() async {
    try {
      final r = await apiClient.getMap('/emergency/cards');
      if (!mounted) return;
      final cards = ((r['data'] as List?) ?? const []).whereType<Map>().toList();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Sakin acil bilgi kartları')),
          body: ListView(children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('${r['note'] ?? ''}', style: const TextStyle(fontSize: 12))),
            if (cards.isEmpty) const ListTile(title: Text('Kart yok')),
            for (final c in cards)
              ListTile(
                title: Text('${c['unit']} · ${c['resident_name'] ?? ''}'),
                subtitle: Text('${c['needs'] ?? ''}\nHane ${c['household_count'] ?? '—'} · yakını ${[c['contact_name'], c['contact_phone']].where((x) => x != null).join(' · ')}'),
                isThreeLine: true,
              ),
          ]),
        ),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Acil durum ve afet'),
          actions: [if (_canWrite) IconButton(tooltip: 'Acil bilgi kartları (kayda geçer)', icon: const Icon(Icons.medical_information), onPressed: _cards)],
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Durum bildirimi'), Tab(text: 'Noktalar'), Tab(text: 'İletişim'), Tab(text: 'Tatbikatlar')]),
        ),
        body: TabBarView(children: [
          ApiList(
            token: _token,
            load: () => apiClient.getList('/emergency/checks'),
            empty: 'Durum bildirimi çağrısı yok',
            header: (_) => Column(children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Her türlü acil durumda 112 aranır.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ),
              _addButton('Çağrı başlat', _openCheck),
            ]),
            itemBuilder: (context, s, _) => ListTile(
              leading: Icon(s['status'] == 'OPEN' ? Icons.campaign : Icons.check, color: s['status'] == 'OPEN' ? Colors.red : null),
              title: Text('${s['title'] ?? ''}'),
              subtitle: Text('${_l(_kind, s['kind'])} · ${formatDateTime(s['opened_at'])}\n'
                  '${s['responded']} / ${s['units']} daire yanıt · ${s['need_help']} yardım talebi'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _responses('${s['id']}'),
            ),
          ),
          ApiObject(
            key: ValueKey('p$_token'),
            load: () => apiClient.getMap('/emergency/info'),
            builder: (context, d, reload) {
              final points = ((d['points'] as List?) ?? const []).whereType<Map>().toList();
              return ListView(children: [
                _addButton('Nokta ekle', () async {
                  if (await formAction(context, 'Nokta ekle', const [
                    FSpec('kind', 'Tür', type: FType.select, options: _pointKind, initial: 'ASSEMBLY_AREA', required: true),
                    FSpec('name', 'Ad', required: true),
                    FSpec('location', 'Konum', required: true, hint: 'ör. B blok bodrum, kazan dairesi girişi solda'),
                    FSpec('note', 'Not'),
                  ], (v) => apiClient.post('/emergency/points', v), success: 'Eklendi')) {
                    await reload();
                  }
                }),
                if (points.isEmpty) const ListTile(title: Text('Kayıt yok')),
                for (final p in points)
                  ListTile(
                    title: Text('${p['name']}'),
                    subtitle: Text('${_l(_pointKind, p['kind'])} · ${p['location']}${(p['note'] ?? '').toString().isNotEmpty ? '\n${p['note']}' : ''}'),
                    trailing: _canWrite
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmAction(context, 'Sil', '${p['name']} silinsin mi?', () => apiClient.delete('/emergency/points/${p['id']}'), ok: 'Sil', success: 'Silindi')) {
                                await reload();
                              }
                            },
                          )
                        : null,
                  ),
              ]);
            },
          ),
          ApiObject(
            key: ValueKey('c$_token'),
            load: () => apiClient.getMap('/emergency/info'),
            builder: (context, d, reload) {
              final contacts = ((d['contacts'] as List?) ?? const []).whereType<Map>().toList();
              return ListView(children: [
                _addButton('İletişim ekle', () async {
                  if (await formAction(context, 'Acil iletişim ekle', const [
                    FSpec('category', 'Kategori', type: FType.select, options: _contactCat, initial: 'UTILITY', required: true),
                    FSpec('name', 'Ad', required: true),
                    FSpec('phone', 'Telefon', required: true),
                    FSpec('note', 'Not'),
                    FSpec('sort_order', 'Sıra', type: FType.integer, initial: 0),
                  ], (v) => apiClient.post('/emergency/contacts', {'sort_order': 0, ...v}), success: 'Eklendi')) {
                    await reload();
                  }
                }),
                ListTile(
                  leading: const Icon(Icons.local_phone, color: Colors.red),
                  title: Text('Ulusal acil: ${d['national_emergency'] ?? '112'}'),
                  onTap: () => launchUrl(Uri.parse('tel:${d['national_emergency'] ?? '112'}')),
                ),
                for (final c in contacts)
                  ListTile(
                    title: Text('${c['name']}'),
                    subtitle: Text('${_l(_contactCat, c['category'])} · ${c['phone']}'),
                    onTap: () => launchUrl(Uri.parse('tel:${c['phone']}')),
                    trailing: _canWrite
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmAction(context, 'Sil', '${c['name']} silinsin mi?', () => apiClient.delete('/emergency/contacts/${c['id']}'), ok: 'Sil', success: 'Silindi')) {
                                await reload();
                              }
                            },
                          )
                        : null,
                  ),
              ]);
            },
          ),
          ApiList(
            token: _token,
            load: () => apiClient.getList('/emergency/drills'),
            empty: 'Tatbikat kaydı yok',
            header: (_) => Column(children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Personel çalıştıran site yönetimi işverendir: yılda en az bir tatbikat yapılır ve eksiklikleri içeren rapor tutulur.',
                    style: TextStyle(fontSize: 12)),
              ),
              _addButton('Tatbikat raporu', () async {
                if (await formAction(context, 'Tatbikat raporu', [
                  const FSpec('kind', 'Tür', type: FType.select, options: _kind, initial: 'EARTHQUAKE', required: true),
                  FSpec('drill_date', 'Tarih', type: FType.date, initial: DateTime.now(), required: true),
                  const FSpec('participants', 'Katılımcı sayısı', type: FType.integer),
                  const FSpec('findings', 'Görülen eksiklikler', type: FType.multiline, required: true, hint: "Eksiklik yoksa 'eksiklik görülmedi' yazın"),
                  const FSpec('corrective_actions', 'Düzeltici ve önleyici faaliyetler', type: FType.multiline),
                ], (v) => apiClient.post('/emergency/drills', v), success: 'Tatbikat kaydedildi')) {
                  _changed();
                }
              }),
            ]),
            itemBuilder: (context, x, _) => ListTile(
              title: Text('${formatDate(x['drill_date'])} · ${_l(_kind, x['kind'])}${x['participants'] != null ? ' · ${x['participants']} kişi' : ''}'),
              subtitle: Text('Eksiklikler: ${x['findings'] ?? ''}${x['corrective_actions'] != null ? '\nDüzeltici: ${x['corrective_actions']}' : ''}'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Responses extends StatelessWidget {
  final String id;
  final bool canWrite;
  const _Responses({required this.id, required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Durum yanıtları')),
      body: ApiObject(
        load: () => apiClient.getMap('/emergency/checks/$id/responses'),
        builder: (context, d, reload) {
          final c = (d['check'] as Map?) ?? const {};
          final rows = ((d['data'] as List?) ?? const []).whereType<Map>().toList();
          final silent = ((d['silent_units'] as List?) ?? const []).map((e) => '$e').toList();
          return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
            ListTile(
              title: Text('${c['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${c['safe']} güvende · ${c['need_help']} yardım · ${c['responded']} / ${c['units']} daire yanıt verdi'),
            ),
            for (final x in rows)
              ListTile(
                leading: Icon(x['status'] == 'NEED_HELP' ? Icons.sos : Icons.verified_user, color: x['status'] == 'NEED_HELP' ? Colors.red : Colors.green),
                title: Text('${x['unit'] ?? '—'} · ${x['name'] ?? ''}'),
                subtitle: Text('${formatDateTime(x['responded_at'])}${(x['note'] ?? '').toString().isNotEmpty ? '\n${x['note']}' : ''}'),
              ),
            if (silent.isNotEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text('Henüz yanıt vermeyen daireler: ${silent.join(', ')}', style: const TextStyle(color: Colors.orange))),
            if (canWrite && c['status'] == 'OPEN')
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () async {
                    if (await confirmAction(context, 'Çağrıyı kapat', 'Yeni yanıt alınmaz.', () => apiClient.post('/emergency/checks/$id/close'), ok: 'Kapat', success: 'Çağrı kapatıldı')) {
                      await reload();
                    }
                  },
                  child: const Text('Çağrıyı kapat'),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
