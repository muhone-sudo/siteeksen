// Kiracılık işlemleri (altıncı tur D4, migration 069).
//
// Kiracı: malikin bitiş isteğini onaylar ya da reddeder (onaylamadan kiracılık bitmez); yönetim yolunda belgeyi
// görür ve 7 gün içinde itiraz eder (işlem askıya alınır), isterse onaylayarak bitirir.
// Malik: açtığı isteğin durumunu görür ve geri çekebilir. Belge yalnız kiracıya ve yönetime açıktır.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../documents/domain/document_file.dart';

const _kind = {'OWNER_REQUEST': 'Malik isteği', 'TENANT_EXIT': 'Kiracının çıkışı', 'MANAGEMENT': 'Yönetim yolu (belgeye dayalı)'};
const _status = {
  'PENDING_TENANT': 'Kiracı onayı bekliyor',
  'OBJECTION_WINDOW': 'İtiraz süresinde',
  'SUSPENDED': 'İtiraz edildi — askıda',
  'COMPLETED': 'Bitti',
  'REJECTED': 'Kiracı reddetti',
  'CANCELLED': 'İptal edildi',
  'REVERSED': 'Geri alındı',
};
const _docKind = {
  'TAHLIYE_KARARI': 'Tahliye kararı',
  'ICRA_TAHLIYE': 'İcra yoluyla tahliye',
  'TASINMA_TUTANAGI': 'Taşınma tutanağı',
  'DIGER': 'Diğer belge',
};

String _err(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return toUserMessage(e);
}

class TenancyRequestsScreen extends StatefulWidget {
  const TenancyRequestsScreen({super.key});

  @override
  State<TenancyRequestsScreen> createState() => _TenancyRequestsScreenState();
}

class _TenancyRequestsScreenState extends State<TenancyRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await apiClient.getTenancyRequests();
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _err(e);
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() call) async {
    try {
      final res = await call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'İşlem tamamlandı.'}')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<String?> _askText(String title, String hint, {int min = 5}) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, maxLines: 3, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().length < min) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return res;
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla')),
          ],
        ),
      ) ==
      true;

  Future<void> _openDocument(String requestId, Map<String, dynamic> d) async {
    try {
      final bytes = await apiClient.tenancyDocument(requestId, '${d['id']}');
      final file = File('${(await getTemporaryDirectory()).path}/${safeFileName('${d['file_name'] ?? 'belge'}')}');
      await file.writeAsBytes(bytes, flush: true);
      final r = await OpenFilex.open(file.path, type: '${d['content_type'] ?? ''}');
      if (r.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Belge indirildi ama açılamadı: ${r.message}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  List<Widget> _actions(Map<String, dynamic> r) {
    final id = '${r['id']}';
    final status = '${r['status']}';
    final kind = '${r['kind']}';
    final tenant = r['is_tenant'] == true;
    final out = <Widget>[];
    if (tenant && kind == 'OWNER_REQUEST' && status == 'PENDING_TENANT') {
      out.add(TextButton(
        onPressed: () async {
          final note = await _askText('Reddet', 'Neden (isteğe bağlı)', min: 0);
          if (note != null) _run(() => apiClient.respondTenancyRequest(id, false, note: note));
        },
        child: const Text('Reddet'),
      ));
    }
    if (tenant && (status == 'PENDING_TENANT' || (kind == 'MANAGEMENT' && (status == 'OBJECTION_WINDOW' || status == 'SUSPENDED')))) {
      out.add(FilledButton(
        onPressed: () async {
          if (await _confirm('Kiracılığı bitir', 'Onaylarsanız kiracılığınız bugün itibarıyla sona erer ve bu daire için bildirim almazsınız. Geçmiş kayıtlarınız silinmez.')) {
            _run(() => apiClient.respondTenancyRequest(id, true));
          }
        },
        child: const Text('Onayla'),
      ));
    }
    if (tenant && kind == 'MANAGEMENT' && status == 'OBJECTION_WINDOW') {
      out.add(OutlinedButton(
        onPressed: () async {
          final reason = await _askText('İtiraz et', 'Belge neden hatalı? (en az 5 karakter)');
          if (reason != null) _run(() => apiClient.objectTenancyRequest(id, reason));
        },
        child: const Text('İtiraz et'),
      ));
    }
    if (r['requested_by_self'] == true && kind == 'OWNER_REQUEST' && status == 'PENDING_TENANT') {
      out.add(TextButton(onPressed: () => _run(() => apiClient.cancelTenancyRequest(id)), child: const Text('Geri çek')));
    }
    return out;
  }

  Widget _card(Map<String, dynamic> r) {
    final docs = (r['documents'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final deadline = r['objection_deadline'];
    final actions = _actions(r);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r['unit']} · ${_kind['${r['kind']}'] ?? r['kind']}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(_status['${r['status']}'] ?? '${r['status']}'),
          if ('${r['reason'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Gerekçe: ${r['reason']}')),
          if (deadline != null && r['status'] == 'OBJECTION_WINDOW')
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('İtiraz için son gün: ${formatDate(deadline)}')),
          if (r['end_date'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Bitiş: ${formatDate(r['end_date'])}')),
          for (final d in docs)
            TextButton.icon(
              onPressed: r['is_tenant'] == true ? () => _openDocument('${r['id']}', d) : null,
              icon: const Icon(Icons.description_outlined),
              label: Text('${_docKind['${d['document_kind']}'] ?? d['document_kind']}${'${d['uyap_code'] ?? ''}'.isNotEmpty ? ' · UYAP ${d['uyap_code']}' : ''}'),
            ),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiracılık işlemleri')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyStateView(message: 'Kiracılıkla ilgili bekleyen ya da geçmiş işlem yok')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [for (final r in _items) _card(r)]),
                    ),
    );
  }
}
