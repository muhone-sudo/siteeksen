// İşlem kayıtları (073, FAZ H.3): sitedeki bütün işlemler. Yönetici ve denetçi görür;
// görüntüleme de kayda geçer.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const _actions = {
  'VIEW': 'Görüntüleme', 'CREATE': 'Oluşturma', 'UPDATE': 'Güncelleme', 'DELETE': 'Silme',
  'DENIED': 'Yetki reddi', 'CLIENT': 'Uygulama etkinliği', 'PII_REVEAL': 'Kişisel veri açma',
};
const _sources = {'API': 'Sunucu', 'CLIENT': 'Uygulama', 'SYSTEM': 'Sistem'};
const _levels = {'OFF': 'Kapalı (yalnız zorunlu)', 'STANDARD': 'Standart', 'FULL': 'Tam'};

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String _action = '';
  String _source = '';
  String _q = '';
  String _level = '';

  Future<List<dynamic>> _load() async {
    final res = await apiClient.getMap('/audit-logs', query: {
      'limit': 200,
      if (_action.isNotEmpty) 'action': _action,
      if (_source.isNotEmpty) 'source': _source,
      if (_q.isNotEmpty) 'q': _q,
    });
    final level = '${res['level'] ?? ''}';
    if (mounted && level != _level) setState(() => _level = level);
    return (res['data'] as List?) ?? [];
  }

  Future<void> _search() async {
    final v = await askText(context, 'Olay / ekran ara', 'ör. auth.login, /finance', required: false, initial: _q);
    if (v != null) setState(() => _q = v.trim());
  }

  void _show(Map<String, dynamic> r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            for (final e in {
              'Zaman': formatDateTime(r['created_at']),
              'Kullanıcı': r['user_name'],
              'IP': r['ip'],
              'Kaynak': _sources[r['source']] ?? r['source'],
              'İşlem': _actions[r['action']] ?? r['action'],
              'Olay': r['event'],
              'Modül': r['entity_type'],
              'Kayıt': r['entity_id'],
              'Ekran / yol': r['screen'],
              'Durum kodu': r['status_code'],
              'Ayrıntı': r['details'],
            }.entries)
              ListTile(dense: true, title: Text(e.key), subtitle: Text(e.value == null || '${e.value}'.isEmpty ? '—' : '${e.value}')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Kayıtları'),
        actions: [
          IconButton(tooltip: 'Ara', icon: const Icon(Icons.search), onPressed: _search),
          IconButton(
            tooltip: 'Kayıt istatistiği',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Kayıt istatistiği')),
                body: ApiObject(
                  load: () => apiClient.getMap('/audit-logs/stats'),
                  builder: (context, d, _) => ListView(children: [
                    Padding(padding: const EdgeInsets.all(16), child: Text('Son ${d['period_days'] ?? '—'} gün')),
                    for (final x in ApiClient.listOf(d['data']).whereType<Map>())
                      ListTile(
                        dense: true,
                        title: Text('${_sources[x['source']] ?? x['source']} · ${_actions[x['action']] ?? x['action']}'),
                        subtitle: x['oldest'] != null ? Text('En eski ${formatDateTime(x['oldest'])}') : null,
                        trailing: Text('${x['total']}'),
                      ),
                  ]),
                ),
              ),
            )),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _action,
                decoration: const InputDecoration(labelText: 'İşlem'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tümü')),
                  for (final e in _actions.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _action = v ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Kaynak'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tümü')),
                  for (final e in _sources.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _source = v ?? ''),
              ),
            ),
          ]),
        ),
        if (_level.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Kayıt düzeyi: ${_levels[_level] ?? _level}${_q.isNotEmpty ? ' · arama: $_q' : ''}',
                style: const TextStyle(color: Colors.black54)),
          ),
        Expanded(
          child: ApiList(
            token: '$_action|$_source|$_q',
            load: _load,
            empty: 'Kayıt yok',
            emptyIcon: Icons.history,
            itemBuilder: (context, r, reload) => ListTile(
              dense: true,
              leading: Icon(r['action'] == 'DENIED' ? Icons.block : Icons.history,
                  color: r['action'] == 'DENIED' ? Colors.red : null),
              title: Text('${_actions[r['action']] ?? r['action']} · ${r['event'] ?? r['entity_type']}'),
              subtitle: Text('${formatDateTime(r['created_at'])} · ${r['user_name'] ?? '—'}\n${r['screen'] ?? ''}'),
              isThreeLine: true,
              onTap: () => _show(r),
            ),
          ),
        ),
      ]),
    );
  }
}
