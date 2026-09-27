// Ziyaretçi Ön Kayıt Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// "Ön Kayıt Oluştur" düğmesi HİÇBİR AĞ ÇAĞRISI YAPMADAN "Ön Kayıt Oluşturuldu!"
// diyor ve üstüne "QR kodlu giriş linki SMS olarak gönderildi" diye
// GERÇEKLEŞMEMİŞ bir işlemi bildiriyordu. Kullanıcı misafirini kaydettiğini
// sanıyor, güvenlik görevlisine hiçbir bilgi ulaşmıyordu.
// Ayrıca tarih biçimlendirmesi elle yapılıyordu (`core/utils/formatters.dart`
// varken).
//
// Bu sürüm:
//   - Kaydı gerçekten gönderir: `POST /visitors`, dairenizle (`unit_id`)
//     birlikte. Daire gönderilmezse kayıt dairesiz kalıyor ve ziyaretçi
//     girişinde size bildirim gidemiyordu (2026-09-26 düzeltmesi).
//   - Yalnızca sunucu 2xx dönerse "oluşturuldu" der.
//   - SMS/QR gönderimi için entegrasyon yoktur; böyle bir vaat gösterilmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Ziyaretçi Ön Kayıt Ekranı - Apple Tarzı
class VisitorPreRegisterScreen extends StatefulWidget {
  const VisitorPreRegisterScreen({super.key});

  @override
  State<VisitorPreRegisterScreen> createState() =>
      _VisitorPreRegisterScreenState();
}

class _VisitorPreRegisterScreenState extends State<VisitorPreRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedVisitorType = 0;
  bool _submitting = false;

  /// `code` değeri sunucuya `purpose` alanında gönderilir
  /// (005_new_modules.sql:26 → visitors.purpose).
  static const _visitorTypes = [
    (name: 'Misafir', code: 'GUEST', icon: Icons.person_rounded, color: AppleTheme.systemBlue),
    (name: 'Kurye', code: 'COURIER', icon: Icons.local_shipping_rounded, color: AppleTheme.systemGreen),
    (name: 'Temizlik', code: 'CLEANING', icon: Icons.cleaning_services_rounded, color: AppleTheme.systemPurple),
    (name: 'Tamirat', code: 'MAINTENANCE', icon: Icons.build_rounded, color: AppleTheme.systemOrange),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      !_submitting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Ziyaretçi Ön Kayıt'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // Visitor Type Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ziyaretçi Türü',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < _visitorTypes.length; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedVisitorType = i),
                            child: AnimatedContainer(
                              duration: AppleTheme.fastAnimation,
                              margin: EdgeInsets.only(
                                  right: i < _visitorTypes.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _selectedVisitorType == i
                                    ? _visitorTypes[i]
                                        .color
                                        .withValues(alpha: 0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedVisitorType == i
                                      ? _visitorTypes[i].color
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(_visitorTypes[i].icon,
                                      color: _visitorTypes[i].color),
                                  const SizedBox(height: 6),
                                  Text(
                                    _visitorTypes[i].name,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _selectedVisitorType == i
                                            ? FontWeight.w600
                                            : FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Form Fields
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ziyaretçi Bilgileri',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: AppleTheme.inputDecoration('Ad Soyad',
                        prefixIcon: Icons.person_rounded),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: AppleTheme.inputDecoration('Telefon',
                        prefixIcon: Icons.phone_rounded),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _plateController,
                    decoration: AppleTheme.inputDecoration(
                        'Araç Plakası (Opsiyonel)',
                        prefixIcon: Icons.directions_car_rounded),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
          ),

          // Date & Time
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ziyaret Zamanı',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppleTheme.systemGray6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppleTheme.systemBlue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Tarih',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppleTheme.secondaryLabel)),
                                      // Elle biçimlendirme yerine ortak yardımcı.
                                      Text(formatDate(_selectedDate),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppleTheme.systemGray6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    color: AppleTheme.systemBlue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Saat',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppleTheme.secondaryLabel)),
                                      Text(_selectedTime.format(context),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // SMS/QR vaadi kaldırıldı: ne SMS ne QR entegrasyonu var.
          const SliverToBoxAdapter(
            child: NotImplementedNotice(
              title: 'QR kod ve SMS bildirimi henüz hazır değil',
              detail: 'Ziyaretçinize otomatik SMS ya da QR kodlu giriş linki '
                  'gönderilmez. Ön kayıt yalnızca güvenlik kaydı olarak '
                  'oluşturulur.',
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSubmit ? _submitPreRegister : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_submitting ? 'Gönderiliyor…' : 'Ön Kayıt Oluştur'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  /// Ön kaydı sunucuya gönderir. Alan adları `visitors` tablosuyla uyumludur
  /// (backend/migrations/005_new_modules.sql:10-30).
  /// Ziyaretin geleceği daire. Birden çok daireniz varsa sorulur.
  Future<String?> _pickUnit() async {
    final props = await apiClient.getUserProperties();
    final units = props
        .whereType<Map>()
        .where((p) => (p['unit_id'] ?? '').toString().isNotEmpty)
        .toList();
    if (units.isEmpty) return null;
    if (units.length == 1 || !mounted) return '${units.first['unit_id']}';
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Hangi daireye?'),
        children: [
          for (final u in units)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, '${u['unit_id']}'),
              child: Text('${u['property_name'] ?? ''} · ${u['unit_name'] ?? ''}'),
            ),
        ],
      ),
    );
  }

  Future<void> _submitPreRegister() async {
    setState(() => _submitting = true);
    String? unitId;
    try {
      unitId = await _pickUnit();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailure(e);
      return;
    }
    if (unitId == null) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailure(StateError('Kayıtlı bir daireniz bulunamadı; ön kayıt için site yönetimiyle görüşün.'));
      return;
    }

    final expectedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final plate = _plateController.text.trim();

    try {
      final result = await apiClient.createVisitorPreRegistration({
        'unit_id': unitId,
        'visitor_name': _nameController.text.trim(),
        'visitor_phone': _phoneController.text.trim(),
        if (plate.isNotEmpty) 'vehicle_plate': plate,
        'purpose': _visitorTypes[_selectedVisitorType].code,
        'expected_at': expectedAt.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccess(result, expectedAt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailure(e);
    }
  }

  void _showSuccess(Map<String, dynamic> result, DateTime expectedAt) {
    final code = (result['qr_code'] as String?)?.trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppleTheme.systemGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppleTheme.systemGreen),
            ),
            const SizedBox(height: 24),
            const Text('Ön Kayıt Oluşturuldu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${_nameController.text.trim()} için '
              '${formatDateTime(expectedAt)} ziyareti kaydedildi.'
              '${code == null || code.isEmpty ? '' : '\nGiriş kodu: $code'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppleTheme.secondaryLabel),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFailure(Object error) {
    final notImplemented = isNotImplemented(error);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(notImplemented
            ? 'Ziyaretçi modülü henüz hazır değil'
            : 'Ön kayıt oluşturulamadı'),
        content: Text(
          notImplemented
              ? 'Sunucu ziyaretçi kayıtlarını henüz saklamıyor. Ön kayıt '
                  'OLUŞTURULMADI; misafirinizi güvenliğe ayrıca bildirin.'
              : '${error is StateError ? error.message : toUserMessage(error)}\n\nÖn kayıt OLUŞTURULMADI.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }
}
