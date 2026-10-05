// Raporlar — PDF / Excel dökümleri (TEST_RAPORU 2.6).
//
// Sunucu belgeyi gerçek veriden üretir (pkg/reports); her sayfada içerik özeti
// (SHA-256 doğrulama kodu) yazar. Uygulama dosyayı indirip geçici dizine yazar ve
// cihazdaki görüntüleyiciyle açar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/api_views.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _open(BuildContext context, String path, String fallback) async {
    await runAction(context, () async {
      final (bytes, name) = await apiClient.downloadBytes(path, fallback);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      final r = await OpenFilex.open(file.path);
      if (r.type != ResultType.done) {
        throw StateError('Dosya indirildi ama açılamadı: ${r.message}');
      }
      return <String, dynamic>{};
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Borçlu listesi'),
            subtitle: Text('Yalnızca yönetimin iç kullanımı içindir; ortak alanlara asılamaz (KVK Kurulu 2026/348).'),
          ),
          OverflowBar(alignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => _open(context, '/finance/reports/debtors?format=pdf', 'borclu-listesi.pdf'), child: const Text('PDF')),
            TextButton(onPressed: () => _open(context, '/finance/reports/debtors?format=xlsx', 'borclu-listesi.xlsx'), child: const Text('Excel')),
          ]),
          const Divider(),
          ListTile(title: Text('$year tahakkuk ve tahsilat özeti'), subtitle: const Text('Mizan değildir; muhasebe kaydı mali müşavir programındadır.')),
          OverflowBar(alignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => _open(context, '/finance/reports/collections?year=$year&format=pdf', 'tahsilat-ozeti.pdf'), child: const Text('PDF')),
            TextButton(onPressed: () => _open(context, '/finance/reports/collections?year=$year&format=xlsx', 'tahsilat-ozeti.xlsx'), child: const Text('Excel')),
          ]),
          const Divider(),
          const ListTile(
            title: Text('Hazirun cetveli, işletme projesi, karar defteri'),
            subtitle: Text('Yönetim panelinde Raporlar ve Yönetişim ekranlarından indirilir.'),
          ),
        ],
      ),
    );
  }
}
