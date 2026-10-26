// Bildirimlerim — kişisel bildirim kutusu (073, FAZ H.2). Yönetime giden bildirimler
// (KVKK başvurusu, tadilat, ihlal, düşük stok, zamanlanmış hatırlatmalar) burada görünür.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _unreadOnly = true;
  final _list = GlobalKey<ApiListState>();

  Future<List<dynamic>> _load() => apiClient.getList('/notifications',
      query: {'channel': 'IN_APP', 'limit': 200, if (_unreadOnly) 'unread': '1'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimlerim'),
        actions: [
          IconButton(
            tooltip: 'Tümünü okundu say',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              if (await runAction(context, () => apiClient.post('/notifications/read-all'), success: 'Tümü okundu sayıldı')) {
                _list.currentState?.reload();
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Okunmamış')),
              ButtonSegment(value: false, label: Text('Tümü')),
            ],
            selected: {_unreadOnly},
            onSelectionChanged: (s) => setState(() => _unreadOnly = s.first),
          ),
        ),
        Expanded(
          child: ApiList(
            key: _list,
            token: _unreadOnly,
            load: _load,
            empty: _unreadOnly ? 'Okunmamış bildirim yok' : 'Bildirim yok',
            emptyIcon: Icons.notifications_none,
            itemBuilder: (context, n, reload) {
              final read = n['read_at'] != null;
              return ListTile(
                leading: Icon(read ? Icons.drafts_outlined : Icons.mark_email_unread, color: read ? Colors.grey : Colors.blue),
                title: Text('${n['subject'] ?? n['topic']}', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w600)),
                subtitle: Text('${n['body']}\n${formatDateTime(n['created_at'])}${read ? ' · okundu ${formatDateTime(n['read_at'])}' : ''}'),
                isThreeLine: true,
                onTap: read
                    ? null
                    : () async {
                        if (await runAction(context, () => apiClient.post('/notifications/${n['id']}/read'), success: 'Okundu sayıldı')) {
                          await reload();
                        }
                      },
              );
            },
          ),
        ),
      ]),
    );
  }
}
