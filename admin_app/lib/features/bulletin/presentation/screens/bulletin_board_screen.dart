import 'package:flutter/material.dart';
import '../../core/theme/apple_theme.dart';
import '../../core/widgets/apple_widgets.dart';

/// Site İlan Panosu Yönetim Ekranı - Apple Tarzı
class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Tümü', 'icon': 'grid_view'},
    {'id': 'sale', 'name': 'Satılık', 'icon': 'sell'},
    {'id': 'rent', 'name': 'Kiralık', 'icon': 'key'},
    {'id': 'help', 'name': 'Yardımlaşma', 'icon': 'favorite'},
    {'id': 'service', 'name': 'Hizmet', 'icon': 'handyman'},
    {'id': 'lost', 'name': 'Kayıp/Bulundu', 'icon': 'search'},
  ];

  final List<Map<String, dynamic>> _listings = [
    {
      'id': '1',
      'category': 'sale',
      'title': 'Çocuk Bisikleti - 16 Jant',
      'description': 'Az kullanılmış, kırmızı renk çocuk bisikleti. 5-7 yaş arası için uygundur.',
      'price': '1500',
      'images': ['bike1.jpg'],
      'author': 'Mehmet Yılmaz',
      'unit': 'A Blok D.105',
      'date': '2 saat önce',
      'views': 24,
      'isActive': true,
    },
    {
      'id': '2',
      'category': 'help',
      'title': 'Hafta sonu köpek bakımı',
      'description': 'Bu hafta sonu şehir dışına çıkıyoruz. Küçük köpeğimizle ilgilenecek komşu arıyoruz.',
      'price': null,
      'images': [],
      'author': 'Ayşe Demir',
      'unit': 'B Blok D.203',
      'date': '5 saat önce',
      'views': 18,
      'isActive': true,
    },
    {
      'id': '3',
      'category': 'service',
      'title': 'Özel Matematik Dersi',
      'description': 'İlkokul ve ortaokul öğrencileri için özel matematik dersi verilir. Sitemizdeki çocuklara öncelik.',
      'price': '250/saat',
      'images': [],
      'author': 'Deniz Öğretmen',
      'unit': 'C Blok D.401',
      'date': '1 gün önce',
      'views': 45,
      'isActive': true,
    },
    {
      'id': '4',
      'category': 'rent',
      'title': 'Piknik Seti Kiralık',
      'description': '6 kişilik piknik masası ve sandalye seti. Günlük veya haftalık kiralanır.',
      'price': '100/gün',
      'images': ['picnic.jpg'],
      'author': 'Ali Vural',
      'unit': 'A Blok D.302',
      'date': '2 gün önce',
      'views': 12,
      'isActive': true,
    },
    {
      'id': '5',
      'category': 'lost',
      'title': 'Siyah Kedi Kayıp',
      'description': 'Yeşil gözlü siyah kedimiz 3 gündür kayıp. Gören olursa lütfen haber versin.',
      'price': null,
      'images': ['cat.jpg'],
      'author': 'Zeynep Kaya',
      'unit': 'D Blok D.101',
      'date': '3 gün önce',
      'views': 89,
      'isActive': true,
      'urgent': true,
    },
  ];

  final Map<String, dynamic> _stats = {
    'totalListings': 47,
    'activeListings': 38,
    'weeklyViews': 456,
    'completedDeals': 12,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Site İlan Panosu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        Text('Komşular arası alışveriş ve yardımlaşma', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showCreateListingSheet(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppleTheme.systemBlue, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildStatCard('Toplam İlan', '${_stats['totalListings']}', Icons.article_rounded, AppleTheme.systemBlue),
                    _buildStatCard('Aktif İlan', '${_stats['activeListings']}', Icons.check_circle_rounded, AppleTheme.systemGreen),
                    _buildStatCard('Haftalık Görüntüleme', '${_stats['weeklyViews']}', Icons.visibility_rounded, AppleTheme.systemPurple),
                    _buildStatCard('Tamamlanan', '${_stats['completedDeals']}', Icons.handshake_rounded, AppleTheme.systemOrange),
                  ],
                ),
              ),
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat['name']!),
                        onSelected: (selected) => setState(() => _selectedCategory = cat['id']!),
                        backgroundColor: Colors.white,
                        selectedColor: AppleTheme.systemBlue.withOpacity(0.15),
                        checkmarkColor: AppleTheme.systemBlue,
                        labelStyle: TextStyle(
                          color: isSelected ? AppleTheme.systemBlue : AppleTheme.label,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: BorderSide(color: isSelected ? AppleTheme.systemBlue : AppleTheme.systemGray5),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGray6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppleTheme.label,
                  unselectedLabelColor: AppleTheme.secondaryLabel,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Aktif İlanlar'),
                    Tab(text: 'Onay Bekleyen'),
                  ],
                ),
              ),
            ),

            // Listings Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = _getFilteredListings()[index];
                    return _buildListingCard(listing);
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final catInfo = _getCategoryInfo(listing['category']);
    
    return GestureDetector(
      onTap: () => _showListingDetail(context, listing),
      child: Container(
        decoration: AppleTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: catInfo['color'].withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(catInfo['icon'], size: 40, color: catInfo['color'].withOpacity(0.5))),
                  if (listing['urgent'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppleTheme.systemRed, borderRadius: BorderRadius.circular(4)),
                        child: const Text('ACİL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: catInfo['color'].withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                      child: Text(catInfo['name'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (listing['price'] != null)
                      Text(
                        '₺${listing['price']}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppleTheme.systemGreen),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 12, color: AppleTheme.tertiaryLabel),
                        const SizedBox(width: 4),
                        Text('${listing['views']}', style: TextStyle(fontSize: 11, color: AppleTheme.tertiaryLabel)),
                        const Spacer(),
                        Text(listing['date'], style: TextStyle(fontSize: 11, color: AppleTheme.tertiaryLabel)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        return {'name': 'Kayıp/Bulundu', 'icon': Icons.search_rounded, 'color': AppleTheme.systemRed};
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  const Text('Yeni İlan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () {}, child: const Text('Yayınla')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Category Selection
                  const Text('Kategori', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.skip(1).map((cat) {
                      final info = _getCategoryInfo(cat['id']!);
                      return ChoiceChip(
                        label: Text(cat['name']!),
                        selected: false,
                        avatar: Icon(info['icon'], size: 18),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      hintText: 'İlan başlığı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      hintText: 'Detaylı açıklama yazın...',
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
                  const SizedBox(height: 24),

                  // Image Upload
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppleTheme.systemGray4, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppleTheme.systemGray2),
                        const SizedBox(height: 8),
                        Text('Fotoğraf Ekle', style: TextStyle(color: AppleTheme.systemGray2)),
                      ],
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
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Category Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: catInfo['color'].withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catInfo['icon'], size: 16, color: catInfo['color']),
                          const SizedBox(width: 6),
                          Text(catInfo['name'], style: TextStyle(color: catInfo['color'], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(listing['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  // Price
                  if (listing['price'] != null)
                    Text('₺${listing['price']}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppleTheme.systemGreen)),
                  
                  const SizedBox(height: 16),

                  // Author Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppleTheme.systemGray6, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppleTheme.systemBlue.withOpacity(0.15),
                          child: Text(
                            listing['author'].toString().substring(0, 1),
                            style: TextStyle(color: AppleTheme.systemBlue, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing['author'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(listing['unit'], style: TextStyle(color: AppleTheme.secondaryLabel)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.chat_bubble_outline_rounded, color: AppleTheme.systemBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Açıklama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(listing['description'], style: TextStyle(color: AppleTheme.secondaryLabel, height: 1.5)),
                  
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 16, color: AppleTheme.tertiaryLabel),
                      const SizedBox(width: 4),
                      Text('${listing['views']} görüntüleme', style: TextStyle(color: AppleTheme.tertiaryLabel)),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 16, color: AppleTheme.tertiaryLabel),
                      const SizedBox(width: 4),
                      Text(listing['date'], style: TextStyle(color: AppleTheme.tertiaryLabel)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Admin Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Düzenle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemRed),
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('Kaldır'),
                        ),
                      ),
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
