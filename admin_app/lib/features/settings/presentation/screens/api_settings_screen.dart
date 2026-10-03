// API Anahtarları — kimlik bilgisi kasası bu sürümde yok.
//
// DÜZELTME (2026-09-26): ekran var olmayan /credentials uçlarına istek atıyordu; sunucu bilerek 501 döner.
// Uydurma sayı ya da "işlem yapıldı" gösterilmez; durum açıkça yazılır.

import 'package:flutter/material.dart';

import '../../../../core/widgets/data_state.dart';

class APISettingsScreen extends StatelessWidget {
  const APISettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Anahtarları')),
      body: ListView(
        children: const [
          NotImplementedNotice(
            title: 'Kimlik bilgisi kasası yok',
            detail: 'Üçüncü taraf API anahtarlarının güvenli saklanması (kasa, döndürme) henüz kurulmadı. Anahtarlar sunucu tarafında ortam değişkeniyle verilir; uygulamadan girilmez ve gösterilmez.',
          ),
        ],
      ),
    );
  }
}
