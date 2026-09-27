// Toplantılar — genel kurul işlemleri yönetişim modülündedir.
//
// DÜZELTME (2026-09-26): ayrı bir "toplantı sihirbazı" servisi yazılmadı (governance ile tekrar olurdu; sunucu 501 döner).
// Uydurma sayı ya da "işlem yapıldı" gösterilmez; durum açıkça yazılır.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/data_state.dart';

class MeetingWizardScreen extends StatelessWidget {
  const MeetingWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplantılar')),
      body: ListView(
        children: [
          const NotImplementedNotice(
            title: 'Genel kurullar Yönetişim ekranında',
            detail: 'Genel kurul, gündem, nisap ve karar defteri kayıtları Yönetişim ekranında görüntülenir (KMK m.29-32).',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => context.go('/governance'),
              icon: const Icon(Icons.gavel),
              label: const Text('Yönetişime git'),
            ),
          ),
        ],
      ),
    );
  }
}
