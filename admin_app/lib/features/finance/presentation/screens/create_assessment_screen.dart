// Tahakkuk oluşturma ekranı.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran üç sabit gider kalemiyle ("Yönetim Gideri 15.000", "Temizlik 8.000",
// "Güvenlik 12.000") açılıyor, dağıtımı sabit "124 daire"ye bölüyor ve "Kaydet"e
// basıldığında sunucuya HİÇBİR istek göndermeden "Tahakkuk oluşturuldu" diyordu.
// Yani yönetici tahakkuk yaptığını sanıp hiçbir şey kaydetmiyordu — para akışında
// en ağır hata türü.
//
// Artık: gider kalemleri gerçek kategori listesinden (`/finance/expense-categories`) seçilir,
// daire sayısı `getUnits()` ile sayılır, kayıt `POST /finance/assessments` ile yapılır ve
// başarı mesajı yalnızca sunucu 2xx döndüğünde gösterilir.
// Backend `CreateAssessmentInput` alanları: period_year, period_month, due_date,
// expense_items[{category_id, amount}] — gönderilen gövde buna birebir uyar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/data_state.dart';

class CreateAssessmentScreen extends StatefulWidget {
  const CreateAssessmentScreen({super.key});

  @override
  State<CreateAssessmentScreen> createState() => _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState extends State<CreateAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedYear;
  late int _selectedMonth;
  late DateTime _dueDate;

  bool _loading = true;
  Object? _error;
  bool _saving = false;

  /// Sunucudan gelen gerçek gider kategorileri (id + ad).
  List<Map<String, dynamic>> _categories = const [];

  /// Daire sayısı sunucudan sayılır; sabit "124" kullanılmaz.
  int? _unitCount;

  /// Kullanıcının eklediği kalemler. Başlangıçta BOŞ — örnek kalem uydurulmaz.
  final List<_ExpenseItem> _expenseItems = [];

  double get _totalAmount => _expenseItems.fold(0, (sum, item) => sum + item.amount);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    // Varsayılan son ödeme tarihi: içinde bulunulan ayın sonu.
    _dueDate = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  @override
  void dispose() {
    for (final item in _expenseItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await apiClient.getList('/finance/expense-categories');
      // Daire sayısı ayrı bir uçtan gelir; alınamazsa dağıtım bilgisi "—" gösterilir,
      // tahmini bir sayı uydurulmaz.
      int? unitCount;
      try {
        unitCount = (await apiClient.getUnits()).length;
      } catch (_) {
        unitCount = null;
      }
      if (!mounted) return;
      setState(() {
        // Sayaç bazlı (METER_READING) ve özel (CUSTOM) kalemler tahakkukta
        // paylaştırılmaz; sunucu reddeder. Seçtirilmez.
        _categories = categories
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => distributableCategory(e['distribution_type']))
            .toList();
        _unitCount = unitCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tahakkuk Oluştur')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Gider kategorileri alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: const [
          NotImplementedNotice(
            title: 'Tahakkuk oluşturma henüz hazır değil',
            detail: 'Gider kategorileri sunucudan alınamadığı için tahakkuk oluşturulamaz.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                          initialValue: _selectedYear,
                          decoration: const InputDecoration(labelText: 'Yıl'),
                          items: _yearOptions
                              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          decoration: const InputDecoration(labelText: 'Ay'),
                          items: List.generate(12, (i) => i + 1)
                              .map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m))))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedMonth = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sunucu `due_date` alanını zorunlu tutuyor; bu yüzden ekranda var.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Son Ödeme Tarihi'),
                    subtitle: Text(formatDate(_dueDate)),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: _pickDueDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gider Kalemleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: _categories.isEmpty ? null : _addExpenseItem,
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_categories.isEmpty)
            const EmptyStateView(
              message: 'Sunucuda tanımlı gider kategorisi yok. Önce kategori tanımlanmalı.',
            )
          else if (_expenseItems.isEmpty)
            const EmptyStateView(message: 'Henüz gider kalemi eklenmedi.')
          else
            ..._expenseItems.map((item) => _ExpenseItemCard(
                  item: item,
                  categories: _categories,
                  onRemove: () => setState(() {
                    _expenseItems.remove(item);
                    item.dispose();
                  }),
                  onChanged: () => setState(() {}),
                )),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam Gider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(formatTry(_totalAmount),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dağıtım Bilgisi', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Toplam Daire',
                    value: _unitCount == null ? '—' : '$_unitCount',
                  ),
                  _InfoRow(
                    label: 'Daire Başı Ortalama',
                    // Daire sayısı bilinmiyorsa bölme yapılmaz; yanlış tutar gösterilmez.
                    value: (_unitCount == null || _unitCount == 0)
                        ? '—'
                        : formatTry(_totalAmount / _unitCount!),
                  ),
                  if (_unitCount == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Daire sayısı sunucudan alınamadı. Gerçek dağıtım sunucuda hesaplanır.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saving ? null : _createAssessment,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Tahakkuk Oluştur'),
          ),
        ],
      ),
    );
  }

  List<int> get _yearOptions {
    final current = DateTime.now().year;
    return [current - 1, current, current + 1];
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _addExpenseItem() {
    setState(() {
      _expenseItems.add(_ExpenseItem(categoryId: _categories.first['id']?.toString()));
    });
  }

  Future<void> _createAssessment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_expenseItems.isEmpty) {
      _showMessage('En az bir gider kalemi ekleyin.', isError: true);
      return;
    }
    if (_expenseItems.any((i) => i.categoryId == null || i.amount <= 0)) {
      _showMessage('Her kalem için kategori ve sıfırdan büyük tutar girin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await apiClient.post('/finance/assessments', {
        'period_year': _selectedYear,
        'period_month': _selectedMonth,
        // DÜZELTME (2026-09-27): sunucu YYYY-MM-DD bekler; ISO zaman damgası 400 alıyordu.
        'due_date': apiDate(_dueDate),
        'expense_items': _expenseItems
            .map((i) => {'category_id': i.categoryId, 'amount': i.amount})
            .toList(),
      });
      if (!mounted) return;
      // Başarı mesajı YALNIZCA sunucu isteği başarıyla tamamladığında gösterilir.
      final n = res['data'] is List ? (res['data'] as List).length : null;
      _showMessage(n == null ? 'Tahakkuk oluşturuldu' : 'Tahakkuk oluşturuldu: $n daire');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(errorText(e), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }
}

String _monthName(int month) {
  const months = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  return (month >= 1 && month <= 12) ? months[month] : '—';
}

class _ExpenseItem {
  String? categoryId;
  final TextEditingController amountController = TextEditingController();

  _ExpenseItem({this.categoryId});

  double get amount => double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;

  void dispose() => amountController.dispose();
}

class _ExpenseItemCard extends StatelessWidget {
  final _ExpenseItem item;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExpenseItemCard({
    required this.item,
    required this.categories,
    required this.onRemove,
    required this.onChanged,
  });

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
              child: DropdownButtonFormField<String>(
                initialValue: item.categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kalem', isDense: true),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c['id']?.toString(),
                          child: Text(
                            (c['name'] ?? c['category_name'] ?? '—').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  item.categoryId = v;
                  onChanged();
                },
                validator: (v) => v == null ? 'Kategori seçin' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: item.amountController,
                decoration: const InputDecoration(labelText: 'Tutar (₺)', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Tutar girin';
                  return null;
                },
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

/// Tahakkukta paylaştırılabilen dağıtım yöntemleri (sunucu ile aynı kural).
bool distributableCategory(Object? distributionType) =>
    const {'EQUAL', 'SHARE_RATIO', 'AREA_M2'}.contains(distributionType);
