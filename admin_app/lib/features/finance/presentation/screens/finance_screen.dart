// Finans özeti ekranı.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran tamamen koda gömülü rakamlar gösteriyordu: "₺105,400" tahakkuk, "₺93,050"
// tahsilat, "%88.3" oran, beş sabit gider kalemi ve "Fatma Çelik / Ayşe Kaya / Hasan Öz"
// adında var olmayan borçlular. Para ekranında uydurma rakam, yöneticinin yanlış karar
// almasına yol açar; bu yüzden tüm veriler `apiClient` üzerinden alınacak şekilde
// yeniden yazıldı. Veri alınamadığında sessizce boş/sıfır göstermek yerine
// `ErrorStateView`, sunucu 501 dönerse `NotImplementedNotice` gösterilir.
//
// Borçlu sakin listesi için `ApiClient` üzerinde bir metot bulunmadığından o bölüm
// uydurma isimlerle doldurulmak yerine `NotImplementedNotice` ile işaretlendi.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Dönem, sabit "Ocak 2026" yerine cihazın bugünkü tarihinden başlar.
  late int _year;
  late int _month;

  bool _loading = true;
  Object? _error;

  Map<String, dynamic>? _overview;

  // Gider dağılımı ayrı bir uçtan gelir; o uç 501 dönse bile özet kartları
  // görünmeye devam etsin diye durumu ayrı tutulur.
  List<_CategoryTotal> _expenseBreakdown = const [];
  Object? _expenseError;

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
      _expenseError = null;
    });

    Map<String, dynamic>? overview;
    Object? overviewError;
    try {
      overview = await apiClient.getFinanceOverview();
    } catch (e) {
      overviewError = e;
    }

    List<_CategoryTotal> breakdown = const [];
    Object? expenseError;
    try {
      final rows = await apiClient.getExpenses(year: _year, month: _month);
      breakdown = _aggregateByCategory(rows);
    } catch (e) {
      expenseError = e;
    }

    if (!mounted) return;
    setState(() {
      _overview = overview;
      _error = overviewError;
      _expenseBreakdown = breakdown;
      _expenseError = expenseError;
      _loading = false;
    });
  }

  /// Gider kayıtlarını kategoriye göre toplar. Grafik verisi sunucudan hazır
  /// gelmediği için burada gerçek kayıtlardan hesaplanır — sabit liste kullanılmaz.
  List<_CategoryTotal> _aggregateByCategory(List<dynamic> rows) {
    final totals = <String, double>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final label = _text(map, const ['category_name', 'category', 'name']) ?? 'Diğer';
      totals[label] = (totals[label] ?? 0) + (_number(map, const ['amount', 'total_amount']) ?? 0);
    }
    final list = totals.entries
        .map((e) => _CategoryTotal(label: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Dışa aktar',
            // Dışa aktarma için doğrulanmış bir uç yok; sahte bir "indirildi"
            // mesajı vermek yerine durum açıkça söyleniyor.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dışa aktarma henüz hazır değil.')),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Finans özeti alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _periodCard(),
          const SizedBox(height: 16),
          const NotImplementedNotice(
            title: 'Finans özeti henüz hazır değil',
            detail: 'Sunucu bu dönem için tahakkuk/tahsilat özeti üretmiyor.',
          ),
          const SizedBox(height: 16),
          _quickActions(),
        ],
      );
    }

    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    final overview = _overview ?? const <String, dynamic>{};
    final assessed = _number(overview, const ['total_amount', 'total_assessed', 'assessed']);
    final collected = _number(overview, const ['collected_amount', 'total_collected', 'collected']);
    final pending = _number(overview, const ['pending_amount', 'outstanding_amount', 'pending']) ??
        ((assessed != null && collected != null) ? assessed - collected : null);
    final rate = _number(overview, const ['collection_rate', 'rate']) ??
        ((assessed != null && assessed > 0 && collected != null)
            ? (collected / assessed) * 100
            : null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _periodCard(),
        const SizedBox(height: 16),

        // Özet kartları — değer gelmediyse uydurma sıfır değil, "—" gösterilir.
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Tahakkuk',
                value: _money(assessed),
                icon: Icons.receipt_long,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Tahsilat',
                value: _money(collected),
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
                value: _money(pending),
                icon: Icons.pending_actions,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Tahsilat Oranı',
                value: rate == null ? '—' : '%${formatNumber(double.parse(rate.toStringAsFixed(1)))}',
                icon: Icons.trending_up,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _quickActions(),
        const SizedBox(height: 24),

        const Text('Gider Dağılımı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildExpenseBreakdown(),
        const SizedBox(height: 24),

        const Text('Borçlu Sakinler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        // Borçlu listesi için istemcide tanımlı bir uç yok; sahte isim yerine bildirim.
        const NotImplementedNotice(
          title: 'Borçlu sakin listesi henüz hazır değil',
          detail: 'Bu liste için sunucu ucu uygulamaya bağlanmadı.',
        ),
      ],
    );
  }

  Widget _periodCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month),
        title: Text('${_monthName(_month)} $_year'),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: _pickPeriod,
      ),
    );
  }

  Widget _quickActions() {
    return Row(
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
    );
  }

  Widget _buildExpenseBreakdown() {
    if (_expenseError != null && isNotImplemented(_expenseError!)) {
      return const NotImplementedNotice(
        title: 'Gider dağılımı henüz hazır değil',
        detail: 'Gider servisi bu dönem için veri döndürmüyor.',
      );
    }
    if (_expenseError != null) {
      return ErrorStateView(message: toUserMessage(_expenseError!), onRetry: _load);
    }
    if (_expenseBreakdown.isEmpty) {
      return const EmptyStateView(message: 'Bu dönem için gider kaydı yok.');
    }

    final total = _expenseBreakdown.fold<double>(0, (sum, e) => sum + e.amount);
    const palette = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
    ];
    return Column(
      children: [
        for (var i = 0; i < _expenseBreakdown.length; i++)
          _ExpenseBar(
            label: _expenseBreakdown[i].label,
            amount: _expenseBreakdown[i].amount,
            total: total,
            color: palette[i % palette.length],
          ),
      ],
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

String _monthName(int month) {
  const months = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  return (month >= 1 && month <= 12) ? months[month] : '—';
}

/// Değer gerçekten yoksa "0 ₺" yazmak yanıltıcıdır; bilinmeyen için "—" kullanılır.
String _money(num? value) => value == null ? '—' : formatTry(value);

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

class _CategoryTotal {
  final String label;
  final double amount;
  const _CategoryTotal({required this.label, required this.amount});
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
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
    final ratio = total > 0 ? (amount / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(formatTry(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
