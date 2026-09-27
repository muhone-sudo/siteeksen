// Enerji / tüketim analizi.
//
// DÜZELTME (2026-09-27): ekran var olmayan `/energy/summary` ve
// `/energy/consumption` uçlarına gidiyor, "YZ önerileri" ve "tasarruf
// tahmini" bekliyordu. Sunucu yapay zekâ KULLANMAZ; iki gerçek uç vardır:
// - `GET /energy/trends?meter_type=` → aylık toplamlar, aylık ve (13 ay veri
//   varsa) yıllık değişim;
// - `GET /energy/anomalies?meter_type=` → bölüm bazlı tüketim ve alan başına
//   tüketimin medyandan sapmasıyla işaretlenen olağandışı bölümler (gerekçeli).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

/// Sunucunun tanıdığı sayaç türleri.
const meterTypes = {
  'HEAT': 'Isı',
  'WATER_COLD': 'Soğuk su',
  'WATER_HOT': 'Sıcak su',
  'GAS': 'Doğalgaz',
  'ELECTRIC': 'Elektrik',
};

/// `change_pct` + `direction` → "↑ %12,5". Yüzde tanımsızsa (önceki dönem 0)
/// yalnızca yön yazılır; "%100 arttı" uydurulmaz.
String trendText(Object? trend) {
  if (trend is! Map) return '—';
  final arrow = switch (trend['direction']) { 'UP' => '↑', 'DOWN' => '↓', 'FLAT' => '→', _ => '?' };
  final pct = trend['change_pct'];
  if (pct == null) return trend['direction'] == 'FLAT' ? '$arrow değişim yok' : '$arrow (önceki dönem 0)';
  return '$arrow %${formatNumber(toNum(pct).abs())}';
}

class EnergyDashboardScreen extends StatefulWidget {
  const EnergyDashboardScreen({super.key});

  @override
  State<EnergyDashboardScreen> createState() => _EnergyDashboardScreenState();
}

class _EnergyDashboardScreenState extends State<EnergyDashboardScreen> {
  String _type = 'HEAT';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tüketim Analizi'),
          bottom: const TabBar(tabs: [Tab(text: 'Eğilim'), Tab(text: 'Olağandışı')]),
        ),
        body: Column(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              for (final e in meterTypes.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _type == e.key, onSelected: (_) => setState(() => _type = e.key)),
                ),
            ]),
          ),
          Expanded(
            child: TabBarView(children: [
              ApiObject(
                key: ValueKey('t$_type'),
                load: () => apiClient.getMap('/energy/trends', query: {'meter_type': _type, 'months': 13}),
                builder: (context, res, _) => _Trends(res),
              ),
              ApiObject(
                key: ValueKey('a$_type'),
                load: () => apiClient.getMap('/energy/anomalies', query: {'meter_type': _type}),
                builder: (context, res, _) => _Anomalies(res),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

Widget _note(BuildContext context, Object? text) => text is String && text.isNotEmpty
    ? Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: Text(text, style: Theme.of(context).textTheme.bodySmall))
    : const SizedBox.shrink();

class _Trends extends StatelessWidget {
  final Map<String, dynamic> res;
  const _Trends(this.res);

  @override
  Widget build(BuildContext context) {
    final periods = res['periods'] is List ? (res['periods'] as List).whereType<Map>().toList() : const <Map>[];
    final max = periods.fold<num>(0, (m, p) => toNum(p['total_consumption']) > m ? toNum(p['total_consumption']) : m);
    return ListView(children: [
      StatRow([
        ('Önceki aya göre', trendText(res['month_over_month'])),
        ('Geçen yıla göre', res['year_over_year'] == null ? '—' : trendText(res['year_over_year'])),
      ]),
      _note(context, res['year_over_year_note']),
      _note(context, res['note']),
      if (periods.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Bu sayaç türünde okuma yok'))),
      for (final p in periods.reversed)
        ListTile(
          title: Text(periodLabel(p['period'])),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['units_with_reading'] ?? 0} bölüm · ${p['reading_count'] ?? 0} okuma'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: max > 0 ? (toNum(p['total_consumption']) / max).toDouble() : 0),
          ]),
          trailing: Text(formatNumber(toNum(p['total_consumption']))),
        ),
    ]);
  }
}

class _Anomalies extends StatelessWidget {
  final Map<String, dynamic> res;
  const _Anomalies(this.res);

  @override
  Widget build(BuildContext context) {
    final anomalies = res['anomalies'] is List ? (res['anomalies'] as List).whereType<Map>().toList() : const <Map>[];
    final usages = res['usages'] is List ? (res['usages'] as List).whereType<Map>().toList() : const <Map>[];
    return ListView(children: [
      _note(context, res['basis']),
      _note(context, res['excluded_note']),
      _note(context, res['anomalies_note']),
      for (final a in anomalies)
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: Icon(Icons.warning_amber, color: a['severity'] == 'HIGH' ? Colors.red : Colors.orange),
            title: Text('${a['unit_name'] ?? ''}'),
            subtitle: Text('${a['reason'] ?? ''}'),
            trailing: Text('%${formatNumber(toNum(a['deviation_pct']))}'),
          ),
        ),
      if (usages.isNotEmpty)
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 4), child: Text('Bölüm bazlı tüketim (son 12 ay)', style: TextStyle(fontWeight: FontWeight.w600))),
      for (final u in usages)
        ListTile(
          dense: true,
          title: Text('${u['unit_name'] ?? ''}'),
          subtitle: Text((u['per_square_meter'] ?? '').toString().isEmpty
              ? 'Kullanım alanı tanımsız'
              : '${formatNumber(toNum(u['per_square_meter']))} / m²'),
          trailing: Text(formatNumber(toNum(u['consumption']))),
        ),
    ]);
  }
}
