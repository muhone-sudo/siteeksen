import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class CreateAssessmentScreen extends StatefulWidget {
  const CreateAssessmentScreen({super.key});

  @override
  State<CreateAssessmentScreen> createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends State<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedYear = 2026;
  int _selectedMonth = 2;
  final List<_ExpenseItem> _expenseItems = [
    _ExpenseItem(category: 'Yönetim Gideri', amount: 15000),
    _ExpenseItem(category: 'Temizlik', amount: 8000),
    _ExpenseItem(category: 'Güvenlik', amount: 12000),
  ];

  double get _totalAmount => _expenseItems.fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tahakkuk Oluştur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dönem Seçimi', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(labelText: 'Yıl'),
                            items: [2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                            onChanged: (v) => setState(() => _selectedYear = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(labelText: 'Ay'),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedMonth = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expense Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gider Kalemleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _addExpenseItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._expenseItems.map((item) => _ExpenseItemCard(
              item: item,
              onRemove: () => setState(() => _expenseItems.remove(item)),
              onAmountChanged: (v) => setState(() => item.amount = v),
            )),
            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam Gider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('₺${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Distribution info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dağıtım Bilgisi', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Toplam Daire', value: '124'),
                    _InfoRow(label: 'Daire Başı Ortalama', value: '₺${(_totalAmount / 124).toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _createAssessment,
              child: const Text('Tahakkuk Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month];
  }

  void _addExpenseItem() {
    setState(() {
      _expenseItems.add(_ExpenseItem(category: 'Yeni Kalem', amount: 0));
    });
  }

  void _createAssessment() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tahakkuk oluşturuldu'), backgroundColor: Colors.green),
      );
      context.pop();
    }
  }
}

class _ExpenseItem {
  String category;
  double amount;
  _ExpenseItem({required this.category, required this.amount});
}

class _ExpenseItemCard extends StatelessWidget {
  final _ExpenseItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onAmountChanged;

  const _ExpenseItemCard({required this.item, required this.onRemove, required this.onAmountChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.category,
                decoration: const InputDecoration(labelText: 'Kalem', isDense: true),
                onChanged: (v) => item.category = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: item.amount.toInt().toString(),
                decoration: const InputDecoration(labelText: 'Tutar (₺)', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) => onAmountChanged(double.tryParse(v) ?? 0),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
