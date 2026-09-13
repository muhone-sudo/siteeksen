// Sakinlerin gördüğü site gideri listesi.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran beş sahte gider kaydıyla açılıyordu (AYEDAŞ ₺2.450,75 / su ₺1.850 / asansör
// ₺3.500 / çatı ₺1.800 / temizlik ₺8.000) ve "Bu Ay Sizin Payınız" başlığı altında
// bu uydurma rakamların toplamını gösteriyordu. Sakine, ödeyeceği tutar diye var
// olmayan bir rakam göstermek en ağır hata türüdür. Ayrıca "Faturayı Görüntüle"
// düğmesi her zaman sabit bir "fatura.pdf" açıyordu.
//
// Artık liste `apiClient.getExpenses(year:, month:)` ile gelir; pay toplamı gerçek
// `per_unit_amount` alanlarından hesaplanır. Belge görüntüleyici bağlanmadığı için
// o bölüm `NotImplementedNotice` gösterir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class ResidentExpensesScreen extends StatefulWidget {
  const ResidentExpensesScreen({super.key});

  @override
  State<ResidentExpensesScreen> createState() => _ResidentExpensesScreenState();
}

class _ResidentExpensesScreenState extends State<ResidentExpensesScreen> {
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
      final rows = await apiClient.getExpenses(year: _year, month: _month);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Giderleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Dönem seç',
            onPressed: _pickPeriod,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Site giderleri alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: [
          _periodCard(),
          const NotImplementedNotice(
            title: 'Site giderleri henüz hazır değil',
            detail: 'Sunucu bu dönem için gider dökümü döndürmüyor.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    // Payın toplamı yalnızca sunucunun gerçekten döndürdüğü `per_unit_amount`
    // değerlerinden hesaplanır; alan yoksa toplama katılmaz.
    double? shareTotal;
    var hasAnyShare = false;
    for (final e in _expenses) {
      if (_flag(e, const ['reflects_to_assessment']) != true) continue;
      final perUnit = _number(e, const ['per_unit_amount']);
      if (perUnit == null) continue;
      hasAnyShare = true;
      shareTotal = (shareTotal ?? 0) + perUnit;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _periodCard(),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('Bu Ay Sizin Payınız',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                hasAnyShare ? formatTry(shareTotal) : '—',
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                hasAnyShare
                    ? 'Değişken giderler toplamı'
                    : 'Bu dönem için daire payı hesaplanmadı',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bina temizliği, güvenlik gibi sabit giderler aylık aidatınıza dahildir.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Gider Detayları',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        if (_expenses.isEmpty)
          EmptyStateView(message: '${_monthName(_month)} $_year için gider kaydı yok.')
        else
          ..._expenses.map((e) => _ExpenseCard(expense: e)),
      ],
    );
  }

  Widget _periodCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
        title: Text('${_monthName(_month)} $_year'),
        subtitle: const Text('Görüntülenen dönem'),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: _pickPeriod,
      ),
    );
  }

  Future<void> _pickPeriod() async {
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
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final category = _text(expense, const ['category_name', 'category']) ?? 'Kategorisiz';
    final description = _text(expense, const ['description', 'title']) ?? '—';
    final amount = _number(expense, const ['amount', 'total_amount']);
    final perUnit = _number(expense, const ['per_unit_amount']);
    final isInvoiced = _flag(expense, const ['is_invoiced']);
    final reflects = _flag(expense, const ['reflects_to_assessment']);
    final documents = _documents(expense);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Text(
                        formatDate(expense['expense_date'] ??
                            expense['date'] ??
                            expense['created_at']),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Pay bilgisi yalnızca sunucu gerçekten hesapladıysa gösterilir.
            if (reflects == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sizin Payınız:', style: TextStyle(fontSize: 13)),
                  Text(perUnit == null ? '—' : formatTry(perUnit),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              )
            else if (reflects == false)
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                  SizedBox(width: 4),
                  Text('Aidatınıza dahil',
                      style: TextStyle(color: AppTheme.successColor, fontSize: 13)),
                ],
              )
            else
              const Text('Aidata yansıma bilgisi yok.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),

            if (isInvoiced == false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, size: 18, color: AppTheme.warningColor),
                        SizedBox(width: 8),
                        Text('Faturasız Gider',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warningColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _text(expense, const ['non_invoiced_reason', 'reason']) ??
                          'Bu gider için resmi fatura bulunmamaktadır.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],

            if (documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showDocument(context, documents.first),
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
    );
  }

  void _showDocument(BuildContext context, Map<String, dynamic> document) {
    final name = _text(document, const ['name', 'file_name']) ?? 'Belge';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            // Belge görüntüleyici/indirici bağlanmadı; sahte bir PDF önizlemesi
            // göstermek yerine durum açıkça bildiriliyor.
            Expanded(
              child: ListView(
                controller: scrollController,
                children: const [
                  NotImplementedNotice(
                    title: 'Belge görüntüleme henüz hazır değil',
                    detail: 'Fatura dosyasını indirme/görüntüleme ucu uygulamaya bağlanmadı.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _documents(Map<String, dynamic> expense) {
  for (final key in const ['invoices', 'documents', 'files', 'attachments']) {
    final v = expense[key];
    if (v is List) {
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }
  return const [];
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
