import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// AI Akıllı Tahsilat Dashboard - Apple Tarzı
class SmartCollectionScreen extends StatefulWidget {
  const SmartCollectionScreen({super.key});

  @override
  State<SmartCollectionScreen> createState() => _SmartCollectionScreenState();
}

class _SmartCollectionScreenState extends State<SmartCollectionScreen> {
  int _selectedRiskLevel = 0;

  final List<String> _riskFilters = ['Tümü', 'Yüksek Risk', 'Orta Risk', 'Düşük Risk'];

  final Map<String, dynamic> _collectionStats = {
    'totalDebt': 245000,
    'collected': 180000,
    'pending': 65000,
    'collectionRate': 73.5,
  };

  final List<Map<String, dynamic>> _debts = [
    {
      'id': '1',
      'resident': 'Ahmet Yılmaz',
      'unit': 'D.105',
      'amount': 8500,
      'daysOverdue': 120,
      'riskScore': 85,
      'riskLevel': 'high',
      'phone': '0532 111 2233',
      'lastPayment': '2025-09-15',
      'aiStrategy': 'Hukuki işlem önerilir',
    },
    {
      'id': '2',
      'resident': 'Fatma Demir',
      'unit': 'D.208',
      'amount': 4200,
      'daysOverdue': 60,
      'riskScore': 55,
      'riskLevel': 'medium',
      'phone': '0533 222 3344',
      'lastPayment': '2025-11-20',
      'aiStrategy': 'Taksitlendirme teklifi yapılabilir',
    },
    {
      'id': '3',
      'resident': 'Ali Kaya',
      'unit': 'D.312',
      'amount': 1800,
      'daysOverdue': 15,
      'riskScore': 25,
      'riskLevel': 'low',
      'phone': '0534 333 4455',
      'lastPayment': '2025-12-10',
      'aiStrategy': 'Hatırlatma SMS yeterli',
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
                'Akıllı Tahsilat',
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
                  color: AppleTheme.systemIndigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded, size: 16, color: AppleTheme.systemIndigo),
                    const SizedBox(width: 4),
                    Text('AI Risk Analizi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.systemIndigo)),
                  ],
                ),
              ),
            ],
          ),

          // Main Stats Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tahsilat Oranı', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up_rounded, size: 14, color: AppleTheme.systemGreen),
                            const SizedBox(width: 4),
                            Text('+5.2%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.systemGreen)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('%${_collectionStats['collectionRate'].toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -1)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _collectionStats['collectionRate'] / 100,
                      backgroundColor: AppleTheme.systemGray6,
                      valueColor: AlwaysStoppedAnimation<Color>(AppleTheme.systemGreen),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatColumn('Toplam Alacak', '₺${_formatNumber(_collectionStats['totalDebt'])}')),
                      Container(width: 1, height: 40, color: AppleTheme.opaqueSeparator),
                      Expanded(child: _buildStatColumn('Tahsil Edilen', '₺${_formatNumber(_collectionStats['collected'])}')),
                      Container(width: 1, height: 40, color: AppleTheme.opaqueSeparator),
                      Expanded(child: _buildStatColumn('Bekleyen', '₺${_formatNumber(_collectionStats['pending'])}')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Risk Filters
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _riskFilters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedRiskLevel == index;
                  Color? chipColor;
                  if (index == 1) chipColor = AppleTheme.systemRed;
                  if (index == 2) chipColor = AppleTheme.systemOrange;
                  if (index == 3) chipColor = AppleTheme.systemGreen;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_riskFilters[index]),
                      onSelected: (selected) => setState(() => _selectedRiskLevel = index),
                      backgroundColor: Colors.white,
                      selectedColor: (chipColor ?? AppleTheme.systemBlue).withOpacity(0.15),
                      checkmarkColor: chipColor ?? AppleTheme.systemBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? (chipColor ?? AppleTheme.systemBlue) : AppleTheme.label,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // AI Actions Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppleTheme.systemIndigo.withOpacity(0.15), AppleTheme.systemPurple.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: AppleTheme.systemIndigo),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Tahsilat Önerileri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('3 borçlu için önerilen aksiyonlar mevcut', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Görüntüle')),
                ],
              ),
            ),
          ),

          // Debts List
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Risk Analizi'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredDebts.asMap().entries.map((entry) {
                  return _buildDebtTile(entry.value, isLast: entry.key == _filteredDebts.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.send_rounded,
        label: 'Toplu SMS',
        onPressed: () {},
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredDebts {
    if (_selectedRiskLevel == 0) return _debts;
    final riskMap = {1: 'high', 2: 'medium', 3: 'low'};
    return _debts.where((d) => d['riskLevel'] == riskMap[_selectedRiskLevel]).toList();
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
      ],
    );
  }

  Widget _buildDebtTile(Map<String, dynamic> debt, {bool isLast = false}) {
    Color riskColor;
    String riskText;
    switch (debt['riskLevel']) {
      case 'high':
        riskColor = AppleTheme.systemRed;
        riskText = 'Yüksek';
        break;
      case 'medium':
        riskColor = AppleTheme.systemOrange;
        riskText = 'Orta';
        break;
      default:
        riskColor = AppleTheme.systemGreen;
        riskText = 'Düşük';
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _showDebtDetails(context, debt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Risk Score Indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${debt['riskScore']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: riskColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(debt['resident'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(riskText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: riskColor)),
                          ),
                        ],
                      ),
                      Text('${debt['unit']} • ${debt['daysOverdue']} gün gecikme',
                          style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₺${_formatNumber(debt['amount'])}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: riskColor)),
                    Text('gecikmiş', style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
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

  void _showDebtDetails(BuildContext context, Map<String, dynamic> debt) {
    Color riskColor;
    switch (debt['riskLevel']) {
      case 'high': riskColor = AppleTheme.systemRed; break;
      case 'medium': riskColor = AppleTheme.systemOrange; break;
      default: riskColor = AppleTheme.systemGreen;
    }

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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${debt['riskScore']}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: riskColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(debt['resident'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            Text(debt['unit'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // AI Strategy Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemIndigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppleTheme.systemIndigo.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.psychology_rounded, color: AppleTheme.systemIndigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Öneri', style: TextStyle(fontSize: 13, color: AppleTheme.systemIndigo, fontWeight: FontWeight.w600)),
                              Text(debt['aiStrategy'], style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInfoRow(Icons.monetization_on_rounded, 'Borç Tutarı', '₺${_formatNumber(debt['amount'])}'),
                  _buildInfoRow(Icons.schedule_rounded, 'Gecikme', '${debt['daysOverdue']} gün'),
                  _buildInfoRow(Icons.phone_rounded, 'Telefon', debt['phone']),
                  _buildInfoRow(Icons.payment_rounded, 'Son Ödeme', debt['lastPayment']),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.sms_rounded),
                          label: const Text('SMS Gönder'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_rounded),
                          label: const Text('Ara'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.gavel_rounded, color: AppleTheme.systemRed),
                      label: Text('Hukuki İşlem Başlat', style: TextStyle(color: AppleTheme.systemRed)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppleTheme.systemRed)),
                    ),
                  ),
                ],
              ),
            ),
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
