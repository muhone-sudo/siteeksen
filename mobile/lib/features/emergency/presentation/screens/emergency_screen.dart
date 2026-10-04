// Acil durum (FAZ 7.3, 2026-10-04).
//
// - Bilgi kartı (toplanma alanı, vanalar, acil telefonlar) cihazda saklanır:
//   afette internet olmayabilir, son alınan kart gösterilir.
// - Açık durum bildirimi çağrısı varsa "Güvendeyim / Yardım gerekiyor".
// - Acil bilgi kartım: yardım ihtiyacı özel nitelikli veridir (KVKK m.6);
//   açık rıza olmadan gönderilmez, sakin dilediği an siler.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/data_state.dart';

const emergencyCacheKey = 'emergency_info_v1';

const emergencyPointLabels = {
  'ASSEMBLY_AREA': 'Toplanma alanı',
  'WATER_VALVE': 'Ana su vanası',
  'GAS_VALVE': 'Gaz vanası',
  'ELECTRIC_PANEL': 'Elektrik panosu',
  'GENERATOR': 'Jeneratör',
  'FIRE_PUMP': 'Yangın pompası',
  'FIRE_CABINET': 'Yangın dolabı / tüp',
  'FIRST_AID': 'İlk yardım dolabı',
  'SHELTER': 'Sığınak',
  'OTHER': 'Diğer',
};

/// Önbellekteki kartı çözer; bozuk ya da boşsa null.
Map<String, dynamic>? emergencyInfoFromCache(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final v = jsonDecode(raw);
    return v is Map<String, dynamic> && v['points'] is List ? v : null;
  } catch (_) {
    return null;
  }
}

/// Açık çağrıdaki kendi durum metni.
String safetyStatusLabel(String? status) => switch (status) {
      'SAFE' => 'Güvende olduğunuzu bildirdiniz',
      'NEED_HELP' => 'Yardım talebiniz iletildi',
      _ => 'Henüz durum bildirmediniz',
    };

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Map<String, dynamic>? _info;
  bool _offline = false;
  List<Map> _checks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final info = await apiClient.getEmergencyInfo();
      await prefs.setString(emergencyCacheKey, jsonEncode(info));
      final checks = (await apiClient.getSafetyChecks()).whereType<Map>().toList();
      if (!mounted) return;
      setState(() {
        _info = info;
        _offline = false;
        _checks = checks;
        _loading = false;
      });
    } catch (_) {
      // Ağ yoksa son kaydedilen kart gösterilir; bu durum ekranda açıkça yazar.
      if (!mounted) return;
      setState(() {
        _info = emergencyInfoFromCache(prefs.getString(emergencyCacheKey));
        _offline = true;
        _loading = false;
      });
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _respond(Map check, String status) async {
    try {
      final res = await apiClient.respondSafetyCheck('${check['id']}', status);
      if (!mounted) return;
      _snack('${res['message'] ?? 'Gönderildi'}');
      await _load();
    } catch (e) {
      if (mounted) _snack(toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _checks.where((c) => c['status'] == 'OPEN').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Acil durum')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const ListTile(
                      leading: Icon(Icons.call),
                      title: Text('Acil çağrı: 112'),
                      subtitle: Text('Her türlü acil durumda'),
                    ),
                  ),
                  if (_offline)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('İnternet yok: cihazda kayıtlı son bilgi kartı gösteriliyor.'),
                    ),
                  for (final c in open)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${c['title']}', style: Theme.of(context).textTheme.titleMedium),
                          Text(safetyStatusLabel('${c['my_status'] ?? ''}')),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: FilledButton(onPressed: () => _respond(c, 'SAFE'), child: const Text('Güvendeyim'))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                onPressed: () => _respond(c, 'NEED_HELP'),
                                child: const Text('Yardım gerekiyor'),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  if (_info == null)
                    const EmptyStateView(message: 'Bilgi kartı alınamadı', icon: Icons.cloud_off)
                  else ...[
                    const SizedBox(height: 8),
                    Text('Toplanma alanı ve kritik noktalar', style: Theme.of(context).textTheme.titleSmall),
                    for (final p in ApiClient.listOf(_info!['points']).whereType<Map>())
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text('${emergencyPointLabels['${p['kind']}'] ?? p['kind']}: ${p['name']}'),
                        subtitle: Text('${p['location']}'),
                      ),
                    const Divider(),
                    Text('Acil telefonlar', style: Theme.of(context).textTheme.titleSmall),
                    for (final c in ApiClient.listOf(_info!['contacts']).whereType<Map>())
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text('${c['name']}'),
                        subtitle: SelectableText('${c['phone']}'),
                      ),
                  ],
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.accessible_outlined),
                    title: const Text('Acil bilgi kartım'),
                    subtitle: const Text('Tahliyede yardım ihtiyacınızı yönetimle paylaşın (isteğe bağlı)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyCardScreen())),
                  ),
                ],
              ),
            ),
    );
  }
}

class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  late Future<Map<String, dynamic>> _future;
  final _needs = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final res = await apiClient.getMyEmergencyCards();
    final cards = ApiClient.listOf(res['data']).whereType<Map>().toList();
    if (cards.isNotEmpty) {
      _needs.text = '${cards.first['needs'] ?? ''}';
      _contactName.text = '${cards.first['contact_name'] ?? ''}';
      _contactPhone.text = '${cards.first['contact_phone'] ?? ''}';
    }
    return res;
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<String?> _unitId() async {
    final props = await apiClient.getUserProperties();
    final units = props.whereType<Map>().where((p) => '${p['unit_id'] ?? ''}'.isNotEmpty).toList();
    return units.isEmpty ? null : '${units.first['unit_id']}';
  }

  Future<void> _save(String version) async {
    final unit = await _unitId();
    if (unit == null) {
      _snack('Kayıtlı daireniz bulunamadı');
      return;
    }
    try {
      final res = await apiClient.saveMyEmergencyCard({
        'unit_id': unit,
        'needs': _needs.text.trim(),
        'contact_name': _contactName.text.trim(),
        'contact_phone': _contactPhone.text.trim(),
        'consent': _consent,
        'consent_version': version,
      });
      if (mounted) _snack('${res['message'] ?? 'Kaydedildi'}');
    } catch (e) {
      if (mounted) _snack(toUserMessage(e));
    }
  }

  Future<void> _delete() async {
    final unit = await _unitId();
    if (unit == null) return;
    try {
      await apiClient.deleteMyEmergencyCard(unit);
      if (!mounted) return;
      _needs.clear();
      _contactName.clear();
      _contactPhone.clear();
      setState(() => _consent = false);
      _snack('Kartınız ve rızanız silindi');
    } catch (e) {
      if (mounted) _snack(toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acil bilgi kartım')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: () => setState(() => _future = _load()));
          final d = snap.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            TextField(
              controller: _needs,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Tahliyede yardım ihtiyacı', hintText: 'ör. tekerlekli sandalye, yatağa bağlı yakın, bebek'),
            ),
            TextField(controller: _contactName, decoration: const InputDecoration(labelText: 'Ulaşılacak yakın (isteğe bağlı)')),
            TextField(controller: _contactPhone, decoration: const InputDecoration(labelText: 'Yakının telefonu (isteğe bağlı)')),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: Text('${d['consent_text'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton(
              onPressed: _consent && _needs.text.trim().isNotEmpty ? () => _save('${d['consent_version']}') : null,
              child: const Text('Açık rızamla kaydet'),
            ),
            TextButton(onPressed: _delete, child: const Text('Kartımı ve rızamı sil')),
          ]);
        },
      ),
    );
  }
}
