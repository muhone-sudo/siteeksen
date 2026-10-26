// Memnuniyet ölçümü (NPS: 9-10 destekçi, 7-8 pasif, 0-6 eleştirmen) — FAZ H.7, panel /dashboard/nps ile eşit.
// Yanıtlar anonimdir; 10'dan az yanıtla sonuç güvenilir sayılmaz.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

class NpsScreen extends StatefulWidget {
  const NpsScreen({super.key});

  @override
  State<NpsScreen> createState() => _NpsScreenState();
}

class _NpsScreenState extends State<NpsScreen> {
  final _list = GlobalKey<ApiListState>();
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
      appBar: AppBar(title: const Text('Memnuniyet (NPS)')),
      floatingActionButton: _canWrite
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await formAction(context, 'Memnuniyet ölçümü başlat', const [
                  FSpec('title', 'Başlık', required: true),
                  FSpec('description', 'Açıklama', type: FType.multiline),
                  FSpec('ends_at', 'Bitiş', type: FType.dateTime),
                ], (v) => apiClient.post('/nps', v), success: 'Ölçüm başladı')) {
                  await _list.currentState?.reload();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Ölçüm'))
          : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/nps'),
        empty: 'Ölçüm yok',
        itemBuilder: (context, s, reload) => ListTile(
          title: Text('${s['title'] ?? ''}'),
          subtitle: Text('${formatDateTime(s['starts_at'])} – ${formatDateTime(s['ends_at'])}\nYanıt ${s['responses'] ?? 0}/${s['eligible_respondents'] ?? 0} · ${s['status'] == 'ACTIVE' ? 'Açık' : 'Kapalı'}'),
          isThreeLine: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _NpsDetail(id: '${s['id']}', title: '${s['title'] ?? ''}'))),
          trailing: _canWrite && s['status'] == 'ACTIVE'
              ? RowMenu([
                  ('Kapat', () async {
                    if (await confirmAction(context, 'Ölçümü kapat', 'Yeni yanıt alınmaz.', () => apiClient.post('/nps/${s['id']}/close'), ok: 'Kapat', success: 'Ölçüm kapatıldı')) {
                      await reload();
                    }
                  }),
                ])
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _NpsDetail extends StatelessWidget {
  final String id;
  final String title;
  const _NpsDetail({required this.id, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ApiList(
        load: () => apiClient.getList('/nps/$id/comments'),
        empty: 'Yorum yok',
        header: (_) => FutureBuilder<Map<String, dynamic>>(
          future: apiClient.getMap('/nps/$id'),
          builder: (context, s) {
            final d = s.data;
            if (d == null) return s.hasError ? ListTile(title: Text(errorText(s.error!))) : const LinearProgressIndicator();
            final r = d['result'] as Map?;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (r != null) ...[
                  Text('${r['nps_score']} NPS', style: Theme.of(context).textTheme.headlineMedium),
                  if (r['reliable'] != true) const Text("10'dan az yanıt — güvenilir değil", style: TextStyle(color: Colors.orange)),
                  Text('Destekçi ${r['promoters']} · Pasif ${r['passives']} · Eleştirmen ${r['detractors']} (katılım %${d['participation_pct'] ?? '—'})'),
                  const SizedBox(height: 8),
                  Text('${r['interpretation'] ?? ''}'),
                ] else
                  Text('${d['result_note'] ?? 'Henüz yanıt yok.'}'),
                const SizedBox(height: 8),
                Text('${d['method'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                const Divider(),
                const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
            );
          },
        ),
        itemBuilder: (context, c, _) => ListTile(
          leading: CircleAvatar(child: Text('${c['score'] ?? '—'}')),
          title: Text('${c['comment'] ?? ''}'),
          subtitle: Text(formatDateTime(c['created_at'])),
        ),
      ),
    );
  }
}
