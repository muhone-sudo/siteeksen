import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';

/// Ziyaretçi Ön Kayıt Ekranı - Apple Tarzı
class VisitorPreRegisterScreen extends StatefulWidget {
  const VisitorPreRegisterScreen({super.key});

  @override
  State<VisitorPreRegisterScreen> createState() => _VisitorPreRegisterScreenState();
}

class _VisitorPreRegisterScreenState extends State<VisitorPreRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedVisitorType = 0;

  final List<Map<String, dynamic>> _visitorTypes = [
    {'name': 'Misafir', 'icon': Icons.person_rounded, 'color': AppleTheme.systemBlue},
    {'name': 'Kurye', 'icon': Icons.local_shipping_rounded, 'color': AppleTheme.systemGreen},
    {'name': 'Temizlik', 'icon': Icons.cleaning_services_rounded, 'color': AppleTheme.systemPurple},
    {'name': 'Tamirat', 'icon': Icons.build_rounded, 'color': AppleTheme.systemOrange},
  ];

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
                  const Text('Ziyaretçi Türü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: _visitorTypes.asMap().entries.map((entry) {
                      final isSelected = _selectedVisitorType == entry.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedVisitorType = entry.key),
                          child: AnimatedContainer(
                            duration: AppleTheme.fastAnimation,
                            margin: EdgeInsets.only(right: entry.key < 3 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (entry.value['color'] as Color).withOpacity(0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? entry.value['color'] as Color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(entry.value['icon'] as IconData, color: entry.value['color'] as Color),
                                const SizedBox(height: 6),
                                Text(
                                  entry.value['name'] as String,
                                  style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                  const Text('Ziyaretçi Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: AppleTheme.inputDecoration('Ad Soyad', prefixIcon: Icons.person_rounded),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: AppleTheme.inputDecoration('Telefon', prefixIcon: Icons.phone_rounded),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _plateController,
                    decoration: AppleTheme.inputDecoration('Araç Plakası (Opsiyonel)', prefixIcon: Icons.directions_car_rounded),
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
                  const Text('Ziyaret Zamanı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                                Icon(Icons.calendar_today_rounded, color: AppleTheme.systemBlue),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tarih', style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
                                    Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                  ],
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
                                Icon(Icons.access_time_rounded, color: AppleTheme.systemBlue),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Saat', style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
                                    Text(_selectedTime.format(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                  ],
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

          // Info Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.systemBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, color: AppleTheme.systemBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ziyaretçinize QR kodlu giriş linki SMS ile gönderilecektir.',
                      style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSubmit ? () => _submitPreRegister(context) : null,
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('Ön Kayıt Oluştur'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ),
    );
  }

  bool get _canSubmit => _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty;

  String _formatDate(DateTime date) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submitPreRegister(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppleTheme.systemGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 64, color: AppleTheme.systemGreen),
            ),
            const SizedBox(height: 24),
            const Text('Ön Kayıt Oluşturuldu!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${_nameController.text} için QR kodlu giriş linki SMS olarak gönderildi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }
}
