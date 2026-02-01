import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Sözleşme Yönetim Ekranı - Apple Tarzı
class ContractManagementScreen extends StatefulWidget {
  const ContractManagementScreen({super.key});

  @override
  State<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends State<ContractManagementScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _contracts = [
    {
      'id': 'SZL-2024-001',
      'title': 'Güvenlik Hizmeti Sözleşmesi',
      'vendor': 'ABC Güvenlik Ltd.',
      'type': 'service',
      'startDate': '2024-01-01',
      'endDate': '2026-12-31',
      'monthlyValue': 45000,
      'status': 'active',
      'daysRemaining': 334,
    },
    {
      'id': 'SZL-2024-002',
      'title': 'Asansör Bakım Sözleşmesi',
      'vendor': 'Asansör Teknik A.Ş.',
      'type': 'maintenance',
      'startDate': '2024-03-01',
      'endDate': '2026-03-01',
      'monthlyValue': 8500,
      'status': 'active',
      'daysRemaining': 28,
    },
    {
      'id': 'SZL-2024-003',
      'title': 'Temizlik Hizmeti',
      'vendor': 'Temiz İş Hizmetler',
      'type': 'service',
      'startDate': '2024-06-01',
      'endDate': '2027-06-01',
      'monthlyValue': 32000,
      'status': 'active',
      'daysRemaining': 485,
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
                'Sözleşmeler',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
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
                  _buildMiniStat('Aktif', '${_contracts.length}', Icons.description_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Yaklaşan', '1', Icons.warning_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Aylık Maliyet', '₺85K', Icons.monetization_on_rounded, AppleTheme.systemGreen),
                ],
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Sözleşme ara...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Expiring Soon Alert
          if (_contracts.any((c) => c['daysRemaining'] < 60))
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppleTheme.systemOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppleTheme.systemOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sözleşme Yenileme Uyarısı', style: TextStyle(fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                          Text(
                            '1 sözleşmenin bitiş tarihi yaklaşıyor',
                            style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Görüntüle')),
                  ],
                ),
              ),
            ),

          // List
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Aktif Sözleşmeler'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _contracts.asMap().entries.map((entry) {
                  return _buildContractTile(entry.value, isLast: entry.key == _contracts.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Sözleşme',
        onPressed: () {},
      ),
    );
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

  Widget _buildContractTile(Map<String, dynamic> contract, {bool isLast = false}) {
    final isExpiringSoon = contract['daysRemaining'] < 60;

    return Column(
      children: [
        InkWell(
          onTap: () => _showContractDetails(context, contract),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract['title'],
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isExpiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: AppleTheme.systemOrange),
                            const SizedBox(width: 4),
                            Text('${contract['daysRemaining']} gün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(contract['vendor'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                    const SizedBox(width: 4),
                    Text(
                      '${contract['startDate']} - ${contract['endDate']}',
                      style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel),
                    ),
                    const Spacer(),
                    Text(
                      '₺${contract['monthlyValue']}/ay',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  void _showContractDetails(BuildContext context, Map<String, dynamic> contract) {
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
                  Text(contract['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(contract['vendor'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.tag_rounded, 'Sözleşme No', contract['id']),
                  _buildInfoRow(Icons.play_arrow_rounded, 'Başlangıç', contract['startDate']),
                  _buildInfoRow(Icons.stop_rounded, 'Bitiş', contract['endDate']),
                  _buildInfoRow(Icons.monetization_on_rounded, 'Aylık Tutar', '₺${contract['monthlyValue']}'),
                  _buildInfoRow(Icons.schedule_rounded, 'Kalan Süre', '${contract['daysRemaining']} gün'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.file_download_rounded),
                          label: const Text('PDF İndir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Yenile'),
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
