// Ödemeler ekranı.
//
// DÜZELTME (2026-09-27): ekran var olmayan `?status=` süzgeciyle tek liste
// gösteriyordu; havale/nakit ödemelerin borçtan düşmesi için gereken YÖNETİM
// ONAYI mobilde hiç yoktu. Artık iki sekme var:
// - "Onay bekleyen": `GET /finance/payments/pending`; onay (`{reference}`) borcu
//   düşürür, ret borcu olduğu gibi bırakır.
// - "Tümü": `GET /finance/payments` (yönetim için sitenin bütün ödemeleri).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

/// Ödeme durumu → (etiket, renk).
(String, Color) paymentStatus(Object? status) {
  switch ('${status ?? ''}') {
    case 'PENDING':
      return ('Onay bekliyor', Colors.orange);
    case 'COMPLETED':
      return ('Tamamlandı', Colors.green);
    case 'FAILED':
      return ('Reddedildi', Colors.red);
    case 'REFUNDED':
      return ('İade edildi', Colors.blueGrey);
    default:
      return ('${status ?? '—'}', Colors.blueGrey);
  }
}

/// Ödeme yöntemi etiketi (sunucunun kabul ettiği dört değer).
String paymentMethodLabel(Object? method) {
  switch ('${method ?? ''}') {
    case 'CREDIT_CARD':
      return 'Kredi kartı';
    case 'SAVED_CARD':
      return 'Kayıtlı kart';
    case 'BANK_TRANSFER':
      return 'Havale/EFT';
    case 'CASH':
      return 'Nakit';
    default:
      return '${method ?? '—'}';
  }
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _canWrite = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _confirm(Map<String, dynamic> p) async {
    final ref = await askText(context, 'Ödemeyi onayla', 'Dekont / havale referansı (isteğe bağlı)', required: false);
    if (ref == null || !mounted) return;
    final ok = await runAction(context, () => apiClient.post('/finance/payments/${p['id']}/confirm', {'reference': ref}));
    if (ok && mounted) setState(() => _token++);
  }

  Future<void> _reject(Map<String, dynamic> p) async {
    final ok = await confirm(context, 'Ödemeyi reddet', 'Ödeme başarısız işaretlenir, borç değişmez.', ok: 'Reddet');
    if (!ok || !mounted) return;
    final done = await runAction(context, () => apiClient.post('/finance/payments/${p['id']}/reject'));
    if (done && mounted) setState(() => _token++);
  }

  Widget _tile(Map<String, dynamic> p, {bool actions = false}) {
    final (label, color) = paymentStatus(p['status']);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                [p['name'], p['unit']].where((v) => '${v ?? ''}'.isNotEmpty).join(' · ').ifEmpty('Ödeme'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(formatTry(toNum(p['amount'])), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            StatusChip(label, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text('${paymentMethodLabel(p['payment_method'])} · ${formatDateTime(p['created_at'])}')),
          ]),
          if (actions && _canWrite)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => _reject(p), child: const Text('Reddet')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _confirm(p), child: const Text('Onayla')),
            ]),
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
          title: const Text('Ödemeler'),
          bottom: const TabBar(tabs: [Tab(text: 'Onay bekleyen'), Tab(text: 'Tümü')]),
        ),
        body: TabBarView(children: [
          ApiList(
            token: _token,
            load: () => apiClient.getList('/finance/payments/pending'),
            empty: 'Onay bekleyen ödeme yok',
            header: (items) => StatRow([
              ('Bekleyen', '${items.length}'),
              ('Tutar', formatTry(items.fold<num>(0, (a, i) => a + toNum(i['amount'])))),
            ]),
            itemBuilder: (context, p, _) => _tile(p, actions: true),
          ),
          ApiList(
            token: _token,
            // Sunucu sayfalıdır (varsayılan 50); en çok 500 istenir ve tavana
            // ulaşıldıysa listenin kesildiği söylenir (B69).
            load: () => apiClient.getList('/finance/payments?limit=500'),
            empty: 'Ödeme kaydı yok',
            header: (items) => items.length >= 500
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('En yeni 500 ödeme gösteriliyor; daha eski kayıtlar bu ekranda listelenmez.'),
                  )
                : const SizedBox.shrink(),
            itemBuilder: (context, p, _) => _tile(p),
          ),
        ]),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
