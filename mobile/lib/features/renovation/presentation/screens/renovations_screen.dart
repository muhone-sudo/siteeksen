// Tadilat izni (FAZ 7.5, 2026-10-04).
//
// Malik ya da vekil kendi dairesi için başvurur ve sonucunu izler. Dairenin
// diğer sakinleri de dairelerine ait izinleri görür. Ortak yer ve dış cephe
// değişikliği kat maliklerinin 4/5 yazılı rızasını ister (KMK m.19/2).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const renovationScopeLabels = {
  'INTERIOR': 'İç tadilat (taşıyıcıya dokunmayan)',
  'STRUCTURAL': 'Taşıyıcı sistem / esaslı tadilat',
  'COMMON_AREA': 'Ortak yerde değişiklik',
  'FACADE': 'Dış cephe / balkon / pencere',
};

const renovationScopeHints = {
  'INTERIOR': 'Yönetim onayından sonra çalışmaya başlayabilirsiniz.',
  'STRUCTURAL': 'Yapı ruhsatı / belediye izni gerekir (İmar K. m.21). Anayapıya zarar verecek değişiklik yapılamaz (KMK m.19/2).',
  'COMMON_AREA': 'Bütün kat maliklerinin beşte dördünün yazılı rızası gerekir (KMK m.19/2).',
  'FACADE': 'Bütün kat maliklerinin beşte dördünün yazılı rızası gerekir (KMK m.19/2).',
};

/// İznin durum metni.
String renovationStatusText(Map<dynamic, dynamic> p) {
  switch (p['status']) {
    case 'PENDING':
      return 'Yönetim onayı bekleniyor';
    case 'APPROVED':
      final hours = '${p['work_hours'] ?? ''}';
      return hours.isEmpty ? 'Onaylandı' : 'Onaylandı · çalışma saatleri: $hours';
    case 'REJECTED':
      return 'Reddedildi: ${p['decision_note'] ?? ''}';
    case 'STOPPED':
      return 'Durduruldu: ${p['stop_reason'] ?? ''}';
    case 'COMPLETED':
      final deposit = toNum(p['deposit_amount']);
      if (deposit > 0) {
        return 'Tamamlandı · teminat iadesi ${formatTry(toNum(p['deposit_refunded']))} / ${formatTry(deposit)}';
      }
      return 'Tamamlandı';
    case 'CANCELLED':
      return 'Geri çekildi';
    default:
      return '${p['status']}';
  }
}

class RenovationsScreen extends StatefulWidget {
  const RenovationsScreen({super.key});

  @override
  State<RenovationsScreen> createState() => _RenovationsScreenState();
}

class _RenovationsScreenState extends State<RenovationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getRenovations();
  }

  Future<void> _cancel(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Başvuruyu geri çek'),
        content: const Text('Tadilat izni başvurunuz geri çekilsin mi? Gerekirse yeniden başvurabilirsiniz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Geri çek')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiClient.cancelRenovation('${p['id']}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başvuru geri çekildi')));
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getRenovations());
    await _future;
  }

  Future<void> _create() async {
    final props = await apiClient.getUserProperties();
    final units = props
        .whereType<Map>()
        .where((p) => '${p['unit_id'] ?? ''}'.isNotEmpty)
        .where((p) => p['role'] == null || p['role'] == 'OWNER' || p['role'] == 'PROXY')
        .toList();
    if (!mounted) return;
    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tadilat başvurusunu dairenin maliki ya da vekili yapabilir.')));
      return;
    }
    var unitId = '${units.first['unit_id']}';
    var scope = 'INTERIOR';
    final desc = TextEditingController();
    final contractor = TextEditingController();
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var end = start.add(const Duration(days: 7));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tadilat başvurusu'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (units.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: unitId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Daire'),
                  items: [
                    for (final u in units)
                      DropdownMenuItem(value: '${u['unit_id']}', child: Text('${u['property_name'] ?? ''} · ${u['unit_name'] ?? ''}')),
                  ],
                  onChanged: (v) => setLocal(() => unitId = v ?? unitId),
                ),
              DropdownButtonFormField<String>(
                initialValue: scope,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kapsam'),
                items: [
                  for (final e in renovationScopeLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setLocal(() => scope = v ?? 'INTERIOR'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(renovationScopeHints[scope] ?? '', style: Theme.of(ctx).textTheme.bodySmall),
              ),
              TextField(
                controller: desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Yapılacak iş', hintText: 'En az 10 karakter'),
              ),
              TextField(controller: contractor, decoration: const InputDecoration(labelText: 'Usta / firma (isteğe bağlı)')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Tarih: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}'),
                trailing: const Icon(Icons.date_range),
                onTap: () async {
                  final r = await showDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: DateTime(now.year + 1, now.month, now.day),
                    initialDateRange: DateTimeRange(start: start, end: end),
                  );
                  if (r != null) {
                    setLocal(() {
                      start = r.start;
                      end = r.end;
                    });
                  }
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await apiClient.createRenovation({
        'unit_id': unitId,
        'scope': scope,
        'description': desc.text.trim(),
        'contractor_name': contractor.text.trim(),
        'start_date': apiDate(start),
        'end_date': apiDate(end),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Başvurunuz alındı. ${res['requirement'] ?? ''}')));
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tadilat izinleri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Başvuru yap'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (items.isEmpty) const EmptyStateView(message: 'Tadilat izni yok', icon: Icons.handyman_outlined),
                for (final p in items)
                  ListTile(
                    leading: const Icon(Icons.handyman_outlined),
                    title: Text('${p['unit']} · ${renovationScopeLabels['${p['scope']}'] ?? p['scope']}'),
                    subtitle: Text('${formatDate(p['start_date'])} – ${formatDate(p['end_date'])}\n${renovationStatusText(p)}'),
                    isThreeLine: true,
                    // Bekleyen başvuruyu yalnız başvuran geri çekebilir (sunucu denetler; FAZ H.6 S6).
                    trailing: p['status'] == 'PENDING'
                        ? TextButton(onPressed: () => _cancel(Map<String, dynamic>.from(p)), child: const Text('Geri çek'))
                        : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
