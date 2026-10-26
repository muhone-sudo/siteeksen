// Demirbaş Yönetimi Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü demirbaş listesi (marka/model/garanti tarihleri) ve bunlardan
// hesaplanan sahte "toplam değer / garantisi biten" sayaçları gösteriyordu.
// Demirbaş listesi KMK m.39 kapsamında hesap verme belgelerinin parçasıdır;
// uydurma kayıt, yıllık hesabın yanlış çıkmasına yol açar.
// FAZ H.7: kayıt, kategori, amortisman, bakım, zimmet ve hurdaya ayırma panelle eşit.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _conditions = [('NEW', 'Yeni'), ('GOOD', 'İyi'), ('FAIR', 'Orta'), ('POOR', 'Kötü'), ('LOST', 'Kayıp')];
const _mtypes = [('PREVENTIVE', 'Periyodik (önleyici)'), ('CORRECTIVE', 'Arıza (düzeltici)'), ('INSPECTION', 'Muayene / kontrol')];

String _condition(Object? v) => v == 'DISPOSED' ? 'Hurdaya ayrıldı' : _conditions.firstWhere((e) => e.$1 == v, orElse: () => ('', '$v')).$2;

class AssetManagementScreen extends StatefulWidget {
  const AssetManagementScreen({super.key});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _due = false;
  bool _canWrite = false;
  bool _canMaintain = false;

  @override
  void initState() {
    super.initState();
    apiClient.getCurrentUserRoles().then((r) {
      if (mounted) {
        setState(() {
          _canWrite = r.any(writeRoles.contains);
          _canMaintain = _canWrite || r.contains('STAFF');
        });
      }
    });
  }

  Future<void> _addCategory() async {
    await formAction(context, 'Demirbaş kategorisi', const [
      FSpec('name', 'Ad', required: true, hint: 'Bahçe ekipmanı'),
      FSpec('depreciation_years', 'Amortisman süresi (yıl)', type: FType.integer, hint: 'Boşsa amortisman hesaplanmaz'),
      FSpec('description', 'Açıklama'),
    ], (v) => apiClient.post('/asset-categories', v), success: 'Kategori eklendi');
  }

  Future<void> _add() async {
    final cats = await optionsFrom('/asset-categories', (c) => '${c['name']}').catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    if (await formAction(context, 'Demirbaş ekle', [
      const FSpec('name', 'Ad', required: true),
      FSpec('category_id', 'Kategori', type: FType.select, options: cats),
      const FSpec('asset_code', 'Demirbaş kodu'),
      const FSpec('serial_number', 'Seri no'),
      const FSpec('location', 'Konum'),
      const FSpec('condition', 'Durum', type: FType.select, options: _conditions, initial: 'GOOD'),
      const FSpec('purchase_date', 'Alış tarihi', type: FType.date),
      const FSpec('purchase_price', 'Alış bedeli (TL)', type: FType.decimal),
      const FSpec('vendor', 'Tedarikçi'),
      const FSpec('warranty_end', 'Garanti bitişi', type: FType.date),
      const FSpec('depreciation_years', 'Amortisman (yıl)', type: FType.integer, hint: 'Boşsa kategori varsayılanı'),
      const FSpec('maintenance_interval_days', 'Bakım aralığı (gün)', type: FType.integer),
    ], (v) => apiClient.post('/assets', v), success: 'Demirbaş kaydedildi')) {
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demirbaşlar'),
        actions: [
          FilterChip(label: const Text('Bakımı gelen'), selected: _due, onSelected: (v) => setState(() => _due = v)),
          if (_canWrite) IconButton(tooltip: 'Kategori ekle', icon: const Icon(Icons.create_new_folder_outlined), onPressed: _addCategory),
        ],
      ),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Demirbaş')) : null,
      body: ApiList(
        key: _list,
        token: _due,
        load: () => apiClient.getList('/assets', query: {if (_due) 'maintenance_due': 'true'}),
        empty: 'Kayıtlı demirbaş yok',
        emptyIcon: Icons.chair_outlined,
        header: (_) => FutureBuilder<Map<String, dynamic>>(
          future: apiClient.getMap('/assets-summary'),
          builder: (context, snap) {
            final s = snap.data;
            if (s == null) return const SizedBox.shrink();
            return StatRow([
              ('Aktif', '${s['active'] ?? 0}'),
              ('Bakımı gecikmiş', '${s['maintenance_overdue'] ?? 0}'),
              ('Garantisi 30 günde biten', '${s['warranty_expiring_30_days'] ?? 0}'),
              ('Bu yıl bakım gideri', formatTry(toNum(s['maintenance_cost_ytd_try']))),
            ]);
          },
        ),
        itemBuilder: (context, a, reload) => ListTile(
          leading: Icon(toNum(a['maintenance_overdue_days']) > 0 ? Icons.build_circle : Icons.chair,
              color: toNum(a['maintenance_overdue_days']) > 0 ? Colors.red : null),
          title: Text('${a['name'] ?? ''}'),
          subtitle: Text([
            [a['asset_code'], a['category_name'], a['location']].where((x) => x != null && '$x'.isNotEmpty).join(' · '),
            'Defter değeri ${formatTry(toNum(a['book_value']))} · ${_condition(a['condition'])}',
            toNum(a['maintenance_overdue_days']) > 0
                ? 'Bakım ${a['maintenance_overdue_days']} gün gecikti'
                : 'Sonraki bakım ${formatDate(a['next_maintenance_date'])}',
          ].where((s) => s.isNotEmpty).join('\n')),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _AssetDetail(asset: a, canWrite: _canWrite, canMaintain: _canMaintain)));
            await reload();
          },
        ),
      ),
    );
  }
}

class _AssetDetail extends StatefulWidget {
  final Map<String, dynamic> asset;
  final bool canWrite;
  final bool canMaintain;
  const _AssetDetail({required this.asset, required this.canWrite, required this.canMaintain});

  @override
  State<_AssetDetail> createState() => _AssetDetailState();
}

class _AssetDetailState extends State<_AssetDetail> {
  int _token = 0;
  String get _id => '${widget.asset['id']}';

  void _changed() => setState(() => _token++);

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    final active = a['status'] != 'DISPOSED';
    return Scaffold(
      appBar: AppBar(title: Text('${a['name'] ?? ''}'), actions: [
        if (active)
          RowMenu([
            if (widget.canMaintain)
              ('Bakım kaydı', () async {
                if (await formAction(context, 'Bakım kaydı', [
                  const FSpec('maintenance_type', 'Tür', type: FType.select, options: _mtypes, initial: 'PREVENTIVE', required: true),
                  FSpec('performed_at', 'Tarih', type: FType.date, initial: DateTime.now()),
                  const FSpec('labor_cost', 'İşçilik (TL)', type: FType.decimal),
                  const FSpec('parts_cost', 'Parça (TL)', type: FType.decimal),
                  const FSpec('performed_by', 'Yapan'),
                  const FSpec('new_condition', 'Yeni durum', type: FType.select, options: _conditions, hint: 'Değişmedi'),
                  const FSpec('description', 'Açıklama', type: FType.multiline, required: true),
                ], (v) async {
                  final r = await apiClient.post('/assets/$_id/maintenance', {'labor_cost': 0, 'parts_cost': 0, ...v});
                  return {...r, 'message': 'Bakım kaydedildi (toplam ${formatTry(toNum(r['total_cost']))})'};
                })) {
                  _changed();
                }
              }),
            if (widget.canWrite)
              ('Zimmet', () async {
                final who = await askText(context, 'Zimmet', 'Zimmetlenen kişi / birim (boşsa zimmet kaldırılır)',
                    required: false, initial: '${a['assigned_to'] ?? ''}');
                if (who == null || !context.mounted) return;
                if (await runAction(context, () => apiClient.post('/assets/$_id/assign', {'assigned_to': who}),
                    success: who.isEmpty ? 'Zimmet kaldırıldı' : 'Zimmet kaydedildi')) {
                  a['assigned_to'] = who;
                  _changed();
                }
              }),
            if (widget.canWrite)
              ('Hurdaya ayır', () async {
                if (await formAction(context, 'Hurdaya ayır', const [
                  FSpec('reason', 'Gerekçe', type: FType.multiline, required: true),
                  FSpec('decision_ref', 'Karar referansı', required: true, hint: 'Yönetim/kurul kararının tarih ve numarası'),
                ], (v) => apiClient.post('/assets/$_id/dispose', v), submit: 'Hurdaya ayır', success: 'Demirbaş hurdaya ayrıldı')) {
                  if (context.mounted) Navigator.pop(context);
                }
              }),
          ]),
      ]),
      body: ApiList(
        token: _token,
        load: () => apiClient.getList('/assets/$_id/maintenance'),
        empty: 'Bakım kaydı yok',
        header: (_) => FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_token),
          future: apiClient.getMap('/assets/$_id'),
          builder: (context, snap) {
            final d = snap.data;
            final dep = d?['depreciation'] as Map?;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ListTile(
                title: Text([a['asset_code'], a['category_name'], a['location']].where((x) => x != null && '$x'.isNotEmpty).join(' · ')),
                subtitle: Text([
                  'Durum: ${_condition(a['condition'])}',
                  if (a['purchase_price'] != null) 'Alış ${formatTry(toNum(a['purchase_price']))} (${formatDate(a['purchase_date'])})',
                  if (a['warranty_end'] != null) 'Garanti ${formatDate(a['warranty_end'])}',
                  if ((a['assigned_to'] ?? '').toString().isNotEmpty) 'Zimmet: ${a['assigned_to']}',
                ].join('\n')),
              ),
              if (d != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(dep != null
                      ? 'Birikmiş amortisman ${formatTry(toNum(dep['accumulated']))} · defter değeri ${formatTry(toNum(dep['book_value']))} · yıllık ${formatTry(toNum(dep['annual_amount']))}${dep['fully_depreciated'] == true ? ' · tamamen amorti edildi' : ''}'
                      : '${d['depreciation_note'] ?? 'Amortisman hesaplanamadı (alış tarihi/bedeli yok).'}'),
                ),
              const ListTile(title: Text('Bakım geçmişi', style: TextStyle(fontWeight: FontWeight.w600))),
            ]);
          },
        ),
        itemBuilder: (context, m, _) => ListTile(
          title: Text('${_mtypes.firstWhere((t) => t.$1 == m['maintenance_type'], orElse: () => ('', '${m['maintenance_type']}')).$2} · ${formatTry(toNum(m['total_cost']))}'),
          subtitle: Text([formatDate(m['performed_at']), '${m['description'] ?? ''}', if (m['performed_by'] != null) '${m['performed_by']}'].join(' · ')),
        ),
      ),
    );
  }
}
