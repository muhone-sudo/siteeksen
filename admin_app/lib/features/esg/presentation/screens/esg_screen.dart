// Karbon ayak izi (FAZ H.7, panel /dashboard/esg ile eşit). Emisyon katsayıları koda gömülü değildir:
// kullanıcı kaynağını belirterek girer; bileşik "sürdürülebilirlik skoru" üretilmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';
import '../../../meters/presentation/screens/meters_screen.dart' show meterTypes;

class EsgScreen extends StatefulWidget {
  const EsgScreen({super.key});

  @override
  State<EsgScreen> createState() => _EsgScreenState();
}

class _EsgScreenState extends State<EsgScreen> {
  DateTime? _from;
  DateTime? _to;
  Map<String, dynamic>? _result;

  Map<String, dynamic> get _range => {if (_from != null) 'from': apiDate(_from!), if (_to != null) 'to': apiDate(_to!)};

  Future<void> _pick(bool from) async {
    final d = await showDatePicker(context: context, initialDate: (from ? _from : _to) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d != null) setState(() => from ? _from = d : _to = d);
  }

  Future<void> _calc(List<Map> lines) async {
    final v = await showForm(context, 'Karbon ayak izi', [
      for (final c in lines)
        FSpec('${c['meter_type']}', '${meterTypes['${c['meter_type']}'] ?? c['meter_type']} katsayısı (kgCO₂e / birim)', type: FType.decimal,
            hint: 'Tüketim ${formatNumber(toNum(c['total_consumption']))}'),
      const FSpec('emission_factor_source', 'Katsayı kaynağı', required: true, hint: "ör. 'TEİAŞ 2025 şebeke emisyon faktörü'"),
    ], submit: 'Hesapla');
    if (v == null || !mounted) return;
    final source = v.remove('emission_factor_source');
    try {
      final r = await apiClient.post('/esg/carbon-footprint', {..._range, 'emission_factors': v, 'emission_factor_source': source});
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Karbon ayak izi')),
      body: ApiObject(
        key: ValueKey('$_from-$_to'),
        load: () => apiClient.getMap('/esg/consumption', query: _range),
        builder: (context, d, _) {
          final lines = ((d['consumption'] as List?) ?? const []).whereType<Map>().toList();
          final res = ((r?['lines'] as List?) ?? const []).whereType<Map>().toList();
          return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
            Row(children: [
              Expanded(child: ListTile(title: const Text('Başlangıç'), subtitle: Text(_from == null ? 'Tümü' : formatDate(apiDate(_from!))), onTap: () => _pick(true))),
              Expanded(child: ListTile(title: const Text('Bitiş'), subtitle: Text(_to == null ? 'Bugün' : formatDate(apiDate(_to!))), onTap: () => _pick(false))),
            ]),
            if (lines.isEmpty) const ListTile(title: Text('Bu aralıkta okuma yok')),
            for (final c in lines)
              ListTile(
                title: Text('${meterTypes['${c['meter_type']}'] ?? c['meter_type']}'),
                subtitle: Text('${c['meter_count']} sayaç · ${c['reading_count']} okuma'),
                trailing: Text(formatNumber(toNum(c['total_consumption']))),
              ),
            Padding(padding: const EdgeInsets.all(16), child: Text('${d['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall)),
            if (lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(onPressed: () => _calc(lines), icon: const Icon(Icons.eco), label: const Text('Hesapla')),
              ),
            if (r != null) ...[
              ListTile(title: Text('Toplam ${formatNumber(toNum(r['total_co2e_kg']))} kg CO₂e', style: const TextStyle(fontWeight: FontWeight.w700))),
              for (final l in res)
                ListTile(
                  dense: true,
                  title: Text('${meterTypes['${l['meter_type']}'] ?? l['meter_type']}'),
                  subtitle: Text('Tüketim ${formatNumber(toNum(l['consumption']))} × ${l['emission_factor']}'),
                  trailing: Text('${formatNumber(toNum(l['co2e_kg']))} kg'),
                ),
              Padding(padding: const EdgeInsets.all(16), child: Text('${r['method'] ?? ''} ${r['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall)),
            ],
          ]);
        },
      ),
    );
  }
}
