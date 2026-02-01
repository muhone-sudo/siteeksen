import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Kargo Takip Ekranı - Apple Tarzı
class PackageTrackingScreen extends StatefulWidget {
  const PackageTrackingScreen({super.key});

  @override
  State<PackageTrackingScreen> createState() => _PackageTrackingScreenState();
}

class _PackageTrackingScreenState extends State<PackageTrackingScreen> {
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['Tümü', 'Bekleyen', 'Teslim Edildi'];

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'KRG-2024-001',
      'carrier': 'Aras Kargo',
      'recipient': 'Ali Veli',
      'unit': 'D.101',
      'status': 'waiting',
      'arrivedAt': '2026-02-01 10:30',
      'deliveredAt': null,
    },
    {
      'id': 'KRG-2024-002',
      'carrier': 'Yurtiçi Kargo',
      'recipient': 'Ayşe Kaya',
      'unit': 'D.205',
      'status': 'waiting',
      'arrivedAt': '2026-02-01 14:15',
      'deliveredAt': null,
    },
    {
      'id': 'KRG-2024-003',
      'carrier': 'MNG Kargo',
      'recipient': 'Mehmet Demir',
      'unit': 'D.301',
      'status': 'delivered',
      'arrivedAt': '2026-01-31 09:00',
      'deliveredAt': '2026-01-31 18:30',
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
                'Kargo Takibi',
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
                  _buildMiniStat('Bekleyen', '${_packages.where((p) => p['status'] == 'waiting').length}', 
                      Icons.inventory_2_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Bugün Gelen', '5', Icons.local_shipping_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Teslim', '12', Icons.check_circle_rounded, AppleTheme.systemGreen),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Kargo ara...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_filters[index]),
                      onSelected: (selected) => setState(() => _selectedFilter = index),
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

          // Package Alert
          if (_packages.any((p) => p['status'] == 'waiting'))
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
                    Icon(Icons.notifications_active_rounded, color: AppleTheme.systemOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teslim Bekleyen Kargolar',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppleTheme.systemOrange),
                          ),
                          Text(
                            '${_packages.where((p) => p['status'] == 'waiting').length} kargo teslim edilmeyi bekliyor',
                            style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('SMS Gönder'),
                    ),
                  ],
                ),
              ),
            ),

          // List Header
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Kargolar'),
          ),

          // Package List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _filteredPackages.isEmpty
                  ? const AppleEmptyState(
                      icon: Icons.inventory_2_rounded,
                      title: 'Kargo Bulunamadı',
                    )
                  : Column(
                      children: _filteredPackages.asMap().entries.map((entry) {
                        return _buildPackageTile(entry.value, isLast: entry.key == _filteredPackages.length - 1);
                      }).toList(),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Kargo Ekle',
        onPressed: () => _showAddPackageSheet(context),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredPackages {
    return _packages.where((p) {
      final matchesSearch = _searchController.text.isEmpty ||
          p['id'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p['recipient'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      bool matchesFilter = true;
      if (_selectedFilter == 1) matchesFilter = p['status'] == 'waiting';
      if (_selectedFilter == 2) matchesFilter = p['status'] == 'delivered';
      
      return matchesSearch && matchesFilter;
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
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildPackageTile(Map<String, dynamic> pkg, {bool isLast = false}) {
    final isWaiting = pkg['status'] == 'waiting';

    return Column(
      children: [
        InkWell(
          onTap: () => _showPackageDetails(context, pkg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWaiting 
                        ? AppleTheme.systemOrange.withOpacity(0.12)
                        : AppleTheme.systemGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isWaiting ? Icons.inventory_2_rounded : Icons.check_circle_rounded,
                    color: isWaiting ? AppleTheme.systemOrange : AppleTheme.systemGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg['recipient'],
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${pkg['unit']} • ${pkg['carrier']}',
                        style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                      ),
                      Text(
                        pkg['id'],
                        style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isWaiting
                            ? AppleTheme.systemOrange.withOpacity(0.12)
                            : AppleTheme.systemGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isWaiting ? 'Bekliyor' : 'Teslim',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isWaiting ? AppleTheme.systemOrange : AppleTheme.systemGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (pkg['arrivedAt'] as String).split(' ').last,
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

  void _showPackageDetails(BuildContext context, Map<String, dynamic> pkg) {
    final isWaiting = pkg['status'] == 'waiting';
    
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isWaiting
                              ? AppleTheme.systemOrange.withOpacity(0.12)
                              : AppleTheme.systemGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: isWaiting ? AppleTheme.systemOrange : AppleTheme.systemGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg['recipient'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            Text(pkg['unit'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.local_shipping_rounded, 'Kargo Firması', pkg['carrier']),
                  _buildInfoRow(Icons.tag_rounded, 'Takip No', pkg['id']),
                  _buildInfoRow(Icons.access_time_rounded, 'Geliş Saati', pkg['arrivedAt']),
                  if (pkg['deliveredAt'] != null)
                    _buildInfoRow(Icons.check_circle_rounded, 'Teslim Saati', pkg['deliveredAt']),
                  const SizedBox(height: 24),
                  if (isWaiting) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Teslim Edildi Olarak İşaretle'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemGreen),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.sms_rounded),
                        label: const Text('SMS Bildirimi Gönder'),
                      ),
                    ),
                  ],
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

  void _showAddPackageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  const Text('Yeni Kargo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kaydet')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Kargo Firması', prefixIcon: Icon(Icons.local_shipping_outlined)),
                    items: ['Aras Kargo', 'Yurtiçi Kargo', 'MNG Kargo', 'PTT Kargo', 'Sürat Kargo', 'UPS', 'DHL']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Alıcı', prefixIcon: Icon(Icons.person_outlined)),
                    items: ['Ali Veli - D.101', 'Ayşe Kaya - D.205', 'Mehmet Demir - D.301']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Takip Numarası (Opsiyonel)', prefixIcon: Icon(Icons.tag_outlined)),
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
