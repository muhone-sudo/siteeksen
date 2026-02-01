import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ResidentDetailScreen extends StatelessWidget {
  final String residentId;
  
  const ResidentDetailScreen({super.key, required this.residentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakin Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'reminder', child: Text('Hatırlatma Gönder')),
              const PopupMenuItem(value: 'delete', child: Text('Sakini Kaldır', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text('AY', style: TextStyle(fontSize: 24, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahmet Yılmaz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('A Blok Daire 12', style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Aktif', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Info
            Card(
              child: Column(
                children: [
                  _InfoTile(icon: Icons.phone, label: 'Telefon', value: '0532 123 4567'),
                  const Divider(height: 1),
                  _InfoTile(icon: Icons.email, label: 'E-posta', value: 'ahmet@email.com'),
                  const Divider(height: 1),
                  _InfoTile(icon: Icons.calendar_today, label: 'Kayıt Tarihi', value: '15 Ocak 2024'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary
            const Text('Finansal Durum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Toplam Borç',
                    value: '₺0',
                    color: AppTheme.successColor,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Son Ödeme',
                    value: '₺850',
                    color: AppTheme.primaryColor,
                    icon: Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assessments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Aidat Geçmişi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () {}, child: const Text('Tümünü Gör')),
              ],
            ),
            Card(
              child: Column(
                children: [
                  _AssessmentTile(month: 'Ocak 2026', amount: 850, status: 'PAID'),
                  const Divider(height: 1),
                  _AssessmentTile(month: 'Aralık 2025', amount: 820, status: 'PAID'),
                  const Divider(height: 1),
                  _AssessmentTile(month: 'Kasım 2025', amount: 820, status: 'PAID'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  final String month;
  final double amount;
  final String status;

  const _AssessmentTile({required this.month, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'PAID';
    return ListTile(
      leading: Icon(
        isPaid ? Icons.check_circle : Icons.pending,
        color: isPaid ? AppTheme.successColor : AppTheme.warningColor,
      ),
      title: Text(month),
      trailing: Text('₺${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
