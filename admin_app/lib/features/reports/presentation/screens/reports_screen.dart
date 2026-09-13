// Raporlar Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran sabit bir dönem ("Ocak 2026") ve koda gömülü rapor özetleri gösteriyor,
// "PDF olarak indir" / "Excel olarak indir" düğmeleri ise hiçbir şey yapmıyordu.
// Ayrıca gateway tarafındaki rapor üretimi tamamen uydurma tutarlarla PDF
// üretiyordu; o da kaldırıldı (FAZ 2.2). Mali rapor, KMK m.39 kapsamında hesap
// verme belgesidir — uydurma içerikli bir rapor hukuki sonuç doğurur.
//
// Bu sürümde rapor üretimi sunucudan istenir; sunucu hazır değilse bu açıkça
// söylenir ve indirme düğmesi yanıltıcı bir başarı göstermez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/data_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _reportTypes = [
    (
      id: 'assessment',
      title: 'Tahakkuk ve Tahsilat Raporu',
      subtitle: 'Dönem bazlı aidat tahakkuku, tahsilat ve bakiye',
      icon: Icons.receipt_long_rounded,
      color: AppleTheme.systemBlue,
    ),
    (
      id: 'expense',
      title: 'Gider Raporu',
      subtitle: 'Kalem bazlı gider dökümü',
      icon: Icons.payments_rounded,
      color: AppleTheme.systemOrange,
    ),
    (
      id: 'debtor',
      title: 'Borçlu Listesi',
      subtitle: 'Ödenmemiş aidat ve gecikme tazminatı',
      icon: Icons.warning_amber_rounded,
      color: AppleTheme.systemRed,
    ),
    (
      id: 'annual',
      title: 'Yıllık Hesap Özeti',
      subtitle: 'KMK m.39 — yıllık hesap verme belgesi',
      icon: Icons.description_rounded,
      color: AppleTheme.systemGreen,
    ),
  ];

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String? _busyReport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          for (final r in _reportTypes) _reportCard(r),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: AppleTheme.systemBlue),
          const SizedBox(width: 12),
          const Text('Dönem', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          DropdownButton<int>(
            value: _month,
            underline: const SizedBox.shrink(),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(_monthName(m))),
            ],
            onChanged: (v) => setState(() => _month = v ?? _month),
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _year,
            underline: const SizedBox.shrink(),
            items: [
              for (var y = DateTime.now().year - 4; y <= DateTime.now().year + 1; y++)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ][m];

  Widget _reportCard(({String id, String title, String subtitle, IconData icon, Color color}) r) {
    final busy = _busyReport == r.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppleTheme.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: r.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(r.icon, color: r.color),
        ),
        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(r.subtitle, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
        trailing: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_rounded),
        onTap: busy ? null : () => _generate(r.id, r.title),
      ),
    );
  }

  Future<void> _generate(String type, String title) async {
    setState(() => _busyReport = type);
    try {
      final ref = await apiClient.generateReport(type, year: _year, month: _month);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title üretildi (referans: $ref)')),
      );
    } catch (e) {
      if (!mounted) return;
      // Rapor üretilemediyse "indirildi" DENMEZ; nedeni gösterilir.
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isNotImplemented(e) ? 'Rapor üretimi henüz hazır değil' : 'Rapor üretilemedi'),
          content: Text(
            isNotImplemented(e)
                ? 'Rapor üretimi, gerçek mali veriye bağlanana kadar kapalıdır. '
                    'Önceki sürüm uydurma tutarlarla PDF üretiyordu; bu kaldırıldı.'
                : toUserMessage(e),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busyReport = null);
    }
  }
}
