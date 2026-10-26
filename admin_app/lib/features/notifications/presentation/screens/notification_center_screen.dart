// Bildirim merkezi (FAZ H.7, panel /dashboard/notifications ile eşit): giden kutusu, kanal
// tercihleri ve tek alıcıya bildirim. Push/SMS/e-posta sağlayıcısı bağlı değilse ileti
// "kuyrukta" bekler; ticari ileti açık onayı olmayan alıcıya gitmez (6563 s. Kanun m.6).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _channels = [('IN_APP', 'Uygulama içi'), ('PUSH', 'Anlık bildirim'), ('SMS', 'SMS'), ('EMAIL', 'E-posta')];
const _status = {'PENDING': ('Kuyrukta', Colors.orange), 'SENT': ('Gönderildi', Colors.green), 'FAILED': ('Başarısız', Colors.red), 'SUPPRESSED': ('Engellendi', Colors.grey)};

String _ch(Object? v) => _channels.firstWhere((c) => c.$1 == v, orElse: () => ('', '$v')).$2;

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String? _st;
  final _outbox = GlobalKey<ApiListState>();

  Future<void> _send() async {
    final rec = await optionsFrom('/residents', (r) => '${r['first_name'] ?? ''} ${r['last_name'] ?? ''} (${r['unit'] ?? r['unit_name'] ?? ''})', id: 'user_id')
        .catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    if (await formAction(context, 'Bildirim gönder', [
      FSpec('recipient_user_id', 'Alıcı', type: FType.select, options: rec, required: true),
      const FSpec('channel', 'Kanal', type: FType.select, options: _channels, initial: 'IN_APP', required: true),
      const FSpec('category', 'Tür', type: FType.select, options: [('TRANSACTIONAL', 'Bilgilendirme'), ('COMMERCIAL', 'Ticari')], initial: 'TRANSACTIONAL', required: true,
          hint: 'Ticari ileti yalnızca açık onayı olan alıcıya gider'),
      const FSpec('subject', 'Konu'),
      const FSpec('body', 'İleti', type: FType.multiline, required: true),
    ], (v) async {
      final r = await apiClient.post('/notifications', v);
      final n = (r['notification'] as Map?) ?? {};
      return {...r, 'message': 'Bildirim durumu: ${_status[n['status']]?.$1 ?? n['status']}${n['reason'] != null ? ' (${n['reason']})' : ''}'};
    }, submit: 'Gönder')) {
      await _outbox.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bildirim merkezi'),
          bottom: const TabBar(tabs: [Tab(text: 'Giden kutusu'), Tab(text: 'Tercihlerim')]),
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _send, icon: const Icon(Icons.send), label: const Text('Gönder')),
        body: TabBarView(children: [
          Column(children: [
            SizedBox(
              height: 48,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                for (final s in [null, ..._status.keys])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(s == null ? 'Tümü' : _status[s]!.$1), selected: _st == s, onSelected: (_) => setState(() => _st = s)),
                  ),
              ]),
            ),
            Expanded(
              child: ApiList(
                key: _outbox,
                token: _st,
                load: () => apiClient.getList('/notifications/outbox', query: {'status': _st}),
                empty: 'Bildirim yok',
                header: (_) => FutureBuilder<Map<String, dynamic>>(
                  future: apiClient.getMap('/notifications/summary'),
                  builder: (context, s) {
                    final m = (s.data?['summary'] as Map?) ?? const {};
                    if (s.data == null) return const SizedBox.shrink();
                    return Column(children: [
                      StatRow([
                        ('Toplam', '${m['total'] ?? 0}'),
                        ('Gönderildi', '${m['sent'] ?? 0}'),
                        ('Kuyrukta', '${m['pending'] ?? 0}'),
                        ('Engellendi / başarısız', '${m['suppressed'] ?? 0} / ${m['failed'] ?? 0}'),
                      ]),
                      if (m['pending_note'] != null) Padding(padding: const EdgeInsets.all(12), child: Text('${m['pending_note']}', style: const TextStyle(fontSize: 12))),
                    ]);
                  },
                ),
                itemBuilder: (context, n, _) {
                  final st = _status[n['status']];
                  return ListTile(
                    title: Text('${n['subject'] ?? n['topic'] ?? ''}'),
                    subtitle: Text([
                      '${n['recipient_name'] ?? n['recipient_masked'] ?? ''} · ${_ch(n['channel'])} · ${formatDateTime(n['created_at'])}',
                      '${n['body'] ?? ''}',
                      if (n['suppress_reason'] != null) '${n['suppress_reason']}',
                    ].join('\n'), maxLines: 4, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: st == null ? null : StatusChip(st.$1, color: st.$2),
                  );
                },
              ),
            ),
          ]),
          ApiObject(
            load: () => apiClient.getMap('/notification-preferences'),
            builder: (context, d, reload) {
              final prefs = ((d['data'] as List?) ?? const []).whereType<Map>().toList();
              return ListView(children: [
                Padding(padding: const EdgeInsets.all(16), child: Text('${d['note'] ?? ''}')),
                for (final p in prefs)
                  SwitchListTile(
                    title: Text('${_ch(p['channel'])} · ${p['category'] == 'COMMERCIAL' ? 'Ticari' : 'Bilgilendirme'}'),
                    subtitle: p['consent_at'] != null ? Text('Onay: ${formatDateTime(p['consent_at'])} (${p['consent_source'] ?? '—'})') : null,
                    value: p['enabled'] == true,
                    onChanged: (v) async {
                      if (await runAction(context, () => apiClient.put('/notification-preferences',
                          {'channel': p['channel'], 'category': p['category'], 'enabled': v, 'consent_source': 'ADMIN_APP'}), success: 'Tercih güncellendi')) {
                        await reload();
                      }
                    },
                  ),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}
