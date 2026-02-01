import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Stok/Envanter Yönetim Ekranı - Apple Tarzı
class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;

  final List<String> _categories = ['Tümü', 'Temizlik', 'Elektrik', 'Bahçe', 'Ofis'];

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Çöp Poşeti (Büyük)',
      'category': 'Temizlik',
      'sku': 'TEM-001',
      'stock': 45,
      'minStock': 20,
      'unit': 'Paket',
      'price': 50,
      'isLow': false,
    },
    {
      'name': 'Çamaşır Suyu 5L',
      'category': 'Temizlik',
      'sku': 'TEM-002',
      'stock': 8,
      'minStock': 10,
      'unit': 'Adet',
      'price': 75,
      'isLow': true,
    },
    {
      'name': 'LED Ampul 12W',
      'category': 'Elektrik',
      'sku': 'ELK-001',
      'stock': 25,
      'minStock': 15,
      'unit': 'Adet',
      'price': 45,
      'isLow': false,
    },
    {
      'name': 'Gübre 25kg',
      'category': 'Bahçe',
      'sku': 'BAH-001',
      'stock': 3,
      'minStock': 5,
      'unit': 'Adet',
      'price': 250,
      'isLow': true,
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
                'Stok Takibi',
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
                  _buildMiniStat('Toplam', '45', Icons.inventory_2_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Düşük Stok', '5', Icons.warning_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Toplam Değer', '₺25K', Icons.monetization_on_rounded, AppleTheme.systemGreen),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Ürün ara...',
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
                      labelStyle: TextStyle(
                        color: isSelected ? AppleTheme.systemBlue : AppleTheme.label,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Low Stock Alert
          if (_items.any((item) => item['isLow'] == true))
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppleTheme.systemOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppleTheme.systemOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Düşük Stok Uyarısı',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppleTheme.systemOrange),
                          ),
                          Text(
                            '${_items.where((item) => item['isLow'] == true).length} ürün minimum stok seviyesinin altında',
                            style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Görüntüle'),
                    ),
                  ],
                ),
              ),
            ),

          // Items List
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Stok Kalemleri'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredItems.asMap().entries.map((entry) {
                  return _buildItemTile(entry.value, isLast: entry.key == _filteredItems.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Stok Girişi',
        onPressed: () {},
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = _searchController.text.isEmpty ||
          item['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 0 ||
          item['category'] == _categories[_selectedCategory];
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
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
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, {bool isLast = false}) {
    final isLow = item['isLow'] as bool;

    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLow ? AppleTheme.systemOrange.withOpacity(0.12) : AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: isLow ? AppleTheme.systemOrange : AppleTheme.systemGray,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          if (isLow) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.warning_rounded, size: 16, color: AppleTheme.systemOrange),
                          ],
                        ],
                      ),
                      Text(
                        '${item['category']} • ${item['sku']}',
                        style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item['stock']} ${item['unit']}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isLow ? AppleTheme.systemOrange : AppleTheme.label,
                      ),
                    ),
                    Text(
                      'Min: ${item['minStock']}',
                      style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                    ),
                  ],
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
}
