// Kural ihlali (FAZ 7.5, 2026-10-04).
//
// Sakin, yönetim planı kurallarını görür, ihlal bildirir (kimliği ihlal
// bildirilen daireye gösterilmez) ve dairesiyle ilgili kayıtlara savunma yazar.
// Site yönetimi para cezası veremez; süreç uyarı → ihtar → sulh hukuk
// mahkemesi (KMK m.33).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const violationStageLabels = {
  'NONE': 'Değerlendiriliyor',
  'VERBAL_WARNING': 'Sözlü uyarı',
  'WRITTEN_WARNING': 'Yazılı uyarı',
  'FORMAL_NOTICE': 'İhtar',
  'LEGAL': 'Hukuki yol (KMK m.33)',
};

/// Kaydın sakine gösterilen durum metni.
String violationStatusText(Map<dynamic, dynamic> v) {
  switch (v['status']) {
    case 'OPEN':
      return 'Yönetim değerlendiriyor';
    case 'DISMISSED':
      return 'Doğrulanmadı';
    case 'RESOLVED':
      return 'Kapandı';
    default:
      return violationStageLabels['${v['stage']}'] ?? '${v['stage']}';
  }
}

/// Kayıt kişinin kendi bildirimi mi (bildiren alanı yalnızca bildirene dolu gelir).
bool isOwnReport(Map<dynamic, dynamic> v) => '${v['reported_by'] ?? ''}'.isNotEmpty;

class ViolationsScreen extends StatefulWidget {
  const ViolationsScreen({super.key});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getViolations();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getViolations());
    await _future;
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _report() async {
    try {
      final rules = (await apiClient.getSiteRules()).whereType<Map>().toList();
      final units = (await apiClient.getUnits()).whereType<Map>().toList();
      if (!mounted) return;
      if (rules.isEmpty) {
        _snack('Yönetim henüz kural tanımlamamış.');
        return;
      }
      String? ruleId, unitId;
      final desc = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Kural ihlali bildir'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kural'),
                  items: [
                    for (final r in rules)
                      DropdownMenuItem(value: '${r['id']}', child: Text('${r['title']}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setLocal(() => ruleId = v),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Daire'),
                  items: [
                    for (final u in units)
                      DropdownMenuItem(value: '${u['id']}', child: Text('${u['block']}-${u['door_number']}')),
                  ],
                  onChanged: (v) => setLocal(() => unitId = v),
                ),
                TextField(
                  controller: desc,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Ne oldu?', hintText: 'Tarih, saat ve olayı yazın (en az 10 karakter)'),
                ),
                const SizedBox(height: 8),
                Text('Kimliğiniz ihlal bildirilen daireye gösterilmez.', style: Theme.of(ctx).textTheme.bodySmall),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
            ],
          ),
        ),
      );
      if (ok != true || ruleId == null || unitId == null) return;
      final res = await apiClient.reportViolation(ruleId!, unitId!, desc.text.trim());
      if (!mounted) return;
      _snack('${res['note'] ?? 'Bildiriminiz alındı'}');
      await _reload();
    } catch (e) {
      if (mounted) _snack(toUserMessage(e));
    }
  }

  Future<void> _respond(Map v) async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Savunma'),
        content: TextField(controller: text, maxLines: 5, decoration: const InputDecoration(hintText: 'Açıklamanız')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiClient.respondViolation('${v['id']}', text.text.trim());
      if (!mounted) return;
      _snack('Savunmanız yönetime iletildi');
      await _reload();
    } catch (e) {
      if (mounted) _snack(toUserMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kural ihlalleri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _report,
        icon: const Icon(Icons.report_outlined),
        label: const Text('Bildir'),
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
                if (items.isEmpty) const EmptyStateView(message: 'Kayıt yok', icon: Icons.rule_outlined),
                for (final v in items)
                  ListTile(
                    leading: Icon(isOwnReport(v) ? Icons.outbox_outlined : Icons.home_outlined),
                    title: Text('${v['unit']} · ${v['rule_title']}'),
                    subtitle: Text('${isOwnReport(v) ? 'Bildiriminiz' : 'Dairenizle ilgili'} · '
                        '${formatDate(v['occurred_at'])} · ${violationStatusText(v)}'),
                    trailing: !isOwnReport(v) && (v['status'] == 'OPEN' || v['status'] == 'VERIFIED')
                        ? TextButton(onPressed: () => _respond(v), child: const Text('Savunma'))
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
