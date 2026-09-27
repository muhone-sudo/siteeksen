// Rezervasyon yönetimi.
//
// DÜZELTME (2026-09-26): ekran `date`/`time_slot` ve küçük harfli `confirmed`
// durumunu arıyordu (sunucu start_time/end_time ve PENDING/APPROVED…);
// Onayla/İptal düğmeleri yalnızca pencereyi kapatıyordu; sayılar uydurmaydı.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const reservationStatus = {
  'PENDING': ('Onay bekliyor', Colors.orange),
  'APPROVED': ('Onaylandı', Colors.green),
  'REJECTED': ('Reddedildi', Colors.red),
  'CANCELLED': ('İptal', Colors.grey),
  'COMPLETED': ('Tamamlandı', Colors.blueGrey),
};

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  String? _status = 'PENDING';
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _act(Map r, String action, Future<void> Function() reload) async {
    Map<String, dynamic> body = {};
    if (action == 'reject' || action == 'cancel') {
      final reason = await askText(context, action == 'reject' ? 'Reddet' : 'İptal et', 'Gerekçe', required: action == 'reject');
      if (reason == null) return;
      body = {'reason': reason};
    }
    if (!mounted) return;
    if (await runAction(context, () => apiClient.post('/reservations/${r['id']}/$action', body))) await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezervasyonlar')),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in [null, ...reservationStatus.keys])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s == null ? 'Tümü' : reservationStatus[s]!.$1),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ApiList(
            token: _status,
            load: () => apiClient.getList('/reservations', query: {'status': _status}),
            empty: 'Rezervasyon yok',
            itemBuilder: (context, r, reload) {
              final st = reservationStatus['${r['status']}'];
              final open = r['status'] == 'PENDING' || r['status'] == 'APPROVED';
              final fee = toNum(r['total_fee']);
              return ListTile(
                title: Text('${r['facility_name'] ?? 'Tesis'} · ${r['unit_name'] ?? ''}'),
                subtitle: Text([
                  '${formatDate(r['start_time'])} ${formatTime(r['start_time'])}–${formatTime(r['end_time'])}',
                  '${r['resident_name'] ?? ''}',
                  if (toNum(r['guest_count']) > 0) '${toNum(r['guest_count']).toInt()} kişi',
                  if (fee > 0) '${formatTry(fee)} (tahsil edilmedi)',
                  if ((r['purpose'] ?? '').toString().isNotEmpty) '${r['purpose']}',
                  if ((r['rejection_reason'] ?? '').toString().isNotEmpty) 'Gerekçe: ${r['rejection_reason']}',
                ].where((s) => s.isNotEmpty).join('\n')),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (st != null) StatusChip(st.$1, color: st.$2),
                  if (_canWrite && open)
                    PopupMenuButton<String>(
                      onSelected: (a) => _act(r, a, reload),
                      itemBuilder: (_) => [
                        if (r['status'] == 'PENDING') const PopupMenuItem(value: 'approve', child: Text('Onayla')),
                        if (r['status'] == 'PENDING') const PopupMenuItem(value: 'reject', child: Text('Reddet')),
                        const PopupMenuItem(value: 'cancel', child: Text('İptal et')),
                      ],
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
