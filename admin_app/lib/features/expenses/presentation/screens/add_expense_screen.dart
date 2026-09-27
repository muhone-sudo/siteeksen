// Gider ekleme ekranı.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Üç ayrı sahtelik vardı:
//   1. Kategori listesi koda gömülüydü (9 sabit kategori, uydurma id'ler 1..9).
//      Bu id'lerle kayıt atılsaydı sunucuda hiçbir kategoriye denk gelmezdi.
//   2. "AI ile Tara" düğmesi 2 saniye bekleyip HER SEFERİNDE aynı sahte sonucu
//      döndürüyordu: "AYEDAŞ Elektrik Dağıtım A.Ş. / 2026-001234 / ₺2.450,75 / %94 güven".
//      Dosya seçici de gerçek dosya yerine uydurma bir "belge.pdf" ekliyordu.
//   3. "Kaydet" sunucuya hiçbir istek göndermeden "Gider eklendi" diyordu (`// TODO: API call`).
//      Yönetici gideri kaydettiğini sanıp hiçbir kayıt oluşmuyordu.
//
// Artık kategoriler `GET /expense-categories` ile gelir, kayıt `POST /expenses` ile
// yapılır ve başarı mesajı yalnızca sunucu 2xx döndüğünde gösterilir. Fatura yükleme
// ve AI tarama için bağlanmış bir uç olmadığından o bölüm `NotImplementedNotice` oldu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/data_state.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _nonInvoicedReasonController = TextEditingController();

  String? _selectedCategory;
  DateTime _expenseDate = DateTime.now();
  bool _isInvoiced = true;
  bool _reflectsToAssessment = true;
  String _distributionType = 'EQUAL';

  bool _loading = true;
  Object? _error;
  bool _saving = false;

  /// Sunucudan gelen gerçek gider kategorileri.
  List<Map<String, dynamic>> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _nonInvoicedReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await apiClient.getList('/expense-categories');
      if (!mounted) return;
      setState(() {
        _categories =
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
        title: const Text('Gider Ekle'),
        actions: [
          TextButton.icon(
            onPressed: (_loading || _error != null || _saving) ? null : _saveExpense,
            icon: _saving
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Gider kategorileri alınıyor...');

    if (_error != null && isNotImplemented(_error!)) {
      return ListView(
        children: const [
          NotImplementedNotice(
            title: 'Gider ekleme henüz hazır değil',
            detail: 'Gider kategorileri sunucudan alınamadığı için yeni gider kaydedilemez.',
          ),
        ],
      );
    }
    if (_error != null) {
      return ErrorStateView(message: toUserMessage(_error!), onRetry: _loadCategories);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fatura yükleme + AI tarama için bağlanmış bir uç yok. Sahte tarama
          // sonucu üretmek yerine durum açıkça bildiriliyor.
          const NotImplementedNotice(
            title: 'Fatura yükleme ve AI tarama henüz hazır değil',
            detail: 'Gider bilgilerini şimdilik elle girin. Dosya yükleme ucu bağlanmadı.',
          ),
          const SizedBox(height: 8),

          const Text('Gider Bilgileri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          if (_categories.isEmpty)
            const EmptyStateView(
              message: 'Sunucuda tanımlı gider kategorisi yok. Önce kategori tanımlanmalı.',
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori *'),
              items: _categories.map((c) {
                final type = _text(c, const ['type']);
                return DropdownMenuItem(
                  value: c['id']?.toString(),
                  child: Row(
                    children: [
                      if (type != null) ...[
                        _categoryBadge(type),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          (c['name'] ?? c['category_name'] ?? '—').toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedCategory = v;
                  final cat = _categories.firstWhere(
                    (c) => c['id']?.toString() == v,
                    orElse: () => const <String, dynamic>{},
                  );
                  // Kategori "aidata yansır mı" bilgisini gerçekten döndürüyorsa uygula;
                  // döndürmüyorsa kullanıcının seçimi bozulmaz (varsayım yapılmaz).
                  final reflects = _flag(cat, const ['reflects_to_assessment']);
                  if (reflects != null) _reflectsToAssessment = reflects;
                  final distribution = _text(cat, const ['distribution_type']);
                  if (distribution != null) {
                    _distributionType = _normalizeDistribution(distribution);
                  }
                });
              },
              validator: (v) => v == null ? 'Kategori seçin' : null,
            ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Açıklama *'),
            maxLines: 2,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Açıklama girin' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Tutar (₺) *', prefixText: '₺ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Tutar girin';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Tarih *', suffixIcon: Icon(Icons.calendar_today)),
                    // Tarih `formatDate` ile yazılır; elle "g.a.y" birleştirme yapılmaz.
                    child: Text(formatDate(_expenseDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Faturalı Gider'),
                  subtitle: Text(_isInvoiced
                      ? 'Bu gider için fatura mevcut'
                      : 'Faturasız gider (açıklama gerekli)'),
                  value: _isInvoiced,
                  onChanged: (v) => setState(() => _isInvoiced = v),
                ),
                if (!_isInvoiced) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                            SizedBox(width: 8),
                            Text('Faturasız Gider Uyarısı',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warningColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Faturasız giderler site sakinlerine "Faturasız" olarak gösterilecek ve onay gerektirebilir.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nonInvoicedReasonController,
                          decoration:
                              const InputDecoration(labelText: 'Faturasız olma nedeni *'),
                          maxLines: 2,
                          validator: (v) => !_isInvoiced && (v?.trim().isEmpty ?? true)
                              ? 'Neden belirtin'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aidata Yansısın'),
                  subtitle: Text(_reflectsToAssessment
                      ? 'Bu gider aylık aidata eklenecek'
                      : 'Sabit gider - aidata eklenmez'),
                  value: _reflectsToAssessment,
                  onChanged: (v) => setState(() => _reflectsToAssessment = v),
                ),
                if (_reflectsToAssessment) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dağıtım Şekli'),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'EQUAL', label: Text('Eşit')),
                            ButtonSegment(value: 'AREA_M2', label: Text('m² Bazlı')),
                            ButtonSegment(value: 'SHARE_RATIO', label: Text('Arsa Payı')),
                          ],
                          selected: {_distributionType},
                          onSelectionChanged: (v) =>
                              setState(() => _distributionType = v.first),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isInvoiced) ...[
            const Text('Firma Bilgileri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: 'Firma Adı'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(labelText: 'Fatura No'),
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _categoryBadge(String type) {
    Color color;
    String label;
    switch (type.toUpperCase()) {
      case 'FIXED':
        color = Colors.grey;
        label = 'Sabit';
        break;
      case 'VARIABLE':
        color = AppTheme.primaryColor;
        label = 'Değişken';
        break;
      case 'UNPLANNED':
        color = AppTheme.warningColor;
        label = 'Plansız';
        break;
      default:
        color = Colors.grey;
        label = type;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _expenseDate = date);
  }

  Future<void> _saveExpense() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      _showMessage('Kategori seçin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await apiClient.post('/expenses', {
        'category_id': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text.replaceAll(',', '.')),
        // DÜZELTME (2026-09-27): sunucu YYYY-AA-GG bekler; ISO damga 400 alıyordu.
        'expense_date': apiDate(_expenseDate),
        'is_invoiced': _isInvoiced,
        'reflects_to_assessment': _reflectsToAssessment,
        if (_reflectsToAssessment) 'distribution_type': _distributionType,
        if (_reflectsToAssessment) 'assessment_period': apiDate(_expenseDate).substring(0, 7),
        if (_isInvoiced) 'vendor_name': _vendorController.text.trim(),
        if (_isInvoiced) 'invoice_number': _invoiceNumberController.text.trim(),
        // DÜZELTME: alan adı `invoice_reason`; `non_invoiced_reason` yok sayılıyor,
        // faturasız her gider 422 alıyordu.
        if (!_isInvoiced) 'invoice_reason': _nonInvoicedReasonController.text.trim(),
      });
      if (!mounted) return;
      // Başarı mesajı YALNIZCA sunucu kaydı onayladığında gösterilir.
      final e = res['expense'] is Map ? res['expense'] as Map : const {};
      final n = e['distributions'] is List ? (e['distributions'] as List).length : 0;
      final note = res['note'] is String ? '\n${res['note']}' : '';
      _showMessage((n > 0 ? 'Gider kaydedildi; $n bağımsız bölüme paylaştırıldı' : 'Gider kaydedildi') + note);
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

/// Sunucu dağıtım tipini farklı adlandırabiliyor; SegmentedButton'ın bildiği
/// değerlere indirgenir, tanınmayan değer varsayılanı bozmaz.
String _normalizeDistribution(String value) {
  switch (value.toUpperCase()) {
    case 'AREA':
    case 'AREA_M2':
      return 'AREA_M2';
    case 'SHARE_RATIO':
      return 'SHARE_RATIO';
    default:
      return 'EQUAL';
  }
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
