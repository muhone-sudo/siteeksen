import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeler'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Row(
            children: [
              Expanded(child: _SummaryChip(label: 'Bugün', value: '₺4,250', color: AppTheme.successColor)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryChip(label: 'Bu Hafta', value: '₺18,750', color: AppTheme.primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryChip(label: 'Bu Ay', value: '₺93,050', color: AppTheme.secondaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payments list
          const Text('Son Ödemeler', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _PaymentCard(name: 'Ahmet Yılmaz', unit: 'A Blok D.12', amount: 850, method: 'Kredi Kartı', date: '01.02.2026 14:30'),
          _PaymentCard(name: 'Ayşe Kaya', unit: 'B Blok D.5', amount: 920, method: 'Kredi Kartı', date: '01.02.2026 11:15'),
          _PaymentCard(name: 'Mehmet Demir', unit: 'A Blok D.8', amount: 780, method: 'Havale', date: '31.01.2026 16:45'),
          _PaymentCard(name: 'Zeynep Arslan', unit: 'C Blok D.10', amount: 850, method: 'Kredi Kartı', date: '31.01.2026 09:20'),
          _PaymentCard(name: 'Can Yıldız', unit: 'B Blok D.22', amount: 850, method: 'Nakit', date: '30.01.2026 14:00'),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String name;
  final String unit;
  final double amount;
  final String method;
  final String date;
  const _PaymentCard({required this.name, required this.unit, required this.amount, required this.method, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.successColor,
              child: Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$unit • $method', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₺${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                Text(date, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
