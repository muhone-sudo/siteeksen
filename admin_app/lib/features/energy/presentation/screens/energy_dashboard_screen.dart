import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// AI Enerji Analitik Dashboard - Apple Tarzı
class EnergyDashboardScreen extends StatefulWidget {
  const EnergyDashboardScreen({super.key});

  @override
  State<EnergyDashboardScreen> createState() => _EnergyDashboardScreenState();
}

class _EnergyDashboardScreenState extends State<EnergyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedPeriod = 0;

  final List<String> _periods = ['Bu Ay', 'Son 3 Ay', 'Son 6 Ay', 'Bu Yıl'];

  final Map<String, dynamic> _dashboardData = {
    'electricity': {'value': 45200, 'unit': 'kWh', 'cost': 162720, 'change': -5.2},
    'gas': {'value': 1200, 'unit': 'm³', 'cost': 18000, 'change': 12.5},
    'water': {'value': 850, 'unit': 'm³', 'cost': 12750, 'change': -2.1},
  };

  final List<Map<String, dynamic>> _anomalies = [
    {
      'title': 'Havuz Sayacı Anomalisi',
      'description': 'Beklenen tüketimin %85 üzerinde',
      'severity': 'medium',
      'time': '2 saat önce',
    },
    {
      'title': 'Gece Tüketim Artışı',
      'description': 'B Blok gece tüketiminde artış',
      'severity': 'low',
      'time': '5 saat önce',
    },
  ];

  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'LED Aydınlatmaya Geçiş',
      'description': 'Ortak alan aydınlatmaları',
      'savings': 3500,
      'priority': 'high',
      'confidence': 0.92,
    },
    {
      'title': 'Isı Pompası Optimizasyonu',
      'description': 'Termostat ayarlarının optimize edilmesi',
      'savings': 2200,
      'priority': 'medium',
      'confidence': 0.78,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: CustomScrollView(
        slivers: [
          // Large Title AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Enerji Analitik',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: AppleTheme.systemGreen),
                    const SizedBox(width: 4),
                    Text(
                      'AI Aktif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppleTheme.systemGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Period Selector
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray6,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: _periods.asMap().entries.map((entry) {
                  final isSelected = _selectedPeriod == entry.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = entry.key),
                      child: AnimatedContainer(
                        duration: AppleTheme.normalAnimation,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppleTheme.label : AppleTheme.secondaryLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Stats
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _animation.value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam Maliyet',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppleTheme.secondaryLabel,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppleTheme.systemGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 14, color: AppleTheme.systemGreen),
                              Text(
                                '%1.8',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppleTheme.systemGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '₺193.470',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildEnergyTypeCard(
                          'Elektrik',
                          '${_dashboardData['electricity']['value']} kWh',
                          '₺${_dashboardData['electricity']['cost']}',
                          _dashboardData['electricity']['change'] as double,
                          Icons.bolt_rounded,
                          AppleTheme.systemBlue,
                        ),
                        const SizedBox(width: 12),
                        _buildEnergyTypeCard(
                          'Doğalgaz',
                          '${_dashboardData['gas']['value']} m³',
                          '₺${_dashboardData['gas']['cost']}',
                          _dashboardData['gas']['change'] as double,
                          Icons.local_fire_department_rounded,
                          AppleTheme.systemOrange,
                        ),
                        const SizedBox(width: 12),
                        _buildEnergyTypeCard(
                          'Su',
                          '${_dashboardData['water']['value']} m³',
                          '₺${_dashboardData['water']['cost']}',
                          _dashboardData['water']['change'] as double,
                          Icons.water_drop_rounded,
                          const Color(0xFF5AC8FA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Anomalies Section
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'AI Anomali Tespiti'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _anomalies.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 48, color: AppleTheme.systemGreen),
                          const SizedBox(height: 16),
                          const Text('Anomali tespit edilmedi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : Column(
                      children: _anomalies.asMap().entries.map((entry) {
                        return _buildAnomalyTile(entry.value, isLast: entry.key == _anomalies.length - 1);
                      }).toList(),
                    ),
            ),
          ),

          // AI Recommendations
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'AI Tasarruf Önerileri'),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: _recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
            ),
          ),

          // Carbon Footprint
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppleTheme.systemGreen.withOpacity(0.15),
                    AppleTheme.systemGreen.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppleTheme.systemGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.eco_rounded, color: AppleTheme.systemGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Karbon Ayak İzi',
                          style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                        ),
                        const Text(
                          '25.000 kg CO₂',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '≈ 1.250 ağaç eşdeğeri',
                          style: TextStyle(fontSize: 13, color: AppleTheme.systemGreen),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 14, color: AppleTheme.systemGreen),
                        Text(
                          '3.2%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.systemGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.analytics_rounded,
        label: 'AI Analiz',
        onPressed: () {},
      ),
    );
  }

  Widget _buildEnergyTypeCard(String title, String value, String cost, double change, IconData icon, Color color) {
    final isNegative = change < 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 12,
                  color: isNegative ? AppleTheme.systemGreen : AppleTheme.systemRed,
                ),
                Text(
                  '${change.abs()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isNegative ? AppleTheme.systemGreen : AppleTheme.systemRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyTile(Map<String, dynamic> anomaly, {bool isLast = false}) {
    final severity = anomaly['severity'] as String;
    Color severityColor;
    switch (severity) {
      case 'high':
        severityColor = AppleTheme.systemRed;
        break;
      case 'medium':
        severityColor = AppleTheme.systemOrange;
        break;
      default:
        severityColor = AppleTheme.systemBlue;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_rounded, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anomaly['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(anomaly['description'], style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                  ],
                ),
              ),
              Text(anomaly['time'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final priority = rec['priority'] as String;
    final confidence = rec['confidence'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: priority == 'high'
                  ? AppleTheme.systemGreen.withOpacity(0.12)
                  : AppleTheme.systemBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: priority == 'high' ? AppleTheme.systemGreen : AppleTheme.systemBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(rec['description'], style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'AI Güven: %${(confidence * 100).toInt()}',
                      style: TextStyle(fontSize: 12, color: AppleTheme.systemGreen, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${rec['savings']}/ay',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppleTheme.systemGreen),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priority == 'high' ? AppleTheme.systemRed.withOpacity(0.12) : AppleTheme.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority == 'high' ? 'Yüksek' : 'Orta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: priority == 'high' ? AppleTheme.systemRed : AppleTheme.systemOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
