import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Araç/Otopark Yönetim Ekranı - Apple Tarzı
class ParkingManagementScreen extends StatefulWidget {
  const ParkingManagementScreen({super.key});

  @override
  State<ParkingManagementScreen> createState() => _ParkingManagementScreenState();
}

class _ParkingManagementScreenState extends State<ParkingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _vehicles = [
    {
      'plate': '34 ABC 123',
      'owner': 'Ali Veli',
      'unit': 'D.101',
      'brand': 'Toyota Corolla',
      'color': 'Beyaz',
      'spot': 'A-15',
      'type': 'resident',
      'isInside': true,
    },
    {
      'plate': '06 DEF 456',
      'owner': 'Ayşe Kaya',
      'unit': 'D.205',
      'brand': 'Honda Civic',
      'color': 'Siyah',
      'spot': 'B-03',
      'type': 'resident',
      'isInside': false,
    },
    {
      'plate': '35 XYZ 789',
      'owner': 'Misafir',
      'unit': 'D.301',
      'brand': '-',
      'color': 'Gri',
      'spot': 'M-01',
      'type': 'visitor',
      'isInside': true,
    },
  ];

  final List<Map<String, dynamic>> _parkingZones = [
    {'name': 'A Blok', 'capacity': 50, 'occupied': 35, 'available': 15},
    {'name': 'B Blok', 'capacity': 50, 'occupied': 42, 'available': 8},
    {'name': 'Misafir', 'capacity': 20, 'occupied': 8, 'available': 12},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Otopark',
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppleTheme.systemBlue,
                  labelColor: AppleTheme.systemBlue,
                  unselectedLabelColor: AppleTheme.systemGray,
                  tabs: const [
                    Tab(text: 'Araçlar'),
                    Tab(text: 'Bölgeler'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVehiclesTab(),
            _buildZonesTab(),
          ],
        ),
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Araç Ekle',
        onPressed: () {},
      ),
    );
  }

  Widget _buildVehiclesTab() {
    return CustomScrollView(
      slivers: [
        // Stats
        SliverToBoxAdapter(
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(top: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCompactStat('Toplam', '120', Icons.directions_car_rounded, AppleTheme.systemBlue),
                _buildCompactStat('İçeride', '65', Icons.location_on_rounded, AppleTheme.systemGreen),
                _buildCompactStat('Dışarıda', '55', Icons.location_off_rounded, AppleTheme.systemGray),
              ],
            ),
          ),
        ),

        // Search
        SliverToBoxAdapter(
          child: AppleSearchBar(
            controller: _searchController,
            placeholder: 'Plaka ara...',
            onChanged: (value) => setState(() {}),
          ),
        ),

        const SliverToBoxAdapter(
          child: AppleSectionHeader(title: 'Kayıtlı Araçlar'),
        ),

        // Vehicle List
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _vehicles.asMap().entries.map((entry) {
                return _buildVehicleTile(
                  entry.value,
                  isLast: entry.key == _vehicles.length - 1,
                );
              }).toList(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildZonesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Zone Cards
        ..._parkingZones.map((zone) => _buildZoneCard(zone)),

        const SizedBox(height: 16),

        // Recent Activity
        const AppleSectionHeader(title: 'Son Hareketler'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildActivityTile('34 ABC 123', 'Giriş', '14:32', AppleTheme.systemGreen),
              _buildActivityTile('06 DEF 456', 'Çıkış', '14:15', AppleTheme.systemOrange),
              _buildActivityTile('35 XYZ 789', 'Giriş', '13:45', AppleTheme.systemGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppleTheme.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTile(Map<String, dynamic> vehicle, {bool isLast = false}) {
    final isInside = vehicle['isInside'] as bool;
    final isResident = vehicle['type'] == 'resident';

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
                    color: isResident
                        ? AppleTheme.systemBlue.withOpacity(0.12)
                        : AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: isResident ? AppleTheme.systemBlue : AppleTheme.systemOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['plate'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle['owner']} • ${vehicle['unit']}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppleTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside
                        ? AppleTheme.systemGreen.withOpacity(0.12)
                        : AppleTheme.systemGray5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInside ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 14,
                        color: isInside ? AppleTheme.systemGreen : AppleTheme.systemGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isInside ? 'İçeride' : 'Dışarıda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isInside ? AppleTheme.systemGreen : AppleTheme.systemGray,
                        ),
                      ),
                    ],
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

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final occupancyPercent = zone['occupied'] / zone['capacity'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zone['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: zone['available'] > 5
                      ? AppleTheme.systemGreen.withOpacity(0.12)
                      : AppleTheme.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${zone['available']} boş',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: zone['available'] > 5
                        ? AppleTheme.systemGreen
                        : AppleTheme.systemOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancyPercent,
              backgroundColor: AppleTheme.systemGray5,
              valueColor: AlwaysStoppedAnimation(
                occupancyPercent > 0.8
                    ? AppleTheme.systemOrange
                    : AppleTheme.systemGreen,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${zone['occupied']} / ${zone['capacity']} dolu',
                style: TextStyle(
                  fontSize: 13,
                  color: AppleTheme.secondaryLabel,
                ),
              ),
              Text(
                '%${(occupancyPercent * 100).toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppleTheme.secondaryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String plate, String action, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              action == 'Giriş' ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plate, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(action, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }
}
