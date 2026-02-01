import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Enerji Tüketimi Mobil Ekranı - Apple Tarzı
class EnergyConsumptionMobileScreen extends StatefulWidget {
  const EnergyConsumptionMobileScreen({super.key});

  @override
  State<EnergyConsumptionMobileScreen> createState() => _EnergyConsumptionMobileScreenState();
}

class _EnergyConsumptionMobileScreenState extends State<EnergyConsumptionMobileScreen> {
  String _selectedPeriod = 'month';

  final Map<String, dynamic> _currentUsage = {
    'electricity': {'current': 245, 'previous': 280, 'unit': 'kWh', 'cost': 612.50},
    'gas': {'current': 78, 'previous': 95, 'unit': 'm³', 'cost': 312.00},
    'water': {'current': 12, 'previous': 15, 'unit': 'm³', 'cost': 96.00},
  };

  final List<Map<String, dynamic>> _monthlyTrend = [
    {'month': 'Ağu', 'electricity': 320, 'gas': 45, 'water': 18},
    {'month': 'Eyl', 'electricity': 290, 'gas': 55, 'water': 16},
    {'month': 'Eki', 'electricity': 310, 'gas': 75, 'water': 14},
    {'month': 'Kas', 'electricity': 280, 'gas': 90, 'water': 13},
    {'month': 'Ara', 'electricity': 265, 'gas': 110, 'water': 12},
    {'month': 'Oca', 'electricity': 245, 'gas': 78, 'water': 12},
  ];

  final List<Map<String, dynamic>> _tips = [
    {'text': 'LED ampuller kullanarak elektrik tüketiminizi %30 azaltabilirsiniz.', 'icon': Icons.lightbulb_outline_rounded},
    {'text': 'Termostat sıcaklığını 1°C düşürmek %6 enerji tasarrufu sağlar.', 'icon': Icons.thermostat_rounded},
    {'text': 'Duşta geçirdiğiniz süreyi kısaltarak su tasarrufu yapın.', 'icon': Icons.water_drop_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final totalCost = (_currentUsage['electricity']['cost'] as double) +
        (_currentUsage['gas']['cost'] as double) +
        (_currentUsage['water']['cost'] as double);

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
                    const Expanded(child: Text('Enerji Tüketimi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Total Cost Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppleTheme.systemBlue, AppleTheme.systemPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bu Ay Toplam', style: TextStyle(color: Colors.white70)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_down_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                const Text('%12 tasarruf', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('₺${totalCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Geçen aya göre ₺156.50 daha az', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

            // Period Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildPeriodChip('Hafta', 'week'),
                    _buildPeriodChip('Ay', 'month'),
                    _buildPeriodChip('Yıl', 'year'),
                  ],
                ),
              ),
            ),

            // Usage Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildUsageCard('Elektrik', _currentUsage['electricity'], Icons.bolt_rounded, AppleTheme.systemYellow),
                    const SizedBox(height: 12),
                    _buildUsageCard('Doğalgaz', _currentUsage['gas'], Icons.local_fire_department_rounded, AppleTheme.systemOrange),
                    const SizedBox(height: 12),
                    _buildUsageCard('Su', _currentUsage['water'], Icons.water_drop_rounded, AppleTheme.systemBlue),
                  ],
                ),
              ),
            ),

            // Trend Chart Placeholder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppleTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('6 Aylık Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _monthlyTrend.map((m) {
                            final value = (m['electricity'] as int) / 320;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 24,
                                  height: 80 * value,
                                  decoration: BoxDecoration(
                                    color: AppleTheme.systemBlue.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(m['month'], style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tips
            const SliverToBoxAdapter(child: AppleSectionTitle(title: 'Tasarruf İpuçları')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppleTheme.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppleTheme.systemGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_tips[index]['icon'], color: AppleTheme.systemGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_tips[index]['text'], style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel))),
                      ],
                    ),
                  ),
                ),
                childCount: _tips.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: AnimatedContainer(
          duration: AppleTheme.fastAnimation,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppleTheme.systemBlue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppleTheme.systemBlue : AppleTheme.systemGray5),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppleTheme.label, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildUsageCard(String title, Map<String, dynamic> data, IconData icon, Color color) {
    final current = data['current'] as int;
    final previous = data['previous'] as int;
    final change = ((current - previous) / previous * 100);
    final isDecrease = change < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$current ${data['unit']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDecrease ? AppleTheme.systemGreen : AppleTheme.systemRed).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDecrease ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            size: 12,
                            color: isDecrease ? AppleTheme.systemGreen : AppleTheme.systemRed,
                          ),
                          Text(
                            '${change.abs().toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 11, color: isDecrease ? AppleTheme.systemGreen : AppleTheme.systemRed, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₺${(data['cost'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              Text('tahmini', style: TextStyle(fontSize: 11, color: AppleTheme.tertiaryLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
