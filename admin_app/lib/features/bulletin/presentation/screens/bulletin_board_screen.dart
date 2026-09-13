// Site ilan panosu yönetimi.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran beş uydurma ilan (Mehmet Yılmaz'ın bisikleti, Ayşe Demir'in köpeği,
// Zeynep Kaya'nın kayıp kedisi…) ve dört uydurma sayaç (47 ilan / 38 aktif /
// 456 görüntüleme / 12 tamamlanan) gösteriyordu. İlanların altında gerçek kişi
// adı ve daire numarası yazılıydı; bu hem yalan hem de kişisel veri taklidiydi.
// "Yayınla", "Düzenle", "Kaldır" ve mesaj düğmeleri hiçbir istek göndermiyordu.
//
// Artık ilanlar `apiClient.getBulletins()` ile alınıyor, yeni ilan
// `apiClient.createBulletin()` ile gönderiliyor, kaldırma
// `apiClient.deleteBulletin()` çağırıyor. Sayaçlar gelen gerçek kayıtlardan
// hesaplanıyor. Sunucu 501 dönerse `NotImplementedNotice`, başka hata olursa
// `ErrorStateView` gösterilir — sessizce boş liste gösterilmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Site İlan Panosu Yönetim Ekranı
class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Tümü'},
    {'id': 'sale', 'name': 'Satılık'},
    {'id': 'rent', 'name': 'Kiralık'},
    {'id': 'help', 'name': 'Yardımlaşma'},
    {'id': 'service', 'name': 'Hizmet'},
    {'id': 'lost', 'name': 'Kayıp/Bulundu'},
  ];

  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _listings = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await apiClient.getBulletins();
      if (!mounted) return;
      setState(() {
        _listings =
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

  bool get _hasData => !_loading && _error == null;

  /// Onaylanmış/yayında olan ilan mı? Durum alanı hiç gelmiyorsa yayında sayılır —
  /// aksi halde tüm ilanlar sessizce "onay bekliyor" sekmesinde kaybolurdu.
  bool _isPending(Map<String, dynamic> l) {
    final status = (_text(l, const ['status', 'state']) ?? '').toUpperCase();
    return status == 'PENDING' || status == 'AWAITING_APPROVAL' || status == 'BEKLIYOR';
  }

  List<Map<String, dynamic>> get _filteredListings {
    return _listings.where((l) {
      if (_tabController.index == 0 && _isPending(l)) return false;
      if (_tabController.index == 1 && !_isPending(l)) return false;
      if (_selectedCategory == 'all') return true;
      return _categoryId(l) == _selectedCategory;
    }).toList();
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Site İlan Panosu',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                          Text('Komşular arası alışveriş ve yardımlaşma',
                              style: TextStyle(
                                  fontSize: 15, color: AppleTheme.secondaryLabel)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showCreateListingSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppleTheme.systemBlue,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats — sabit sayılar yerine yüklenen kayıtlardan hesaplanır.
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _buildStatCards(),
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
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat['id']!),
                        backgroundColor: Colors.white,
                        selectedColor:
                            AppleTheme.systemBlue.withValues(alpha: 0.15),
                        checkmarkColor: AppleTheme.systemBlue,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? AppleTheme.systemBlue : AppleTheme.label,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: BorderSide(
                            color: isSelected
                                ? AppleTheme.systemBlue
                                : AppleTheme.systemGray5),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4)
                    ],
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

            _buildListingsSliver(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatCards() {
    if (!_hasData) {
      return [
        _buildStatCard('Toplam İlan', '—', Icons.article_rounded, AppleTheme.systemBlue),
        _buildStatCard('Aktif İlan', '—', Icons.check_circle_rounded, AppleTheme.systemGreen),
        _buildStatCard('Görüntüleme', '—', Icons.visibility_rounded, AppleTheme.systemPurple),
        _buildStatCard('Onay Bekleyen', '—', Icons.pending_rounded, AppleTheme.systemOrange),
      ];
    }

    final pending = _listings.where(_isPending).length;
    final active = _listings.length - pending;
    // Görüntüleme sayacı sunucudan gelmiyorsa uydurulmaz; "—" gösterilir.
    final hasViews = _listings.any((l) => _number(l, const ['views', 'view_count']) != null);
    final views = _listings.fold<double>(
        0, (sum, l) => sum + (_number(l, const ['views', 'view_count']) ?? 0));

    return [
      _buildStatCard('Toplam İlan', '${_listings.length}', Icons.article_rounded,
          AppleTheme.systemBlue),
      _buildStatCard('Aktif İlan', '$active', Icons.check_circle_rounded,
          AppleTheme.systemGreen),
      _buildStatCard('Görüntüleme', hasViews ? formatNumber(views) : '—',
          Icons.visibility_rounded, AppleTheme.systemPurple),
      _buildStatCard('Onay Bekleyen', '$pending', Icons.pending_rounded,
          AppleTheme.systemOrange),
    ];
  }

  Widget _buildListingsSliver() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: SizedBox(height: 220, child: LoadingView(message: 'İlanlar alınıyor...')),
      );
    }

    if (_error != null && isNotImplemented(_error!)) {
      return const SliverToBoxAdapter(
        child: NotImplementedNotice(
          title: 'İlan panosu henüz hazır değil',
          detail:
              'İlan servisi veri katmanına bağlanmadığı için kayıt döndürmüyor. '
              'Hazır olduğunda sakinlerin ilanları burada listelenecek.',
        ),
      );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 260,
          child: ErrorStateView(message: toUserMessage(_error!), onRetry: _load),
        ),
      );
    }

    final items = _filteredListings;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: EmptyStateView(
            message: _listings.isEmpty
                ? 'Henüz ilan yok.'
                : (_tabController.index == 1
                    ? 'Onay bekleyen ilan yok.'
                    : 'Seçili kategoride ilan yok.'),
            icon: Icons.article_rounded,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildListingCard(items[index]),
          childCount: items.length,
        ),
      ),
    );
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              Text(title,
                  style:
                      TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final catInfo = _getCategoryInfo(_categoryId(listing));
    final price = _number(listing, const ['price', 'amount']);
    final views = _number(listing, const ['views', 'view_count']);
    final createdAt = listing['created_at'] ?? listing['published_at'] ?? listing['date'];

    return GestureDetector(
      onTap: () => _showListingDetail(listing),
      child: Container(
        decoration: AppleTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: (catInfo['color'] as Color).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                      child: Icon(catInfo['icon'] as IconData,
                          size: 40,
                          color: (catInfo['color'] as Color)
                              .withValues(alpha: 0.5))),
                  if (_flag(listing, const ['urgent', 'is_urgent']) == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppleTheme.systemRed,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('ACİL',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: (catInfo['color'] as Color)
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(catInfo['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(listing, const ['title', 'subject']) ?? 'Başlıksız ilan',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (price != null)
                      Text(
                        formatTry(price),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppleTheme.systemGreen),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if (views != null) ...[
                          Icon(Icons.visibility_rounded,
                              size: 12, color: AppleTheme.tertiaryLabel),
                          const SizedBox(width: 4),
                          Text(formatNumber(views),
                              style: TextStyle(
                                  fontSize: 11, color: AppleTheme.tertiaryLabel)),
                        ],
                        const Spacer(),
                        Flexible(
                          child: Text(formatDate(createdAt),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: AppleTheme.tertiaryLabel)),
                        ),
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

  String _categoryId(Map<String, dynamic> listing) =>
      (_text(listing, const ['category', 'category_id', 'type']) ?? 'other')
          .toLowerCase();

  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'sale':
        return {
          'name': 'Satılık',
          'icon': Icons.sell_rounded,
          'color': AppleTheme.systemBlue
        };
      case 'rent':
        return {
          'name': 'Kiralık',
          'icon': Icons.key_rounded,
          'color': AppleTheme.systemPurple
        };
      case 'help':
        return {
          'name': 'Yardımlaşma',
          'icon': Icons.favorite_rounded,
          'color': AppleTheme.systemPink
        };
      case 'service':
        return {
          'name': 'Hizmet',
          'icon': Icons.handyman_rounded,
          'color': AppleTheme.systemOrange
        };
      case 'lost':
        return {
          'name': 'Kayıp/Bulundu',
          'icon': Icons.search_rounded,
          'color': AppleTheme.systemRed
        };
      default:
        return {
          'name': 'Diğer',
          'icon': Icons.article_rounded,
          'color': AppleTheme.systemGray
        };
    }
  }

  // =============================================
  // YENİ İLAN
  // =============================================
  void _showCreateListingSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'sale';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
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
                  decoration: BoxDecoration(
                      color: AppleTheme.systemGray4,
                      borderRadius: BorderRadius.circular(2.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('İptal')),
                      const Text('Yeni İlan',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                        content: Text('Başlık zorunludur.')),
                                  );
                                  return;
                                }
                                setSheetState(() => saving = true);
                                final ok = await _submitListing(
                                  title: title,
                                  description: descriptionController.text.trim(),
                                  category: category,
                                  priceText: priceController.text,
                                );
                                if (!sheetContext.mounted) return;
                                setSheetState(() => saving = false);
                                if (ok) Navigator.pop(sheetContext);
                              },
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Yayınla'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const Text('Kategori',
                          style:
                              TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.skip(1).map((cat) {
                          final id = cat['id']!;
                          final info = _getCategoryInfo(id);
                          return ChoiceChip(
                            label: Text(cat['name']!),
                            selected: category == id,
                            avatar: Icon(info['icon'] as IconData, size: 18),
                            onSelected: (_) => setSheetState(() => category = id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Başlık',
                          hintText: 'İlan başlığı',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          hintText: 'Detaylı açıklama yazın...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Fiyat (Opsiyonel)',
                          prefixText: '₺ ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // NOT: Fotoğraf yükleme alanı kaldırıldı — dosya yükleme için
                      // sunucu ucu yok; görsel eklenebileceği izlenimi verilmemeli.
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      priceController.dispose();
    });
  }

  Future<bool> _submitListing({
    required String title,
    required String description,
    required String category,
    required String priceText,
  }) async {
    final price = double.tryParse(priceText.trim().replaceAll(',', '.'));
    try {
      await apiClient.createBulletin({
        'title': title,
        'category': category,
        if (description.isNotEmpty) 'description': description,
        if (price != null) 'price': price,
      });
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('İlan yayınlandı'),
            backgroundColor: AppleTheme.systemGreen),
      );
      await _load();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Yayınlanamadı: ${toUserMessage(e)}'),
            backgroundColor: AppleTheme.systemRed),
      );
      return false;
    }
  }

  void _showListingDetail(Map<String, dynamic> listing) {
    final catInfo = _getCategoryInfo(_categoryId(listing));
    final price = _number(listing, const ['price', 'amount']);
    final views = _number(listing, const ['views', 'view_count']);
    final author = _text(listing, const ['author', 'author_name', 'created_by_name']);
    final unit = _text(listing, const ['unit', 'unit_no', 'unit_number']);
    final description = _text(listing, const ['description', 'content', 'body']);
    final id = _text(listing, const ['id']);
    final createdAt =
        listing['created_at'] ?? listing['published_at'] ?? listing['date'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
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
              decoration: BoxDecoration(
                  color: AppleTheme.systemGray4,
                  borderRadius: BorderRadius.circular(2.5)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: (catInfo['color'] as Color)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catInfo['icon'] as IconData,
                              size: 16, color: catInfo['color'] as Color),
                          const SizedBox(width: 6),
                          Text(catInfo['name'] as String,
                              style: TextStyle(
                                  color: catInfo['color'] as Color,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_text(listing, const ['title', 'subject']) ?? 'Başlıksız ilan',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (price != null)
                    Text(formatTry(price),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppleTheme.systemGreen)),
                  const SizedBox(height: 16),

                  // İlan sahibi yalnızca sunucu gerçekten gönderdiyse gösterilir.
                  if (author != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppleTheme.systemGray6,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppleTheme.systemBlue.withValues(alpha: 0.15),
                            child: Text(
                              author.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                  color: AppleTheme.systemBlue,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(author,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if (unit != null)
                                  Text(unit,
                                      style: TextStyle(
                                          color: AppleTheme.secondaryLabel)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  const Text('Açıklama',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(description ?? 'Açıklama girilmemiş.',
                      style: TextStyle(
                          color: AppleTheme.secondaryLabel, height: 1.5)),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (views != null) ...[
                        Icon(Icons.visibility_rounded,
                            size: 16, color: AppleTheme.tertiaryLabel),
                        const SizedBox(width: 4),
                        Text('${formatNumber(views)} görüntüleme',
                            style: TextStyle(color: AppleTheme.tertiaryLabel)),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.access_time_rounded,
                          size: 16, color: AppleTheme.tertiaryLabel),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(formatDateTime(createdAt),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppleTheme.tertiaryLabel)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Yalnızca gerçek bir uç bulunan işlem bırakıldı: kaldırma.
                  // "Düzenle" ve "Mesaj gönder" düğmeleri karşılıksız olduğu için silindi.
                  if (id != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(sheetContext, id, listing),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppleTheme.systemRed),
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Kaldır'),
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

  Future<void> _confirmDelete(
      BuildContext sheetContext, String id, Map<String, dynamic> listing) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İlanı Kaldır'),
        content: Text(
            '"${_text(listing, const ['title', 'subject']) ?? 'Bu ilan'}" kaldırılsın mı?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemRed),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.deleteBulletin(id);
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('İlan kaldırıldı'),
            backgroundColor: AppleTheme.systemGreen),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Kaldırılamadı: ${toUserMessage(e)}'),
            backgroundColor: AppleTheme.systemRed),
      );
    }
  }
}

String? _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

double? _number(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
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
