import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Site İlan Panosu Mobil Ekranı - Apple Tarzı
class BulletinBoardMobileScreen extends StatefulWidget {
  const BulletinBoardMobileScreen({super.key});

  @override
  State<BulletinBoardMobileScreen> createState() => _BulletinBoardMobileScreenState();
}

class _BulletinBoardMobileScreenState extends State<BulletinBoardMobileScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Tümü'},
    {'id': 'sale', 'name': 'Satılık'},
    {'id': 'rent', 'name': 'Kiralık'},
    {'id': 'help', 'name': 'Yardımlaşma'},
    {'id': 'service', 'name': 'Hizmet'},
    {'id': 'lost', 'name': 'Kayıp'},
  ];

  final List<Map<String, dynamic>> _listings = [
    {
      'id': '1',
      'category': 'sale',
      'title': 'Çocuk Bisikleti - 16 Jant',
      'description': 'Az kullanılmış, kırmızı renk çocuk bisikleti. 5-7 yaş arası için uygundur.',
      'price': '1500',
      'author': 'Mehmet Y.',
      'unit': 'A-105',
      'date': '2s önce',
      'views': 24,
    },
    {
      'id': '2',
      'category': 'help',
      'title': 'Hafta sonu köpek bakımı',
      'description': 'Bu hafta sonu şehir dışına çıkıyoruz. Küçük köpeğimizle ilgilenecek komşu arıyoruz.',
      'price': null,
      'author': 'Ayşe D.',
      'unit': 'B-203',
      'date': '5s önce',
      'views': 18,
    },
    {
      'id': '3',
      'category': 'service',
      'title': 'Özel Matematik Dersi',
      'description': 'İlkokul ve ortaokul öğrencileri için özel matematik dersi verilir.',
      'price': '250/saat',
      'author': 'Deniz Ö.',
      'unit': 'C-401',
      'date': '1g önce',
      'views': 45,
    },
    {
      'id': '4',
      'category': 'lost',
      'title': 'Siyah Kedi Kayıp',
      'description': 'Yeşil gözlü siyah kedimiz 3 gündür kayıp. Gören olursa lütfen haber versin.',
      'price': null,
      'author': 'Zeynep K.',
      'unit': 'D-101',
      'date': '3g önce',
      'views': 89,
      'urgent': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'İlan Panosu',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreateListingSheet(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['id']!),
                        child: AnimatedContainer(
                          duration: AppleTheme.fastAnimation,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppleTheme.systemBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppleTheme.systemBlue : AppleTheme.systemGray5,
                            ),
                          ),
                          child: Text(
                            cat['name']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppleTheme.label,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Listings
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = _getFilteredListings()[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildListingCard(listing),
                    );
                  },
                  childCount: _getFilteredListings().length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredListings() {
    if (_selectedCategory == 'all') return _listings;
    return _listings.where((l) => l['category'] == _selectedCategory).toList();
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final catInfo = _getCategoryInfo(listing['category']);
    
    return GestureDetector(
      onTap: () => _showListingDetail(context, listing),
      child: Container(
        decoration: AppleTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: catInfo['color'].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(catInfo['icon'], color: catInfo['color'], size: 28)),
                    if (listing['urgent'] == true)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppleTheme.systemRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: catInfo['color'].withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            catInfo['name'],
                            style: TextStyle(fontSize: 10, color: catInfo['color'], fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Text(listing['date'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing['title'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing['description'],
                      style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (listing['price'] != null) ...[
                          Text(
                            '₺${listing['price']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppleTheme.systemGreen,
                            ),
                          ),
                          const Spacer(),
                        ],
                        Text(
                          '${listing['author']} • ${listing['unit']}',
                          style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'sale':
        return {'name': 'Satılık', 'icon': Icons.sell_rounded, 'color': AppleTheme.systemBlue};
      case 'rent':
        return {'name': 'Kiralık', 'icon': Icons.key_rounded, 'color': AppleTheme.systemPurple};
      case 'help':
        return {'name': 'Yardımlaşma', 'icon': Icons.favorite_rounded, 'color': AppleTheme.systemPink};
      case 'service':
        return {'name': 'Hizmet', 'icon': Icons.handyman_rounded, 'color': AppleTheme.systemOrange};
      case 'lost':
        return {'name': 'Kayıp', 'icon': Icons.search_rounded, 'color': AppleTheme.systemRed};
      default:
        return {'name': 'Diğer', 'icon': Icons.article_rounded, 'color': AppleTheme.systemGray};
    }
  }

  void _showCreateListingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  const Text('İlan Oluştur', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () {}, child: const Text('Paylaş')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Category
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categories.skip(1).map((cat) {
                      final info = _getCategoryInfo(cat['id']!);
                      return ChoiceChip(label: Text(cat['name']!), selected: false, avatar: Icon(info['icon'], size: 16));
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      hintText: 'Ne paylaşmak istiyorsunuz?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      hintText: 'Detayları yazın...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Fiyat (Opsiyonel)',
                      prefixText: '₺ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Photo
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppleTheme.systemGray4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 32, color: AppleTheme.systemGray2),
                          const SizedBox(height: 8),
                          Text('Fotoğraf Ekle', style: TextStyle(color: AppleTheme.systemGray2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListingDetail(BuildContext context, Map<String, dynamic> listing) {
    final catInfo = _getCategoryInfo(listing['category']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: catInfo['color'].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catInfo['icon'], size: 16, color: catInfo['color']),
                        const SizedBox(width: 6),
                        Text(catInfo['name'], style: TextStyle(color: catInfo['color'], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Price
                  Text(listing['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  if (listing['price'] != null) ...[
                    const SizedBox(height: 8),
                    Text('₺${listing['price']}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppleTheme.systemGreen)),
                  ],
                  const SizedBox(height: 20),

                  // Author Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppleTheme.systemGray6, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppleTheme.systemBlue.withOpacity(0.15),
                          child: Text(listing['author'].toString()[0], style: TextStyle(color: AppleTheme.systemBlue, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing['author'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(listing['unit'], style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppleTheme.systemBlue, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.message_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Açıklama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(listing['description'], style: TextStyle(color: AppleTheme.secondaryLabel, height: 1.6)),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 16, color: AppleTheme.tertiaryLabel),
                      const SizedBox(width: 4),
                      Text('${listing['views']} görüntüleme', style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
                      const Spacer(),
                      Text(listing['date'], style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
