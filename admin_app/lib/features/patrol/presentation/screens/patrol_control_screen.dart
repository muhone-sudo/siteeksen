import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Tur Kontrol Ekranı - Apple Tarzı
class PatrolControlScreen extends StatefulWidget {
  const PatrolControlScreen({super.key});

  @override
  State<PatrolControlScreen> createState() => _PatrolControlScreenState();
}

class _PatrolControlScreenState extends State<PatrolControlScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _checkpoints = [
    {'id': '1', 'name': 'A Blok Giriş', 'location': 'A Blok', 'type': 'nfc'},
    {'id': '2', 'name': 'B Blok Giriş', 'location': 'B Blok', 'type': 'nfc'},
    {'id': '3', 'name': 'Otopark Giriş', 'location': 'Otopark', 'type': 'qr'},
    {'id': '4', 'name': 'Havuz Alanı', 'location': 'Sosyal Tesis', 'type': 'nfc'},
    {'id': '5', 'name': 'Spor Salonu', 'location': 'Sosyal Tesis', 'type': 'qr'},
    {'id': '6', 'name': 'Bahçe Perimetresi', 'location': 'Dış Alan', 'type': 'nfc'},
  ];

  final List<Map<String, dynamic>> _tours = [
    {
      'id': '1',
      'guard': 'Ahmet Güvenlik',
      'startTime': '08:00',
      'endTime': '08:45',
      'status': 'completed',
      'checkpoints': 6,
      'completedCheckpoints': 6,
    },
    {
      'id': '2',
      'guard': 'Mehmet Güvenlik',
      'startTime': '12:00',
      'endTime': '12:35',
      'status': 'completed',
      'checkpoints': 6,
      'completedCheckpoints': 5,
    },
    {
      'id': '3',
      'guard': 'Ali Güvenlik',
      'startTime': '16:00',
      'endTime': null,
      'status': 'active',
      'checkpoints': 6,
      'completedCheckpoints': 3,
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
                'Tur Kontrol',
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
                icon: Icon(Icons.map_rounded, color: AppleTheme.systemBlue),
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
                  _buildMiniStat('Bugün', '${_tours.length}', Icons.route_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Tamamlanan', '${_tours.where((t) => t['status'] == 'completed').length}', 
                      Icons.check_circle_rounded, AppleTheme.systemGreen),
                  _buildMiniStat('Aktif', '${_tours.where((t) => t['status'] == 'active').length}', 
                      Icons.directions_walk_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Kontrol Noktası', '${_checkpoints.length}', Icons.location_on_rounded, AppleTheme.systemPurple),
                ],
              ),
            ),
          ),

          // Active Tour Banner
          if (_tours.any((t) => t['status'] == 'active'))
            SliverToBoxAdapter(
              child: _buildActiveTourBanner(),
            ),

          // Date Selector
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                  ),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
          ),

          // Tours List
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Turlar'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _tours.asMap().entries.map((entry) {
                  return _buildTourTile(entry.value, isLast: entry.key == _tours.length - 1);
                }).toList(),
              ),
            ),
          ),

          // Checkpoints Section
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Kontrol Noktaları', action: 'Düzenle'),
          ),

          SliverToBoxAdapter(
            child: Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _checkpoints.length,
                itemBuilder: (context, index) => _buildCheckpointChip(_checkpoints[index]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.play_arrow_rounded,
        label: 'Tur Başlat',
        onPressed: () {},
      ),
    );
  }

  Widget _buildActiveTourBanner() {
    final activeTour = _tours.firstWhere((t) => t['status'] == 'active');
    final progress = activeTour['completedCheckpoints'] / activeTour['checkpoints'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppleTheme.systemBlue.withOpacity(0.15), AppleTheme.systemBlue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppleTheme.systemBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppleTheme.systemBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_walk_rounded, color: AppleTheme.systemBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktif Tur', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    Text(activeTour['guard'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${activeTour['completedCheckpoints']}/${activeTour['checkpoints']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppleTheme.systemGray6,
              valueColor: AlwaysStoppedAnimation<Color>(AppleTheme.systemBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
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
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildTourTile(Map<String, dynamic> tour, {bool isLast = false}) {
    final isActive = tour['status'] == 'active';
    final isComplete = tour['completedCheckpoints'] == tour['checkpoints'];

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
                    color: isActive ? AppleTheme.systemBlue.withOpacity(0.12) : AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.directions_walk_rounded : Icons.check_circle_rounded,
                    color: isActive ? AppleTheme.systemBlue : (isComplete ? AppleTheme.systemGreen : AppleTheme.systemOrange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tour['guard'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(
                        '${tour['startTime']} - ${tour['endTime'] ?? 'Devam ediyor'}',
                        style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplete ? AppleTheme.systemGreen.withOpacity(0.12) : AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tour['completedCheckpoints']}/${tour['checkpoints']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isComplete ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                    ),
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

  Widget _buildCheckpointChip(Map<String, dynamic> checkpoint) {
    final isNfc = checkpoint['type'] == 'nfc';

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNfc ? AppleTheme.systemBlue.withOpacity(0.12) : AppleTheme.systemPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isNfc ? Icons.nfc_rounded : Icons.qr_code_rounded,
              size: 20,
              color: isNfc ? AppleTheme.systemBlue : AppleTheme.systemPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            checkpoint['name'],
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
