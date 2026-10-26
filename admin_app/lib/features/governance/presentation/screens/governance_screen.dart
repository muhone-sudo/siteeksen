// Yönetişim (KMK): işletme projesi, genel kurul, defterler, icra/dava, ortak alan geliri.
//
// NEDEN VAR (2026-09-26): governance servisi (KMK m.20, 28-32, 36-37) gerçek
// veriyle çalışıyor ama mobil uygulamada karşılığı yoktu.
// FAZ H.7 (kullanıcı kararı K4, 2026-10-26): önceki "mobilde yalnız izleme" kararı
// kaldırıldı; paneldeki bütün işlemler (proje hazırlama/bildirme/kesinleştirme/tahakkuk,
// itiraz sonuçlandırma, toplantı planlama/çağrı/hazirun/oy/karar, defter kaydı/kapatma,
// hukuki takip, ortak alan kiralaması) burada da yapılır. Kuralların hepsi sunucudadır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

// KMK m.37 (7579 s. Kanun, RG 22/5/2026): bildirilen proje GEÇİCİDİR ve genel kurulda
// kabul edilince kesinleşir; yedi günlük itirazla kendiliğinden kesinleşme kaldırıldı.
const budgetStatusLabels = {
  'DRAFT': 'Taslak',
  'NOTIFIED': 'Geçici proje — genel kurul bekliyor',
  'FINAL': 'Genel kurulda kabul edildi',
  'CANCELLED': 'İptal',
};
const assemblyStatusLabels = {'PLANNED': 'Planlandı', 'NOTIFIED': 'Çağrı yapıldı', 'HELD': 'Yapıldı', 'CANCELLED': 'İptal'};
const decisionLabels = {'PENDING': 'Karar bekliyor', 'ACCEPTED': 'Kabul', 'REJECTED': 'Red', 'POSTPONED': 'Ertelendi'};
const _objectionStatus = {'OPEN': 'Açık', 'ACCEPTED': 'Kabul', 'REJECTED': 'Ret', 'WITHDRAWN': 'Geri çekildi'};
const _distribution = [('EQUAL', 'Eşit (KMK m.20/1-a)'), ('SHARE_RATIO', 'Arsa payı (KMK m.20/1-b)'), ('AREA_M2', 'Kullanım alanı (yönetim planı öngörürse)')];
const _liability = [('USAGE', 'Kullanım — oturan öder'), ('OWNER', 'Malik — demirbaş, yenilik, ana yapı')];
const _budgetNotice = [('IMZA_KARSILIGI', 'İmza karşılığı elden'), ('TAAHHUTLU_MEKTUP', 'Taahhütlü mektup'), ('ELEKTRONIK', 'Elektronik (yönetim planı öngörüyorsa)')];
const _assemblyNotice = [('IMZA_KARSILIGI', 'İmza karşılığı elden'), ('TAAHHUTLU_MEKTUP', 'Taahhütlü mektup')];
const _majority = [
  ('', 'Olağan çoğunluk (KMK m.30)'),
  ('MAJORITY_INNOVATION', 'Yenilik ve ilaveler — sayı ve arsa payı çoğunluğu (m.42)'),
  ('MAJORITY_CONSTRUCTION_CONSENT', 'Ortak yerlerde inşaat/değişiklik — 4/5 (m.19/2)'),
  ('MAJORITY_MANAGEMENT_PLAN_CHANGE', 'Yönetim planı değişikliği — 4/5 (m.28)'),
  ('UNANIMITY_TRANSFER_ACTS', 'Temliki tasarruf / kiralama — oybirliği (m.45)'),
];
const _caseTypes = [('EXECUTION', 'İcra takibi'), ('LAWSUIT', 'Dava'), ('MORTGAGE', 'Kanuni ipotek (KMK m.22)')];
const _basis = [('OPERATING_BUDGET', 'Kesinleşmiş işletme projesi'), ('ASSEMBLY_DECISION', 'Kat malikleri kurulu kararı'), ('COURT_ORDER', 'Mahkeme kararı')];
const _caseStatus = {'PREPARING': 'Hazırlanıyor', 'FILED': 'Açıldı', 'OBJECTED': 'İtiraz', 'CONCLUDED': 'Sonuçlandı', 'COLLECTED': 'Tahsil edildi', 'WITHDRAWN': 'Geri çekildi'};
const _leaseKind = [
  ('ROOF_FACADE_AD', 'Çatı / cephe reklamı'), ('ANTENNA', 'Baz istasyonu / anten'), ('CARETAKER_FLAT', 'Kapıcı dairesi'),
  ('PARKING', 'Otopark'), ('STORAGE', 'Depo'), ('SHOP', 'Dükkân / ticari alan'), ('OTHER', 'Diğer'),
];

String _l(List<(String, String)> list, Object? v) => list.firstWhere((e) => e.$1 == (v ?? ''), orElse: () => ('', '${v ?? ''}')).$2;
String _kurus(Object? v) => formatTry(toNum(v) / 100);

/// Yapılmış genel kurullardaki kabul edilen maddeler; [onlyUnanimity] kiralama için.
Future<List<(String, String)>> _acceptedItems({bool onlyUnanimity = false}) async {
  final out = <(String, String)>[];
  final list = await apiClient.getList('/governance/assemblies');
  for (final a in list.whereType<Map>().where((a) => a['status'] == 'HELD')) {
    final d = await apiClient.getMap('/governance/assemblies/${a['id']}');
    for (final i in ApiClient.listOf(d['agenda_items']).whereType<Map>()) {
      if (i['decision_status'] != 'ACCEPTED') continue;
      if (onlyUnanimity && i['required_majority_code'] != 'UNANIMITY_TRANSFER_ACTS') continue;
      out.add(('${i['id']}', '${formatDate(a['held_at'] ?? a['scheduled_at'])} · ${i['order_no']}. ${i['title']}'));
    }
  }
  return out;
}

class GovernanceScreen extends StatefulWidget {
  const GovernanceScreen({super.key});

  @override
  State<GovernanceScreen> createState() => _GovernanceScreenState();
}

class _GovernanceScreenState extends State<GovernanceScreen> {
  bool _w = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _w = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetişim (KMK)'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'İşletme projesi'), Tab(text: 'Genel kurul'), Tab(text: 'Defterler'), Tab(text: 'İcra ve dava'), Tab(text: 'Ortak alan'),
          ]),
        ),
        body: TabBarView(children: [
          _Budgets(canWrite: _w),
          _Assemblies(canWrite: _w),
          _Books(canWrite: _w),
          _Legal(canWrite: _w),
          _CommonArea(canWrite: _w),
        ]),
      ),
    );
  }
}

Widget _addButton(bool show, String label, VoidCallback onTap) => show
    ? Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(label)),
        ),
      )
    : const SizedBox.shrink();

// ------------------------------------------------------------------ işletme projesi

class _Budgets extends StatefulWidget {
  final bool canWrite;
  const _Budgets({required this.canWrite});

  @override
  State<_Budgets> createState() => _BudgetsState();
}

class _BudgetsState extends State<_Budgets> {
  final _list = GlobalKey<ApiListState>();

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BudgetDetail(id: id, canWrite: widget.canWrite)));
    await _list.currentState?.reload();
  }

  Future<void> _create() async {
    final r = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => const _BudgetEditor()));
    if (r == null || !mounted) return;
    await _list.currentState?.reload();
    await _open('${r['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return ApiList(
      key: _list,
      load: () => apiClient.getList('/governance/budgets'),
      empty: 'İşletme projesi yok',
      header: (_) => _addButton(widget.canWrite, 'Proje hazırla', _create),
      itemBuilder: (context, b, _) => ListTile(
        title: Text('${b['period_year']} · ${formatTry(toNum(b['total_amount']))}'),
        subtitle: Text([
          budgetStatusLabels['${b['status']}'] ?? '${b['status']}',
          if (b['notified_at'] != null) 'Bildirim ${formatDate(b['notified_at'])}',
          if (b['status'] == 'NOTIFIED' && b['approval_deadline'] != null) 'Genel kurul son gün ${formatDate(b['approval_deadline'])}',
          if (b['finalized_at'] != null) 'Kesinleşme ${formatDate(b['finalized_at'])}',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open('${b['id']}'),
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor();

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  int _year = DateTime.now().year + 1;
  final _note = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _saving = false;

  Future<void> _addItem([int? index]) async {
    final it = index == null ? null : _items[index];
    final v = await showForm(context, index == null ? 'Kalem ekle' : 'Kalemi düzenle', [
      FSpec('name', 'Kalem adı', required: true, initial: it?['name'], hint: 'ör. Kapıcı gideri'),
      FSpec('amount', 'Yıllık tutar (TL)', type: FType.decimal, required: true, initial: it?['amount']),
      FSpec('distribution_type', 'Dağıtım', type: FType.select, options: _distribution, initial: it?['distribution_type'] ?? 'SHARE_RATIO', required: true),
      FSpec('kind', 'Tür', type: FType.select, options: const [('EXPENSE', 'Gider'), ('INCOME', 'Gelir')], initial: it?['kind'] ?? 'EXPENSE', required: true),
      FSpec('liability', 'Gider sınıfı', type: FType.select, options: _liability, initial: it?['liability'] ?? 'USAGE', visible: (v) => v['kind'] != 'INCOME'),
    ]);
    if (v == null) return;
    if (!(toNum(v['amount']) > 0)) return;
    setState(() => index == null ? _items.add(v) : _items[index] = v);
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az bir kalem ekleyin')));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await apiClient.post('/governance/budgets', {
        'period_year': _year,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
        'items': [for (final i in _items) {'liability': 'USAGE', ...i}],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['period_year']} projesi taslak olarak hazırlandı (${formatTry(toNum(r['total_amount']))})')));
      Navigator.pop(context, r);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<num>(0, (a, i) => a + (i['kind'] == 'INCOME' ? -toNum(i['amount']) : toNum(i['amount'])));
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme projesi hazırla')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: const Text('Taslak kaydet')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        Row(children: [
          const Text('Dönem yılı'),
          IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
          Text('$_year', style: Theme.of(context).textTheme.titleMedium),
          IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
        ]),
        TextField(controller: _note, decoration: const InputDecoration(labelText: 'Not')),
        const SizedBox(height: 12),
        Text('Kalemler · net ${formatTry(total)}', style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < _items.length; i++)
          ListTile(
            title: Text('${_items[i]['name']} · ${formatTry(toNum(_items[i]['amount']))}'),
            subtitle: Text('${_l(_distribution, _items[i]['distribution_type'])} · ${_items[i]['kind'] == 'INCOME' ? 'Gelir' : _l(_liability, _items[i]['liability'] ?? 'USAGE')}'),
            onTap: () => _addItem(i),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _items.removeAt(i))),
          ),
        OutlinedButton.icon(onPressed: () => _addItem(), icon: const Icon(Icons.add), label: const Text('Kalem')),
        const SizedBox(height: 12),
        const Text('Kapıcı, kaloriferci, bahçıvan ve bekçi giderleri eşit; sigorta ve ortak yer bakım/onarım giderleri arsa payına göre paylaştırılır (KMK m.20). '
            'Kullanım giderini dairede oturan, malik giderini malik öder.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }
}

class _BudgetDetail extends StatefulWidget {
  final String id;
  final bool canWrite;
  const _BudgetDetail({required this.id, required this.canWrite});

  @override
  State<_BudgetDetail> createState() => _BudgetDetailState();
}

class _BudgetDetailState extends State<_BudgetDetail> {
  int _token = 0;
  String get _id => widget.id;
  void _changed() => setState(() => _token++);

  Future<void> _notify() async {
    if (await formAction(context, 'Geçici proje olarak bildir', const [
      FSpec('method', 'Bildirim yöntemi', type: FType.select, options: _budgetNotice, initial: 'TAAHHUTLU_MEKTUP', required: true),
    ], (v) async {
      final r = await apiClient.post('/governance/budgets/$_id/notify', v);
      return {...r, 'message': 'Geçici proje bildirildi; en geç ${formatDate(r['approval_deadline'])} tarihine kadar genel kurulda karara bağlanmalı (KMK m.37)'};
    }, note: 'Yürürlükte kabul edilmiş proje varsa geçici projenin toplamı, yeniden değerleme oranı kadar artırılmış tutarını aşamaz (KMK m.37 son fıkra).', submit: 'Bildir')) {
      _changed();
    }
  }

  Future<void> _finalize() async {
    final items = await _acceptedItems().catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    if (await formAction(context, 'Genel kurul kararıyla kesinleştir', [
      FSpec('agenda_item_id', 'Kabul edilen gündem maddesi', type: FType.select, options: items, required: true),
      const FSpec('decision_ref', 'Karar referansı (isteğe bağlı)'),
    ], (v) => apiClient.post('/governance/budgets/$_id/finalize', v), success: 'Proje genel kurul kararına bağlandı ve kesinleşti',
        note: 'Genel kurul projeyi değiştirerek kabul ettiyse kabul edilen içeriği yeni taslak olarak girip bu karara bağlayın.')) {
      _changed();
    }
  }

  Future<void> _assess(Map b) async {
    if (await formAction(context, 'Projeden aylık aidat tahakkuk et', [
      FSpec('period_month', 'Ay', type: FType.select, required: true, initial: '${DateTime.now().month}',
          options: [for (var m = 1; m <= 12; m++) ('$m', '${b['period_year']}-${m.toString().padLeft(2, '0')}')]),
      const FSpec('due_date', 'Son ödeme tarihi', type: FType.date, required: true),
    ], (v) async {
      final r = await apiClient.post('/governance/budgets/$_id/assessments', {'period_month': int.parse('${v['period_month']}'), 'due_date': v['due_date']});
      return {
        ...r,
        'message': '${r['period']} dönemi için ${r['created']} daireye ${_kurus(r['total_kurus'])} aidat tahakkuk edildi. ${r['note'] ?? ''} '
            'Sakin bildirimi: ${(r['notification'] as Map?)?['note'] ?? '—'}',
        'note': null,
      };
    }, note: 'Her dairenin yıllık payı 12 aya kuruşu kuruşuna bölünür. Aynı ay için ikinci tahakkuk açılamaz.', submit: 'Tahakkuk et')) {
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İşletme projesi'),
          actions: [
            RowMenu([
              ('PDF', () => openDownload(context, '/governance/budgets/$_id/export?format=pdf', 'isletme-projesi.pdf')),
              ('Excel', () => openDownload(context, '/governance/budgets/$_id/export?format=xlsx', 'isletme-projesi.xlsx')),
            ]),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Özet'), Tab(text: 'Daire payları'), Tab(text: 'İtirazlar')]),
        ),
        body: ApiObject(
          key: ValueKey(_token),
          load: () => apiClient.getMap('/governance/budgets/$_id'),
          builder: (context, b, _) {
            final items = ApiClient.listOf(b['items']).whereType<Map>().toList();
            final shares = ApiClient.listOf(b['unit_shares']).whereType<Map>().toList();
            final st = '${b['status']}';
            final w = widget.canWrite;
            return TabBarView(children: [
              ListView(padding: const EdgeInsets.all(16), children: [
                Text('${b['period_year']} · ${budgetStatusLabels[st] ?? st}', style: Theme.of(context).textTheme.titleMedium),
                Text([
                  'Toplam ${formatTry(toNum(b['total_amount']))}',
                  if (st == 'NOTIFIED' && b['approval_deadline'] != null) 'Genel kurul son gün ${formatDate(b['approval_deadline'])}',
                  if (b['cap_amount'] != null) 'Geçici proje tavanı ${formatTry(toNum(b['cap_amount']))}',
                  if ((b['decision_ref'] ?? '').toString().isNotEmpty) 'Karar: ${b['decision_ref']}',
                  if (toNum(b['open_objections']) > 0) '${b['open_objections']} açık itiraz',
                ].join('\n')),
                const SizedBox(height: 12),
                if (w)
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (st == 'DRAFT') FilledButton(onPressed: _notify, child: const Text('Geçici proje olarak bildir')),
                    if (st == 'DRAFT' || st == 'NOTIFIED') OutlinedButton(onPressed: _finalize, child: const Text('Genel kurul kararıyla kesinleştir')),
                    if (st == 'NOTIFIED' || st == 'FINAL') OutlinedButton(onPressed: () => _assess(b), child: const Text('Aylık aidat tahakkuk et')),
                  ]),
                const Divider(height: 24),
                Text('Kalemler', style: Theme.of(context).textTheme.titleSmall),
                for (final i in items)
                  ListTile(
                    dense: true,
                    title: Text('${i['name']}'),
                    subtitle: Text('${_l(_distribution, i['distribution_type'])} · ${i['kind'] == 'INCOME' ? 'Gelir' : _l(_liability, i['liability'] ?? 'USAGE')}'),
                    trailing: Text(formatTry(toNum(i['amount']))),
                  ),
              ]),
              ListView(children: [
                for (final s in shares)
                  ListTile(
                    dense: true,
                    title: Text('${s['unit_name'] ?? s['unit_id']}'),
                    subtitle: Text('Yıllık ${_kurus(s['annual_kurus'])}'),
                    trailing: Text(_kurus(s['monthly_kurus']), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ]),
              ApiList(
                load: () => apiClient.getList('/governance/budgets/$_id/objections'),
                empty: 'İtiraz yok',
                itemBuilder: (context, x, reload) => ListTile(
                  title: Text('${x['reason'] ?? ''}'),
                  subtitle: Text('${formatDate(x['submitted_at'])} · ${_objectionStatus[x['status']] ?? x['status']}'
                      '${x['in_time'] == false ? ' · eski 7 günlük süre dışı' : ''}${(x['resolution'] ?? '').toString().isNotEmpty ? '\n${x['resolution']}' : ''}'),
                  trailing: w && x['status'] == 'OPEN'
                      ? RowMenu([
                          for (final (s, l) in const [('ACCEPTED', 'Kabul'), ('REJECTED', 'Ret')])
                            (l, () async {
                              final res = await askText(context, 'İtiraz — $l', 'Karar açıklaması', required: false);
                              if (res == null || !context.mounted) return;
                              if (await runAction(context, () => apiClient.patch('/governance/budgets/$_id/objections/${x['id']}', {'status': s, 'resolution': res}),
                                  success: 'İtiraz sonuçlandırıldı')) {
                                await reload();
                              }
                            }),
                        ])
                      : null,
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ genel kurul

class _Assemblies extends StatefulWidget {
  final bool canWrite;
  const _Assemblies({required this.canWrite});

  @override
  State<_Assemblies> createState() => _AssembliesState();
}

class _AssembliesState extends State<_Assemblies> {
  final _list = GlobalKey<ApiListState>();

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _AssemblyDetail(id: id, canWrite: widget.canWrite)));
    await _list.currentState?.reload();
  }

  Future<void> _create() async {
    final r = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => const _AssemblyEditor()));
    if (r == null || !mounted) return;
    await _list.currentState?.reload();
    await _open('${r['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return ApiList(
      key: _list,
      load: () => apiClient.getList('/governance/assemblies'),
      empty: 'Genel kurul kaydı yok',
      header: (_) => _addButton(widget.canWrite, 'Toplantı planla', _create),
      itemBuilder: (context, a, _) => ListTile(
        title: Text('${formatDateTime(a['scheduled_at'])} · ${a['kind'] == 'ORDINARY' ? 'Olağan' : 'Olağanüstü'} (${a['call_number']}. toplantı)'),
        subtitle: Text([
          assemblyStatusLabels['${a['status']}'] ?? '${a['status']}',
          if (a['location'] != null) '${a['location']}',
          if (a['quorum_met'] != null) a['quorum_met'] == true ? 'nisap sağlandı' : 'nisap yok',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open('${a['id']}'),
      ),
    );
  }
}

class _AssemblyEditor extends StatefulWidget {
  const _AssemblyEditor();

  @override
  State<_AssemblyEditor> createState() => _AssemblyEditorState();
}

class _AssemblyEditorState extends State<_AssemblyEditor> {
  Map<String, dynamic>? _head;
  final List<Map<String, dynamic>> _items = [];
  bool _saving = false;

  Future<void> _editHead() async {
    final v = await showForm(context, 'Toplantı', [
      FSpec('kind', 'Tür', type: FType.select, options: const [('ORDINARY', 'Olağan'), ('EXTRAORDINARY', 'Olağanüstü')], initial: _head?['kind'] ?? 'ORDINARY', required: true),
      FSpec('call_number', 'Toplantı', type: FType.select, options: const [('1', '1. toplantı'), ('2', '2. toplantı')], initial: '${_head?['call_number'] ?? 1}', required: true,
          hint: 'İlk toplantıda nisap sağlanmazsa ikinci toplantıda yeter sayı aranmaz (m.30/3)'),
      const FSpec('scheduled_at', 'Tarih ve saat', type: FType.dateTime, required: true, hint: 'Çağrı en az 15 gün önce yapılmalıdır (m.29)'),
      FSpec('location', 'Yer', initial: _head?['location']),
    ]);
    if (v != null) setState(() => _head = v);
  }

  Future<void> _addItem() async {
    final v = await showForm(context, '${_items.length + 1}. gündem maddesi', const [
      FSpec('title', 'Başlık', required: true),
      FSpec('description', 'Açıklama', type: FType.multiline),
      FSpec('required_majority_code', 'Nisap', type: FType.select, options: _majority, initial: ''),
    ]);
    if (v != null) setState(() => _items.add(v));
  }

  Future<void> _save() async {
    if (_head == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toplantı bilgisi ve en az bir gündem maddesi gerekli')));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await apiClient.post('/governance/assemblies', {
        ..._head!,
        'call_number': int.parse('${_head!['call_number']}'),
        'agenda_items': [for (final i in _items) {...i, if ((i['required_majority_code'] ?? '') == '') 'required_majority_code': null}..removeWhere((k, v) => v == null)],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toplantı planlandı')));
      Navigator.pop(context, r);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _head;
    return Scaffold(
      appBar: AppBar(title: const Text('Toplantı planla')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: const Text('Kaydet')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        ListTile(
          title: Text(h == null ? 'Toplantı bilgisi' : '${h['kind'] == 'ORDINARY' ? 'Olağan' : 'Olağanüstü'} · ${h['call_number']}. toplantı'),
          subtitle: Text(h == null ? 'Tarih, saat ve yer' : '${formatDateTime(h['scheduled_at'])}${h['location'] != null ? ' · ${h['location']}' : ''}'),
          trailing: const Icon(Icons.edit),
          onTap: _editHead,
        ),
        const Divider(),
        Text('Gündem', style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < _items.length; i++)
          ListTile(
            title: Text('${i + 1}. ${_items[i]['title']}'),
            subtitle: Text(_l(_majority, _items[i]['required_majority_code'])),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _items.removeAt(i))),
          ),
        OutlinedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Madde')),
      ]),
    );
  }
}

class _AssemblyDetail extends StatefulWidget {
  final String id;
  final bool canWrite;
  const _AssemblyDetail({required this.id, required this.canWrite});

  @override
  State<_AssemblyDetail> createState() => _AssemblyDetailState();
}

class _AssemblyDetailState extends State<_AssemblyDetail> {
  int _token = 0;
  String get _id => widget.id;
  void _changed() => setState(() => _token++);

  Future<void> _addAttendee(Set<String> present) async {
    final units = await apiClient.getList('/units').catchError((_) => <dynamic>[]);
    final people = await optionsFrom('/residents', (r) => '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}', id: 'user_id').catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    final opts = [
      for (final u in units.whereType<Map>())
        if (!present.contains('${u['id']}')) ('${u['id']}', '${u['block'] ?? ''}-${u['door_number']} (arsa payı ${formatNumber(toNum(u['share_ratio']))})'),
    ];
    if (await formAction(context, 'Hazirune ekle', [
      FSpec('unit_id', 'Daire', type: FType.select, options: opts, required: true),
      const FSpec('attendance_type', 'Katılım', type: FType.select, options: [('SELF', 'Bizzat'), ('PROXY', 'Vekâleten')], initial: 'SELF', required: true),
      FSpec('proxy_holder_id', 'Vekil', type: FType.select, options: {for (final p in people) p.$1: p}.values.toList(), required: true,
          visible: (v) => v['attendance_type'] == 'PROXY', hint: "m.31: bir vekil toplam oyun %5'inden fazlasını kullanamaz"),
    ], (v) => apiClient.post('/governance/assemblies/$_id/attendees', v), success: 'Hazirune eklendi')) {
      _changed();
    }
  }

  Future<void> _vote(Map item, List<Map> attendees) async {
    await formAction(context, 'Oy — ${item['title']}', [
      FSpec('unit_id', 'Daire (hazirundan)', type: FType.select, options: [for (final a in attendees) ('${a['unit_id']}', '${a['unit_name']}')], required: true),
      const FSpec('vote', 'Oy', type: FType.select, options: [('FOR', 'Lehte'), ('AGAINST', 'Aleyhte'), ('ABSTAIN', 'Çekimser')], initial: 'FOR', required: true),
    ], (v) => apiClient.post('/governance/agenda-items/${item['id']}/votes', v), submit: 'Oyu kaydet', success: 'Oy kaydedildi',
        note: 'Aynı dairenin ikinci oyu öncekinin yerine geçer.');
    _changed();
  }

  Future<void> _closeItem(Map item) async {
    final text = await askText(context, 'Kararı hesapla', 'Karar metni (isteğe bağlı)', required: false);
    if (text == null || !mounted) return;
    try {
      final r = await apiClient.post('/governance/agenda-items/${item['id']}/close', {if (text.isNotEmpty) 'decision_text': text});
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(r['accepted'] == true ? 'Kabul edildi' : 'Reddedildi'),
          content: Text('${r['explanation'] ?? ''}\n\nSayı oranı %${(toNum(r['by_count_ratio']) * 100).toStringAsFixed(1)} · '
              'arsa payı oranı %${(toNum(r['by_share_ratio']) * 100).toStringAsFixed(1)}\n${r['legal_basis'] ?? ''}${r['note'] != null ? '\n${r['note']}' : ''}'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
        ),
      );
      _changed();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genel kurul')),
      body: ApiObject(
        key: ValueKey(_token),
        load: () async {
          final a = await apiClient.getMap('/governance/assemblies/$_id');
          final att = await apiClient.getList('/governance/assemblies/$_id/attendees');
          final q = await apiClient.getMap('/governance/assemblies/$_id/quorum').catchError((_) => <String, dynamic>{});
          return {...a, '_attendees': att, '_quorum': q};
        },
        builder: (context, a, _) {
          final items = ApiClient.listOf(a['agenda_items']).whereType<Map>().toList();
          final att = (a['_attendees'] as List).whereType<Map>().toList();
          final q = (a['_quorum'] as Map?) ?? const {};
          final st = '${a['status']}';
          final open = st == 'PLANNED' || st == 'NOTIFIED';
          final w = widget.canWrite;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text('${formatDateTime(a['scheduled_at'])} · ${a['call_number']}. toplantı', style: Theme.of(context).textTheme.titleMedium),
            Text('${assemblyStatusLabels[st] ?? st}${a['notice_method'] != null ? ' · çağrı: ${a['notice_method']}' : ''}'),
            if (q.isNotEmpty)
              Card(
                color: q['met'] == true ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Nisap ${q['met'] == true ? 'sağlanıyor' : 'sağlanmıyor'}: ${q['attended_units']}/${q['total_units']} daire, '
                      'arsa payı ${formatNumber(toNum(q['attended_share_ratio']))}/${formatNumber(toNum(q['total_share_ratio']))}. ${q['explanation'] ?? ''} (${q['legal_basis'] ?? ''})'),
                ),
              ),
            if (w)
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (st == 'PLANNED')
                  FilledButton(
                    onPressed: () async {
                      if (await formAction(context, 'Çağrıyı kaydet', const [
                        FSpec('method', 'Çağrı yöntemi', type: FType.select, options: _assemblyNotice, initial: 'TAAHHUTLU_MEKTUP', required: true),
                      ], (v) => apiClient.post('/governance/assemblies/$_id/notify', v), success: 'Çağrı kaydedildi')) {
                        _changed();
                      }
                    },
                    child: const Text('Çağrıyı kaydet'),
                  ),
                if (open) OutlinedButton(onPressed: () => _addAttendee({for (final x in att) '${x['unit_id']}'}), child: const Text('Hazirune ekle')),
                if (open)
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirmAction(context, 'Toplantıyı yap', 'Nisap fotoğrafı alınır; hazirun bundan sonra değişmez.', () async {
                        final r = await apiClient.post('/governance/assemblies/$_id/hold');
                        return {...r, 'message': 'Toplantı yapıldı. Nisap ${r['met'] == true ? 'sağlandı' : 'SAĞLANMADI'}'};
                      })) {
                        _changed();
                      }
                    },
                    child: const Text('Toplantıyı yap'),
                  ),
              ]),
            const Divider(height: 24),
            Text('Gündem ve kararlar', style: Theme.of(context).textTheme.titleSmall),
            for (final i in items)
              ListTile(
                title: Text('${i['order_no']}. ${i['title']}'),
                subtitle: Text('${_l(_majority, i['required_majority_code'])}\n'
                    'Lehte ${i['votes_for'] ?? 0} · aleyhte ${i['votes_against'] ?? 0} · çekimser ${i['votes_abstain'] ?? 0} · ${decisionLabels['${i['decision_status']}'] ?? i['decision_status']}'
                    '${(i['decision_text'] ?? '').toString().isNotEmpty ? '\n${i['decision_text']}' : ''}'),
                isThreeLine: true,
                trailing: w && st == 'HELD' && i['decision_status'] == 'PENDING'
                    ? RowMenu([('Oy gir', () => _vote(i, att)), ('Kararı hesapla', () => _closeItem(i))])
                    : null,
              ),
            const Divider(height: 24),
            Row(children: [
              Expanded(child: Text('Hazirun (${att.length})', style: Theme.of(context).textTheme.titleSmall)),
              TextButton(onPressed: () => openDownload(context, '/governance/assemblies/$_id/attendance-sheet?format=pdf', 'hazirun-cetveli.pdf'), child: const Text('Cetvel PDF')),
              TextButton(onPressed: () => openDownload(context, '/governance/assemblies/$_id/attendance-sheet?format=xlsx', 'hazirun-cetveli.xlsx'), child: const Text('Excel')),
            ]),
            for (final x in att)
              ListTile(
                dense: true,
                title: Text('${x['unit_name']} · ${x['user_name'] ?? '—'}'),
                subtitle: Text('${x['attendance_type'] == 'PROXY' ? 'Vekâlet: ${x['proxy_holder_name'] ?? ''}' : 'Bizzat'} · arsa payı ${formatNumber(toNum(x['share_ratio']))}'),
              ),
          ]);
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ defterler

class _Books extends StatefulWidget {
  final bool canWrite;
  const _Books({required this.canWrite});

  @override
  State<_Books> createState() => _BooksState();
}

class _BooksState extends State<_Books> {
  int _year = DateTime.now().year;
  String _kind = 'DECISION';
  int _token = 0;

  Future<Map<String, dynamic>> _load() async {
    final book = await apiClient.post('/governance/books?kind=$_kind&year=$_year');
    final id = book['id'];
    final entries = await apiClient.getList('/governance/books/$id/entries');
    final verify = await apiClient.getMap('/governance/books/$id/verify');
    return {'book': book, 'entries': entries, 'verify': verify};
  }

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      key: ValueKey('$_kind-$_year-$_token'),
      load: _load,
      builder: (context, d, _) {
        final book = (d['book'] as Map?) ?? const {};
        final entries = (d['entries'] as List).whereType<Map>().toList();
        final v = (d['verify'] as Map?) ?? const {};
        final open = book['status'] == 'OPEN';
        return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          Row(children: [
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _kind,
              items: const [DropdownMenuItem(value: 'DECISION', child: Text('Karar defteri')), DropdownMenuItem(value: 'OPERATING', child: Text('İşletme defteri'))],
              onChanged: (k) => setState(() => _kind = k ?? _kind),
            ),
            const Spacer(),
            IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
            Text('$_year'),
            IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
          ]),
          ListTile(
            leading: Icon(v['valid'] == true ? Icons.verified : Icons.gpp_bad, color: v['valid'] == true ? Colors.green : Colors.red),
            title: Text(open ? 'Açık' : 'Notere kapatıldı ${formatDate(book['notary_closed_at'])}'),
            subtitle: Text('${v['message'] ?? ''}'),
            trailing: RowMenu([
              ('PDF', () => openDownload(context, '/governance/books/${book['id']}/export?format=pdf', 'defter.pdf')),
              if (widget.canWrite && open)
                ('Kayıt ekle', () async {
                  if (await formAction(context, 'Deftere kayıt ekle', [
                    const FSpec('title', 'Başlık', required: true),
                    const FSpec('body', 'Metin', type: FType.multiline, required: true),
                    FSpec('entry_date', 'Tarih', type: FType.date, initial: DateTime.now()),
                  ], (x) async {
                    final r = await apiClient.post('/governance/books/${book['id']}/entries', x);
                    return {...r, 'message': '${r['entry_no']} numaralı kayıt eklendi'};
                  }, note: 'Kayıt eklendikten sonra DEĞİŞTİRİLEMEZ ve SİLİNEMEZ. Düzeltme gerekirse yeni bir kayıtla yapılır.')) {
                    setState(() => _token++);
                  }
                }),
              if (widget.canWrite && open)
                ('Notere kapat', () async {
                  if (await formAction(context, 'Defteri notere kapat', [
                    const FSpec('notary_ref', 'Noter kapanış no'),
                    FSpec('closed_at', 'Kapanış tarihi', type: FType.date, initial: DateTime.now()),
                  ], (x) => apiClient.post('/governance/books/${book['id']}/close', {...x, 'period_year': book['period_year']}),
                      note: 'KMK m.36: yıl sonundan itibaren bir ay içinde kapattırılmalıdır; süre aşılırsa uyarı verilir.', submit: 'Kapat')) {
                    setState(() => _token++);
                  }
                }),
            ]),
          ),
          if (entries.isEmpty) const ListTile(title: Text('Defterde kayıt yok')),
          for (final e in entries)
            ListTile(
              title: Text('${e['entry_no']}. ${e['title']}'),
              subtitle: Text('${formatDate(e['entry_date'])}\n${e['body'] ?? ''}'),
              isThreeLine: true,
            ),
        ]);
      },
    );
  }
}

// ------------------------------------------------------------------ icra ve dava

class _Legal extends StatefulWidget {
  final bool canWrite;
  const _Legal({required this.canWrite});

  @override
  State<_Legal> createState() => _LegalState();
}

class _LegalState extends State<_Legal> {
  final _list = GlobalKey<ApiListState>();

  @override
  Widget build(BuildContext context) {
    return ApiList(
      key: _list,
      load: () => apiClient.getList('/governance/legal-cases'),
      empty: 'Takip kaydı yok',
      header: (_) => _addButton(widget.canWrite, 'Takip aç', () async {
        final units = await unitOptions();
        if (!context.mounted) return;
        if (await formAction(context, 'Hukuki takip aç', [
          FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true),
          const FSpec('case_type', 'Tür', type: FType.select, options: _caseTypes, initial: 'EXECUTION', required: true),
          const FSpec('basis_document_type', 'Dayanak belge', type: FType.select, options: _basis, initial: 'OPERATING_BUDGET', hint: 'Belirtilmezse uyarı verilir'),
          const FSpec('office_or_court', 'İcra dairesi / mahkeme'),
          const FSpec('file_no', 'Dosya no'),
          const FSpec('lawyer_name', 'Avukat'),
          const FSpec('note', 'Not', type: FType.multiline),
        ], (v) async {
          final r = await apiClient.post('/governance/legal-cases', v);
          return {...r, 'message': r['warning'] != null ? 'Takip açıldı. ${r['warning']}' : 'Takip açıldı — anapara ${_kurus((r['case'] as Map?)?['principal_kurus'])}', 'warning': null};
        }, note: 'Anapara ve gecikme tazminatı, dairenin ödenmemiş tahakkuklarından otomatik hesaplanır.')) {
          await _list.currentState?.reload();
        }
      }),
      itemBuilder: (context, c, _) => ListTile(
        title: Text('${_l(_caseTypes, c['case_type'])} · ${_caseStatus[c['status']] ?? c['status']}'),
        subtitle: Text([
          'Anapara ${_kurus(c['principal_kurus'])} · gecikme ${_kurus(c['late_fee_kurus'])}',
          _l(_basis, c['basis_document_type']),
          [c['office_or_court'], c['file_no']].where((x) => x != null && '$x'.isNotEmpty).join(' · '),
          'Açılış ${formatDate(c['filed_at'])}',
        ].where((s) => s.isNotEmpty).join('\n')),
        isThreeLine: true,
      ),
    );
  }
}

// ------------------------------------------------------------------ ortak alan

class _CommonArea extends StatefulWidget {
  final bool canWrite;
  const _CommonArea({required this.canWrite});

  @override
  State<_CommonArea> createState() => _CommonAreaState();
}

class _CommonAreaState extends State<_CommonArea> {
  int _token = 0;
  int _year = DateTime.now().year;

  Future<void> _create() async {
    final items = await _acceptedItems(onlyUnanimity: true).catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    if (await formAction(context, 'Ortak yer kiralaması', [
      const FSpec('area_kind', 'Alan türü', type: FType.select, options: _leaseKind, initial: 'ROOF_FACADE_AD', required: true),
      const FSpec('area_name', 'Alan adı', required: true),
      const FSpec('tenant_name', 'Kiracı', required: true),
      const FSpec('monthly_rent', 'Aylık kira (TL)', type: FType.decimal, required: true),
      FSpec('start_date', 'Başlangıç', type: FType.date, initial: DateTime.now(), required: true),
      const FSpec('tenant_is_business', 'Kiracı işyeri (stopaj yapar)', type: FType.toggle, initial: true),
      FSpec('agenda_item_id', 'Oybirliğiyle kabul edilen madde', type: FType.select, options: items, required: true, hint: items.isEmpty ? 'Oybirliği maddesi yok' : null),
    ], (v) => apiClient.post('/governance/common-area/leases', v), success: 'Kiralama kaydedildi',
        note: 'Ortak yerin kiraya verilmesi bütün kat maliklerinin oybirliğini ister (KMK m.45). Sığınak kiraya verilemez.')) {
      setState(() => _token++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      key: ValueKey('$_token-$_year'),
      load: () async => {
        'leases': await apiClient.getList('/governance/common-area/leases'),
        'report': await apiClient.getMap('/governance/common-area/report', query: {'year': _year}),
      },
      builder: (context, d, _) {
        final leases = (d['leases'] as List).whereType<Map>().toList();
        final rep = (d['report'] as Map?) ?? const {};
        final rows = ApiClient.listOf(rep['data']).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          _addButton(widget.canWrite, 'Kiralama', _create),
          const ListTile(title: Text('Kiralamalar', style: TextStyle(fontWeight: FontWeight.w600))),
          if (leases.isEmpty) const ListTile(title: Text('Kiralama yok')),
          for (final l in leases)
            ListTile(
              title: Text('${l['area_name']} · ${l['tenant_name']}${l['tenant_is_business'] == true ? ' (işyeri)' : ''}'),
              subtitle: Text('${_l(_leaseKind, l['area_kind'])} · ${formatDate(l['start_date'])} · aylık ${formatTry(toNum(l['monthly_rent']))}\n'
                  'Toplam gelir ${formatTry(toNum(l['income_total']))} · ${l['status'] == 'ACTIVE' ? 'Aktif' : 'Sona erdi'} · ${l['decision_ref'] ?? ''}'),
              isThreeLine: true,
              trailing: widget.canWrite && l['status'] == 'ACTIVE'
                  ? RowMenu([
                      ('Tahsilat gir', () async {
                        final now = DateTime.now();
                        if (await formAction(context, 'Kira tahsilatı — ${l['area_name']}', [
                          FSpec('period', 'Dönem (YYYY-AA)', initial: '${now.year}-${now.month.toString().padLeft(2, '0')}', required: true),
                          FSpec('received_on', 'Tahsilat tarihi', type: FType.date, initial: now, required: true),
                          FSpec('gross_amount', 'Brüt kira (TL)', type: FType.decimal, initial: l['monthly_rent'], required: true),
                          if (l['tenant_is_business'] == true) const FSpec('withholding_amount', 'Kiracının kestiği stopaj (TL)', type: FType.decimal, initial: 0, hint: 'GVK m.94'),
                        ], (v) => apiClient.post('/governance/common-area/leases/${l['id']}/incomes', {'withholding_amount': 0, ...v}))) {
                          setState(() => _token++);
                        }
                      }),
                      ('Sonlandır', () async {
                        if (await confirmAction(context, 'Kiralamayı sonlandır', '${l['area_name']} kiralaması bugün itibarıyla sona erdirilsin mi?',
                            () => apiClient.post('/governance/common-area/leases/${l['id']}/end', {'end_date': apiDate(DateTime.now())}), ok: 'Sonlandır', success: 'Kiralama sona erdirildi')) {
                          setState(() => _token++);
                        }
                      }),
                    ])
                  : null,
            ),
          const Divider(),
          Row(children: [
            const Padding(padding: EdgeInsets.only(left: 16), child: Text('Kat maliki payları', style: TextStyle(fontWeight: FontWeight.w600))),
            const Spacer(),
            IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
            Text('$_year'),
            IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
          ]),
          if (rows.isEmpty) const ListTile(title: Text('Bu yıl için gelir yok')),
          for (final r in rows)
            ListTile(
              dense: true,
              title: Text('${r['unit']} · ${r['owners'] ?? '—'}'),
              subtitle: Text('Brüt ${_kurus(r['gross_kurus'])} · stopaj ${_kurus(r['withholding_kurus'])}'),
              trailing: Text(_kurus(toNum(r['gross_kurus']) - toNum(r['withholding_kurus']))),
            ),
          if (rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Toplam brüt ${_kurus(rep['total_gross_kurus'])}, stopaj ${_kurus(rep['total_withholding_kurus'])}. ${rep['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
            ),
        ]);
      },
    );
  }
}
