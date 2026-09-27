// Gider detay ekranı.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran `build()` içinde açıkça "// Mock data" yazan sabit bir map kullanıyordu:
// AYEDAŞ faturası, "2026-001234" fatura numarası, ₺2.450,75 tutar, "124 daire",
// "₺19,76 daire başı" ve var olmayan bir "fatura.pdf (245 KB)". Hangi gidere
// tıklanırsa tıklansın aynı sahte kayıt gösteriliyordu.
//
// Artık kayıt `apiClient.getExpense(id)` ile alınır ve yalnızca sunucudan gelen
// alanlar gösterilir; olmayan alan için "—" yazılır. Düzenle/kopyala/sil ile fatura
// görüntüleme için doğrulanmış bir uç bulunmadığından bu eylemler sahte başarı
// mesajı yerine "henüz hazır değil" bilgisi verir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/data_state.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _loading = true;
  Object? _error;
  Map<String, dynamic>? _expense;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiClient.getMap('/expenses/${widget.expenseId}');
      if (!mounted) return;
      setState(() {
        _expense = data;
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

  // DÜZELTME (2026-09-27): düzenle/kopyala/sil menüsü yalnızca "hazır değil"
  // diyordu (sunucuda bu uçlar yok: kayıtlı gider muhasebe belgesidir). Buna
  // karşılık sunucuda VAR olan onay/ret akışı ekranda hiç yoktu; faturasız
  // giderler mobilden onaylanamıyordu.
  bool _canWrite = false;

  Future<void> _approve() async {
    final ok = await confirm(context, 'Gideri onayla', 'Onaylanan gider hesap verme belgelerine dahil edilir.');
    if (!ok || !mounted) return;
    if (await runAction(context, () => apiClient.post('/expenses/${widget.expenseId}/approve'))) _load();
  }

  Future<void> _reject() async {
    final reason = await askText(context, 'Gideri reddet', 'Red gerekçesi');
    if (reason == null || !mounted) return;
    if (await runAction(context, () => apiClient.post('/expenses/${widget.expenseId}/reject', {'reason': reason}))) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = (_expense?['status'] ?? '').toString().toUpperCase() == 'PENDING';
    return Scaffold(
      appBar: AppBar(title: const Text('Gider Detayı')),
      body: _buildBody(),
      bottomNavigationBar: pending && _canWrite
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: _reject, child: const Text('Reddet'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: _approve, child: const Text('Onayla'))),
                ]),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Gider detayı alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: const [
          NotImplementedNotice(
            title: 'Gider detayı henüz hazır değil',
            detail: 'Gider servisi bu kayıt için veri döndürmüyor.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _load);
    }

    final expense = _expense ?? const <String, dynamic>{};
    final category = _text(expense, const ['category_name', 'category']) ?? 'Kategorisiz';
    final description = _text(expense, const ['description', 'title']) ?? '—';
    final amount = _number(expense, const ['amount', 'total_amount']);
    final perUnit = _number(expense, const ['per_unit_amount']);
    // Sunucu daire sayısı alanı döndürmez; paylaştırma satırlarından sayılır.
    final distributions = expense['distributions'] is List
        ? (expense['distributions'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];
    final unitCount = distributions.isEmpty ? null : distributions.length;
    final isInvoiced = _flag(expense, const ['is_invoiced']);
    final reflects = _flag(expense, const ['reflects_to_assessment']);
    final status = (_text(expense, const ['status']) ?? '').toUpperCase();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        backgroundColor: _categoryColor(category).withValues(alpha: 0.1),
                        child: Icon(_categoryIcon(category), color: _categoryColor(category)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(description,
                                style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam Tutar'),
                        Text(amount == null ? '—' : formatTry(amount),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rozetler yalnızca sunucu o alanı gerçekten döndürdüyse çizilir.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isInvoiced == true)
                        const _Badge(
                            icon: Icons.receipt,
                            label: 'Faturalı',
                            color: AppTheme.successColor)
                      else if (isInvoiced == false)
                        const _Badge(
                            icon: Icons.warning_amber,
                            label: 'Faturasız',
                            color: AppTheme.warningColor),
                      if (reflects == true)
                        const _Badge(
                            icon: Icons.account_balance_wallet,
                            label: 'Aidata Yansıyor',
                            color: AppTheme.primaryColor),
                      if (status.isNotEmpty)
                        _Badge(
                          icon: _statusIcon(status),
                          label: _statusLabel(status),
                          color: _statusColor(status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _DetailTile(
                    icon: Icons.calendar_today,
                    label: 'Gider Tarihi',
                    value: formatDate(expense['expense_date'] ??
                        expense['date'] ??
                        expense['created_at'])),
                const Divider(height: 1),
                _DetailTile(
                    icon: Icons.business,
                    label: 'Firma',
                    value: _text(expense, const ['vendor_name', 'vendor']) ?? '—'),
                const Divider(height: 1),
                _DetailTile(
                    icon: Icons.tag,
                    label: 'Fatura No',
                    value: _text(expense, const ['invoice_number', 'invoice_no']) ?? '—'),
                const Divider(height: 1),
                _DetailTile(
                  icon: Icons.pie_chart,
                  label: 'Dağıtım',
                  value: _distributionLabel(
                      _text(expense, const ['distribution_type']), unitCount),
                ),
                const Divider(height: 1),
                _DetailTile(
                    icon: Icons.home,
                    label: 'Daire Başı',
                    value: perUnit == null ? '—' : formatTry(perUnit)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isInvoiced == false && _text(expense, const ['invoice_reason']) != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                title: const Text('Faturasız olma nedeni'),
                subtitle: Text(_text(expense, const ['invoice_reason'])!),
              ),
            ),
          if (status == 'REJECTED' && _text(expense, const ['rejection_reason']) != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cancel, color: AppTheme.errorColor),
                title: const Text('Red gerekçesi'),
                subtitle: Text(_text(expense, const ['rejection_reason'])!),
              ),
            ),
          const SizedBox(height: 16),

          if (reflects == true) ...[
            const Text('Aidat Dağılımı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SplitRow(
                      label: 'Dönem',
                      value: _periodLabel(expense),
                    ),
                    const Divider(),
                    _SplitRow(
                      label: 'Dağıtım Tipi',
                      value: _distributionLabel(
                          _text(expense, const ['distribution_type']), null),
                    ),
                    const Divider(),
                    _SplitRow(
                      label: 'Daire Sayısı',
                      value: unitCount == null ? '—' : '$unitCount',
                    ),
                    const Divider(),
                    _SplitRow(
                      label: 'Daire Başı Tutar',
                      value: perUnit == null ? '—' : formatTry(perUnit),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),
            if (distributions.isNotEmpty)
              Card(
                child: ExpansionTile(
                  title: Text('Bağımsız bölüm payları (${distributions.length})'),
                  children: [
                    for (final d in distributions)
                      ListTile(
                        dense: true,
                        title: Text(_text(d, const ['unit_name']) ?? '—'),
                        trailing: Text(formatTry(toNum(d['amount']))),
                      ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

String _periodLabel(Map<String, dynamic> expense) {
  final period = _text(expense, const ['assessment_period']);
  return period == null ? '—' : periodLabel(period);
}

String _distributionLabel(String? type, int? unitCount) {
  String base;
  switch (type?.toUpperCase()) {
    case 'EQUAL':
      base = 'Eşit';
      break;
    case 'AREA_M2':
    case 'AREA':
      base = 'm² Bazlı';
      break;
    case 'SHARE_RATIO':
      base = 'Arsa Payı';
      break;
    case 'PERSON':
      base = 'Kişi Sayısı';
      break;
    case null:
      return '—';
    default:
      base = type!;
  }
  return unitCount == null ? base : '$base ($unitCount daire)';
}

String _statusLabel(String status) {
  switch (status) {
    case 'APPROVED':
      return 'Onaylandı';
    case 'PENDING':
      return 'Onay Bekliyor';
    case 'REJECTED':
      return 'Reddedildi';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'APPROVED':
      return AppTheme.successColor;
    case 'REJECTED':
      return AppTheme.errorColor;
    default:
      return AppTheme.warningColor;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'APPROVED':
      return Icons.check_circle;
    case 'REJECTED':
      return Icons.cancel;
    default:
      return Icons.schedule;
  }
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

/// Üç durumlu okuma: bilinmeyen alan için rozet hiç çizilmez.
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

class _SplitRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SplitRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppTheme.primaryColor : null,
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
