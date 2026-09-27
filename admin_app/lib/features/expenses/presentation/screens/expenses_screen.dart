// Gider yönetimi listesi.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran dört sahte gider kaydıyla (AYEDAŞ ₺2.450,75 / Kone ₺3.500 / çatı tamiri ₺1.800 /
// temizlik ₺8.000) ve üç sabit özet rakamıyla (₺15.750 / ₺13.950 / ₺1.800) açılıyordu.
// Bu kayıtlar veritabanında yok; yönetici var olmayan giderleri onaylanmış sanabilirdi.
// Ayrıca ay seçici ("Şubat 2026") ve filtre sayfası hiçbir şey yapmıyordu.
//
// Artık liste `apiClient.getExpenses(year:, month:)` ile geliyor; özet rakamlar gelen
// gerçek kayıtlardan toplanıyor; ay seçici ve filtreler bu veri üstünde gerçekten
// çalışıyor. Sunucu 501 dönerse `NotImplementedNotice`, başka hata olursa
// `ErrorStateView` gösterilir — sessizce boş liste gösterilmez.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _filterType = 'all';

  /// null = tüm kategori tipleri (FIXED / VARIABLE / UNPLANNED).
  String? _categoryTypeFilter;

  late int _year;
  late int _month;

  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _expenses = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await apiClient.getList('/expenses', query: {'year': _year, 'month': _month});
      if (!mounted) return;
      setState(() {
        _expenses =
            rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  /// Seçili sekme ve kategori tipine göre süzülmüş kayıtlar.
  List<Map<String, dynamic>> get _visibleExpenses {
    return _expenses.where((e) {
      switch (_filterType) {
        case 'reflects':
          if (_flag(e, const ['reflects_to_assessment']) != true) return false;
          break;
        case 'non_invoiced':
          if (_flag(e, const ['is_invoiced']) != false) return false;
          break;
        case 'pending':
          if ((_text(e, const ['status']) ?? '').toUpperCase() != 'PENDING') return false;
          break;
      }
      if (_categoryTypeFilter != null) {
        final type = (_text(e, const ['category_type', 'type']) ?? '').toUpperCase();
        if (type != _categoryTypeFilter) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Yönetimi'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Dışa aktar',
            // Dışa aktarma için doğrulanmış bir uç yok; sahte başarı mesajı verilmez.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dışa aktarma henüz hazır değil.')),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Column(
              children: [
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
                        Text('${_monthName(_month)} $_year',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                    label: 'Tümü',
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all')),
                _FilterChip(
                    label: 'Aidata Yansıyan',
                    isSelected: _filterType == 'reflects',
                    onTap: () => setState(() => _filterType = 'reflects')),
                _FilterChip(
                    label: 'Faturasız',
                    isSelected: _filterType == 'non_invoiced',
                    onTap: () => setState(() => _filterType = 'non_invoiced')),
                _FilterChip(
                    label: 'Onay Bekleyen',
                    isSelected: _filterType == 'pending',
                    onTap: () => setState(() => _filterType = 'pending')),
              ],
            ),
          ),

          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/expenses/add');
          // Yeni gider eklendiyse liste gerçek veriyle tazelensin.
          if (mounted) await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Gider Ekle'),
      ),
    );
  }

  /// Özet kartları sabit değil; yüklenen gerçek kayıtlardan hesaplanır.
  Widget _buildSummaryRow() {
    final hasData = !_loading && _error == null;
    double total = 0, invoiced = 0, nonInvoiced = 0;
    if (hasData) {
      for (final e in _expenses) {
        final amount = _number(e, const ['amount', 'total_amount']) ?? 0;
        total += amount;
        if (_flag(e, const ['is_invoiced']) == false) {
          nonInvoiced += amount;
        } else {
          invoiced += amount;
        }
      }
    }
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
              label: 'Toplam',
              value: hasData ? formatTry(total) : '—',
              color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
              label: 'Faturalı',
              value: hasData ? formatTry(invoiced) : '—',
              color: AppTheme.successColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
              label: 'Faturasız',
              value: hasData ? formatTry(nonInvoiced) : '—',
              color: AppTheme.warningColor),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const LoadingView(message: 'Giderler alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: const [
          NotImplementedNotice(
            title: 'Gider listesi henüz hazır değil',
            detail: 'Gider servisi veri katmanına bağlanmadığı için kayıt döndürmüyor.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    final items = _visibleExpenses;
    if (items.isEmpty) {
      return EmptyStateView(
        message: _expenses.isEmpty
            ? '${_monthName(_month)} $_year için gider kaydı yok.'
            : 'Seçili filtreye uyan gider yok.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final expense = items[index];
          final id = _text(expense, const ['id']);
          return _ExpenseCard(
            expense: expense,
            onTap: id == null ? null : () => context.go('/expenses/$id'),
          );
        },
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) {
        final years = [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];
        var year = _year;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dönem Seç',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: years
                        .map((y) => ChoiceChip(
                              label: Text('$y'),
                              selected: y == year,
                              onSelected: (_) => setSheetState(() => year = y),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: List.generate(12, (i) => i + 1)
                        .map((m) => ActionChip(
                              label: Text(_monthName(m)),
                              onPressed: () => Navigator.pop(ctx, DateTime(year, m)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _year = selected.year;
        _month = selected.month;
      });
      await _load();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrele',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Kategori Tipi'),
              const SizedBox(height: 8),
              // Seçimler artık gerçekten listeyi süzüyor (önce hiçbir etkisi yoktu).
              StatefulBuilder(
                builder: (ctx, setSheetState) => Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const {
                      null: 'Tümü',
                      'FIXED': 'Sabit',
                      'VARIABLE': 'Değişken',
                      'UNPLANNED': 'Plansız',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _categoryTypeFilter == entry.key,
                        onSelected: (_) {
                          setSheetState(() {});
                          setState(() => _categoryTypeFilter = entry.key);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ),
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

double? _number(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

/// Üç durumlu okuma: true / false / bilinmiyor (null). Bilinmeyeni `false` saymak,
/// faturalı bir gideri "faturasız" göstermek gibi yanlış rozetler üretir.
bool? _flag(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is bool) return v;
    if (v is String) {
      if (v.toLowerCase() == 'true') return true;
      if (v.toLowerCase() == 'false') return false;
    }
  }
  return null;
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          ),
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
  final Map<String, dynamic> expense;
  final VoidCallback? onTap;
  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = _text(expense, const ['category_name', 'category']) ?? 'Kategorisiz';
    final description = _text(expense, const ['description', 'title']) ?? '—';
    final amount = _number(expense, const ['amount', 'total_amount']);
    final date = expense['expense_date'] ?? expense['date'] ?? expense['created_at'];
    final isInvoiced = _flag(expense, const ['is_invoiced']);
    final reflects = _flag(expense, const ['reflects_to_assessment']);
    final status = (_text(expense, const ['status']) ?? '').toUpperCase();

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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _categoryColor(category).withValues(alpha: 0.1),
                    child: Icon(_categoryIcon(category),
                        color: _categoryColor(category), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amount == null ? '—' : formatTry(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatDate(date),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (isInvoiced == false)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, size: 12, color: AppTheme.warningColor),
                          SizedBox(width: 4),
                          Text('Faturasız',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (reflects == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Aidata Yansıyor',
                          style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                    ),
                  if (status == 'PENDING')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Onay Bekliyor',
                          style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Ortak Elektrik':
      return Colors.amber;
    case 'Ortak Su':
      return Colors.blue;
    case 'Ortak Isınma':
      return Colors.deepOrange;
    case 'Asansör Bakımı':
      return Colors.purple;
    case 'Bina Temizliği':
      return Colors.teal;
    case 'Güvenlik':
      return Colors.indigo;
    case 'Acil Tamir':
      return Colors.orange;
    default:
      return AppTheme.primaryColor;
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Ortak Elektrik':
      return Icons.bolt;
    case 'Ortak Su':
      return Icons.water_drop;
    case 'Ortak Isınma':
      return Icons.whatshot;
    case 'Asansör Bakımı':
      return Icons.elevator;
    case 'Bina Temizliği':
      return Icons.cleaning_services;
    case 'Güvenlik':
      return Icons.security;
    case 'Acil Tamir':
      return Icons.build;
    default:
      return Icons.receipt;
  }
}
