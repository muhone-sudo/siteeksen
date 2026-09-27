// Sayaç okuma girişi.
//
// DÜZELTME (2026-09-26): toplu okuma var olmayan `/meters/bulk-readings`
// yoluna gidiyordu (her kayıt 404). Okumalar sayaç başına `POST /meter-readings`
// ile gönderilir; sunucu zinciri denetler (önceki okumadan küçük değer,
// geleceğe tarih → 409/422) ve nedenini söyler. Değer METİN olarak gider:
// kayan noktalı sayı ondalık hanelerde sapma üretir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import 'meters_screen.dart' show meterTypes;

/// "1.234,5" / "1234,5" / "1234.5" → "1234.5". Geçersizse null.
String? normalizeReading(String input) {
  var t = input.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) t = t.replaceAll('.', '').replaceAll(',', '.');
  return RegExp(r'^\d+(\.\d+)?$').hasMatch(t) ? t : null;
}

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  final _values = <String, TextEditingController>{};
  final _results = <String, String>{};
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final entries = _values.entries.where((e) => e.value.text.trim().isNotEmpty).toList();
    if (entries.isEmpty) return;
    setState(() {
      _saving = true;
      _results.clear();
    });
    var ok = 0;
    for (final e in entries) {
      final v = normalizeReading(e.value.text);
      if (v == null) {
        _results[e.key] = 'Geçersiz değer';
        continue;
      }
      try {
        final res = await apiClient.post('/meter-readings', {
          'meter_id': e.key,
          'current_value': v,
          'reading_date': apiDate(_date),
          'reading_type': 'MANUAL',
        });
        ok++;
        _results[e.key] = 'Kaydedildi${res['note'] is String ? ' — ${res['note']}' : ''}';
        e.value.clear();
      } catch (err) {
        _results[e.key] = errorText(err);
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok / ${entries.length} okuma kaydedildi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaç Okuma'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(formatDate(_date)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Kaydediliyor…' : 'Girilen okumaları kaydet')),
        ),
      ),
      body: ApiList(
        load: () => apiClient.getList('/meters'),
        empty: 'Sayaç yok',
        itemBuilder: (context, m, _) {
          final id = '${m['id']}';
          final c = _values.putIfAbsent(id, TextEditingController.new);
          final result = _results[id];
          return ListTile(
            title: Text('${m['unit_name'] ?? ''} · ${meterTypes['${m['meter_type']}'] ?? m['meter_type']}'),
            subtitle: Text([
              'Son: ${m['last_reading_value'] ?? '—'}',
              if (result != null) result,
            ].join('\n')),
            trailing: SizedBox(
              width: 120,
              child: TextField(
                controller: c,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Yeni değer', isDense: true),
              ),
            ),
          );
        },
      ),
    );
  }
}
