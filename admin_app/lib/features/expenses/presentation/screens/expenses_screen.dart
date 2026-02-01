import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedMonth = '2026-02';
  String _filterType = 'all';

  final List<_Expense> _expenses = [
    _Expense(
      id: '1', category: 'Ortak Elektrik', description: 'Ocak 2026 elektrik faturası',
      amount: 2450.75, date: '28.01.2026', isInvoiced: true, reflectsToAssessment: true,
      status: 'APPROVED', vendorName: 'AYEDAŞ',
    ),
    _Expense(
      id: '2', category: 'Asansör Bakımı', description: 'Yıllık bakım',
      amount: 3500.00, date: '15.01.2026', isInvoiced: true, reflectsToAssessment: true,
      status: 'APPROVED', vendorName: 'Kone',
    ),
    _Expense(
      id: '3', category: 'Acil Tamir', description: 'Çatı tamir işlemi',
      amount: 1800.00, date: '20.01.2026', isInvoiced: false, reflectsToAssessment: true,
      status: 'PENDING', nonInvoicedReason: 'Elden ödeme - usta',
    ),
    _Expense(
      id: '4', category: 'Bina Temizliği', description: 'Ocak ayı temizlik',
      amount: 8000.00, date: '31.01.2026', isInvoiced: true, reflectsToAssessment: false,
      status: 'APPROVED', vendorName: 'Temizlik Ltd.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Yönetimi'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Month Selector & Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                // Month picker
                InkWell(
                  onTap: _showMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month, size: 20),
                        const SizedBox(width: 8),
                        Text('Şubat 2026', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Summary cards
                Row(
                  children: [
                    Expanded(child: _SummaryCard(label: 'Toplam', value: '₺15,750', color: AppTheme.primaryColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: 'Faturalı', value: '₺13,950', color: AppTheme.successColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: 'Faturasız', value: '₺1,800', color: AppTheme.warningColor)),
                  ],
                ),
              ],
            ),
          ),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(label: 'Tümü', isSelected: _filterType == 'all', onTap: () => setState(() => _filterType = 'all')),
                _FilterChip(label: 'Aidata Yansıyan', isSelected: _filterType == 'reflects', onTap: () => setState(() => _filterType = 'reflects')),
                _FilterChip(label: 'Faturasız', isSelected: _filterType == 'non_invoiced', onTap: () => setState(() => _filterType = 'non_invoiced')),
                _FilterChip(label: 'Onay Bekleyen', isSelected: _filterType == 'pending', onTap: () => setState(() => _filterType = 'pending')),
              ],
            ),
          ),
          
          // Expense list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) => _ExpenseCard(
                expense: _expenses[index],
                onTap: () => context.go('/expenses/${_expenses[index].id}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/expenses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Gider Ekle'),
      ),
    );
  }

  void _showMonthPicker() {
    // TODO: Month picker dialog
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Kategori'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Tümü'), selected: true, onSelected: (_) {}),
                ChoiceChip(label: const Text('Sabit'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('Değişken'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('Plansız'), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Uygula'))),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final _Expense expense;
  final VoidCallback onTap;
  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
                    child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category), size: 20),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(expense.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₺${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(expense.date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              
              // Badges
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  // Faturasız badge
                  if (!expense.isInvoiced)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.warningColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, size: 12, color: AppTheme.warningColor),
                          const SizedBox(width: 4),
                          Text('Faturasız', style: TextStyle(fontSize: 10, color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  
                  // Aidata yansıyor badge
                  if (expense.reflectsToAssessment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Aidata Yansıyor', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                    ),
                  
                  // Onay durumu
                  if (expense.status == 'PENDING')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Onay Bekliyor', style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ),
                ],
              ),
            ],
          ),
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

class _Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final String date;
  final bool isInvoiced;
  final bool reflectsToAssessment;
  final String status;
  final String? vendorName;
  final String? nonInvoicedReason;

  _Expense({
    required this.id, required this.category, required this.description,
    required this.amount, required this.date, required this.isInvoiced,
    required this.reflectsToAssessment, required this.status,
    this.vendorName, this.nonInvoicedReason,
  });
}
