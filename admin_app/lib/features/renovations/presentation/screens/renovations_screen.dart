// Tadilat izinleri (FAZ H.7, panel /dashboard/renovations ile eşit). Para cezası yoktur: site yönetimi
// idari para cezası veremez (Kabahatler K. m.22); ihlalde çalışma durdurulur, hasar teminattan
// karşılanır, gerekirse sulh hukuk mahkemesine başvurulur (KMK m.33).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _scopes = [
  ('INTERIOR', 'İç tadilat (taşıyıcıya dokunmayan)'),
  ('STRUCTURAL', 'Taşıyıcı sistem / esaslı tadilat'),
  ('COMMON_AREA', 'Ortak yerde değişiklik'),
  ('FACADE', 'Dış cephe / balkon / pencere'),
];
const _scopeHint = {
  'INTERIOR': 'Yönetim onayı yeterlidir.',
  'STRUCTURAL': 'Yapı ruhsatı / belediye izni gerekir (İmar K. m.21). Anayapıya zarar verecek değişiklik yapılamaz (KMK m.19/2).',
  'COMMON_AREA': 'Bütün kat maliklerinin 4/5 yazılı rızası ya da bu nisapla alınmış genel kurul kararı gerekir (KMK m.19/2).',
  'FACADE': 'Bütün kat maliklerinin 4/5 yazılı rızası ya da bu nisapla alınmış genel kurul kararı gerekir (KMK m.19/2).',
};
const _status = {
  'PENDING': ('Onay bekliyor', Colors.orange), 'APPROVED': ('Onaylandı', Colors.green), 'REJECTED': ('Reddedildi', Colors.red),
  'STOPPED': ('Durduruldu', Colors.red), 'COMPLETED': ('Tamamlandı', Colors.grey), 'CANCELLED': ('Geri çekildi', Colors.grey),
};

String _scope(Object? s) => _scopes.firstWhere((e) => e.$1 == s, orElse: () => ('', '$s')).$2;

class RenovationsScreen extends StatefulWidget {
  const RenovationsScreen({super.key});

  @override
  State<RenovationsScreen> createState() => _RenovationsScreenState();
}

class _RenovationsScreenState extends State<RenovationsScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _create() async {
    final units = await unitOptions();
    if (!mounted) return;
    final v = await showForm(context, 'Tadilat başvurusu', [
      FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true),
      const FSpec('scope', 'Kapsam', type: FType.select, options: _scopes, initial: 'INTERIOR', required: true),
      FSpec('start_date', 'Başlangıç', type: FType.date, initial: DateTime.now(), required: true),
      FSpec('end_date', 'Bitiş', type: FType.date, initial: DateTime.now(), required: true),
      const FSpec('contractor_name', 'Müteahhit / usta'),
      const FSpec('contractor_phone', 'Müteahhit telefonu'),
      const FSpec('description', 'Yapılacak iş', type: FType.multiline, required: true),
    ], note: _scopeHint.values.join('\n'));
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.post('/renovations', v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Başvuru kaydedildi. ${r['requirement'] ?? ''}')));
      await _list.currentState?.reload();
      final id = (r['permit'] as Map?)?['id'];
      if (id != null && mounted) await _open('$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PermitDetail(id: id, canWrite: _canWrite)));
    await _list.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tadilat izinleri')),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Başvuru')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/renovations'),
        empty: 'Tadilat izni yok',
        itemBuilder: (context, p, _) {
          final st = _status[p['status']];
          return ListTile(
            title: Text('${p['unit'] ?? ''} · ${_scope(p['scope'])}'),
            subtitle: Text('${p['applicant_name'] ?? '—'} · ${formatDate(p['start_date'])} – ${formatDate(p['end_date'])}'
                '${toNum(p['deposit_amount']) > 0 ? ' · teminat ${formatTry(toNum(p['deposit_amount']))}' : ''}'),
            trailing: st == null ? null : StatusChip(st.$1, color: st.$2),
            onTap: () => _open('${p['id']}'),
          );
        },
      ),
    );
  }
}

class _PermitDetail extends StatefulWidget {
  final String id;
  final bool canWrite;
  const _PermitDetail({required this.id, required this.canWrite});

  @override
  State<_PermitDetail> createState() => _PermitDetailState();
}

class _PermitDetailState extends State<_PermitDetail> {
  int _token = 0;
  String get _id => widget.id;
  void _changed() => setState(() => _token++);

  Future<void> _consent() async {
    final owners = await optionsFrom('/residents', (r) => '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}', id: 'user_id', query: {'role': 'OWNER'})
        .catchError((_) => <(String, String)>[]);
    final uniq = {for (final o in owners) o.$1: o}.values.toList();
    if (!mounted) return;
    if (await formAction(context, 'Kat maliki yazılı rızası', [
      FSpec('owner_user_id', 'Kat maliki', type: FType.select, options: uniq, required: true),
      const FSpec('document_ref', 'Belge referansı', hint: 'İmzalı muvafakatname no'),
    ], (v) async {
      final r = await apiClient.post('/renovations/$_id/consents', v);
      return {...r, 'message': 'Rıza kaydedildi: ${r['consent_count']} / ${r['consent_required']} (${r['owner_count']} kat maliki)'};
    }, note: 'Rıza, kat malikinin imzalı yazılı beyanı alındıktan sonra kaydedilir (KMK m.19/2: bütün kat maliklerinin beşte dördü, kişi sayısıyla).')) {
      _changed();
    }
  }

  Future<void> _approve(Map p) async {
    final common = p['scope'] == 'COMMON_AREA' || p['scope'] == 'FACADE';
    if (await formAction(context, 'Onayla', [
      const FSpec('conditions', 'Koşullar', hint: 'Asansör koruması, moloz taahhüdü…'),
      const FSpec('deposit_amount', 'Teminat (TL)', type: FType.decimal),
      if (p['scope'] == 'STRUCTURAL') const FSpec('permit_ref', 'Yapı ruhsatı / belediye izni no', required: true),
      if (common) const FSpec('agenda_item_id', 'Genel kurul gündem maddesi (rıza yerine, isteğe bağlı)'),
    ], (v) async {
      final r = await apiClient.post('/renovations/$_id/approve', {'deposit_amount': 0, ...v});
      return {...r, 'message': 'İzin onaylandı. Başvuran: ${(r['notification'] as Map?)?['note'] ?? ''} Komşular: ${(r['neighbors'] as Map?)?['note'] ?? ''}'};
    }, submit: 'Onayla')) {
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tadilat izni')),
      body: ApiObject(
        key: ValueKey(_token),
        load: () => apiClient.getMap('/renovations/$_id'),
        builder: (context, d, _) {
          final p = Map<String, dynamic>.from((d['permit'] as Map?) ?? {});
          final consents = ((d['consents'] as List?) ?? const []).whereType<Map>().toList();
          final st = _status[p['status']];
          final common = p['scope'] == 'COMMON_AREA' || p['scope'] == 'FACADE';
          final w = widget.canWrite;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text('${p['unit'] ?? ''}', style: Theme.of(context).textTheme.titleLarge)),
              if (st != null) StatusChip(st.$1, color: st.$2),
            ]),
            Text('${_scope(p['scope'])} · ${formatDate(p['start_date'])} – ${formatDate(p['end_date'])}'),
            const SizedBox(height: 8),
            Text('${p['description'] ?? ''}'),
            const SizedBox(height: 8),
            Text([
              if (p['contractor_name'] != null) 'Müteahhit: ${p['contractor_name']} ${p['contractor_phone'] ?? ''}',
              if (p['work_hours'] != null) 'Çalışma saatleri: ${p['work_hours']}',
              if (p['conditions'] != null) 'Koşullar: ${p['conditions']}',
              if (toNum(p['deposit_amount']) > 0) 'Teminat: ${formatTry(toNum(p['deposit_amount']))}${p['deposit_refunded'] != null ? ' · iade ${formatTry(toNum(p['deposit_refunded']))}' : ''}',
              if (p['permit_ref'] != null) 'Ruhsat / izin: ${p['permit_ref']}',
              if (p['decision_note'] != null) 'Ret gerekçesi: ${p['decision_note']}',
              if (p['stop_reason'] != null) 'Durdurma gerekçesi: ${p['stop_reason']}',
              if (p['completion_note'] != null) 'Kapanış notu: ${p['completion_note']}',
            ].join('\n'), style: Theme.of(context).textTheme.bodySmall),
            Text(_scopeHint[p['scope']] ?? '', style: Theme.of(context).textTheme.bodySmall),
            if (common) ...[
              const Divider(),
              Text('Kat maliki yazılı rızaları (${consents.length}${p['consent_required'] != null ? ' / ${p['consent_required']}' : ''})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              for (final c in consents) ListTile(dense: true, title: Text('${c['owner_name']}'), subtitle: Text('${formatDate(c['consented_on'])} · ${c['document_ref'] ?? '—'}')),
              if (w && p['status'] == 'PENDING') OutlinedButton.icon(onPressed: _consent, icon: const Icon(Icons.how_to_reg), label: const Text('Rıza kaydet')),
            ],
            const Divider(),
            if (w && p['status'] == 'PENDING')
              Wrap(spacing: 8, children: [
                FilledButton(onPressed: () => _approve(p), child: const Text('Onayla')),
                OutlinedButton(
                  onPressed: () async {
                    if (await reasonAction(context, 'Başvuruyu reddet', (r) => apiClient.post('/renovations/$_id/reject', {'reason': r}), success: 'Kaydedildi; başvurana bildirildi')) _changed();
                  },
                  child: const Text('Reddet'),
                ),
              ]),
            if (w && p['status'] == 'APPROVED') ...[
              Wrap(spacing: 8, children: [
                FilledButton(
                  onPressed: () async {
                    if (await formAction(context, 'Denetle ve kapat', [
                      if (toNum(p['deposit_amount']) > 0)
                        FSpec('deposit_refunded', 'İade edilecek teminat (en çok ${formatTry(toNum(p['deposit_amount']))})', type: FType.decimal, initial: p['deposit_amount']),
                      const FSpec('note', 'Denetim notu', type: FType.multiline, hint: 'Teminattan kesinti yapılıyorsa hasar tespiti zorunludur'),
                    ], (v) => apiClient.post('/renovations/$_id/complete', {'deposit_refunded': 0, ...v}), success: 'İzin kapatıldı')) {
                      _changed();
                    }
                  },
                  child: const Text('Denetle ve kapat'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    if (await reasonAction(context, 'Çalışmayı durdur', (r) => apiClient.post('/renovations/$_id/stop', {'reason': r}), success: 'Kaydedildi; başvurana bildirildi')) _changed();
                  },
                  child: const Text('Çalışmayı durdur'),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Para cezası uygulanmaz; ihlalde çalışma durdurulur, hasar teminattan karşılanır (KMK m.19/3, m.33).', style: TextStyle(fontSize: 12)),
            ],
          ]);
        },
      ),
    );
  }
}
