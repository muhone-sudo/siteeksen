// Talep/Şikayet Oluşturma Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// "Gönder" düğmesi HİÇBİR AĞ ÇAĞRISI YAPMADAN "Talep Oluşturuldu!" diyor ve
// üstüne koda gömülü sahte bir takip numarası ("TLP-2026-042") gösteriyordu.
// Kullanıcı arızasını bildirdiğini sanıyor, yönetime hiçbir kayıt ulaşmıyordu.
// Ayrıca "Ekler" bölümündeki üç düğmenin `onTap`'i boştu.
//
// Bu sürüm:
//   - Talebi gerçekten gönderir: `POST /requests` (apiClient.createRequest).
//     Talepler modülü sunucuda gerçekten kalıcıdır (community servisi).
//   - Başarı ekranında sunucunun döndürdüğü GERÇEK takip numarasını gösterir;
//     sunucu numara döndürmezse numara uydurmaz.
//   - Sunucu hata verirse ("501" dahil) durumu açıkça söyler, "oluşturuldu" demez.
//   - Kategori listesi için sunucuda katalog ucu YOK: seçim sunucuya
//     `category_id` olarak gönderilemiyor, bu yüzden sessizce kaybolmasın diye
//     açıklamanın sonuna eklenir ve durum kullanıcıya bildirilir.
//   - Çalışmayan ek (fotoğraf/dosya) düğmeleri kaldırıldı; yerine durumu
//     açıklayan `NotImplementedNotice` kondu.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

/// Talep/Şikayet Oluşturma Ekranı - Apple Tarzı
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  int _selectedCategory = 0;
  int _selectedPriority = 1;
  bool _submitting = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  /// Kategori etiketleri yalnızca ARAYÜZ etiketidir; sunucuda karşılık gelen bir
  /// kategori kataloğu (`/requests/categories`) bulunmadığı için `category_id`
  /// gönderilemez. Seçim kaybolmasın diye açıklama metnine eklenir.
  static const _categories = [
    (name: 'Teknik Arıza', icon: Icons.build_rounded, color: AppleTheme.systemOrange),
    (name: 'Temizlik', icon: Icons.cleaning_services_rounded, color: AppleTheme.systemGreen),
    (name: 'Güvenlik', icon: Icons.security_rounded, color: AppleTheme.systemRed),
    (name: 'Gürültü', icon: Icons.volume_up_rounded, color: AppleTheme.systemPurple),
    (name: 'Ortak Alan', icon: Icons.park_rounded, color: AppleTheme.systemTeal),
    (name: 'Diğer', icon: Icons.more_horiz_rounded, color: AppleTheme.systemGray),
  ];

  /// `code` değerleri sunucunun beklediği değerlerdir
  /// (001_initial_schema.sql:372 → LOW, NORMAL, HIGH, URGENT).
  static const _priorities = [
    (name: 'Düşük', code: 'LOW', color: AppleTheme.systemGreen),
    (name: 'Normal', code: 'NORMAL', color: AppleTheme.systemOrange),
    (name: 'Yüksek', code: 'HIGH', color: AppleTheme.systemRed),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      !_submitting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Yeni Talep'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _canSubmit ? _submitRequest : null,
              child: Text('Gönder',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _canSubmit
                          ? AppleTheme.systemBlue
                          : AppleTheme.systemGray3)),
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
            child: SizedBox(
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
                        color: isSelected
                            ? category.color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? category.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category.icon, color: category.color, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500),
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

          const SliverToBoxAdapter(
            child: NotImplementedNotice(
              title: 'Kategori kataloğu sunucuda yok',
              detail: 'Sunucu henüz kategori listesi döndürmediği için seçiminiz '
                  'kategori alanına yazılamıyor; talebin açıklamasının sonuna '
                  '"Kategori: …" satırı olarak eklenir.',
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
                decoration: AppleTheme.inputDecoration('Kısa bir başlık yazın',
                    prefixIcon: Icons.title_rounded),
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

          // Location Input — sunucu `location` alanını destekliyor.
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Konum (Opsiyonel)'),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _locationController,
                decoration: AppleTheme.inputDecoration(
                    'Örn: A Blok, 3. kat asansör',
                    prefixIcon: Icons.location_on_rounded),
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
                children: [
                  for (var i = 0; i < _priorities.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = i),
                        child: AnimatedContainer(
                          duration: AppleTheme.fastAnimation,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPriority == i
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedPriority == i
                                ? [
                                    BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4)
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _priorities[i].color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _priorities[i].name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedPriority == i
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: _selectedPriority == i
                                      ? AppleTheme.label
                                      : AppleTheme.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Attachments
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Ekler (Opsiyonel)'),
          ),

          // Fotoğraf/dosya düğmeleri kaldırıldı: hiçbir yükleme ucu yok,
          // düğmelere dokunmak hiçbir şey yapmıyordu.
          const SliverToBoxAdapter(
            child: NotImplementedNotice(
              title: 'Fotoğraf ve dosya eki henüz hazır değil',
              detail: 'Sunucuda dosya yükleme ucu bulunmadığı için talebe ek '
                  'gönderilemiyor. Arızayı açıklama alanında olabildiğince '
                  'ayrıntılı anlatın.',
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Talebi sunucuya gönderir. Yalnızca sunucu 2xx dönerse başarı gösterilir.
  Future<void> _submitRequest() async {
    setState(() => _submitting = true);

    // Kategori seçimi sunucuya `category_id` olarak gönderilemediği için
    // açıklamaya eklenir — kullanıcının seçimi sessizce kaybolmamalıdır.
    final description =
        '${_descriptionController.text.trim()}\n\nKategori: ${_categories[_selectedCategory].name}';

    try {
      final result = await apiClient.createRequest(
        categoryId: '',
        title: _titleController.text.trim(),
        description: description,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        priority: _priorities[_selectedPriority].code,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccess(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showFailure(e);
    }
  }

  void _showSuccess(Map<String, dynamic> result) {
    // Takip numarası SUNUCUDAN gelir; gelmezse uydurulmaz.
    final ticket = (result['ticket_number'] as String?)?.trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.systemGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppleTheme.systemGreen),
            ),
            const SizedBox(height: 24),
            const Text('Talep Oluşturuldu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              ticket == null || ticket.isEmpty
                  ? 'Talebiniz yönetime iletildi.'
                  : 'Talebiniz yönetime iletildi. Takip numaranız: $ticket',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppleTheme.secondaryLabel),
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
            ? 'Talep modülü henüz hazır değil'
            : 'Talep gönderilemedi'),
        content: Text(
          notImplemented
              ? 'Sunucu bu isteği henüz kabul etmiyor. Talebiniz OLUŞTURULMADI.'
              : '${toUserMessage(error)}\n\nTalebiniz OLUŞTURULMADI, lütfen '
                  'yeniden deneyin.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }
}
