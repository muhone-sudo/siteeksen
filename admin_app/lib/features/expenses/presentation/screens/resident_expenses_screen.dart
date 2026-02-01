import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Sakinlerin gördüğü gider listesi ekranı
/// Bu ekran mobil uygulamada sakinlere gösterilecek
class ResidentExpensesScreen extends StatelessWidget {
  const ResidentExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = [
      _ResidentExpense(
        category: 'Ortak Elektrik',
        description: 'Ocak 2026 elektrik faturası',
        amount: 2450.75,
        date: '28.01.2026',
        perUnitAmount: 19.76,
        isInvoiced: true,
        reflectsToAssessment: true,
        hasDocument: true,
      ),
      _ResidentExpense(
        category: 'Ortak Su',
        description: 'Ocak 2026 su faturası',
        amount: 1850.00,
        date: '25.01.2026',
        perUnitAmount: 14.92,
        isInvoiced: true,
        reflectsToAssessment: true,
        hasDocument: true,
      ),
      _ResidentExpense(
        category: 'Asansör Bakımı',
        description: 'Yıllık bakım',
        amount: 3500.00,
        date: '15.01.2026',
        perUnitAmount: 28.23,
        isInvoiced: true,
        reflectsToAssessment: true,
        hasDocument: true,
      ),
      _ResidentExpense(
        category: 'Acil Tamir',
        description: 'Çatı tamir işlemi',
        amount: 1800.00,
        date: '20.01.2026',
        perUnitAmount: 14.52,
        isInvoiced: false,
        nonInvoicedReason: 'Elden ödeme yapılmıştır. Detaylı bilgi için site yönetimine başvurunuz.',
        reflectsToAssessment: true,
        hasDocument: false,
      ),
      _ResidentExpense(
        category: 'Bina Temizliği',
        description: 'Ocak ayı temizlik hizmeti',
        amount: 8000.00,
        date: '31.01.2026',
        perUnitAmount: 0, // Aidata dahil
        isInvoiced: true,
        reflectsToAssessment: false,
        hasDocument: true,
      ),
    ];

    final totalReflecting = expenses.where((e) => e.reflectsToAssessment).fold(0.0, (sum, e) => sum + e.perUnitAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Giderleri'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              title: const Text('Ocak 2026'),
              subtitle: const Text('Görüntülenen dönem'),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Bu Ay Sizin Payınız', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('₺${totalReflecting.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Değişken giderler toplamı', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Info about fixed expenses
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bina temizliği, güvenlik gibi sabit giderler aylık aidatınıza dahildir.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Expense list
          const Text('Gider Detayları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          ...expenses.map((expense) => _ExpenseCard(expense: expense)),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final _ResidentExpense expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: expense.hasDocument ? () => _showDocument(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
                    child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(expense.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₺${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(expense.date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Your share
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (expense.reflectsToAssessment) ...[
                    const Text('Sizin Payınız:', style: TextStyle(fontSize: 13)),
                    Text('₺${expense.perUnitAmount.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                        const SizedBox(width: 4),
                        Text('Aidatınıza dahil', style: TextStyle(color: AppTheme.successColor, fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
              
              // Non-invoiced warning
              if (!expense.isInvoiced) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 18, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          Text('Faturasız Gider', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warningColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.nonInvoicedReason ?? 'Bu gider için resmi fatura bulunmamaktadır.',
                        style: TextStyle(fontSize: 12, color: AppTheme.warningColor.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
              
              // View document button
              if (expense.hasDocument) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showDocument(context),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Faturayı Görüntüle'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDocument(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Text('Fatura Belgesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('fatura.pdf', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('PDF görüntüleyici burada açılacak', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('İndir'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ortak Elektrik': return Colors.amber;
      case 'Ortak Su': return Colors.blue;
      case 'Ortak Isınma': return Colors.deepOrange;
      case 'Asansör Bakımı': return Colors.purple;
      case 'Bina Temizliği': return Colors.teal;
      case 'Güvenlik': return Colors.indigo;
      case 'Acil Tamir': return Colors.orange;
      default: return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ortak Elektrik': return Icons.bolt;
      case 'Ortak Su': return Icons.water_drop;
      case 'Ortak Isınma': return Icons.whatshot;
      case 'Asansör Bakımı': return Icons.elevator;
      case 'Bina Temizliği': return Icons.cleaning_services;
      case 'Güvenlik': return Icons.security;
      case 'Acil Tamir': return Icons.build;
      default: return Icons.receipt;
    }
  }
}

class _ResidentExpense {
  final String category;
  final String description;
  final double amount;
  final String date;
  final double perUnitAmount;
  final bool isInvoiced;
  final String? nonInvoicedReason;
  final bool reflectsToAssessment;
  final bool hasDocument;

  _ResidentExpense({
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.perUnitAmount,
    required this.isInvoiced,
    this.nonInvoicedReason,
    required this.reflectsToAssessment,
    required this.hasDocument,
  });
}
