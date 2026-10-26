// Stok (sarf malzeme).
//
// DÜZELTME (2026-09-26): `quantity`, `min_quantity`, `category` alanları yoktu
// (sunucu current_stock / minimum_stock METİN, category_name); stok hareketi
// var olmayan `/stock-movements` yoluna gidiyordu.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _units = ['ADET', 'KG', 'LT', 'METRE', 'M2', 'M3', 'PAKET', 'KUTU'];
const _moveLabels = {'IN': 'Giriş', 'OUT': 'Çıkış', 'ADJUST': 'Sayım'};

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  bool _belowOnly = false;
  bool _canAdjust = false;
  final _list = GlobalKey<ApiListState>();

  Future<void> _addCategory() async {
    await formAction(context, 'Stok kategorisi ekle', const [
      FSpec('name', 'Ad', required: true),
      FSpec('description', 'Açıklama'),
    ], (v) => apiClient.post('/inventory-categories', v), success: 'Kategori eklendi');
  }

  Future<void> _addItem() async {
    final cats = await optionsFrom('/inventory-categories', (c) => '${c['name']}').catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    if (await formAction(context, 'Stok kalemi ekle', [
      const FSpec('name', 'Ad', required: true),
      FSpec('unit', 'Birim', type: FType.select, options: [for (final u in _units) (u, u)], initial: 'ADET', required: true),
      FSpec('category_id', 'Kategori', type: FType.select, options: cats),
      const FSpec('sku', 'Stok kodu'),
      const FSpec('minimum_stock', 'Asgari stok', hint: 'ör. 5'),
      const FSpec('location', 'Konum'),
    ], (v) => apiClient.post('/inventory', v), success: 'Kalem eklendi (açılış stoğu 0 — mevcut stoğu sayım düzeltmesiyle girin)')) {
      await _list.currentState?.reload();
    }
  }

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canAdjust = v);
    });
  }

  Future<void> _move(Map item, Future<void> Function() reload) async {
    final formKey = GlobalKey<FormState>();
    final qty = TextEditingController();
    final notes = TextEditingController();
    var type = 'OUT';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('${item['name']} — stok hareketi'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Hareket'),
                items: [
                  const DropdownMenuItem(value: 'IN', child: Text('Giriş (alım)')),
                  const DropdownMenuItem(value: 'OUT', child: Text('Çıkış (kullanım)')),
                  if (_canAdjust) const DropdownMenuItem(value: 'ADJUST', child: Text('Sayım düzeltmesi')),
                ],
                onChanged: (v) => set(() => type = v ?? type),
              ),
              TextFormField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Miktar (${item['unit'] ?? ''})'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Miktar gerekli' : null,
              ),
              TextFormField(
                controller: notes,
                decoration: InputDecoration(labelText: type == 'ADJUST' ? 'Açıklama (zorunlu)' : 'Açıklama'),
                validator: (v) => type == 'ADJUST' && (v == null || v.trim().isEmpty) ? 'Sayım düzeltmesinde açıklama zorunlu' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            }, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      // Miktar METİN gider ("2,5" de kabul edilir); sunucu kuruş/ondalık hassas işler.
      final saved = await runAction(context, () => apiClient.post('/inventory/${item['id']}/movements', {
            'movement_type': type,
            'quantity': qty.text.trim(),
            if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
            'reference_type': switch (type) { 'IN' => 'PURCHASE', 'OUT' => 'USAGE', _ => 'ADJUSTMENT' },
          }));
      if (saved) await reload();
    }
    qty.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok'),
        actions: [
          FilterChip(label: const Text('Asgarinin altı'), selected: _belowOnly, onSelected: (v) => setState(() => _belowOnly = v)),
          IconButton(
            tooltip: 'Son hareketler',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Movements(title: 'Son hareketler', load: () => apiClient.getList('/inventory-movements', query: {'limit': 100})))),
          ),
          if (_canAdjust) IconButton(tooltip: 'Kategori ekle', icon: const Icon(Icons.create_new_folder_outlined), onPressed: _addCategory),
        ],
      ),
      floatingActionButton: _canAdjust ? FloatingActionButton.extended(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Kalem')) : null,
      body: ApiList(
        key: _list,
        token: _belowOnly,
        load: () => apiClient.getList('/inventory', query: {if (_belowOnly) 'below_minimum': 'true'}),
        empty: _belowOnly ? 'Asgarinin altında kalem yok' : 'Stok kalemi yok',
        header: (_) => FutureBuilder<Map<String, dynamic>>(
          future: apiClient.getMap('/inventory-summary'),
          builder: (context, snap) {
            final s = snap.data;
            if (s == null) return const SizedBox.shrink();
            return StatRow([
              ('Kalem', '${s['item_count'] ?? 0}'),
              ('Asgarinin altı', '${s['below_minimum'] ?? 0}'),
              ('Tükenen', '${s['out_of_stock'] ?? 0}'),
              ('Stok değeri', formatTry(toNum(s['total_value_try']))),
            ]);
          },
        ),
        itemBuilder: (context, i, reload) => ListTile(
          title: Text('${i['name'] ?? ''}'),
          subtitle: Text([
            'Mevcut: ${i['current_stock'] ?? '0'} ${i['unit'] ?? ''}',
            'Asgari: ${i['minimum_stock'] ?? '0'}',
            if ((i['category_name'] ?? '').toString().isNotEmpty) '${i['category_name']}',
            if ((i['location'] ?? '').toString().isNotEmpty) '${i['location']}',
          ].join(' · ')),
          leading: Icon(i['below_minimum'] == true ? Icons.warning_amber : Icons.inventory_2,
              color: i['below_minimum'] == true ? Colors.orange : null),
          trailing: RowMenu([
            ('Hareket gir', () => _move(i, reload)),
            ('Hareket geçmişi', () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Movements(title: '${i['name']} — geçmiş', load: () => apiClient.getList('/inventory/${i['id']}/movements', query: {'limit': 100}))));
            }),
            if (_canAdjust)
              ('Pasife al', () async {
                if (await reasonAction(context, '${i['name']} pasife al', (r) => apiClient.delete('/inventory/${i['id']}', {'reason': r}),
                    success: 'Kalem pasife alındı; hareket geçmişi korunur')) {
                  await reload();
                }
              }),
          ]),
        ),
      ),
    );
  }
}

class _Movements extends StatelessWidget {
  final String title;
  final Future<List<dynamic>> Function() load;
  const _Movements({required this.title, required this.load});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ApiList(
        load: load,
        empty: 'Hareket yok',
        itemBuilder: (context, m, _) => ListTile(
          leading: Icon(switch (m['movement_type']) { 'IN' => Icons.south, 'OUT' => Icons.north, _ => Icons.tune }),
          title: Text([
            if ((m['item_name'] ?? '').toString().isNotEmpty) '${m['item_name']}',
            '${_moveLabels[m['movement_type']] ?? m['movement_type']} ${m['quantity']} ${m['unit'] ?? ''}',
          ].join(' · ')),
          subtitle: Text([
            '${m['previous_stock']} → ${m['new_stock']}',
            formatDateTime(m['created_at']),
            if ((m['created_by_name'] ?? '').toString().isNotEmpty) '${m['created_by_name']}',
            if ((m['notes'] ?? '').toString().isNotEmpty) '${m['notes']}',
          ].join(' · ')),
        ),
      ),
    );
  }
}
