import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddResidentScreen extends StatefulWidget {
  const AddResidentScreen({super.key});

  @override
  State<AddResidentScreen> createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sakin Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Unit selection
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(labelText: 'Daire Seçin *'),
              items: ['A Blok D.1', 'A Blok D.2', 'B Blok D.1', 'B Blok D.2']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedUnit = v),
              validator: (v) => v == null ? 'Daire seçimi zorunlu' : null,
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ad Soyad *'),
              validator: (v) => v?.isEmpty ?? true ? 'Zorunlu alan' : null,
            ),
            const SizedBox(height: 16),
            
            // Phone
            TextFormField(
              decoration: const InputDecoration(labelText: 'Telefon *', hintText: '+90 5XX XXX XX XX'),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Zorunlu alan' : null,
            ),
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // TC No
            TextFormField(
              decoration: const InputDecoration(labelText: 'TC Kimlik No'),
              keyboardType: TextInputType.number,
              maxLength: 11,
            ),
            const SizedBox(height: 16),
            
            // Type
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Oturum Tipi'),
              value: 'OWNER',
              items: const [
                DropdownMenuItem(value: 'OWNER', child: Text('Ev Sahibi')),
                DropdownMenuItem(value: 'TENANT', child: Text('Kiracı')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            
            // Move in date
            TextFormField(
              decoration: const InputDecoration(labelText: 'Taşınma Tarihi', suffixIcon: Icon(Icons.calendar_today)),
              readOnly: true,
              onTap: () async {
                await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Notes
            TextFormField(
              decoration: const InputDecoration(labelText: 'Notlar'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _saveResident,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveResident() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save via API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sakin eklendi'), backgroundColor: Colors.green),
      );
      context.pop();
    }
  }
}
