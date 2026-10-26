// Belge arşivi (FAZ H.7, panel /dashboard/documents ile eşit). Her görüntüleme ve indirme erişim
// kaydına yazılır (KVKK m.12); dosyanın SHA-256 özeti saklanır. Arşivleme silmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _categories = [
  ('MANAGEMENT_PLAN', 'Yönetim planı'), ('DECISION', 'Karar'), ('BUDGET', 'İşletme projesi'), ('ACCOUNTING', 'Muhasebe'),
  ('CONTRACT', 'Sözleşme'), ('INVOICE', 'Fatura'), ('INSURANCE', 'Sigorta'), ('REPORT', 'Rapor'), ('LEGAL', 'Hukuki'),
  ('PERSONNEL', 'Personel'), ('TECHNICAL', 'Teknik'), ('OTHER', 'Diğer'),
];
const _visibility = [('MANAGEMENT', 'Yalnız yönetim'), ('OWNERS', 'Kat malikleri'), ('RESIDENTS', 'Tüm sakinler')];

String _l(List<(String, String)> list, Object? v) => list.firstWhere((e) => e.$1 == v, orElse: () => ('', '$v')).$2;

String _bytes(Object? v) {
  final b = toNum(v);
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1024 * 1024) return '${formatNumber((b / 1024).round())} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _list = GlobalKey<ApiListState>();
  String? _category;
  bool _archived = false;
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _upload() async {
    final v = await showForm(context, 'Belge yükle', const [
      FSpec('file', 'Dosya', type: FType.file, required: true),
      FSpec('category', 'Kategori', type: FType.select, options: _categories, initial: 'DECISION', required: true),
      FSpec('visibility', 'Görünürlük', type: FType.select, options: _visibility, initial: 'MANAGEMENT'),
      FSpec('title', 'Başlık', hint: 'Boşsa dosya adı kullanılır'),
      FSpec('retention_until', 'Saklama bitişi', type: FType.date),
      FSpec('description', 'Açıklama', type: FType.multiline),
    ], submit: 'Yükle');
    if (v == null || !mounted) return;
    final file = v.remove('file') as (List<int>, String);
    if (await runAction(context, () async {
      final r = await apiClient.postMultipart('/documents', {for (final e in v.entries) e.key: '${e.value}'}, {'file': file});
      final sha = '${r['sha256'] ?? ''}';
      return {...r, 'message': 'Yüklendi (SHA-256 ${sha.length > 12 ? sha.substring(0, 12) : sha}…)'};
    })) {
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belge arşivi'), actions: [
        FilterChip(label: const Text('Arşivdekiler'), selected: _archived, onSelected: (v) => setState(() => _archived = v)),
        PopupMenuButton<String?>(
          tooltip: 'Kategori',
          icon: const Icon(Icons.filter_list),
          onSelected: (c) => setState(() => _category = c),
          itemBuilder: (_) => [const PopupMenuItem(value: null, child: Text('Tüm kategoriler')), for (final c in _categories) PopupMenuItem(value: c.$1, child: Text(c.$2))],
        ),
      ]),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _upload, icon: const Icon(Icons.upload_file), label: const Text('Yükle')) : null,
      body: ApiList(
        key: _list,
        token: '$_category-$_archived',
        load: () => apiClient.getList('/documents', query: {'category': _category, if (_archived) 'include_archived': 'true'}),
        empty: 'Belge yok',
        header: (_) => FutureBuilder<Map<String, dynamic>>(
          future: apiClient.getMap('/documents-summary'),
          builder: (context, s) {
            final d = s.data;
            if (d == null) return const SizedBox.shrink();
            return StatRow([
              ('Belge', '${d['total'] ?? 0}'),
              ('Arşivlenen', '${d['archived'] ?? 0}'),
              ('Toplam boyut', _bytes(d['total_size_bytes'])),
              ('Saklama süresi dolan', '${d['retention_due'] ?? 0}'),
            ]);
          },
        ),
        itemBuilder: (context, x, reload) => ListTile(
          leading: Icon(x['archived_at'] != null ? Icons.archive : Icons.description),
          title: Text('${x['title'] ?? x['file_name'] ?? ''}'),
          subtitle: Text('${_l(_categories, x['category'])} · ${_l(_visibility, x['visibility'])} · ${_bytes(x['size_bytes'])}${toNum(x['version']) > 1 ? ' · v${x['version']}' : ''}\n'
              '${formatDateTime(x['uploaded_at'])} · ${x['uploaded_by_name'] ?? ''}'),
          isThreeLine: true,
          trailing: RowMenu([
            ('İndir / aç', () => openDownload(context, '/documents/${x['id']}/download', '${x['file_name'] ?? 'belge'}')),
            ('Erişim kaydı', () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Erişim — ${x['title'] ?? ''}')),
                  body: ApiList(
                    load: () => apiClient.getList('/documents/${x['id']}/access-log'),
                    empty: 'Erişim yok',
                    itemBuilder: (context, a, _) => ListTile(
                      title: Text('${a['user_name'] ?? '—'} · ${a['action']}'),
                      subtitle: Text('${formatDateTime(a['accessed_at'])} · ${a['ip_address'] ?? '—'}'),
                    ),
                  ),
                ),
              ));
            }),
            if (_canWrite && x['archived_at'] == null)
              ('Arşivle', () async {
                if (await reasonAction(context, 'Belgeyi arşivle', (r) => apiClient.post('/documents/${x['id']}/archive', {'reason': r}), success: 'Arşivlendi (silinmedi)')) {
                  await reload();
                }
              }),
          ]),
        ),
      ),
    );
  }
}
