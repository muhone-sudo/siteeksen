import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../widgets/activation_code_dialog.dart';

const Map<String, String> _roleLabels = {
  'OWNER': 'Ev Sahibi',
  'TENANT': 'Kiracı',
  'PROXY': 'Vekil',
};

class AddResidentScreen extends StatefulWidget {
  const AddResidentScreen({super.key});

  @override
  State<AddResidentScreen> createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedUnitId;
  String _role = 'OWNER';
  bool _isLoadingUnits = true;
  bool _isSaving = false;
  List<dynamic> _units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await apiClient.getUnits();
      if (!mounted) return;
      setState(() {
        _units = units;
        _isLoadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUnits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birimler yüklenemedi, lütfen tekrar deneyin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sakin Ekle')),
      body: _isLoadingUnits
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnitId,
                    decoration: const InputDecoration(labelText: 'Daire Seçin *'),
                    items: _units
                        .map((u) => u as Map<String, dynamic>)
                        .map((u) => DropdownMenuItem(
                              value: u['id'] as String,
                              child: Text('${u['block'] ?? ''}${(u['block'] ?? '').toString().isNotEmpty ? '-' : ''}${u['door_number'] ?? ''} (Kat ${u['floor']})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnitId = v),
                    validator: (v) => v == null ? 'Daire seçimi zorunlu' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Ad *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Soyad *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefon *', hintText: '+90 5XX XXX XX XX'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty ?? true ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Oturum Tipi'),
                    initialValue: _role,
                    items: _roleLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? 'OWNER'),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveResident,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveResident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // DÜZELTME (2026-09-26): yanıt atılıyordu. Yeni hesapta yanıt tek
      // kullanımlık etkinleştirme kodunu BİR KEZ taşır; kod kaybolunca sakin
      // hiçbir zaman giriş yapamıyordu.
      final res = await apiClient.createResident({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': normalizePhone(_phoneController.text),
        if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
        'unit_id': _selectedUnitId,
        'role': _role,
      });
      if (!mounted) return;
      final activation = res['activation'];
      if (res['invitation'] is Map) {
        // S-20: kişi başka sitede kayıtlı; bağ kurulmadı, davet gönderildi.
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Davet gönderildi'),
            content: Text(invitationMessage(res)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
          ),
        );
      } else if (activation is Map) {
        await showActivationCodeDialog(
          context,
          who: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          activation: Map<String, dynamic>.from(activation),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['note'] is String ? 'Sakin eklendi. ${res['note']}' : 'Sakin eklendi'),
          backgroundColor: Colors.green,
        ));
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sakin eklenemedi: ${errorText(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Davet yanıtının yöneticiye gösterilecek metni. Sunucu notu kişinin bilgilerini
/// içermez; not yoksa genel açıklama kullanılır.
String invitationMessage(Map<String, dynamic> res) {
  final note = res['note'];
  if (note is String && note.trim().isNotEmpty) return note;
  return 'Kişi bu siteyle bağı olmayan bir hesaba sahip. Davet kendi uygulamasına gönderildi; '
      'kabul ettiğinde daireye bağlanır.';
}
