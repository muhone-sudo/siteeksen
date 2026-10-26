// Ziyaretçilerim (FAZ H.6 S3): sakinin açtığı ön kayıtlar; bekleyen kaydı iptal etme ve geçiş kodunu
// yenileme (eski kod geçersiz olur). PIN yalnız üretildiği anda gösterilir.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../../core/widgets/future_list.dart';

const _status = {
  'EXPECTED': ('Bekleniyor', Colors.blue),
  'CHECKED_IN': ('İçeride', Colors.green),
  'CHECKED_OUT': ('Çıktı', Colors.grey),
  'CANCELLED': ('İptal', Colors.red),
  'EXPIRED': ('Süresi doldu', Colors.grey),
};

class MyVisitorsScreen extends StatefulWidget {
  const MyVisitorsScreen({super.key});

  @override
  State<MyVisitorsScreen> createState() => _MyVisitorsScreenState();
}

class _MyVisitorsScreenState extends State<MyVisitorsScreen> {
  final _list = GlobalKey<FutureListState>();

  Future<void> _showPass(Map pass, String name) async {
    final pin = '${pass['pin'] ?? ''}';
    final qr = '${pass['qr_token'] ?? ''}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name için yeni kod'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SelectableText(pin, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 6)),
          if (qr.isNotEmpty) SizedBox(width: 180, height: 180, child: QrImageView(data: qr, size: 180)),
          if (pass['expires_at'] != null) Text('Geçerlilik: ${formatDateTime(pass['expires_at'])}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Eski kod artık geçersiz. Kod yalnız şimdi gösterilir.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: 'Site girişinde güvenliğe bu kodu söyleyin: $pin')),
            child: const Text('PIN mesajını kopyala'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ziyaretçilerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed('visitorPreregister');
          await _list.currentState?.reload();
        },
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Ön kayıt'),
      ),
      body: FutureList(
        key: _list,
        load: apiClient.getVisitors,
        empty: 'Ziyaretçi kaydınız yok',
        emptyIcon: Icons.people_outline,
        itemBuilder: (context, v, reload) {
          final st = _status['${v['status']}'] ?? ('${v['status']}', Colors.grey);
          final expected = v['status'] == 'EXPECTED';
          return ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('${v['visitor_name']}'),
            subtitle: Text([
              if (v['expected_at'] != null) 'Beklenen ${formatDateTime(v['expected_at'])}',
              if (v['checked_in_at'] != null) 'Giriş ${formatDateTime(v['checked_in_at'])}',
              if (v['checked_out_at'] != null) 'Çıkış ${formatDateTime(v['checked_out_at'])}',
              if ((v['unit_name'] ?? '').toString().isNotEmpty) '${v['unit_name']}',
            ].join(' · ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(st.$1, style: TextStyle(color: st.$2, fontSize: 12)),
              if (expected)
                PopupMenuButton<String>(
                  onSelected: (a) async {
                    if (a == 'pass') {
                      try {
                        final r = await apiClient.reissueVisitorPass('${v['id']}');
                        if (context.mounted) await _showPass((r['pass'] as Map?) ?? {}, '${v['visitor_name']}');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
                        }
                      }
                    } else {
                      if (!await confirmDialog(context, 'Ön kaydı iptal et', '${v['visitor_name']} ön kaydı ve geçiş kodu iptal edilsin mi?', ok: 'İptal et')) return;
                      if (!context.mounted) return;
                      if (await runSnack(context, () => apiClient.cancelVisitor('${v['id']}'), 'Ön kayıt iptal edildi')) await reload();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pass', child: Text('Kodu yenile')),
                    PopupMenuItem(value: 'cancel', child: Text('İptal et')),
                  ],
                ),
            ]),
          );
        },
      ),
    );
  }
}
