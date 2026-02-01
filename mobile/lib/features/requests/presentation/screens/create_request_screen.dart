import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Talep/Şikayet Oluşturma Ekranı - Apple Tarzı
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  int _selectedCategory = 0;
  int _selectedPriority = 1;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _attachments = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Teknik Arıza', 'icon': Icons.build_rounded, 'color': AppleTheme.systemOrange},
    {'name': 'Temizlik', 'icon': Icons.cleaning_services_rounded, 'color': AppleTheme.systemGreen},
    {'name': 'Güvenlik', 'icon': Icons.security_rounded, 'color': AppleTheme.systemRed},
    {'name': 'Gürültü', 'icon': Icons.volume_up_rounded, 'color': AppleTheme.systemPurple},
    {'name': 'Ortak Alan', 'icon': Icons.park_rounded, 'color': AppleTheme.systemTeal},
    {'name': 'Diğer', 'icon': Icons.more_horiz_rounded, 'color': AppleTheme.systemGray},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'name': 'Düşük', 'color': AppleTheme.systemGreen},
    {'name': 'Normal', 'color': AppleTheme.systemOrange},
    {'name': 'Yüksek', 'color': AppleTheme.systemRed},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Yeni Talep'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _canSubmit ? () => _submitRequest(context) : null,
            child: Text('Gönder', style: TextStyle(fontWeight: FontWeight.w600, color: _canSubmit ? AppleTheme.systemBlue : AppleTheme.systemGray3)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Category Selection
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Kategori'),
          ),

          SliverToBoxAdapter(
            child: Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: AppleTheme.fastAnimation,
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? (category['color'] as Color).withOpacity(0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? category['color'] as Color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'] as IconData, color: category['color'] as Color, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            category['name'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Title Input
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Başlık'),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                decoration: AppleTheme.inputDecoration('Kısa bir başlık yazın', prefixIcon: Icons.title_rounded),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Description Input
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Açıklama'),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _descriptionController,
                decoration: AppleTheme.inputDecoration('Detaylı açıklama yazın'),
                maxLines: 5,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Priority Selection
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Öncelik'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray6,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: _priorities.asMap().entries.map((entry) {
                  final isSelected = _selectedPriority == entry.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = entry.key),
                      child: AnimatedContainer(
                        duration: AppleTheme.fastAnimation,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: entry.value['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.value['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppleTheme.label : AppleTheme.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Attachments
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Ekler (Opsiyonel)'),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildAttachmentButton(Icons.camera_alt_rounded, 'Fotoğraf', () {}),
                  const SizedBox(width: 12),
                  _buildAttachmentButton(Icons.photo_library_rounded, 'Galeri', () {}),
                  const SizedBox(width: 12),
                  _buildAttachmentButton(Icons.attach_file_rounded, 'Dosya', () {}),
                ],
              ),
            ),
          ),

          // Tips
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.systemBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppleTheme.systemBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('İpucu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                          'Net fotoğraflar eklemeniz talebin daha hızlı işlenmesini sağlar.',
                          style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  bool get _canSubmit => _titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty;

  Widget _buildAttachmentButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppleTheme.systemBlue, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _submitRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.systemGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 64, color: AppleTheme.systemGreen),
            ),
            const SizedBox(height: 24),
            const Text('Talep Oluşturuldu!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Talebiniz başarıyla oluşturuldu. Takip numaranız: TLP-2026-042',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
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
