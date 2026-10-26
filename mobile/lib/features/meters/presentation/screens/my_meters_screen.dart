// Sayaçlarım (FAZ H.6 S4): dairenin sayaçları ve okuma geçmişi. Kiracılı dairede kullanım verisini
// kiracı görür (072).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/future_list.dart';

const _types = {'HEAT': 'Isı (kalorimetre)', 'WATER_COLD': 'Soğuk su', 'WATER_HOT': 'Sıcak su', 'GAS': 'Doğal gaz', 'ELECTRIC': 'Elektrik'};

class MyMetersScreen extends StatelessWidget {
  const MyMetersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayaçlarım')),
      body: FutureList(
        load: apiClient.getMyMeters,
        empty: 'Dairenize tanımlı sayaç yok',
        emptyIcon: Icons.speed,
        itemBuilder: (context, m, _) => ListTile(
          leading: const Icon(Icons.speed),
          title: Text('${_types['${m['meter_type']}'] ?? m['meter_type']} · ${m['serial_number']}'),
          subtitle: Text(m['last_reading_date'] != null
              ? 'Son okuma ${formatDate(m['last_reading_date'])}: ${m['last_reading_value'] ?? '—'}'
              : 'Okuma yok'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Readings(meter: m))),
        ),
      ),
    );
  }
}

class _Readings extends StatelessWidget {
  final Map<String, dynamic> meter;
  const _Readings({required this.meter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${meter['serial_number']} okumaları')),
      body: FutureList(
        load: () => apiClient.getMeterReadings('${meter['id']}'),
        empty: 'Okuma yok',
        itemBuilder: (context, r, _) => ListTile(
          title: Text('${formatDate(r['reading_date'])} · ${r['current_value']}'),
          subtitle: Text('Önceki ${r['previous_value']} · tüketim ${r['consumption']}'),
        ),
      ),
    );
  }
}
