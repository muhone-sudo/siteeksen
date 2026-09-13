// Enerji tüketim analitiği panosu.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekranın tamamı uydurmaydı: sabit "₺193.470 toplam maliyet", 45.200 kWh elektrik,
// 1.200 m³ doğalgaz, 850 m³ su, iki uydurma anomali ("Havuz Sayacı Anomalisi"),
// iki uydurma tasarruf önerisi ("AI Güven: %92") ve sabit "25.000 kg CO₂" karbon
// ayak izi. Dönem seçici (Bu Ay / Son 3 Ay …) hiçbir şeyi değiştirmiyordu; "AI Aktif"
// rozeti ve "AI Analiz" düğmesi var olmayan bir yeteneği duyuruyordu.
//
// Artık veriler `apiClient.getEnergySummary()` ve `apiClient.getEnergyConsumption(period:)`
// ile alınıyor; dönem seçici gerçekten yeni istek atıyor. Anomali, öneri ve karbon
// bölümleri yalnızca sunucu o alanı gerçekten döndürdüğünde çizilir — veri yoksa
// bölüm hiç gösterilmez, uydurulmaz. Sunucu 501 dönerse `NotImplementedNotice`,
// başka hata olursa `ErrorStateView` gösterilir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

/// Enerji Analitik Dashboard
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

  /// Görünen etiket → sunucuya gönderilen `period` değeri.
  static const List<MapEntry<String, String>> _periods = [
    MapEntry('Bu Ay', 'month'),
    MapEntry('Son 3 Ay', '3months'),
    MapEntry('Son 6 Ay', '6months'),
    MapEntry('Bu Yıl', 'year'),
  ];

  bool _loading = true;
  Object? _error;
  Map<String, dynamic> _summary = const {};
  List<Map<String, dynamic>> _consumption = const [];

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
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await apiClient.getEnergySummary();
      final consumption = await apiClient.getEnergyConsumption(
          period: _periods[_selectedPeriod].value);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _consumption = consumption
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Özet gövdesinde bölüm arama: alanlar kök seviyede ya da `current_month`
  /// gibi bir sarmalayıcının içinde gelebiliyor.
  Map<String, dynamic>? _section(List<String> keys) {
    for (final container in [
      _summary,
      _summary['current_month'],
      _summary['current'],
      _summary['totals'],
    ]) {
      if (container is Map) {
        for (final key in keys) {
          final v = container[key];
          if (v is Map) return Map<String, dynamic>.from(v);
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>>? _listSection(List<String> keys) {
    for (final key in keys) {
      final v = _summary[key];
      if (v is List) {
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

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
              // "AI Aktif" rozeti kaldırıldı: böyle bir çözümleme çalışmıyor.
              // Yerine gerçek bir iş yapan yenileme düğmesi kondu.
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                tooltip: 'Yenile',
              ),
            ],
          ),
          ..._buildBody(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
              height: 320, child: LoadingView(message: 'Tüketim verisi alınıyor...')),
        ),
      ];
    }

    if (_error != null && isNotImplemented(_error!)) {
      return const [
        SliverToBoxAdapter(
          child: NotImplementedNotice(
            title: 'Enerji analitiği henüz hazır değil',
            detail:
                'Tüketim, anomali ve tasarruf önerileri için sunucu tarafı veri katmanına '
                'bağlanmadı. Sayaç okumaları işlenmeye başladığında bu ekran gerçek '
                'tüketimi gösterecek.',
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: ErrorStateView(message: toUserMessage(_error!), onRetry: _load),
          ),
        ),
      ];
    }

    final electricity = _section(const ['electricity', 'elektrik']);
    final gas = _section(const ['gas', 'natural_gas', 'dogalgaz']);
    final water = _section(const ['water', 'su']);
    final anomalies = _listSection(const ['anomalies', 'recent_anomalies']);
    final recommendations =
        _listSection(const ['recommendations', 'top_recommendations']);
    final carbon = _section(const ['carbon_footprint', 'carbon']);

    final hasAnything = _summary.isNotEmpty || _consumption.isNotEmpty;
    if (!hasAnything) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: EmptyStateView(
              message: 'Seçili dönem için tüketim verisi yok.',
              icon: Icons.bolt_rounded,
            ),
          ),
        ),
      ];
    }

    return [
      _buildPeriodSelector(),
      _buildTotalsCard(electricity, gas, water),
      if (_consumption.isNotEmpty) ...[
        const SliverToBoxAdapter(child: AppleSectionHeader(title: 'Dönem Tüketimi')),
        SliverToBoxAdapter(child: _buildConsumptionList()),
      ],
      if (anomalies != null) ...[
        const SliverToBoxAdapter(child: AppleSectionHeader(title: 'Anomali Tespiti')),
        SliverToBoxAdapter(child: _buildAnomaliesCard(anomalies)),
      ],
      if (recommendations != null && recommendations.isNotEmpty) ...[
        const SliverToBoxAdapter(child: AppleSectionHeader(title: 'Tasarruf Önerileri')),
        SliverToBoxAdapter(
          child: Column(
            children: recommendations.map(_buildRecommendationCard).toList(),
          ),
        ),
      ],
      if (carbon != null) SliverToBoxAdapter(child: _buildCarbonCard(carbon)),
    ];
  }

  Widget _buildPeriodSelector() {
    return SliverToBoxAdapter(
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
                // Dönem değişimi artık gerçekten yeni veri çeker.
                onTap: () {
                  if (isSelected) return;
                  setState(() => _selectedPeriod = entry.key);
                  _load();
                },
                child: AnimatedContainer(
                  duration: AppleTheme.normalAnimation,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      entry.value.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppleTheme.label
                            : AppleTheme.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalsCard(
    Map<String, dynamic>? electricity,
    Map<String, dynamic>? gas,
    Map<String, dynamic>? water,
  ) {
    // Toplam maliyet sunucudan gelmiyorsa türlerin maliyetinden toplanır;
    // o da yoksa "—" yazılır, uydurma rakam basılmaz.
    double? totalCost = _number(_summary, const ['total_cost', 'totalCost', 'cost']);
    if (totalCost == null) {
      final parts = [electricity, gas, water]
          .whereType<Map<String, dynamic>>()
          .map((m) => _number(m, const ['cost', 'total_cost', 'amount']))
          .whereType<double>()
          .toList();
      if (parts.isNotEmpty) totalCost = parts.reduce((a, b) => a + b);
    }
    final totalChange =
        _number(_summary, const ['change', 'change_percent', 'cost_change']);

    return SliverToBoxAdapter(
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
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 20),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam Maliyet',
                      style:
                          TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  if (totalChange != null) _buildChangeBadge(totalChange),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  totalCost == null ? '—' : formatTry(totalCost),
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1),
                ),
              ),
              if (electricity != null || gas != null || water != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (electricity != null)
                      _buildEnergyTypeCard('Elektrik', electricity,
                          Icons.bolt_rounded, AppleTheme.systemBlue, 'kWh'),
                    if (electricity != null && (gas != null || water != null))
                      const SizedBox(width: 12),
                    if (gas != null)
                      _buildEnergyTypeCard('Doğalgaz', gas,
                          Icons.local_fire_department_rounded,
                          AppleTheme.systemOrange, 'm³'),
                    if (gas != null && water != null) const SizedBox(width: 12),
                    if (water != null)
                      _buildEnergyTypeCard('Su', water, Icons.water_drop_rounded,
                          const Color(0xFF5AC8FA), 'm³'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeBadge(double change) {
    final isDown = change < 0;
    final color = isDown ? AppleTheme.systemGreen : AppleTheme.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 14, color: color),
          Text('%${formatNumber(change.abs())}',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildEnergyTypeCard(String title, Map<String, dynamic> data,
      IconData icon, Color color, String fallbackUnit) {
    final value = _number(data, const ['value', 'consumption', 'amount', 'total']);
    final unit = _text(data, const ['unit']) ?? fallbackUnit;
    final change = _number(data, const ['change', 'change_percent']);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title,
                style:
                    TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value == null ? '—' : '${formatNumber(value)} $unit',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    change < 0
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 12,
                    color:
                        change < 0 ? AppleTheme.systemGreen : AppleTheme.systemRed,
                  ),
                  Flexible(
                    child: Text(
                      '${formatNumber(change.abs())}%',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: change < 0
                            ? AppleTheme.systemGreen
                            : AppleTheme.systemRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _consumption.asMap().entries.map((entry) {
          final row = entry.value;
          final label = _text(row, const ['period', 'label', 'month', 'name']) ??
              formatDate(row['date'] ?? row['reading_date']);
          final value = _number(row, const ['value', 'consumption', 'amount']);
          final unit = _text(row, const ['unit']) ?? '';
          final cost = _number(row, const ['cost', 'total_cost']);
          final isLast = entry.key == _consumption.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                    if (value != null)
                      Text('${formatNumber(value)} $unit'.trim(),
                          style: TextStyle(
                              fontSize: 14, color: AppleTheme.secondaryLabel)),
                    if (cost != null) ...[
                      const SizedBox(width: 12),
                      Text(formatTry(cost),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child:
                      Container(height: 0.5, color: AppleTheme.opaqueSeparator),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnomaliesCard(List<Map<String, dynamic>> anomalies) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: anomalies.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 48, color: AppleTheme.systemGreen),
                  const SizedBox(height: 16),
                  const Text('Anomali tespit edilmedi',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : Column(
              children: anomalies.asMap().entries.map((entry) {
                return _buildAnomalyTile(entry.value,
                    isLast: entry.key == anomalies.length - 1);
              }).toList(),
            ),
    );
  }

  Widget _buildAnomalyTile(Map<String, dynamic> anomaly, {bool isLast = false}) {
    final severity = (_text(anomaly, const ['severity', 'level']) ?? '').toLowerCase();
    Color severityColor;
    switch (severity) {
      case 'high':
      case 'critical':
        severityColor = AppleTheme.systemRed;
        break;
      case 'medium':
        severityColor = AppleTheme.systemOrange;
        break;
      default:
        severityColor = AppleTheme.systemBlue;
    }
    final detectedAt = anomaly['detected_at'] ?? anomaly['created_at'] ?? anomaly['time'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_rounded, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _text(anomaly, const ['title', 'name']) ??
                            'Adsız anomali',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        _text(anomaly, const ['description', 'detail']) ?? '—',
                        style: TextStyle(
                            fontSize: 13, color: AppleTheme.secondaryLabel)),
                  ],
                ),
              ),
              if (detectedAt != null)
                Text(formatDate(detectedAt),
                    style:
                        TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
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
    final priority = (_text(rec, const ['priority']) ?? '').toLowerCase();
    final isHigh = priority == 'high';
    final savings = _number(rec, const ['savings', 'monthly_savings', 'amount']);
    final confidence = _number(rec, const ['confidence', 'score']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isHigh ? AppleTheme.systemGreen : AppleTheme.systemBlue)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: isHigh ? AppleTheme.systemGreen : AppleTheme.systemBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_text(rec, const ['title', 'name']) ?? 'Adsız öneri',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_text(rec, const ['description', 'detail']) ?? '—',
                    style: TextStyle(
                        fontSize: 13, color: AppleTheme.secondaryLabel)),
                if (confidence != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Güven: %${(confidence <= 1 ? confidence * 100 : confidence).round()}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppleTheme.systemGreen,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          if (savings != null || priority.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (savings != null)
                  Text(
                    '${formatTry(savings)}/ay',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppleTheme.systemGreen),
                  ),
                if (priority.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isHigh
                              ? AppleTheme.systemRed
                              : AppleTheme.systemOrange)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isHigh ? 'Yüksek' : 'Orta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isHigh
                            ? AppleTheme.systemRed
                            : AppleTheme.systemOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCarbonCard(Map<String, dynamic> carbon) {
    final value = _number(carbon, const ['value', 'total', 'co2_kg', 'amount']);
    final unit = _text(carbon, const ['unit']) ?? 'kg CO₂';
    final trees = _number(carbon, const ['tree_equivalent', 'trees']);
    final change = _number(carbon, const ['change', 'change_percent']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppleTheme.systemGreen.withValues(alpha: 0.15),
            AppleTheme.systemGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppleTheme.systemGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppleTheme.systemGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco_rounded, color: AppleTheme.systemGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Karbon Ayak İzi',
                    style:
                        TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                Text(value == null ? '—' : '${formatNumber(value)} $unit',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                if (trees != null)
                  Text('≈ ${formatNumber(trees)} ağaç eşdeğeri',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.systemGreen)),
              ],
            ),
          ),
          if (change != null) _buildChangeBadge(change),
        ],
      ),
    );
  }
}

String? _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

double? _number(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
