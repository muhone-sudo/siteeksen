// Site belgeleri (sakin — görünürlüğe göre, `GET /documents`).
//
// DÜZELTME (2026-09-26): ekran "belge modülünün sunucu karşılığı yok" diyordu;
// oysa belge arşivi gerçek (document servisi) ve sakinler RESIDENTS/OWNERS
// görünürlüğündeki belgeleri görebiliyor. Liste artık sunucudan gelir.
//
// BELGE AÇMA (2026-10-03): dokunulan belge `/documents/:id/download` ile indirilir,
// sunucunun `X-Document-SHA256` özetiyle doğrulanır, uygulamanın geçici dizinine
// yazılır ve cihazdaki uygun uygulamayla açılır. Özet tutmazsa dosya AÇILMAZ.
// Her yeni indirmede önceki indirilenler silinir: kişisel veri içerebilecek
// belgeler cihazda birikmesin. Belge yükleme yalnızca yönetimindir (M/B).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../domain/document_file.dart';

const documentCategoryLabels = {
  'MANAGEMENT_PLAN': 'Yönetim planı',
  'DECISION': 'Karar',
  'BUDGET': 'İşletme projesi',
  'ACCOUNTING': 'Muhasebe',
  'CONTRACT': 'Sözleşme',
  'INVOICE': 'Fatura',
  'INSURANCE': 'Sigorta',
  'REPORT': 'Rapor',
  'LEGAL': 'Hukuki',
  'PERSONNEL': 'Personel',
  'TECHNICAL': 'Teknik',
  'OTHER': 'Diğer',
};

/// `1536` → `1,5 KB`
String formatBytes(Object? v) {
  final b = toNum(v).toDouble();
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1024 * 1024) return '${formatNumber(double.parse((b / 1024).toStringAsFixed(1)))} KB';
  return '${formatNumber(double.parse((b / (1024 * 1024)).toStringAsFixed(1)))} MB';
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<dynamic>> _future;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getDocuments();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getDocuments());
    await _future;
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(Map d) async {
    final id = '${d['id'] ?? ''}';
    if (id.isEmpty || _openingId != null) return;
    setState(() => _openingId = id);
    try {
      final doc = await apiClient.downloadDocument(id);
      if (!sha256Matches(doc.bytes, doc.sha256)) {
        _say('Belge eksik ya da bozuk indi (bütünlük doğrulanamadı); açılmadı. '
            'Lütfen tekrar deneyin.');
        return;
      }

      final dir = Directory('${(await getTemporaryDirectory()).path}/belgeler');
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      final file = File('${dir.path}/${safeFileName('${d['file_name'] ?? d['title'] ?? ''}')}');
      await file.writeAsBytes(doc.bytes, flush: true);

      final result = await OpenFilex.open(file.path, type: doc.contentType);
      switch (result.type) {
        case ResultType.done:
          break;
        case ResultType.noAppToOpen:
          _say('Bu dosya türünü açabilecek bir uygulama cihazda yok.');
        case ResultType.permissionDenied:
          _say('Dosyayı açmak için izin verilmedi.');
        default:
          _say('Belge açılamadı: ${result.message}');
      }
    } catch (e) {
      _say(toUserMessage(e));
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belgeler')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyStateView(message: 'Size açık belge yok', icon: Icons.folder_open),
                  ),
                for (final d in items)
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text('${d['title'] ?? d['file_name'] ?? 'Belge'}'),
                    subtitle: Text([
                      documentCategoryLabels['${d['category']}'] ?? '${d['category'] ?? ''}',
                      formatDate(d['uploaded_at']),
                      formatBytes(d['size_bytes']),
                      if (toNum(d['version']).toInt() > 1) 'sürüm ${d['version']}',
                    ].where((s) => s.isNotEmpty).join(' · ')),
                    trailing: _openingId == '${d['id']}'
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new),
                    onTap: _openingId == null ? () => _open(d) : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
