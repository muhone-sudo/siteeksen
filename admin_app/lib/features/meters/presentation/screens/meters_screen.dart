// Sayaçlar.
//
// DÜZELTME (2026-09-26): süzgeç `type` parametresiyle gönderiliyordu (sunucu
// `meter_type` bekler — her sekme bütün sayaçları gösteriyordu); `last_reading`
// / `last_read_at` alanları yoktu ve daire yerine kimlik gösteriliyordu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const meterTypes = {
  'HEAT': 'Isı payölçer',
  'WATER_COLD': 'Soğuk su',
  'WATER_HOT': 'Sıcak su',
  'GAS': 'Doğalgaz',
  'ELECTRIC': 'Elektrik',
};

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayaçlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meters/reading'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Okuma gir'),
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final t in [null, ...meterTypes.keys])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t == null ? 'Tümü' : meterTypes[t]!),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ApiList(
            token: _type,
            load: () => apiClient.getList('/meters', query: {'meter_type': _type}),
            empty: 'Sayaç yok',
            itemBuilder: (context, m, _) => ListTile(
              title: Text('${m['unit_name'] ?? ''} · ${meterTypes['${m['meter_type']}'] ?? m['meter_type']}'),
              subtitle: Text([
                'Seri: ${m['serial_number'] ?? '—'}',
                if (m['last_reading_value'] != null)
                  'Son okuma: ${m['last_reading_value']} (${formatDate(m['last_reading_date'])})'
                else
                  'Henüz okuma yok',
              ].join(' · ')),
              trailing: m['is_active'] == false ? const StatusChip('Pasif', color: Colors.grey) : null,
            ),
          ),
        ),
      ]),
    );
  }
}
