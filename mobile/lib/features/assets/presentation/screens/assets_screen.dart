import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';

/// Demirbaş Takip Ekranı - Sakin için daire demirbaşları
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  // Daire demirbaşları
  final List<Map<String, dynamic>> _assets = [
    {
      'id': 'AST-001',
      'name': 'Kombi',
      'brand': 'Baymak',
      'model': 'Eco Fourtech 24',
      'category': 'ısıtma',
      'location': 'Mutfak',
      'purchaseDate': '2022-06-15',
      'warrantyEnd': '2025-06-15',
      'warrantyStatus': 'active',
      'lastMaintenance': '2024-01-10',
      'status': 'working',
    },
    {
      'id': 'AST-002',
      'name': 'Klima',
      'brand': 'Samsung',
      'model': 'WindFree 12000 BTU',
      'category': 'iklimlendirme',
      'location': 'Salon',
      'purchaseDate': '2023-05-20',
      'warrantyEnd': '2026-05-20',
      'warrantyStatus': 'active',
      'lastMaintenance': '2024-03-15',
      'status': 'working',
    },
    {
      'id': 'AST-003',
      'name': 'Bulaşık Makinesi',
      'brand': 'Bosch',
      'model': 'Serie 6',
      'category': 'beyaz_esya',
      'location': 'Mutfak',
      'purchaseDate': '2021-03-10',
      'warrantyEnd': '2024-03-10',
      'warrantyStatus': 'expired',
      'lastMaintenance': null,
      'status': 'working',
    },
    {
      'id': 'AST-004',
      'name': 'Çamaşır Makinesi',
      'brand': 'LG',
      'model': 'F4V5VYP0W',
      'category': 'beyaz_esya',
      'location': 'Banyo',
      'purchaseDate': '2022-08-01',
      'warrantyEnd': '2025-08-01',
      'warrantyStatus': 'active',
      'lastMaintenance': '2024-02-20',
      'status': 'working',
    },
    {
      'id': 'AST-005',
      'name': 'Buzdolabı',
      'brand': 'Arçelik',
      'model': 'No-Frost 540L',
      'category': 'beyaz_esya',
      'location': 'Mutfak',
      'purchaseDate': '2020-11-15',
      'warrantyEnd': '2023-11-15',
      'warrantyStatus': 'expired',
      'lastMaintenance': null,
      'status': 'working',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeWarranty = _assets.where((a) => a['warrantyStatus'] == 'active').length;
    final expiredWarranty = _assets.where((a) => a['warrantyStatus'] == 'expired').length;

    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppleTheme.systemGray6,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppleTheme.label),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Demirbaşlarım', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Dairenize ait demirbaş ve cihazlar', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  ],
                ),
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMiniStat('Toplam', '${_assets.length}', Icons.inventory_2_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Garantili', '$activeWarranty', Icons.verified_rounded, AppleTheme.systemGreen),
                  _buildMiniStat('Garanti Bitti', '$expiredWarranty', Icons.warning_rounded, AppleTheme.systemOrange),
                ],
              ),
            ),
          ),

          // Garanti Uyarısı
          if (expiredWarranty > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppleTheme.systemOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppleTheme.systemOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppleTheme.systemOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$expiredWarranty cihazın garantisi sona ermiş',
                        style: TextStyle(fontSize: 14, color: AppleTheme.systemOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Asset List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final asset = _assets[index];
                return _buildAssetCard(asset);
              },
              childCount: _assets.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final isWarrantyExpired = asset['warrantyStatus'] == 'expired';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getCategoryColor(asset['category']).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(asset['category']), color: _getCategoryColor(asset['category']), size: 24),
              ),
              const SizedBox(width: 14),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(asset['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        if (!isWarrantyExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppleTheme.systemGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppleTheme.systemGreen),
                                SizedBox(width: 4),
                                Text('Garantili', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTheme.systemGreen)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${asset['brand']} ${asset['model']}', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                        const SizedBox(width: 4),
                        Text(asset['location'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                        const SizedBox(width: 4),
                        Text('Garanti: ${asset['warrantyEnd']}', style: TextStyle(fontSize: 12, color: isWarrantyExpired ? AppleTheme.systemOrange : AppleTheme.tertiaryLabel)),
                      ],
                    ),
                  ],
                ),
              ),
              
              Icon(Icons.chevron_right_rounded, color: AppleTheme.systemGray3),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'ısıtma':
        return Icons.whatshot_rounded;
      case 'iklimlendirme':
        return Icons.ac_unit_rounded;
      case 'beyaz_esya':
        return Icons.kitchen_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ısıtma':
        return AppleTheme.systemOrange;
      case 'iklimlendirme':
        return AppleTheme.systemBlue;
      case 'beyaz_esya':
        return AppleTheme.systemGreen;
      default:
        return AppleTheme.systemGray;
    }
  }

  void _showAssetDetails(Map<String, dynamic> asset) {
    final isWarrantyExpired = asset['warrantyStatus'] == 'expired';
    
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
            Container(width: 36, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(asset['category']).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_getCategoryIcon(asset['category']), color: _getCategoryColor(asset['category']), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            Text('${asset['brand']} ${asset['model']}', style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Garanti durumu
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isWarrantyExpired ? AppleTheme.systemOrange.withOpacity(0.1) : AppleTheme.systemGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWarrantyExpired ? Icons.warning_rounded : Icons.verified_rounded,
                          color: isWarrantyExpired ? AppleTheme.systemOrange : AppleTheme.systemGreen,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWarrantyExpired ? 'Garanti Süresi Dolmuş' : 'Garanti Kapsamında',
                                style: TextStyle(fontWeight: FontWeight.w600, color: isWarrantyExpired ? AppleTheme.systemOrange : AppleTheme.systemGreen),
                              ),
                              Text(
                                'Bitiş: ${asset['warrantyEnd']}',
                                style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detaylar
                  _buildInfoRow(Icons.tag_rounded, 'Demirbaş No', asset['id']),
                  _buildInfoRow(Icons.location_on_rounded, 'Konum', asset['location']),
                  _buildInfoRow(Icons.shopping_cart_rounded, 'Alım Tarihi', asset['purchaseDate']),
                  if (asset['lastMaintenance'] != null)
                    _buildInfoRow(Icons.build_rounded, 'Son Bakım', asset['lastMaintenance']),
                  
                  const SizedBox(height: 24),

                  // Arıza Bildir Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Arıza bildirimi oluşturuldu')),
                        );
                      },
                      icon: const Icon(Icons.report_problem_rounded),
                      label: const Text('Arıza Bildir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppleTheme.systemRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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
          Icon(icon, size: 18, color: AppleTheme.secondaryLabel),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
