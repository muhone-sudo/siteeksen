import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Kargo Takip Mobil Ekranı - Apple Tarzı
class PackageTrackingMobileScreen extends StatefulWidget {
  const PackageTrackingMobileScreen({super.key});

  @override
  State<PackageTrackingMobileScreen> createState() => _PackageTrackingMobileScreenState();
}

class _PackageTrackingMobileScreenState extends State<PackageTrackingMobileScreen> {
  final List<Map<String, dynamic>> _packages = [
    {
      'id': '1',
      'carrier': 'Aras Kargo',
      'trackingNo': 'ARS789456123',
      'status': 'arrived',
      'arrivedAt': '14:30',
      'arrivedDate': 'Bugün',
      'description': 'Orta boy kutu',
      'senderName': 'Trendyol',
      'isPickedUp': false,
    },
    {
      'id': '2',
      'carrier': 'Yurtiçi Kargo',
      'trackingNo': 'YK456789012',
      'status': 'arrived',
      'arrivedAt': '11:15',
      'arrivedDate': 'Bugün',
      'description': 'Küçük paket',
      'senderName': 'Amazon',
      'isPickedUp': false,
    },
    {
      'id': '3',
      'carrier': 'MNG Kargo',
      'trackingNo': 'MNG123456789',
      'status': 'in_transit',
      'estimatedDate': 'Yarın',
      'description': 'Büyük kutu',
      'senderName': 'Hepsiburada',
      'isPickedUp': false,
    },
    {
      'id': '4',
      'carrier': 'PTT Kargo',
      'trackingNo': 'PTT987654321',
      'status': 'picked_up',
      'arrivedAt': '09:30',
      'arrivedDate': '30 Ocak',
      'pickedUpAt': '16:45',
      'description': 'Mektup/Zarf',
      'senderName': 'Devlet Kurumu',
      'isPickedUp': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final waitingPackages = _packages.where((p) => p['status'] == 'arrived' && p['isPickedUp'] == false).toList();
    final inTransitPackages = _packages.where((p) => p['status'] == 'in_transit').toList();
    final pickedUpPackages = _packages.where((p) => p['isPickedUp'] == true).toList();

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
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_rounded)),
                    const Expanded(child: Text('Kargolarım', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSummaryCard('Bekleyen', '${waitingPackages.length}', Icons.inventory_2_rounded, AppleTheme.systemOrange),
                    _buildSummaryCard('Yolda', '${inTransitPackages.length}', Icons.local_shipping_rounded, AppleTheme.systemBlue),
                    _buildSummaryCard('Teslim Alınan', '${pickedUpPackages.length}', Icons.check_circle_rounded, AppleTheme.systemGreen),
                  ],
                ),
              ),
            ),

            // Waiting Packages
            if (waitingPackages.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: AppleTheme.systemOrange, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('Güvenlikte Bekliyor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildPackageCard(waitingPackages[index]),
                  ),
                  childCount: waitingPackages.length,
                ),
              ),
            ],

            // In Transit
            if (inTransitPackages.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppleTheme.systemBlue, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Yolda', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildPackageCard(inTransitPackages[index]),
                  ),
                  childCount: inTransitPackages.length,
                ),
              ),
            ],

            // Picked Up
            if (pickedUpPackages.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppleTheme.systemGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Teslim Alındı', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildPackageCard(pickedUpPackages[index]),
                  ),
                  childCount: pickedUpPackages.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              const Spacer(),
              Text(title, style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final status = package['status'] as String;
    final isPickedUp = package['isPickedUp'] == true;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isPickedUp) {
      statusColor = AppleTheme.systemGreen;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Teslim alındı';
    } else if (status == 'arrived') {
      statusColor = AppleTheme.systemOrange;
      statusIcon = Icons.inventory_2_rounded;
      statusText = 'Güvenlikte';
    } else {
      statusColor = AppleTheme.systemBlue;
      statusIcon = Icons.local_shipping_rounded;
      statusText = 'Yolda';
    }

    return GestureDetector(
      onTap: () => _showPackageDetail(context, package),
      child: Container(
        decoration: AppleTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Carrier Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(statusIcon, color: statusColor, size: 26),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(package['carrier'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(package['senderName'], style: TextStyle(color: AppleTheme.secondaryLabel)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.qr_code_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                        const SizedBox(width: 4),
                        Text(package['trackingNo'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (status == 'arrived' && !isPickedUp) ...[
                          Icon(Icons.access_time_rounded, size: 14, color: AppleTheme.systemOrange),
                          const SizedBox(width: 4),
                          Text('${package['arrivedDate']} ${package['arrivedAt']}', style: TextStyle(fontSize: 12, color: AppleTheme.systemOrange)),
                        ] else if (status == 'in_transit') ...[
                          Icon(Icons.schedule_rounded, size: 14, color: AppleTheme.systemBlue),
                          const SizedBox(width: 4),
                          Text('Tahmini: ${package['estimatedDate']}', style: TextStyle(fontSize: 12, color: AppleTheme.systemBlue)),
                        ] else if (isPickedUp) ...[
                          Icon(Icons.check_rounded, size: 14, color: AppleTheme.systemGreen),
                          const SizedBox(width: 4),
                          Text('${package['arrivedDate']} ${package['pickedUpAt']}', style: TextStyle(fontSize: 12, color: AppleTheme.systemGreen)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppleTheme.systemGray3),
            ],
          ),
        ),
      ),
    );
  }

  void _showPackageDetail(BuildContext context, Map<String, dynamic> package) {
    final status = package['status'] as String;
    final isPickedUp = package['isPickedUp'] == true;

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
            Container(width: 36, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Carrier & Status
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: AppleTheme.systemBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.local_shipping_rounded, color: AppleTheme.systemBlue, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(package['carrier'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            Text(package['senderName'], style: TextStyle(color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tracking Number
                  _buildDetailRow('Takip No', package['trackingNo'], canCopy: true),
                  _buildDetailRow('Açıklama', package['description']),
                  if (status == 'arrived')
                    _buildDetailRow('Varış', '${package['arrivedDate']} ${package['arrivedAt']}'),
                  if (isPickedUp)
                    _buildDetailRow('Teslim', '${package['arrivedDate']} ${package['pickedUpAt']}'),
                  if (status == 'in_transit')
                    _buildDetailRow('Tahmini', package['estimatedDate']),

                  const SizedBox(height: 24),

                  // Timeline
                  const Text('Takip', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildTimelineItem('Kargo yola çıktı', 'Gönderici deposundan alındı', true),
                  if (status == 'arrived' || isPickedUp)
                    _buildTimelineItem('Siteye ulaştı', '${package['arrivedDate']} ${package['arrivedAt']}', true),
                  if (isPickedUp)
                    _buildTimelineItem('Teslim edildi', 'Sakin tarafından alındı', true, isLast: true)
                  else if (status == 'arrived')
                    _buildTimelineItem('Teslim bekliyor', 'Güvenlikte', false, isLast: true, isCurrent: true),

                  const SizedBox(height: 24),

                  // Actions
                  if (status == 'arrived' && !isPickedUp)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Güvenlik bilgilendirildi'), backgroundColor: AppleTheme.systemGreen),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text('Güvenliğe Haber Ver'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: AppleTheme.secondaryLabel))),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
                if (canCopy)
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.copy_rounded, size: 18, color: AppleTheme.systemBlue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isCompleted, {bool isLast = false, bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: isCompleted ? AppleTheme.systemGreen : (isCurrent ? AppleTheme.systemOrange : AppleTheme.systemGray4),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: isCompleted ? AppleTheme.systemGreen : AppleTheme.systemGray5),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isCurrent ? AppleTheme.systemOrange : AppleTheme.label)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
