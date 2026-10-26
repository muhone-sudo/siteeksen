// Araçlarım (FAZ H.6 S2): sakin dairesine araç kaydeder ve pasife alır. Kiracılı dairede
// kullanım işlemini kiracı ve hanesi yapar (072); malik bu durumda gerekçeli 403 alır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/future_list.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _list = GlobalKey<FutureListState>();

  Future<String?> _pickUnit() async {
    final props = await apiClient.getUserProperties();
    final units = props.whereType<Map>().where((p) => (p['unit_id'] ?? '').toString().isNotEmpty).toList();
    if (units.isEmpty) return null;
    if (units.length == 1 || !mounted) return '${units.first['unit_id']}';
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Hangi daire için?'),
        children: [
          for (final u in units)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '${u['unit_id']}'), child: Text('${u['unit_name'] ?? ''}')),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final unit = await _pickUnit();
    if (unit == null || !mounted) return;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VehicleForm(),
    );
    if (data == null || !mounted) return;
    if (await runSnack(context, () => apiClient.createVehicle({...data, 'unit_id': unit}), 'Araç kaydedildi')) {
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Araçlarım')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Araç ekle')),
      body: FutureList(
        key: _list,
        load: apiClient.getVehicles,
        empty: 'Kayıtlı aracınız yok',
        emptyIcon: Icons.directions_car_outlined,
        itemBuilder: (context, v, reload) => ListTile(
          leading: const Icon(Icons.directions_car),
          title: Text('${v['plate']}', style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
          subtitle: Text([v['brand'], v['model'], v['color'], v['unit_name']].where((s) => (s ?? '').toString().isNotEmpty).join(' · ')),
          trailing: v['is_active'] == false
              ? const Text('Pasif')
              : IconButton(
                  tooltip: 'Kaldır',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (!await confirmDialog(context, 'Aracı kaldır', '${v['plate']} pasife alınsın mı? Geçmiş otopark hareketleri korunur.', ok: 'Kaldır')) return;
                    if (!context.mounted) return;
                    if (await runSnack(context, () => apiClient.deleteVehicle('${v['id']}'), 'Araç pasife alındı')) await reload();
                  },
                ),
        ),
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm();

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _key = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Araç ekle', style: Theme.of(context).textTheme.titleLarge),
          TextFormField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Plaka *', hintText: '34 ABC 123'),
            validator: (v) => (v ?? '').trim().length < 5 ? 'Plaka gerekli' : null,
          ),
          TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'Marka')),
          TextFormField(controller: _model, decoration: const InputDecoration(labelText: 'Model')),
          TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Renk')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (!_key.currentState!.validate()) return;
              Navigator.pop(context, {
                'plate': _plate.text.trim().toUpperCase(),
                'brand': _brand.text.trim(),
                'model': _model.text.trim(),
                'color': _color.text.trim(),
              });
            },
            child: const Text('Kaydet'),
          ),
        ]),
      ),
    );
  }
}
