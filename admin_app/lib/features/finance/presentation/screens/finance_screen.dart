import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finans'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Ocak 2026'),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Toplam Tahakkuk',
                    value: '₺105,400',
                    icon: Icons.receipt_long,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Tahsilat',
                    value: '₺93,050',
                    icon: Icons.payments,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Bekleyen',
                    value: '₺12,350',
                    icon: Icons.pending_actions,
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Tahsilat Oranı',
                    value: '%88.3',
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/finance/assessments/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tahakkuk Oluştur'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/finance/payments'),
                    icon: const Icon(Icons.list),
                    label: const Text('Ödemeler'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Expense breakdown
            const Text('Gider Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ExpenseBar(label: 'Yönetim Gideri', amount: 15000, total: 105400, color: AppTheme.primaryColor),
            _ExpenseBar(label: 'Temizlik', amount: 8000, total: 105400, color: AppTheme.secondaryColor),
            _ExpenseBar(label: 'Güvenlik', amount: 12000, total: 105400, color: AppTheme.successColor),
            _ExpenseBar(label: 'Bakım Onarım', amount: 5000, total: 105400, color: AppTheme.warningColor),
            _ExpenseBar(label: 'Elektrik/Su', amount: 25000, total: 105400, color: AppTheme.errorColor),
            const SizedBox(height: 24),
            
            // Debtors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Borçlu Sakinler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () {}, child: const Text('Tümünü Gör')),
              ],
            ),
            _DebtorCard(name: 'Fatma Çelik', unit: 'C Blok D.3', amount: 2500),
            _DebtorCard(name: 'Ayşe Kaya', unit: 'B Blok D.5', amount: 1200),
            _DebtorCard(name: 'Hasan Öz', unit: 'A Blok D.22', amount: 850),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;

  const _ExpenseBar({required this.label, required this.amount, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final percentage = (amount / total) * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('₺${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final String name;
  final String unit;
  final double amount;

  const _DebtorCard({required this.name, required this.unit, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.errorColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text(unit),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('-₺${amount.toInt()}', style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
            const Text('Gecikmiş', style: TextStyle(fontSize: 11, color: AppTheme.errorColor)),
          ],
        ),
      ),
    );
  }
}
