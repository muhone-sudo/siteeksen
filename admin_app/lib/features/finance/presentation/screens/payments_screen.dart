// Ödemeler ekranı.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran beş sahte ödeme kaydı ("Ahmet Yılmaz ₺850", "Mehmet Demir ₺780" …) ve üç sabit
// özet rakamı ("Bugün ₺4,250", "Bu Hafta ₺18,750", "Bu Ay ₺93,050") gösteriyordu.
// Bu kayıtların hiçbiri veritabanında yok; yönetici bunlara bakarak tahsilat yapıldığını
// sanabilirdi. Liste artık `apiClient.getPayments()` ile geliyor, özet rakamlar da
// gelen gerçek kayıtlardan hesaplanıyor. Hata durumunda boş liste yerine `ErrorStateView`,
// sunucu 501 dönerse `NotImplementedNotice` gösterilir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _payments = const [];

  /// null = tüm durumlar. Sunucuya `status` parametresi olarak geçilir.
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await apiClient.getPayments(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _payments = rows
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
        title: const Text('Ödemeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Dışa aktar',
            // Doğrulanmış bir dışa aktarma ucu yok; sahte başarı mesajı verilmez.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dışa aktarma henüz hazır değil.')),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Ödemeler alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: const [
          NotImplementedNotice(
            title: 'Ödeme listesi henüz hazır değil',
            detail: 'Sunucu bu uç için henüz veri döndürmüyor.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Özet rakamlar sabit değil; listelenen gerçek ödemelerden toplanır.
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: 'Bugün',
                value: formatTry(_sumSince(startOfToday)),
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'Bu Hafta',
                value: formatTry(_sumSince(startOfWeek)),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'Bu Ay',
                value: formatTry(_sumSince(startOfMonth)),
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Son Ödemeler', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_statusFilter != null)
              Chip(
                label: Text(_statusLabel(_statusFilter!)),
                onDeleted: () {
                  setState(() => _statusFilter = null);
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_payments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: EmptyStateView(message: 'Görüntülenecek ödeme kaydı yok.'),
          )
        else
          ..._payments.map((p) => _PaymentCard(payment: p)),
      ],
    );
  }

  /// Yalnızca tamamlanmış ödemeleri toplar — bekleyen/başarısız bir ödeme
  /// "tahsil edildi" gibi gösterilmemelidir.
  double _sumSince(DateTime start) {
    var total = 0.0;
    for (final p in _payments) {
      final status = (p['status'] as String?)?.toUpperCase();
      if (status != null && status != 'COMPLETED' && status != 'PAID') continue;
      final date = _paymentDate(p);
      if (date == null || date.isBefore(start)) continue;
      total += _number(p, const ['amount', 'total_amount']) ?? 0;
    }
    return total;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Duruma Göre Filtrele',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            for (final entry in const {
              null: 'Tümü',
              'COMPLETED': 'Tamamlandı',
              'PENDING': 'Bekliyor',
              'FAILED': 'Başarısız',
              'REFUNDED': 'İade',
            }.entries)
              RadioListTile<String?>(
                value: entry.key,
                groupValue: _statusFilter,
                title: Text(entry.value),
                onChanged: (v) {
                  Navigator.pop(ctx);
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'Tamamlandı';
    case 'PENDING':
      return 'Bekliyor';
    case 'FAILED':
      return 'Başarısız';
    case 'REFUNDED':
      return 'İade';
    default:
      return status;
  }
}

String _methodLabel(String? method) {
  switch (method?.toUpperCase()) {
    case 'CREDIT_CARD':
    case 'SAVED_CARD':
      return 'Kredi Kartı';
    case 'BANK_TRANSFER':
    case 'EFT':
      return 'Havale/EFT';
    case 'CASH':
      return 'Nakit';
    case null:
      return '—';
    default:
      return method!;
  }
}

DateTime? _paymentDate(Map<String, dynamic> p) {
  for (final key in const ['completed_at', 'paid_at', 'created_at', 'date']) {
    final v = p[key];
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty && !v.startsWith('0001-01-01')) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.toLocal();
    }
  }
  return null;
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    // Ad bilgisi sunucudan gelmeyebilir; uydurma isim yerine işlem referansı gösterilir.
    final title = _text(payment, const ['name', 'user_name', 'payer_name', 'full_name']) ??
        _text(payment, const ['transaction_id', 'id']) ??
        'Ödeme';
    final unit = _text(payment, const ['unit', 'unit_no', 'unit_name']);
    final method = _methodLabel(_text(payment, const ['payment_method', 'method']));
    final status = (_text(payment, const ['status']) ?? '').toUpperCase();
    final isCompleted = status == 'COMPLETED' || status == 'PAID';
    final amount = _number(payment, const ['amount', 'total_amount']);
    final date = _paymentDate(payment);

    final accent = isCompleted
        ? AppTheme.successColor
        : (status == 'FAILED' ? AppTheme.errorColor : AppTheme.warningColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent,
              child: Icon(
                isCompleted ? Icons.check : Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    [if (unit != null) unit, method, if (status.isNotEmpty) _statusLabel(status)]
                        .join(' • '),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount == null ? '—' : formatTry(amount),
                    style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                Text(date == null ? '—' : formatDateTime(date),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
