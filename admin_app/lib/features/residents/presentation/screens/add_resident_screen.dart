import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

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
                    value: _selectedUnitId,
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
                    value: _role,
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
      await apiClient.createResident({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
        'unit_id': _selectedUnitId,
        'role': _role,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sakin eklendi'), backgroundColor: Colors.green),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sakin eklenemedi, lütfen tekrar deneyin')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
