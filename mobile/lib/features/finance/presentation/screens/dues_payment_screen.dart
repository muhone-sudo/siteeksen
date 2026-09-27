// Aidat Ödeme Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13, todo 0.C.1):
// Önceki sürüm TAMAMEN SAHTEYDİ:
//   - Borç tutarı koda gömülüydü (₺1.250,00) — her kullanıcıya aynı rakam gösteriliyordu.
//   - "Öde" → "Onayla" akışı HİÇBİR AĞ ÇAĞRISI YAPMADAN "Ödeme Başarılı!" diyordu.
//     Kullanıcı borcunu ödediğini sanıyor, sistemde hiçbir kayıt oluşmuyordu.
// Para ile ilgili bir ekranda bu, kabul edilebilir en kötü hatadır.
//
// Bu sürüm:
//   - Borcu ve tahakkukları gerçek API'den (`/finance/debt-status`, `/finance/assessments`) alır.
//   - Veri alınamazsa uydurma rakam göstermez; hatayı ve yeniden deneme seçeneğini gösterir.
//   - Ödeme isteğini gerçekten gönderir. Sunucu `payment_gateway_ready: false` döndüğü sürece
//     (ödeme sağlayıcısı entegrasyonu yok — bkz. questions.md S-06) kullanıcıya ödemenin
//     ALINMADIĞI açıkça söylenir; "başarılı" denmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

class DuesPaymentScreen extends StatefulWidget {
  const DuesPaymentScreen({super.key});

  @override
  State<DuesPaymentScreen> createState() => _DuesPaymentScreenState();
}

class _DuesPaymentScreenState extends State<DuesPaymentScreen> {
  int _selectedPaymentMethod = 0;

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  Map<String, dynamic>? _debtStatus;
  List<Map<String, dynamic>> _assessments = const [];

  static const _paymentMethods = [
    (label: 'Kredi/Banka Kartı', code: 'CREDIT_CARD', icon: Icons.credit_card_rounded, color: AppleTheme.systemBlue),
    (label: 'Havale/EFT', code: 'BANK_TRANSFER', icon: Icons.account_balance_rounded, color: AppleTheme.systemGreen),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final debt = await apiClient.getDebtStatus();
      final assessments = await apiClient.getAssessments();
      if (!mounted) return;
      setState(() {
        _debtStatus = debt;
        _assessments = assessments
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = toUserMessage(e);
        _loading = false;
      });
    }
  }

  double get _currentBalance =>
      (_debtStatus?['current_balance'] as num?)?.toDouble() ?? 0;

  /// Ödenmemiş tahakkuklar — ödeme isteğinde bunların kimlikleri gönderilir.
  List<Map<String, dynamic>> get _payableAssessments => _assessments
      .where((a) => (a['status'] as String?) != 'PAID')
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Aidat Ödeme'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildPayBar(context),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Borç bilgisi alınıyor…');
    }
    if (_loadError != null) {
      return ErrorStateView(message: _loadError!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _buildBalanceCard(),
          const SectionTitle(title: 'Borç Detayları'),
          _buildAssessmentList(),
          const SectionTitle(title: 'Ödeme Yöntemi'),
          _buildPaymentMethods(),
          const NotImplementedNotice(
            title: 'Ödeme altyapısı henüz bağlanmadı',
            detail: 'Ödeme sağlayıcısı entegrasyonu tamamlanana kadar bu ekrandan '
                'tahsilat YAPILAMAZ. Ödeme talebi oluşturulur ama tutar tahsil edilmez.',
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final hasDebt = (_debtStatus?['has_debt'] as bool?) ?? (_currentBalance > 0);
    final overdueMonths = (_debtStatus?['overdue_months'] as num?)?.toInt() ?? 0;
    final accent = hasDebt ? AppleTheme.systemRed : AppleTheme.systemGreen;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Borç',
                  style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'Ödenmemiş' : 'Güncel',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatTry(_currentBalance),
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: -1),
          ),
          if (overdueMonths > 0) ...[
            const SizedBox(height: 4),
            Text('$overdueMonths ay gecikmiş ödeme var',
                style: TextStyle(fontSize: 14, color: AppleTheme.tertiaryLabel)),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentList() {
    if (_assessments.isEmpty) {
      return const EmptyStateView(
        message: 'Bu yıl için tahakkuk kaydı bulunamadı.',
        icon: Icons.receipt_long_rounded,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < _assessments.length; i++) ...[
            _assessmentRow(_assessments[i]),
            if (i < _assessments.length - 1)
              const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }

  Widget _assessmentRow(Map<String, dynamic> a) {
    final status = (a['status'] as String?) ?? 'PENDING';
    final isPaid = status == 'PAID';
    final isOverdue = status == 'OVERDUE';
    final color = isPaid
        ? AppleTheme.systemGreen
        : isOverdue
            ? AppleTheme.systemRed
            : AppleTheme.systemOrange;

    // Kısmen ödenmiş dönemde gösterilen tutar KALAN borçtur.
    final total = (toNum(a['total_amount']) - toNum(a['paid_amount'])).toDouble();
    final lateFee = toNum(a['late_fee']).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_rounded
                  : isOverdue
                      ? Icons.priority_high_rounded
                      : Icons.schedule_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_periodLabel(a),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (lateFee > 0)
                  Text('Gecikme tazminatı dahil: ${formatTry(lateFee)}',
                      style: TextStyle(
                          fontSize: 12, color: AppleTheme.tertiaryLabel)),
              ],
            ),
          ),
          Text(formatTry(total),
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _periodLabel(Map<String, dynamic> a) {
    final period = a['period'] as String?;
    if (period == null || !period.contains('-')) return period ?? 'Dönem';
    final parts = period.split('-');
    final month = int.tryParse(parts[1]) ?? 0;
    const names = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    if (month < 1 || month > 12) return period;
    return '${names[month]} ${parts[0]}';
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < _paymentMethods.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: _selectedPaymentMethod,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v ?? 0),
              title: Text(_paymentMethods[i].label),
              secondary: Icon(_paymentMethods[i].icon,
                  color: _paymentMethods[i].color),
            ),
        ],
      ),
    );
  }

  Widget? _buildPayBar(BuildContext context) {
    if (_loading || _loadError != null) return null;

    final payable = _payableAssessments;
    final enabled = payable.isNotEmpty && !_submitting;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? _confirmAndPay : null,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(payable.isEmpty
                  ? 'Ödenecek tahakkuk yok'
                  : '${formatTry(_currentBalance)} Öde'),
        ),
      ),
    );
  }

  Future<void> _confirmAndPay() async {
    final payable = _payableAssessments;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödeme Onayı'),
        content: Text(
          '${payable.length} tahakkuk için toplam ${formatTry(_currentBalance)} '
          'ödeme talebi oluşturulacak.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Devam')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final result = await apiClient.createPayment(
        assessmentIds: payable.map((a) => a['id'] as String).toList(),
        paymentMethod: _paymentMethods[_selectedPaymentMethod].code,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _showPaymentResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ödeme oluşturulamadı'),
          content: Text(toUserMessage(e)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    }
  }

  /// Ödeme sonucu diyalogu.
  ///
  /// DİKKAT: `payment_gateway_ready` false olduğu sürece burada "Ödeme Başarılı"
  /// YAZILMAZ. Sunucu yalnızca bir ödeme KAYDI oluşturur; tahsilat yapılmaz.
  void _showPaymentResult(Map<String, dynamic> result) {
    final ready = (result['payment_gateway_ready'] as bool?) ?? false;
    final amount = (result['amount'] as num?)?.toDouble() ?? 0;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ready ? 'Ödeme alındı' : 'Ödeme talebi oluşturuldu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tutar: ${formatTry(amount)}'),
            const SizedBox(height: 8),
            Text(
              ready
                  ? 'Ödemeniz tahsil edildi.'
                  : 'Ödeme sağlayıcısı entegrasyonu henüz tamamlanmadığı için '
                      'tutar TAHSİL EDİLMEDİ. Kaydınız "beklemede" durumundadır; '
                      'yönetimle iletişime geçerek ödemenizi tamamlayabilirsiniz.',
              style: TextStyle(
                color: ready ? null : AppleTheme.systemOrange,
                fontWeight: ready ? null : FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
