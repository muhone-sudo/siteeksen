// Banka — banka entegrasyonu bu sürümde yok (S-07 kullanıcı kararı).
//
// DÜZELTME (2026-09-26): hata yutuluyor ve ekranda ₺12.450 / ₺245.680 gibi UYDURMA bakiyeler gösteriliyordu.
// Uydurma sayı ya da "işlem yapıldı" gösterilmez; durum açıkça yazılır.

import 'package:flutter/material.dart';

import '../../../../core/widgets/data_state.dart';

class BankIntegrationScreen extends StatelessWidget {
  const BankIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banka')),
      body: ListView(
        children: [
          const NotImplementedNotice(
            title: 'Banka entegrasyonu bu sürümde yok',
            detail: 'Hesap hareketlerinin otomatik çekilmesi ve aidat eşlemesi sonraki sürüme bırakıldı (karar S-07). Havale/EFT ile gelen ödemeleri Finans > Onay bekleyen ödemeler ekranından elle onaylayın.',
          ),
        ],
      ),
    );
  }
}
