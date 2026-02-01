import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Demirbaş Yönetim Ekranı - Apple Tarzı
class AssetManagementScreen extends StatefulWidget {
  const AssetManagementScreen({super.key});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Tümü', 'Mobilya', 'Elektronik', 'Araç', 'Bahçe'];

  final List<Map<String, dynamic>> _assets = [
    {
      'id': 'DMR-001',
      'name': 'Toplantı Odası Masası',
      'category': 'Mobilya',
      'location': 'Yönetim Binası',
      'status': 'active',
      'purchaseDate': '2023-03-15',
      'value': 12500,
      'barcode': '8697812345678',
    },
    {
      'id': 'DMR-002',
      'name': 'Kamera Sistemi (16 Kanal)',
      'category': 'Elektronik',
      'location': 'Güvenlik Odası',
      'status': 'active',
      'purchaseDate': '2024-01-10',
      'value': 45000,
      'barcode': '8697812345679',
    },
    {
      'id': 'DMR-003',
      'name': 'Elektrikli Golf Arabası',
      'category': 'Araç',
      'location': 'Garaj',
      'status': 'maintenance',
      'purchaseDate': '2022-06-20',
      'value': 95000,
      'barcode': '8697812345680',
    },
    {
      'id': 'DMR-004',
      'name': 'Çim Biçme Makinesi',
      'category': 'Bahçe',
      'location': 'Bahçe Deposu',
      'status': 'active',
      'purchaseDate': '2023-04-01',
      'value': 28000,
      'barcode': '8697812345681',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Demirbaşlar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.qr_code_scanner_rounded, color: AppleTheme.systemBlue),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Stats
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMiniStat('Toplam', '${_assets.length}', Icons.inventory_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Aktif', '${_assets.where((a) => a['status'] == 'active').length}', 
                      Icons.check_circle_rounded, AppleTheme.systemGreen),
                  _buildMiniStat('Bakımda', '${_assets.where((a) => a['status'] == 'maintenance').length}', 
                      Icons.build_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Toplam Değer', '₺180K', Icons.monetization_on_rounded, AppleTheme.systemPurple),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Demirbaş ara...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_categories[index]),
                      onSelected: (selected) => setState(() => _selectedCategory = index),
                      backgroundColor: Colors.white,
                      selectedColor: AppleTheme.systemBlue.withOpacity(0.15),
                      checkmarkColor: AppleTheme.systemBlue,
                    ),
                  );
                },
              ),
            ),
          ),

          // Section Header
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Demirbaş Listesi'),
          ),

          // Asset List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredAssets.asMap().entries.map((entry) {
                  return _buildAssetTile(entry.value, isLast: entry.key == _filteredAssets.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Demirbaş Ekle',
        onPressed: () {},
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAssets {
    return _assets.where((a) {
      final matchesSearch = _searchController.text.isEmpty ||
          a['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          a['id'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 0 || a['category'] == _categories[_selectedCategory];
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildAssetTile(Map<String, dynamic> asset, {bool isLast = false}) {
    final isActive = asset['status'] == 'active';
    Color statusColor = isActive ? AppleTheme.systemGreen : AppleTheme.systemOrange;
    String statusText = isActive ? 'Aktif' : 'Bakımda';

    return Column(
      children: [
        InkWell(
          onTap: () => _showAssetDetails(context, asset),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getCategoryIcon(asset['category']), color: AppleTheme.systemGray),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        '${asset['category']} • ${asset['location']}',
                        style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                      ),
                      Text(
                        asset['id'],
                        style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 76),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Mobilya': return Icons.chair_rounded;
      case 'Elektronik': return Icons.devices_rounded;
      case 'Araç': return Icons.directions_car_rounded;
      case 'Bahçe': return Icons.grass_rounded;
      default: return Icons.inventory_rounded;
    }
  }

  void _showAssetDetails(BuildContext context, Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray4,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(asset['id'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.category_rounded, 'Kategori', asset['category']),
                  _buildInfoRow(Icons.location_on_rounded, 'Konum', asset['location']),
                  _buildInfoRow(Icons.calendar_today_rounded, 'Alım Tarihi', asset['purchaseDate']),
                  _buildInfoRow(Icons.monetization_on_rounded, 'Değer', '₺${asset['value']}'),
                  _buildInfoRow(Icons.qr_code_rounded, 'Barkod', asset['barcode']),
                  const SizedBox(height: 24),
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
                          icon: const Icon(Icons.build_rounded),
                          label: const Text('Bakım'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppleTheme.secondaryLabel),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
