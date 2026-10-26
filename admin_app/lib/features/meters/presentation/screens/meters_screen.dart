// Sayaçlar.
//
// DÜZELTME (2026-09-26): süzgeç `type` parametresiyle gönderiliyordu (sunucu
// `meter_type` bekler — her sekme bütün sayaçları gösteriyordu); `last_reading`
// / `last_read_at` alanları yoktu ve daire yerine kimlik gösteriliyordu.
// FAZ H.7: sayaç ekleme/değiştirme/pasife alma, paylaştırma, pusulalar ve
// pusula itirazları panelle eşit.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const meterTypes = {
  'HEAT': 'Isı payölçer',
  'WATER_COLD': 'Soğuk su',
  'WATER_HOT': 'Sıcak su',
  'GAS': 'Doğalgaz',
  'ELECTRIC': 'Elektrik',
};

String _kurus(Object? v) => formatTry(toNum(v) / 100);

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> {
  String? _type;
  final _meters = GlobalKey<ApiListState>();
  bool _canWrite = false;
  bool _canOps = false;

  @override
  void initState() {
    super.initState();
    apiClient.getCurrentUserRoles().then((r) {
      if (mounted) {
        setState(() {
          _canWrite = r.any(writeRoles.contains);
          _canOps = _canWrite || r.contains('STAFF');
        });
      }
    });
  }

  Future<void> _addMeter() async {
    final units = await unitOptions();
    if (!mounted) return;
    if (await formAction(context, 'Sayaç ekle', [
      FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true),
      FSpec('meter_type', 'Tür', type: FType.select, options: [for (final e in meterTypes.entries) (e.key, e.value)], initial: 'HEAT', required: true),
      const FSpec('serial_number', 'Seri no', required: true),
      const FSpec('brand', 'Marka'),
    ], (v) => apiClient.post('/meters', v), success: 'Sayaç kaydedildi')) {
      await _meters.currentState?.reload();
    }
  }

  Future<void> _replace(Map m, Future<void> Function() reload) async {
    if (await formAction(context, 'Sayaç değişimi — ${m['unit_name'] ?? ''} ${m['serial_number'] ?? ''}', [
      const FSpec('removal_value', 'Eski sayacın söküm endeksi', required: true),
      FSpec('replaced_on', 'Değişim tarihi', type: FType.date, initial: DateTime.now(), required: true),
      const FSpec('new_serial_number', 'Yeni sayacın seri no', required: true),
      const FSpec('new_initial_value', 'Yeni sayacın montaj endeksi', initial: '0', required: true),
      const FSpec('reason', 'Gerekçe', required: true),
    ], (v) => apiClient.post('/meters/${m['id']}/replace', v),
        note: 'Söküm endeksi okuma olarak yazılır ve eski sayaç pasife alınır; dönem tüketimi iki sayaçtan toplanır.',
        success: 'Sayaç değiştirildi')) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sayaçlar'),
          actions: [if (_canWrite) IconButton(tooltip: 'Sayaç ekle', icon: const Icon(Icons.add_circle_outline), onPressed: _addMeter)],
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Sayaçlar'), Tab(text: 'Okumalar'), Tab(text: 'Paylaştır'), Tab(text: 'Pusulalar'), Tab(text: 'İtirazlar')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/meters/reading'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Okuma gir'),
        ),
        body: TabBarView(children: [
          Column(children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final t in [null, ...meterTypes.keys])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t == null ? 'Tümü' : meterTypes[t]!),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ApiList(
                key: _meters,
                token: _type,
                load: () => apiClient.getList('/meters', query: {'meter_type': _type}),
                empty: 'Sayaç yok',
                itemBuilder: (context, m, reload) => ListTile(
                  title: Text('${m['unit_name'] ?? ''} · ${meterTypes['${m['meter_type']}'] ?? m['meter_type']}'),
                  subtitle: Text([
                    'Seri: ${m['serial_number'] ?? '—'}',
                    if (m['last_reading_value'] != null)
                      'Son okuma: ${m['last_reading_value']} (${formatDate(m['last_reading_date'])})'
                    else
                      'Henüz okuma yok',
                  ].join(' · ')),
                  trailing: m['is_active'] == false
                      ? const StatusChip('Pasif', color: Colors.grey)
                      : RowMenu([
                          if (_canOps) ('Sayaç değiştir', () => _replace(m, reload)),
                          if (_canWrite)
                            ('Pasife al', () async {
                              if (await confirmAction(context, 'Sayacı pasife al', '${m['serial_number']} pasife alınsın mı? Okuma geçmişi korunur.',
                                  () => apiClient.delete('/meters/${m['id']}'), ok: 'Pasife al')) {
                                await reload();
                              }
                            }),
                        ]),
                ),
              ),
            ),
          ]),
          ApiList(
            load: () => apiClient.getList('/meter-readings'),
            empty: 'Okuma yok',
            itemBuilder: (context, r, _) => ListTile(
              title: Text('${r['unit_name'] ?? '—'} · ${r['serial_number'] ?? ''}'),
              subtitle: Text('${formatDate(r['reading_date'])} · ${r['previous_value']} → ${r['current_value']}'
                  '${r['reading_type'] == 'ESTIMATED' ? ' · tahmini' : ''} · ${r['reader_name'] ?? '—'}'),
              trailing: Text('${r['consumption']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          _AllocateTab(canWrite: _canWrite),
          ApiList(
            load: () => apiClient.getList('/consumption/statements'),
            empty: 'Yayımlanmış paylaştırma yok',
            itemBuilder: (context, a, _) => ListTile(
              title: Text('${meterTypes['${a['meter_type']}'] ?? a['meter_type']} · ${formatDate(a['period_from'])} – ${formatDate(a['period_to'])}'),
              subtitle: Text('Toplam ${_kurus(a['total_kurus'])} · tüketim %${a['consumption_share_pct'] ?? '—'} · alan %${a['area_share_pct'] ?? '—'}\nYayım ${formatDate(a['published_at'])}'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => openDownload(context, '/consumption/statements/${a['id']}/pdf', 'tuketim-pusulasi.pdf'),
              ),
            ),
          ),
          ApiList(
            load: () => apiClient.getList('/consumption/objections'),
            empty: 'İtiraz yok',
            itemBuilder: (context, o, reload) => ListTile(
              title: Text('${o['unit'] ?? ''} · ${meterTypes['${o['meter_type']}'] ?? o['meter_type']} · ${_kurus(o['total_kurus'])}'),
              subtitle: Text([
                '${formatDate(o['period_from'])} – ${formatDate(o['period_to'])}',
                '${o['user_name'] ?? ''} (${formatDate(o['created_at'])}): ${o['reason'] ?? ''}',
                if (o['status'] != 'OPEN') '${o['status'] == 'ACCEPTED' ? 'Kabul' : 'Ret'}: ${o['response'] ?? ''} — ${o['responded_by_name'] ?? ''}',
              ].join('\n')),
              isThreeLine: true,
              trailing: o['status'] == 'OPEN'
                  ? (_canWrite
                      ? TextButton(
                          onPressed: () async {
                            if (await formAction(context, 'İtiraz — ${o['unit'] ?? ''}', const [
                              FSpec('decision', 'Karar', type: FType.select, options: [('ACCEPTED', 'Kabul'), ('REJECTED', 'Ret')], initial: 'ACCEPTED', required: true),
                              FSpec('response', 'Açıklama', type: FType.multiline, required: true,
                                  hint: 'Kabulde düzeltmenin nasıl yapılacağını yazın; yayımlanmış pusula değişmez'),
                            ], (v) => apiClient.post('/consumption/objections/${o['id']}/respond', v), note: 'Gerekçe: ${o['reason'] ?? ''}')) {
                              await reload();
                            }
                          },
                          child: const Text('Yanıtla'),
                        )
                      : const StatusChip('Yanıt bekliyor', color: Colors.orange))
                  : StatusChip(o['status'] == 'ACCEPTED' ? 'Kabul' : 'Ret', color: o['status'] == 'ACCEPTED' ? Colors.green : Colors.red),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Dönem giderini paylaştırma: önce hesap, istenirse yayım (pusulalar değiştirilemez).
class _AllocateTab extends StatefulWidget {
  final bool canWrite;
  const _AllocateTab({required this.canWrite});

  @override
  State<_AllocateTab> createState() => _AllocateTabState();
}

class _AllocateTabState extends State<_AllocateTab> {
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _last;

  Future<void> _run({bool confirmOutliers = false}) async {
    final v = confirmOutliers
        ? _last
        : await showForm(context, 'Dönem giderini paylaştır', [
            FSpec('meter_type', 'Sayaç türü', type: FType.select, options: [for (final e in meterTypes.entries) (e.key, e.value)], initial: 'HEAT', required: true),
            const FSpec('from', 'Başlangıç', type: FType.date, required: true),
            FSpec('to', 'Bitiş', type: FType.date, initial: DateTime.now(), required: true),
            const FSpec('total_amount_try', 'Toplam gider (TL)', type: FType.decimal, required: true),
            const FSpec('publish', 'Sakinlere yayımla', type: FType.toggle,
                hint: 'Pusulalar saklanır ve sonradan değiştirilemez; okuması eksik bölüm varken yayımlanmaz'),
          ], submit: 'Hesapla');
    if (v == null || !mounted) return;
    _last = v;
    try {
      final r = await apiClient.post('/consumption/allocate', {...v, if (confirmOutliers) 'confirm_outliers': true});
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      final msg = errorText(e);
      if (v['publish'] == true && msg.contains('medyan') && !confirmOutliers) {
        if (await confirm(context, 'Olağandışı tüketim', '$msg\n\nOkumaları kontrol ettiyseniz yayımı teyit edin (teyit eden ve bölümler pusulayla saklanır).', ok: 'Teyit et ve yayımla')) {
          await _run(confirmOutliers: true);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final alloc = (r?['allocation'] as Map?) ?? const {};
    final units = ((alloc['units'] as List?) ?? const []).whereType<Map>().toList();
    final outliers = ((r?['outliers'] as List?) ?? const []).whereType<Map>().toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Isıtma gideri ölçülen tüketime ve net kullanım alanına göre paylaştırılır (oranlar mevzuat tablosundan). '
          'Sonuç kuruş hassasiyetindedir; paylar toplamı tutara eşittir.'),
      FutureBuilder<Map<String, dynamic>>(
        future: widget.canWrite ? apiClient.getMap('/consumption/area-check') : Future.value(const <String, dynamic>{}),
        builder: (context, s) {
          final d = s.data;
          if (d == null || d['ready'] != false) return const SizedBox.shrink();
          final missing = ((d['missing'] as List?) ?? const []).whereType<Map>().map((m) => '${m['unit']}').toList();
          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${missing.length} bölümün net kullanım alanı eksik: ${missing.take(20).join(', ')}${missing.length > 20 ? ' …' : ''}. ${d['note'] ?? ''}'),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: widget.canWrite ? () => _run() : null, icon: const Icon(Icons.calculate), label: const Text('Hesapla / yayımla')),
      if (r != null) ...[
        const SizedBox(height: 16),
        if (r['warning'] != null) Text('${r['warning']}', style: const TextStyle(color: Colors.orange)),
        if (outliers.isNotEmpty)
          Text('Olağandışı tüketim: ${outliers.map((o) => '${o['unit_name']}: ${o['intensity']} (medyan ${o['median']}, ${o['ratio']} kat)').join(' · ')}. ${r['outlier_warning'] ?? ''}',
              style: const TextStyle(color: Colors.orange)),
        Text('${r['basis_note'] ?? ''} ${r['note'] ?? ''}'),
        const SizedBox(height: 8),
        Text('Toplam ${_kurus(alloc['total_kurus'])} = tüketim payı ${_kurus(alloc['consumption_part_kurus'])} + alan payı ${_kurus(alloc['area_part_kurus'])}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        for (final u in units)
          ListTile(
            dense: true,
            title: Text('${u['unit_name']}${u['meter_replaced'] == true ? ' (sayaç değişti)' : ''}'),
            subtitle: Text('${u['first_value'] ?? '—'} → ${u['last_value'] ?? '—'} · tüketim ${u['consumption']} · alan ${u['usable_area']} m²'),
            trailing: Text(_kurus(u['total_kurus']), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    ]);
  }
}
