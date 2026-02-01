import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Anket/Oylama Yönetim Ekranı - Apple Tarzı
class SurveyManagementScreen extends StatefulWidget {
  const SurveyManagementScreen({super.key});

  @override
  State<SurveyManagementScreen> createState() => _SurveyManagementScreenState();
}

class _SurveyManagementScreenState extends State<SurveyManagementScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _surveys = [
    {
      'id': '1',
      'title': 'Otopark Düzenlemesi Hakkında',
      'type': 'poll',
      'status': 'active',
      'participants': 45,
      'totalVoters': 120,
      'deadline': '2026-02-10',
      'createdAt': '2026-01-25',
    },
    {
      'id': '2',
      'title': 'Site İçi Hız Limiti Değişikliği',
      'type': 'poll',
      'status': 'active',
      'participants': 78,
      'totalVoters': 120,
      'deadline': '2026-02-15',
      'createdAt': '2026-01-28',
    },
    {
      'id': '3',
      'title': 'Memnuniyet Anketi 2026',
      'type': 'survey',
      'status': 'completed',
      'participants': 95,
      'totalVoters': 120,
      'deadline': '2026-01-20',
      'createdAt': '2026-01-01',
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
                'Anketler & Oylamalar',
                style: TextStyle(
                  fontSize: 26,
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
                  _buildMiniStat('Aktif', '2', Icons.how_to_vote_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Katılım', '%62', Icons.groups_rounded, AppleTheme.systemGreen),
                  _buildMiniStat('Tamamlanan', '8', Icons.check_circle_rounded, AppleTheme.systemGray),
                ],
              ),
            ),
          ),

          // Tab Selector
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray6,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab('Oylamalar', 0, Icons.how_to_vote_rounded),
                  _buildTab('Anketler', 1, Icons.poll_rounded),
                ],
              ),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: AppleSectionHeader(
              title: _selectedTab == 0 ? 'Aktif Oylamalar' : 'Anketler',
              action: 'Geçmiş',
            ),
          ),

          // List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredSurveys.asMap().entries.map((entry) {
                  return _buildSurveyTile(entry.value, isLast: entry.key == _filteredSurveys.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: _selectedTab == 0 ? 'Oylama' : 'Anket',
        onPressed: () => _showCreateSheet(context),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSurveys {
    final type = _selectedTab == 0 ? 'poll' : 'survey';
    return _surveys.where((s) => s['type'] == type).toList();
  }

  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: AppleTheme.normalAnimation,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppleTheme.systemBlue : AppleTheme.secondaryLabel),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppleTheme.label : AppleTheme.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildSurveyTile(Map<String, dynamic> survey, {bool isLast = false}) {
    final isActive = survey['status'] == 'active';
    final participation = survey['participants'] / survey['totalVoters'];

    return Column(
      children: [
        InkWell(
          onTap: () => _showSurveyDetails(context, survey),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        survey['title'],
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppleTheme.systemGreen.withOpacity(0.12)
                            : AppleTheme.systemGray.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Tamamlandı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppleTheme.systemGreen : AppleTheme.systemGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: participation,
                    backgroundColor: AppleTheme.systemGray6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? AppleTheme.systemBlue : AppleTheme.systemGray,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 14, color: AppleTheme.secondaryLabel),
                    const SizedBox(width: 4),
                    Text(
                      '${survey['participants']}/${survey['totalVoters']} katılım',
                      style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                    const SizedBox(width: 4),
                    Text(
                      'Son: ${survey['deadline']}',
                      style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel),
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

  void _showSurveyDetails(BuildContext context, Map<String, dynamic> survey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(survey['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemGray6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Katılım', '${((survey['participants'] / survey['totalVoters']) * 100).toInt()}%'),
                        Container(width: 1, height: 40, color: AppleTheme.opaqueSeparator),
                        _buildStatColumn('Oy Sayısı', '${survey['participants']}'),
                        Container(width: 1, height: 40, color: AppleTheme.opaqueSeparator),
                        _buildStatColumn('Toplam', '${survey['totalVoters']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('Sonuçları Görüntüle'),
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
      ],
    );
  }

  void _showCreateSheet(BuildContext context) {
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
                  Text(_selectedTab == 0 ? 'Yeni Oylama' : 'Yeni Anket', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Oluştur')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Başlık', prefixIcon: Icon(Icons.title_rounded)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.description_rounded)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Son Tarih', prefixIcon: Icon(Icons.calendar_today_rounded)),
                    readOnly: true,
                    onTap: () {},
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
