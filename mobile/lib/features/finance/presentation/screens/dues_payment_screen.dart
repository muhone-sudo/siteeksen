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

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
        actions: [
          IconButton(
            key: const Key('clearance'),
            tooltip: 'Borcu yoktur belgesi',
            icon: const Icon(Icons.task_alt_rounded),
            onPressed: _clearance,
          ),
          IconButton(
            key: const Key('credit-notes'),
            tooltip: 'Alacak dekontlarım',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: _creditNotes,
          ),
          IconButton(
            key: const Key('verify-ledger'),
            tooltip: 'Tahsilat kayıtlarını doğrula',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: _verifyLedger,
          ),
        ],
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
              const Text('Toplam Borç',
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
                style: const TextStyle(fontSize: 14, color: AppleTheme.tertiaryLabel)),
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
                      style: const TextStyle(
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

  String _periodLabel(Map<String, dynamic> a) => assessmentLabel(a);

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: RadioGroup<int>(
        groupValue: _selectedPaymentMethod,
        onChanged: (v) => setState(() => _selectedPaymentMethod = v ?? 0),
        child: Column(
          children: [
            for (var i = 0; i < _paymentMethods.length; i++)
              RadioListTile<int>(
                value: i,
                title: Text(_paymentMethods[i].label),
                secondary: Icon(_paymentMethods[i].icon,
                    color: _paymentMethods[i].color),
              ),
          ],
        ),
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

  /// Borcu yoktur belgesi (Apsiyon BUG-04): vadesi gelmemiş cari aidat borç sayılmaz;
  /// belge karekodlu PDF olarak indirilip cihazda açılır.
  Future<void> _clearance() async {
    String? message;
    try {
      final props = await apiClient.getUserProperties();
      final unit = props.whereType<Map>().map((p) => '${p['unit_id'] ?? ''}').firstWhere((u) => u.isNotEmpty, orElse: () => '');
      if (unit.isEmpty) {
        message = 'Kayıtlı bir daireniz bulunamadı.';
      } else {
        final cert = await apiClient.createClearance(unit);
        final bytes = await apiClient.clearancePdf('${cert['id']}');
        final file = File('${(await getTemporaryDirectory()).path}/borcu-yoktur-belgesi.pdf');
        await file.writeAsBytes(bytes, flush: true);
        final r = await OpenFilex.open(file.path, type: 'application/pdf');
        if (r.type != ResultType.done) message = 'Belge indirildi ama açılamadı: ${r.message}';
      }
    } catch (e) {
      message = toUserMessage(e);
    }
    if (!mounted || message == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borcu yoktur belgesi'),
        content: Text(message!),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  /// Alacak dekontları (Apsiyon BUG-12): yönetimin yaptığı indirim/düzeltme sisteme işlenmiş
  /// numaralı belge olarak görünür; borç bu tutar kadar düşmüştür.
  Future<void> _creditNotes() async {
    List<dynamic> notes = const [];
    String? error;
    try {
      notes = await apiClient.getCreditNotes();
    } catch (e) {
      error = toUserMessage(e);
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alacak dekontlarım'),
        content: SizedBox(
          width: double.maxFinite,
          child: error != null
              ? Text(error)
              : notes.isEmpty
                  ? const Text('Dairenize kesilmiş alacak dekontu yok.')
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final n in notes.whereType<Map>())
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${n['document_no']} · ${formatTry(((n['amount_kurus'] as num?) ?? 0) / 100)}'),
                            subtitle: Text('${n['unit']} · ${n['period']}\n${n['reason']}'
                                '${n['reversed_at'] != null ? '\nTERS KAYDI YAPILDI: ${n['reversal_reason'] ?? ''}' : ''}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'PDF',
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              onPressed: () => _openCreditNotePdf('${n['id']}', '${n['document_no']}'),
                            ),
                          ),
                      ],
                    ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
      ),
    );
  }

  Future<void> _openCreditNotePdf(String id, String no) async {
    try {
      final bytes = await apiClient.creditNotePdf(id);
      final file = File('${(await getTemporaryDirectory()).path}/alacak-dekontu-$no.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path, type: 'application/pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  /// Tahsilat defteri zincirini doğrular: ödemelerin sonradan silinip değiştirilmediğini
  /// kat maliki kendisi görebilir (Apsiyon BUG-03).
  Future<void> _verifyLedger() async {
    String text;
    try {
      final v = await apiClient.verifyLedger();
      text = v['valid'] == true
          ? 'Tahsilat defteri geçerli: ${v['entries']} kayıt, hiçbiri sonradan değiştirilmemiş ya da silinmemiş.'
          : 'UYARI: tahsilat defterinde bozulma var (sıra ${v['first_invalid_seq']}): ${v['reason']}. Denetçiye bildirin.';
    } catch (e) {
      text = toUserMessage(e);
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tahsilat kayıtları'),
        content: Text(text),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  Future<void> _confirmAndPay() async {
    final payable = _payableAssessments;
    final transfer = _paymentMethods[_selectedPaymentMethod].code == 'BANK_TRANSFER';
    // Havale/EFT'de ödemenin yapıldığı gün (valör): gecikme tazminatı bu günde durur
    // (KMK m.20/2); yönetimin onay gecikmesi sakine faiz olarak yansımaz.
    var valueDate = DateTime.now();
    final reference = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Ödeme Onayı'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${payable.length} tahakkuk için toplam ${formatTry(_currentBalance)} '
            'ödeme talebi oluşturulacak.',
          ),
          if (transfer) ...[
            const SizedBox(height: 12),
            ListTile(
              key: const Key('value-date'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Havaleyi yaptığınız gün'),
              subtitle: Text(formatDate(valueDate)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: valueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setLocal(() => valueDate = picked);
              },
            ),
            TextField(
              controller: reference,
              maxLength: 140,
              decoration: const InputDecoration(labelText: 'Havale açıklaması / dekont no (isteğe bağlı)'),
            ),
            const Text('Gecikme tazminatı ödeme gününe göre hesaplanır ve onay beklerken işlemez.',
                style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
          ],
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Devam')),
        ],
      )),
    );
    final ref = reference.text.trim();
    reference.dispose();
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final result = await apiClient.createPayment(
        assessmentIds: payable.map((a) => a['id'] as String).toList(),
        paymentMethod: _paymentMethods[_selectedPaymentMethod].code,
        valueDate: transfer ? apiDate(valueDate) : null,
        reference: transfer ? ref : null,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      final checkout = (result['checkout_url'] ?? '').toString();
      if (checkout.isNotEmpty) {
        await _runCardCheckout('${result['payment_id']}', checkout, result);
        return;
      }
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

  /// Kartla ödeme (Apsiyon BUG-09): iyzico ödeme sayfası tarayıcıda açılır (kart bilgisi ve
  /// 3D Secure orada girilir; uygulamaya kart bilgisi gelmez). Uygulama sonucu sunucudan sorar:
  /// "işlemde" iken beyaz ekran yerine durum gösterilir, ret olursa bankanın Türkçe nedeni yazar.
  Future<void> _runCardCheckout(String paymentId, String url, Map<String, dynamic> result) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      _showCardOutcome('FAILED', 'Ödeme sayfası açılamadı; tutar çekilmedi. Lütfen yeniden deneyin.');
      return;
    }
    final status = ValueNotifier<String>('Ödeme sayfasında işlemi tamamlayın. Sonuç burada görünecek…');
    var done = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödeme işlemde'),
        content: ValueListenableBuilder<String>(
          valueListenable: status,
          builder: (_, v, __) => Column(mainAxisSize: MainAxisSize.min, children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text(v),
            if ((result['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${result['note']}', style: const TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              done = true;
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Arka planda bekle'),
          ),
        ],
      ),
    );
    // Sonuç sunucuda kesinleşir (iyzico dönüşü ya da uzlaştırma); burada yalnızca okunur.
    for (var i = 0; i < 120 && !done; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (done || !mounted) return;
      try {
        final s = await apiClient.getPaymentStatus(paymentId);
        final st = '${s['status']}';
        if (st == 'COMPLETED' || st == 'FAILED') {
          done = true;
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          _showCardOutcome(st, st == 'COMPLETED' ? 'Ödemeniz alındı ve borcunuzdan düşüldü.' : '${s['error_message'] ?? 'Ödeme tamamlanamadı.'}');
          return;
        }
        status.value = s['gateway_status'] == 'PROCESSING' ? 'Banka sonucu sorgulanıyor…' : 'Ödeme sayfasında işlemi tamamlayın. Sonuç burada görünecek…';
      } catch (_) {
        status.value = 'Bağlantı bekleniyor; ödemeniz sunucuda güvende, sonuç kendiliğinden güncellenecek.';
      }
    }
  }

  void _showCardOutcome(String status, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'COMPLETED' ? 'Ödeme alındı' : 'Ödeme tamamlanamadı'),
        content: Text(message),
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

  /// Ödeme sonucu diyalogu.
  ///
  /// DİKKAT: `payment_gateway_ready` false olduğu sürece burada "Ödeme Başarılı"
  /// YAZILMAZ. Sunucu yalnızca bir ödeme KAYDI oluşturur; tahsilat yapılmaz.
  /// Dekont dosyası seçip havale bildirimine ekler (PDF ya da görsel; en çok 5 MB).
  Future<void> _attachReceipt(String paymentId) async {
    String message;
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return;
      if (file.size > 5 * 1024 * 1024) {
        message = 'Dosya 5 MB sınırını aşıyor.';
      } else {
        final res = await apiClient.uploadPaymentReceipt(paymentId, file.bytes!, file.name);
        message = '${res['message'] ?? 'Dekont eklendi.'}';
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      message = data is Map && data['error'] is String ? data['error'] as String : toUserMessage(e);
    } catch (e) {
      message = toUserMessage(e);
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
            if ((result['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${result['note']}'),
            ],
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
          // Havale bildirimine dekont dosyası (064, B9): yönetim onay sırasında görür.
          if (!ready && (result['value_date'] ?? '').toString().isNotEmpty && result['payment_id'] != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _attachReceipt('${result['payment_id']}');
                _load();
              },
              child: const Text('Dekont ekle'),
            ),
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
