// KVKK m.11 ilgili kişi başvuruları (FAZ H.7, panel /dashboard/kvkk ile eşit). Başvuru en geç 30 gün
// içinde sonuçlandırılır (m.13/2); ret gerekçeli olmalıdır. Kayıtlar silinmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _types = {
  'INFO': 'Bilgi talebi', 'CORRECTION': 'Düzeltme', 'ERASURE': 'Silme / yok etme',
  'OBJECTION': 'İtiraz', 'COMPENSATION': 'Zararın giderilmesi', 'OTHER': 'Diğer',
};

class KvkkRequestsScreen extends StatefulWidget {
  const KvkkRequestsScreen({super.key});

  @override
  State<KvkkRequestsScreen> createState() => _KvkkRequestsScreenState();
}

class _KvkkRequestsScreenState extends State<KvkkRequestsScreen> {
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KVKK başvuruları')),
      body: ApiList(
        load: () => apiClient.getList('/kvkk-requests'),
        empty: 'Başvuru yok',
        itemBuilder: (context, r, reload) {
          final open = r['status'] == 'OPEN';
          final left = toNum(r['days_left']).toInt();
          return ListTile(
            title: Text('${r['applicant_name'] ?? '—'} · ${_types[r['request_type']] ?? r['request_type']}'),
            subtitle: Text([
              '${r['description'] ?? ''}',
              'Başvuru ${formatDate(r['created_at'])} · son gün ${formatDate(r['due_date'])}${open ? (left < 0 ? ' (${-left} gün geçti)' : ' ($left gün)') : ''}',
              if (!open && (r['response'] ?? '').toString().isNotEmpty) 'Yanıt: ${r['response']}',
            ].join('\n'), style: open && left < 0 ? const TextStyle(color: Colors.red) : null),
            isThreeLine: true,
            trailing: open
                ? (_canWrite
                    ? TextButton(
                        onPressed: () async {
                          if (await formAction(context, 'Başvuruyu sonuçlandır', const [
                            FSpec('status', 'Sonuç', type: FType.select, options: [('ANSWERED', 'Yanıtlandı / kabul'), ('REJECTED', 'Reddedildi (gerekçeli)')], initial: 'ANSWERED', required: true),
                            FSpec('response', 'Yanıt', type: FType.multiline, required: true, hint: 'Başvurana iletilir; ret gerekçeli olmalıdır (KVKK m.13/3)'),
                          ], (v) => apiClient.post('/kvkk-requests/${r['id']}/respond', v),
                              note: '${r['applicant_name']} — ${_types[r['request_type']] ?? ''}: ${r['description'] ?? ''}',
                              success: 'Başvuru sonuçlandırıldı; başvurana bildirildi')) {
                            await reload();
                          }
                        },
                        child: const Text('Yanıtla'),
                      )
                    : const StatusChip('Açık', color: Colors.blue))
                : StatusChip(r['status'] == 'ANSWERED' ? 'Yanıtlandı' : 'Reddedildi', color: r['status'] == 'ANSWERED' ? Colors.green : Colors.grey),
          );
        },
      ),
    );
  }
}
