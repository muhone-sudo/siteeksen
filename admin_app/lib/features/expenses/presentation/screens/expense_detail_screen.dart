import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final expense = {
      'id': expenseId,
      'category': 'Ortak Elektrik',
      'description': 'Ocak 2026 elektrik faturası',
      'amount': 2450.75,
      'date': '28.01.2026',
      'is_invoiced': true,
      'reflects_to_assessment': true,
      'status': 'APPROVED',
      'vendor_name': 'AYEDAŞ Elektrik Dağıtım A.Ş.',
      'invoice_number': '2026-001234',
      'distribution_type': 'EQUAL',
      'per_unit_amount': 19.76,
      'invoices': [
        {'id': '1', 'name': 'fatura.pdf', 'type': 'PDF'},
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'duplicate', child: Text('Kopyala')),
              const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.amber.withOpacity(0.1),
                          child: const Icon(Icons.bolt, color: Colors.amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(expense['category'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(expense['description'] as String, style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Toplam Tutar'),
                          Text('₺${expense['amount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Badges
                    Wrap(
                      spacing: 8,
                      children: [
                        if (expense['is_invoiced'] == true)
                          _Badge(icon: Icons.receipt, label: 'Faturalı', color: AppTheme.successColor)
                        else
                          _Badge(icon: Icons.warning_amber, label: 'Faturasız', color: AppTheme.warningColor),
                        
                        if (expense['reflects_to_assessment'] == true)
                          _Badge(icon: Icons.account_balance_wallet, label: 'Aidata Yansıyor', color: AppTheme.primaryColor),
                        
                        _Badge(icon: Icons.check_circle, label: 'Onaylandı', color: AppTheme.successColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Details
            Card(
              child: Column(
                children: [
                  _DetailTile(icon: Icons.calendar_today, label: 'Gider Tarihi', value: expense['date'] as String),
                  const Divider(height: 1),
                  _DetailTile(icon: Icons.business, label: 'Firma', value: expense['vendor_name'] as String),
                  const Divider(height: 1),
                  _DetailTile(icon: Icons.tag, label: 'Fatura No', value: expense['invoice_number'] as String),
                  const Divider(height: 1),
                  _DetailTile(icon: Icons.pie_chart, label: 'Dağıtım', value: 'Eşit (124 daire)'),
                  const Divider(height: 1),
                  _DetailTile(icon: Icons.home, label: 'Daire Başı', value: '₺${expense['per_unit_amount']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Invoices
            const Text('Fatura Dosyaları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                title: const Text('fatura.pdf'),
                subtitle: const Text('28.01.2026 • 245 KB'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.visibility), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Assessment Distribution
            if (expense['reflects_to_assessment'] == true) ...[
              const Text('Aidat Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dönem'),
                          const Text('Şubat 2026', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dağıtım Tipi'),
                          const Text('Eşit Dağılım', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daire Sayısı'),
                          const Text('124', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daire Başı Tutar'),
                          Text('₺${expense['per_unit_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
