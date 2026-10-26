// Sensörler ve alarmlar (074, FAZ H.4). Cihaz okumayı kendi anahtarıyla gönderir; eşik dışı
// değer, tetiklenen ikili sensör ya da kesilen sinyal alarm açar ve işletme ekibine bildirim gider.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const _types = {
  'WATER_LEAK': 'Su kaçağı', 'TEMPERATURE': 'Sıcaklık', 'HUMIDITY': 'Nem', 'SMOKE': 'Duman', 'GAS': 'Gaz',
  'POWER_OUTAGE': 'Elektrik kesintisi', 'TANK_LEVEL': 'Depo seviyesi', 'ELEVATOR_FAULT': 'Asansör arızası',
  'DOOR_OPEN': 'Kapı açık', 'OTHER': 'Diğer',
};
const _binary = {'WATER_LEAK', 'SMOKE', 'GAS', 'POWER_OUTAGE', 'ELEVATOR_FAULT', 'DOOR_OPEN'};
const _states = {
  'OK': ('Normal', Colors.green), 'ALERT': ('Alarm', Colors.red), 'OFFLINE': ('Sinyal yok', Colors.orange),
  'NO_DATA': ('Veri gelmedi', Colors.grey), 'PASSIVE': ('Pasif', Colors.grey),
};
const _alertStatus = {'OPEN': 'Açık', 'ACKNOWLEDGED': 'Onaylandı', 'CLOSED': 'Kapatıldı'};
const _writeRoles = ['MANAGER', 'BOARD_MEMBER'];
const _actRoles = ['MANAGER', 'BOARD_MEMBER', 'STAFF'];

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  bool _canWrite = false;
  bool _canAct = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    hasAnyRole(_writeRoles).then((v) => mounted ? setState(() => _canWrite = v) : null);
    hasAnyRole(_actRoles).then((v) => mounted ? setState(() => _canAct = v) : null);
  }

  void _refresh() => setState(() => _token++);

  Future<void> _showKey(String key, String note) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cihaz anahtarı'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bu anahtar bir daha gösterilmez. Şimdi cihaza girin.', style: TextStyle(color: Colors.orange)),
          const SizedBox(height: 8),
          SelectableText(key, style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: key)),
            child: const Text('Kopyala'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }

  Future<void> _edit([Map<String, dynamic>? s]) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SensorForm(initial: s),
    );
    if (res == null || !mounted) return;
    if (s == null) {
      try {
        final r = await apiClient.post('/sensors', res);
        if (!mounted) return;
        _refresh();
        await _showKey('${r['device_key']}', '${r['note'] ?? ''}');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    } else if (await runAction(context, () => apiClient.patch('/sensors/${s['id']}', res), success: 'Sensör güncellendi')) {
      _refresh();
    }
  }

  Future<void> _rotate(Map<String, dynamic> s) async {
    if (!await confirm(context, 'Anahtarı yenile', 'Yeni anahtar üretilecek; eski anahtar hemen geçersiz olur.', ok: 'Yenile')) return;
    try {
      final r = await apiClient.post('/sensors/${s['id']}/rotate-key');
      if (mounted) await _showKey('${r['device_key']}', '${r['note'] ?? ''}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  void _history(Map<String, dynamic> s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          ListTile(title: Text('${s['name']} — son 24 saat')),
          Expanded(
            child: ApiList(
              load: () async => ((await apiClient.getMap('/sensors/${s['id']}/data', query: {'hours': 24}))['data'] as List?) ?? [],
              empty: 'Son 24 saatte okuma yok',
              itemBuilder: (context, r, _) => ListTile(
                dense: true,
                title: Text(s['binary'] == true
                    ? ((r['value'] as num) >= 1 ? 'Tetiklendi' : 'Normal')
                    : '${r['value']} ${s['unit_label'] ?? ''}'),
                trailing: Text(formatDateTime(r['recorded_at'])),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sensörler'),
          bottom: const TabBar(tabs: [Tab(text: 'Alarmlar'), Tab(text: 'Sensörler')]),
        ),
        floatingActionButton: _canWrite
            ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Sensör ekle'))
            : null,
        body: TabBarView(children: [
          ApiList(
            token: _token,
            load: () async => ((await apiClient.getMap('/iot/alerts', query: {'status': 'ACTIVE'}))['data'] as List?) ?? [],
            empty: 'Açık alarm yok',
            emptyIcon: Icons.check_circle_outline,
            itemBuilder: (context, a, reload) => ListTile(
              leading: Icon(a['kind'] == 'OFFLINE' ? Icons.signal_wifi_off : Icons.warning_amber, color: a['kind'] == 'OFFLINE' ? Colors.orange : Colors.red),
              title: Text('${a['sensor_name']} · ${a['kind_label']}'),
              subtitle: Text('${a['type_label']}${(a['location'] ?? '').toString().isNotEmpty ? ' · ${a['location']}' : ''}\n'
                  '${formatDateTime(a['opened_at'])} · ${_alertStatus[a['status']] ?? a['status']}'
                  '${a['value'] != null ? ' · değer ${a['value']}' : ''}${a['normalized_at'] != null ? ' · normale döndü' : ''}'),
              isThreeLine: true,
              trailing: !_canAct
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'ack') {
                          if (await runAction(context, () => apiClient.post('/iot/alerts/${a['id']}/acknowledge'), success: 'Alarm onaylandı')) await reload();
                        } else {
                          final note = await askText(context, 'Alarmı kapat', 'Ne yapıldı?');
                          if (note == null || !context.mounted) return;
                          if (await runAction(context, () => apiClient.post('/iot/alerts/${a['id']}/close', {'note': note}), success: 'Alarm kapatıldı')) {
                            await reload();
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (a['status'] == 'OPEN') const PopupMenuItem(value: 'ack', child: Text('Onayla')),
                        const PopupMenuItem(value: 'close', child: Text('Kapat')),
                      ],
                    ),
            ),
          ),
          ApiList(
            token: _token,
            load: () async => ((await apiClient.getMap('/sensors'))['data'] as List?) ?? [],
            empty: 'Sensör tanımlanmamış',
            emptyIcon: Icons.sensors_off,
            itemBuilder: (context, s, reload) {
              final st = _states[s['state']] ?? ('${s['state']}', Colors.grey);
              final last = s['last_value'] == null
                  ? '—'
                  : s['binary'] == true
                      ? ((s['last_value'] as num) >= 1 ? 'Tetiklendi' : 'Normal')
                      : '${s['last_value']} ${s['unit_label'] ?? ''}';
              return ListTile(
                leading: const Icon(Icons.sensors),
                title: Text('${s['name']}'),
                subtitle: Text('${s['type_label']}${(s['location'] ?? '').toString().isNotEmpty ? ' · ${s['location']}' : ''}\n'
                    'Son değer: $last · ${s['last_seen_at'] != null ? formatDateTime(s['last_seen_at']) : 'sinyal yok'}'),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  StatusChip(st.$1, color: st.$2),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'history') _history(s);
                      if (v == 'edit') _edit(s);
                      if (v == 'rotate') _rotate(s);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'history', child: Text('Geçmiş')),
                      if (_canWrite) const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      if (_canWrite) const PopupMenuItem(value: 'rotate', child: Text('Anahtarı yenile')),
                    ],
                  ),
                ]),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _SensorForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _SensorForm({this.initial});

  @override
  State<_SensorForm> createState() => _SensorFormState();
}

class _SensorFormState extends State<_SensorForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: '${widget.initial?['name'] ?? ''}');
  late final _loc = TextEditingController(text: '${widget.initial?['location'] ?? ''}');
  late final _unit = TextEditingController(text: '${widget.initial?['unit_label'] ?? ''}');
  late final _min = TextEditingController(text: widget.initial?['min_threshold']?.toString() ?? '');
  late final _max = TextEditingController(text: widget.initial?['max_threshold']?.toString() ?? '');
  late final _off = TextEditingController(text: '${widget.initial?['offline_after_minutes'] ?? 30}');
  late String _type = '${widget.initial?['sensor_type'] ?? 'TEMPERATURE'}';
  late bool _active = widget.initial?['is_active'] != false;

  double? _num(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final binary = _binary.contains(_type);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.initial == null ? 'Sensör ekle' : 'Sensörü düzenle', style: Theme.of(context).textTheme.titleLarge),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Ad *'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Ad gerekli' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tür *'),
            items: [for (final e in _types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          TextFormField(controller: _loc, decoration: const InputDecoration(labelText: 'Konum')),
          if (!binary) ...[
            TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Birim (°C, %, cm)')),
            TextFormField(
              controller: _min,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Alt eşik'),
            ),
            TextFormField(
              controller: _max,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Üst eşik'),
              validator: (_) => _num(_min.text) == null && _num(_max.text) == null ? 'En az bir eşik gerekli' : null,
            ),
          ],
          TextFormField(
            controller: _off,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sinyal kesilme süresi (dk) *'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              return n == null || n < 2 || n > 1440 ? '2-1440 arası olmalı' : null;
            },
          ),
          if (widget.initial != null)
            SwitchListTile(value: _active, onChanged: (v) => setState(() => _active = v), title: const Text('Etkin')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (!_key.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'sensor_type': _type,
                'location': _loc.text.trim(),
                'unit_label': binary ? '' : _unit.text.trim(),
                'min_threshold': binary ? null : _num(_min.text),
                'max_threshold': binary ? null : _num(_max.text),
                'offline_after_minutes': int.parse(_off.text.trim()),
                if (widget.initial != null) 'is_active': _active,
              });
            },
            child: const Text('Kaydet'),
          ),
        ]),
      ),
    );
  }
}
