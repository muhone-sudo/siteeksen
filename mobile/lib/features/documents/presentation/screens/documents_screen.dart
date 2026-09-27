// Site belgeleri (sakin — görünürlüğe göre, `GET /documents`).
//
// DÜZELTME (2026-09-26): ekran "belge modülünün sunucu karşılığı yok" diyordu;
// oysa belge arşivi gerçek (document servisi) ve sakinler RESIDENTS/OWNERS
// görünürlüğündeki belgeleri görebiliyor. Liste artık sunucudan gelir.
//
// Bilinçli sınır: mobilde dosyayı açacak bir görüntüleyici/indirme eklentisi
// yok. Belge içeriği için yönetimden istenmesi söylenir; "indirildi" denmez.
// Belge yükleme yalnızca yönetimindir (M/B).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

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

  @override
  void initState() {
    super.initState();
    _future = apiClient.getDocuments();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getDocuments());
    await _future;
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
                const NotImplementedNotice(
                  title: 'Belgeler mobilde yalnızca listelenir',
                  detail: 'Dosyayı açmak bu sürümde desteklenmiyor. Bir belgenin içeriğine '
                      'ihtiyacınız varsa site yönetiminden isteyin; kanun gereği (KMK m.36) '
                      'kat maliklerine incelemeye açık tutulması gerekir.',
                ),
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
