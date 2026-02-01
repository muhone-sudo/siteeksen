import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Durumum'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Özet Kart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Toplam Borç',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺1.200,00',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Öde'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Aidatlar Başlığı
          Text(
            'Aidatlarım',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Aidat Listesi
          _AssessmentItem(
            period: 'Ocak 2026',
            amount: '₺1.200,00',
            status: 'PENDING',
          ),
          _AssessmentItem(
            period: 'Aralık 2025',
            amount: '₺1.150,00',
            status: 'PAID',
          ),
          _AssessmentItem(
            period: 'Kasım 2025',
            amount: '₺1.150,00',
            status: 'PAID',
          ),
          _AssessmentItem(
            period: 'Ekim 2025',
            amount: '₺1.100,00',
            status: 'PAID',
          ),
        ],
      ),
    );
  }
}

class _AssessmentItem extends StatelessWidget {
  final String period;
  final String amount;
  final String status;

  const _AssessmentItem({
    required this.period,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'PAID';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            isPaid ? Icons.check : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(period),
        subtitle: Text(amount),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isPaid ? 'Ödendi' : 'Bekliyor',
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
