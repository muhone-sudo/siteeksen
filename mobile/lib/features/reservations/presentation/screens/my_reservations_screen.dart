// Sakinin rezervasyonları (`GET /reservations` — sakin yalnızca kendininkini görür).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Sunucudaki rezervasyon durumlarının Türkçe karşılığı.
const reservationStatusLabels = {
  'PENDING': 'Onay bekliyor',
  'APPROVED': 'Onaylandı',
  'REJECTED': 'Reddedildi',
  'CANCELLED': 'İptal edildi',
  'COMPLETED': 'Tamamlandı',
};

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getReservations();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getReservations());
    await _future;
  }

  Future<void> _cancel(Map r) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezervasyonu iptal et'),
        content: TextField(controller: reason, decoration: const InputDecoration(labelText: 'Gerekçe (isteğe bağlı)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İptal et')),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true) return;
    try {
      final res = await apiClient.cancelReservation('${r['id']}', reason: text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'İptal edildi'}')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezervasyonlarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed('createReservation');
          if (mounted) await _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          if (items.isEmpty) return const EmptyStateView(message: 'Rezervasyonunuz yok', icon: Icons.event_busy);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = items[i];
                final status = '${r['status'] ?? ''}';
                final cancellable = status == 'PENDING' || status == 'APPROVED';
                final fee = toNum(r['total_fee']);
                return ListTile(
                  title: Text('${r['facility_name'] ?? 'Tesis'}'),
                  subtitle: Text([
                    '${formatDate(r['start_time'])} ${formatTime(r['start_time'])}–${formatTime(r['end_time'])}',
                    reservationStatusLabels[status] ?? status,
                    if (fee > 0) '${formatTry(fee)} (tahsil edilmedi)',
                    if ((r['rejection_reason'] ?? '').toString().isNotEmpty) 'Gerekçe: ${r['rejection_reason']}',
                  ].join(' · ')),
                  trailing: cancellable
                      ? TextButton(onPressed: () => _cancel(r), child: const Text('İptal'))
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
