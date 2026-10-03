// Raporlar — rapor üretimi sunucuda yok.
//
// DÜZELTME (2026-09-26): ekran /reports/generate ucuna istek atıyordu; sunucu bilerek 501 döner.
// Uydurma sayı ya da "işlem yapıldı" gösterilmez; durum açıkça yazılır.

import 'package:flutter/material.dart';

import '../../../../core/widgets/data_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: ListView(
        children: const [
          NotImplementedNotice(
            title: 'Rapor üretimi henüz yok',
            detail: 'PDF/Excel rapor üretimi sunucuda yazılmadı. Tahakkuk/tahsilat özeti için Finans, gider dökümü için Giderler ve karar kayıtları için Yönetişim ekranlarını kullanın.',
          ),
        ],
      ),
    );
  }
}
