// Kural ihlalleri (FAZ H.7, panel /dashboard/violations ile eşit). Kurallar yönetim planına atıflıdır
// (KMK m.28). Para cezası yoktur (Kabahatler K. m.22); süreç uyarı → ihtar → sulh hukuk (KMK m.33).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _category = [
  ('NOISE', 'Gürültü'), ('PET', 'Evcil hayvan'), ('PARKING', 'Otopark'), ('WASTE', 'Çöp / atık'),
  ('COMMON_AREA', 'Ortak alan kullanımı'), ('RENOVATION', 'Tadilat'), ('OTHER', 'Diğer'),
];
const _status = {
  'OPEN': ('Doğrulama bekliyor', Colors.orange), 'VERIFIED': ('Doğrulandı', Colors.blue),
  'DISMISSED': ('Doğrulanmadı', Colors.grey), 'RESOLVED': ('Kapandı', Colors.green),
};
const _stage = {
  'NONE': '—', 'VERBAL_WARNING': 'Sözlü uyarı', 'WRITTEN_WARNING': 'Yazılı uyarı', 'FORMAL_NOTICE': 'İhtar', 'LEGAL': 'Hukuki yol (KMK m.33)',
};
const _stageOrder = ['NONE', 'VERBAL_WARNING', 'WRITTEN_WARNING', 'FORMAL_NOTICE', 'LEGAL'];
const _event = {
  'REPORTED': 'Bildirildi', 'VERIFIED': 'Doğrulandı', 'DISMISSED': 'Doğrulanmadı', 'RESPONSE': 'Savunma', 'RESOLVED': 'Kapatıldı', ..._stage,
};

class ViolationsScreen extends StatefulWidget {
  const ViolationsScreen({super.key});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  final _list = GlobalKey<ApiListState>();
  final _rules = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _report() async {
    final rules = await apiClient.getList('/site-rules').catchError((_) => <dynamic>[]);
    final units = await unitOptions();
    if (!mounted) return;
    final ruleOpts = [for (final r in rules.whereType<Map>()) if (r['is_active'] == true) ('${r['id']}', '${r['title']}')];
    final v = await showForm(context, 'İhlal kaydet', [
      FSpec('rule_id', 'Kural', type: FType.select, options: ruleOpts, required: true),
      FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true),
      const FSpec('description', 'Ne oldu?', type: FType.multiline, required: true),
    ]);
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.post('/violations', v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(['İhlal kaydedildi', r['note']].whereType<String>().join(' — '))));
      await _list.currentState?.reload();
      final id = (r['violation'] as Map?)?['id'];
      if (id != null && mounted) await _open('$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ViolationDetail(id: id, canWrite: _canWrite)));
    await _list.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Kural ihlalleri'), bottom: const TabBar(tabs: [Tab(text: 'İhlaller'), Tab(text: 'Kural kataloğu')])),
        floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _report, icon: const Icon(Icons.report), label: const Text('İhlal')) : null,
        body: TabBarView(children: [
          ApiList(
            key: _list,
            load: () => apiClient.getList('/violations'),
            empty: 'İhlal kaydı yok',
            header: (_) => const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Site yönetimi para cezası veremez (Kabahatler K. m.22). Süreç: uyarı → yazılı uyarı → ihtar → sulh hukuk mahkemesi (KMK m.33).',
                  style: TextStyle(fontSize: 12)),
            ),
            itemBuilder: (context, v, _) {
              final st = _status[v['status']];
              final rep = toNum(v['unit_repeat_count']).toInt();
              return ListTile(
                title: Text('${v['unit'] ?? ''} · ${v['rule_title'] ?? ''}'),
                subtitle: Text('${formatDateTime(v['occurred_at'])} · ${v['reporter_name'] ?? '—'}\nKademe: ${_stage[v['stage']] ?? v['stage']}'
                    '${rep > 1 ? ' · son 24 ayda $rep ihlal' : ''}', style: rep > 1 ? const TextStyle(color: Colors.red) : null),
                isThreeLine: true,
                trailing: st == null ? null : StatusChip(st.$1, color: st.$2),
                onTap: () => _open('${v['id']}'),
              );
            },
          ),
          ApiList(
            key: _rules,
            load: () => apiClient.getList('/site-rules'),
            empty: 'Kural tanımlanmamış',
            header: (_) => _canWrite
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (await formAction(context, 'Kural ekle', const [
                            FSpec('title', 'Kural', required: true),
                            FSpec('category', 'Kategori', type: FType.select, options: _category, initial: 'NOISE'),
                            FSpec('management_plan_ref', 'Yönetim planı dayanağı', required: true,
                                hint: 'ör. Yönetim planı m.12/3 — karşılığı olmayan kural malikleri bağlamaz (KMK m.28)'),
                            FSpec('description', 'Açıklama', type: FType.multiline),
                          ], (v) => apiClient.post('/site-rules', v), success: 'Kural eklendi')) {
                            await _rules.currentState?.reload();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Kural ekle'),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            itemBuilder: (context, r, reload) => ListTile(
              title: Text('${r['title'] ?? ''}'),
              subtitle: Text('${_category.firstWhere((c) => c.$1 == r['category'], orElse: () => ('', '${r['category']}')).$2} · ${r['management_plan_ref'] ?? ''}'),
              trailing: r['is_active'] == true
                  ? (_canWrite
                      ? RowMenu([
                          ('Pasifleştir', () async {
                            if (await confirmAction(context, 'Kuralı pasifleştir', '${r['title']} pasifleştirilsin mi? Geçmiş ihlal kayıtları korunur.',
                                () => apiClient.post('/site-rules/${r['id']}/deactivate'), ok: 'Pasifleştir', success: 'Kural pasifleştirildi')) {
                              await reload();
                            }
                          }),
                        ])
                      : const StatusChip('Etkin', color: Colors.green))
                  : const StatusChip('Pasif', color: Colors.grey),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ViolationDetail extends StatefulWidget {
  final String id;
  final bool canWrite;
  const _ViolationDetail({required this.id, required this.canWrite});

  @override
  State<_ViolationDetail> createState() => _ViolationDetailState();
}

class _ViolationDetailState extends State<_ViolationDetail> {
  int _token = 0;

  Future<void> _note(String title, String path, {Map<String, dynamic> extra = const {}, bool required = true, String? note}) async {
    if (await formAction(context, title, [FSpec('note', 'Açıklama', type: FType.multiline, required: required)],
        (v) => switch (path) {
              'escalate' => apiClient.post('/violations/${widget.id}/escalate', {...extra, ...v}),
              'resolve' => apiClient.post('/violations/${widget.id}/resolve', v),
              _ => apiClient.post('/violations/${widget.id}/dismiss', v),
            }, note: note, success: 'Kaydedildi')) {
      setState(() => _token++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İhlal kaydı')),
      body: ApiObject(
        key: ValueKey(_token),
        load: () => apiClient.getMap('/violations/${widget.id}'),
        builder: (context, v, _) {
          final st = _status[v['status']];
          final events = ((v['events'] as List?) ?? const []).whereType<Map>().toList();
          final w = widget.canWrite;
          final next = _stageOrder.sublist(_stageOrder.indexOf('${v['stage']}') + 1);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text('${v['unit'] ?? ''}', style: Theme.of(context).textTheme.titleLarge)),
              if (st != null) StatusChip(st.$1, color: st.$2),
            ]),
            Text('${v['rule_title'] ?? ''} (${v['management_plan_ref'] ?? ''}) · kademe: ${_stage[v['stage']] ?? v['stage']}'),
            const SizedBox(height: 8),
            Text('${v['description'] ?? ''}'),
            const SizedBox(height: 12),
            if (w && v['status'] == 'OPEN')
              Wrap(spacing: 8, children: [
                FilledButton(
                  onPressed: () async {
                    if (await runAction(context, () => apiClient.post('/violations/${widget.id}/verify', {}), success: 'Doğrulandı')) setState(() => _token++);
                  },
                  child: const Text('Doğrula'),
                ),
                OutlinedButton(onPressed: () => _note('Doğrulanmadı', 'dismiss'), child: const Text('Doğrulanmadı')),
              ]),
            if (w && v['status'] == 'VERIFIED')
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in next)
                  OutlinedButton(
                    onPressed: () => _note(_stage[s]!, 'escalate',
                        extra: {'stage': s}, required: s != 'VERBAL_WARNING',
                        note: 'Bildirim dairenin bütün aktif sakinlerine (malik ve kiracı) gider; kiracı malikle müteselsil sorumludur (KMK m.18).'),
                    child: Text(_stage[s]!),
                  ),
                FilledButton(onPressed: () => _note('Kaydı kapat', 'resolve'), child: const Text('Kapat')),
                TextButton(onPressed: () => _note('Doğrulanmadı', 'dismiss'), child: const Text('Doğrulanmadı')),
              ]),
            const Divider(),
            const Text('Olay geçmişi', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final e in events)
              ListTile(
                dense: true,
                title: Text('${_event[e['event_type']] ?? e['event_type']} · ${e['actor_name'] ?? '—'}'),
                subtitle: Text('${formatDateTime(e['created_at'])}${(e['note'] ?? '').toString().isNotEmpty ? '\n${e['note']}' : ''}'),
              ),
            Text('Olay geçmişi değiştirilemez; sulh hukuk mahkemesine (KMK m.33) taşınacak dosyanın kaydıdır. Kayıt: ${formatDate(v['created_at'])}.',
                style: Theme.of(context).textTheme.bodySmall),
          ]);
        },
      ),
    );
  }
}
