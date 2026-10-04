// DASK poliçem (FAZ 7.2, 2026-10-04).
//
// Zorunlu deprem sigortasını malik ya da intifa hakkı sahibi yaptırır ve her yıl
// yeniler (6305 s. Kanun m.10/3). Malik poliçesini girer; bitişe 30 gün kala hatırlatılır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const daskStateLabels = {'VALID': 'Geçerli', 'EXPIRING': 'Bitiyor', 'EXPIRED': 'Bitmiş', 'MISSING': 'Poliçe girilmemiş'};

/// Satır alt yazısı.
String daskSubtitle(Map<dynamic, dynamic> r) {
  final state = daskStateLabels['${r['state']}'] ?? '${r['state']}';
  if ('${r['policy_no'] ?? ''}'.isEmpty) return state;
  return '$state · ${r['policy_no']} · bitiş ${formatDate(r['end_date'])}';
}

class DaskScreen extends StatefulWidget {
  const DaskScreen({super.key});

  @override
  State<DaskScreen> createState() => _DaskScreenState();
}

class _DaskScreenState extends State<DaskScreen> {
  late Future<Map<String, dynamic>> _future = apiClient.getDask();

  Future<void> _reload() async {
    setState(() => _future = apiClient.getDask());
    await _future;
  }

  Future<void> _add(Map r) async {
    final no = TextEditingController();
    final insurer = TextEditingController();
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    var end = DateTime(now.year + 1, now.month, now.day);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${r['unit']} — DASK poliçesi'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: no, decoration: const InputDecoration(labelText: 'Poliçe no')),
            TextField(controller: insurer, decoration: const InputDecoration(labelText: 'Sigorta şirketi')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}'),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final p = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 3),
                  initialDateRange: DateTimeRange(start: start, end: end),
                );
                if (p != null) {
                  setLocal(() {
                    start = p.start;
                    end = p.end;
                  });
                }
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await apiClient.addDask({
        'unit_id': '${r['unit_id']}',
        'policy_no': no.text.trim(),
        'insurer': insurer.text.trim(),
        'start_date': apiDate(start),
        'end_date': apiDate(end),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poliçe kaydedildi')));
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DASK poliçem')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final rows = ApiClient.listOf(snap.data!['data']).whereType<Map>().toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (rows.isEmpty) const EmptyStateView(message: 'Malik ya da vekili olduğunuz daire yok', icon: Icons.house_outlined),
              for (final r in rows)
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text('${r['unit']}'),
                  subtitle: Text(daskSubtitle(r)),
                  trailing: TextButton(onPressed: () => _add(r), child: const Text('Poliçe gir')),
                ),
              const SizedBox(height: 12),
              Text('${snap.data!['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
            ]),
          );
        },
      ),
    );
  }
}