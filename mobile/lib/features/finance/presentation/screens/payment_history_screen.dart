// Ödeme geçmişi (FAZ H.6 S1): sakinin kendi ödemeleri; yönetimin girdiği tahsilatlar da görünür
// (`recorded_by_management`, 061).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/future_list.dart';

const _status = {
  'PENDING': ('Onay bekliyor', Colors.orange),
  'COMPLETED': ('Onaylandı', Colors.green),
  'FAILED': ('Reddedildi', Colors.red),
  'REFUNDED': ('İade / ters kayıt', Colors.grey),
  'REVERSED': ('Ters kayıt', Colors.grey),
};
const _methods = {'BANK_TRANSFER': 'Havale/EFT', 'CREDIT_CARD': 'Kart', 'CASH': 'Elden', 'EFT': 'EFT'};

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _total = 0;

  Future<List<dynamic>> _load() async {
    final res = await apiClient.getMyPayments(limit: 200);
    final total = toNum(res['total']).toInt();
    if (mounted && total != _total) setState(() => _total = total);
    return (res['data'] as List?) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Geçmişi')),
      body: FutureList(
        load: _load,
        empty: 'Henüz ödeme kaydınız yok',
        emptyIcon: Icons.receipt_long,
        header: _total > 200
            ? Padding(padding: const EdgeInsets.all(12), child: Text('Son 200 ödeme gösteriliyor (toplam $_total).'))
            : null,
        itemBuilder: (context, p, _) {
          final st = _status['${p['status']}'] ?? ('${p['status']}', Colors.grey);
          return ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(formatTry(toNum(p['amount']))),
            subtitle: Text([
              formatDateTime(p['created_at']),
              _methods['${p['payment_method']}'] ?? '${p['payment_method'] ?? ''}',
              if (p['recorded_by_management'] == true) 'yönetim girdi',
            ].where((s) => s.isNotEmpty).join(' · ')),
            trailing: Chip(
              label: Text(st.$1, style: const TextStyle(fontSize: 12)),
              backgroundColor: st.$2.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}
