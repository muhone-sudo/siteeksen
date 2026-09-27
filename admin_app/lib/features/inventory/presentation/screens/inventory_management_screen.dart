// Stok (sarf malzeme).
//
// DÜZELTME (2026-09-26): `quantity`, `min_quantity`, `category` alanları yoktu
// (sunucu current_stock / minimum_stock METİN, category_name); stok hareketi
// var olmayan `/stock-movements` yoluna gidiyordu.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  bool _belowOnly = false;
  bool _canAdjust = false;

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
          const SizedBox(width: 8),
        ],
      ),
      body: ApiList(
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
          trailing: IconButton(icon: const Icon(Icons.swap_vert), tooltip: 'Hareket', onPressed: () => _move(i, reload)),
        ),
      ),
    );
  }
}
