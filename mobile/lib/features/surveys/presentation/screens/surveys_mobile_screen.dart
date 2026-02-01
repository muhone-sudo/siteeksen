import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Anket Listesi ve Oylama Ekranı - Apple Tarzı
class SurveysMobileScreen extends StatefulWidget {
  const SurveysMobileScreen({super.key});

  @override
  State<SurveysMobileScreen> createState() => _SurveysMobileScreenState();
}

class _SurveysMobileScreenState extends State<SurveysMobileScreen> {
  final List<Map<String, dynamic>> _surveys = [
    {
      'id': '1',
      'title': 'Bahçe Yenileme Projesi',
      'description': 'Site bahçesinin yenilenmesi için hangi seçeneği tercih ediyorsunuz?',
      'endDate': '15 Şubat 2026',
      'daysLeft': 14,
      'totalVotes': 128,
      'totalResidents': 200,
      'hasVoted': false,
      'isActive': true,
      'options': [
        {'id': 'a', 'text': 'Çim + Çiçek Bahçesi', 'votes': 52, 'percentage': 40.6},
        {'id': 'b', 'text': 'Çocuk Oyun Alanı', 'votes': 45, 'percentage': 35.2},
        {'id': 'c', 'text': 'Yürüyüş Parkuru', 'votes': 31, 'percentage': 24.2},
      ],
    },
    {
      'id': '2',
      'title': 'Güvenlik Kamerası Yenileme',
      'description': 'Mevcut güvenlik kameralarının yenilenmesi için bütçe ayrılsın mı?',
      'endDate': '10 Şubat 2026',
      'daysLeft': 9,
      'totalVotes': 156,
      'totalResidents': 200,
      'hasVoted': true,
      'votedOption': 'a',
      'isActive': true,
      'options': [
        {'id': 'a', 'text': 'Evet, yenilensin', 'votes': 112, 'percentage': 71.8},
        {'id': 'b', 'text': 'Hayır, gerek yok', 'votes': 44, 'percentage': 28.2},
      ],
    },
    {
      'id': '3',
      'title': 'Genel Kurul Tarihi',
      'description': '2026 Genel Kurulu için hangi tarih sizin için uygundur?',
      'endDate': '5 Şubat 2026',
      'daysLeft': 4,
      'totalVotes': 89,
      'totalResidents': 200,
      'hasVoted': false,
      'isActive': true,
      'isUrgent': true,
      'options': [
        {'id': 'a', 'text': '15 Mart Cumartesi', 'votes': 34, 'percentage': 38.2},
        {'id': 'b', 'text': '22 Mart Cumartesi', 'votes': 28, 'percentage': 31.5},
        {'id': 'c', 'text': '29 Mart Cumartesi', 'votes': 27, 'percentage': 30.3},
      ],
    },
    {
      'id': '4',
      'title': 'Havuz Çalışma Saatleri',
      'description': 'Yaz sezonu havuz çalışma saatleri için tercihiniz?',
      'endDate': '25 Ocak 2026',
      'totalVotes': 167,
      'totalResidents': 200,
      'hasVoted': true,
      'votedOption': 'b',
      'isActive': false,
      'options': [
        {'id': 'a', 'text': '08:00 - 20:00', 'votes': 56, 'percentage': 33.5},
        {'id': 'b', 'text': '09:00 - 21:00', 'votes': 78, 'percentage': 46.7, 'winner': true},
        {'id': 'c', 'text': '10:00 - 22:00', 'votes': 33, 'percentage': 19.8},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeSurveys = _surveys.where((s) => s['isActive'] == true).toList();
    final completedSurveys = _surveys.where((s) => s['isActive'] == false).toList();

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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                    const Expanded(
                      child: Text('Anketler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Stats Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('Aktif Anket', '${activeSurveys.length}', AppleTheme.systemBlue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Oy Verdiğim', '${_surveys.where((s) => s['hasVoted'] == true).length}', AppleTheme.systemGreen)),
                  ],
                ),
              ),
            ),

            // Active Surveys
            if (activeSurveys.isNotEmpty) ...[
              const SliverToBoxAdapter(child: AppleSectionTitle(title: 'Aktif Anketler')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildSurveyCard(activeSurveys[index]),
                  ),
                  childCount: activeSurveys.length,
                ),
              ),
            ],

            // Completed Surveys
            if (completedSurveys.isNotEmpty) ...[
              const SliverToBoxAdapter(child: AppleSectionTitle(title: 'Tamamlanan')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _buildSurveyCard(completedSurveys[index]),
                  ),
                  childCount: completedSurveys.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          Text(title, style: TextStyle(color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey) {
    final hasVoted = survey['hasVoted'] == true;
    final isActive = survey['isActive'] == true;
    final isUrgent = survey['isUrgent'] == true;
    final participation = (survey['totalVotes'] / survey['totalResidents'] * 100).toInt();

    return GestureDetector(
      onTap: () => _showSurveyDetail(context, survey),
      child: Container(
        decoration: AppleTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppleTheme.systemGray5, borderRadius: BorderRadius.circular(6)),
                          child: Text('Tamamlandı', style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel, fontWeight: FontWeight.w600)),
                        )
                      else if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppleTheme.systemRed.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_rounded, size: 12, color: AppleTheme.systemRed),
                              const SizedBox(width: 4),
                              Text('${survey['daysLeft']} gün kaldı', style: TextStyle(fontSize: 11, color: AppleTheme.systemRed, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppleTheme.systemGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text('Aktif', style: TextStyle(fontSize: 11, color: AppleTheme.systemGreen, fontWeight: FontWeight.w600)),
                        ),
                      const Spacer(),
                      if (hasVoted)
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: AppleTheme.systemGreen),
                            const SizedBox(width: 4),
                            Text('Oy verildi', style: TextStyle(fontSize: 12, color: AppleTheme.systemGreen)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(survey['title'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(survey['description'], style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel), maxLines: 2, overflow: TextOverflow.ellipsis),
                  
                  const SizedBox(height: 16),

                  // Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Katılım', style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                                Text('%$participation', style: TextStyle(fontSize: 12, color: AppleTheme.systemBlue, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: participation / 100,
                                backgroundColor: AppleTheme.systemGray5,
                                valueColor: AlwaysStoppedAnimation(AppleTheme.systemBlue),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${survey['totalVotes']}/${survey['totalResidents']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('oy', style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vote Button
            if (isActive && !hasVoted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemBlue.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.how_to_vote_rounded, color: AppleTheme.systemBlue, size: 18),
                    const SizedBox(width: 8),
                    Text('Oy Ver', style: TextStyle(color: AppleTheme.systemBlue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSurveyDetail(BuildContext context, Map<String, dynamic> survey) {
    final hasVoted = survey['hasVoted'] == true;
    final isActive = survey['isActive'] == true;
    final options = survey['options'] as List;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          String? selectedOption;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36, height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Title
                      Text(survey['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(survey['description'], style: TextStyle(color: AppleTheme.secondaryLabel, height: 1.5)),
                      const SizedBox(height: 16),

                      // End Date
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppleTheme.systemGray6, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: AppleTheme.secondaryLabel),
                            const SizedBox(width: 8),
                            Text('Bitiş: ${survey['endDate']}', style: TextStyle(color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      const Text('Seçenekler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      ...options.map((option) {
                        final isVoted = survey['votedOption'] == option['id'];
                        final isWinner = option['winner'] == true;
                        final isSelected = selectedOption == option['id'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: isActive && !hasVoted ? () => setSheetState(() => selectedOption = option['id']) : null,
                            child: AnimatedContainer(
                              duration: AppleTheme.fastAnimation,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppleTheme.systemBlue.withOpacity(0.08) : (isWinner ? AppleTheme.systemGreen.withOpacity(0.08) : AppleTheme.systemGray6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppleTheme.systemBlue : (isWinner ? AppleTheme.systemGreen : Colors.transparent),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(option['text'], style: const TextStyle(fontWeight: FontWeight.w600))),
                                      if (isVoted)
                                        Icon(Icons.check_circle_rounded, color: AppleTheme.systemGreen, size: 20),
                                      if (isWinner)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppleTheme.systemGreen, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Kazanan', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                  if (hasVoted || !isActive) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: option['percentage'] / 100,
                                              backgroundColor: AppleTheme.systemGray5,
                                              valueColor: AlwaysStoppedAnimation(isWinner ? AppleTheme.systemGreen : AppleTheme.systemBlue),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('%${option['percentage'].toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${option['votes']} oy', style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Vote Button
                      if (isActive && !hasVoted)
                        ElevatedButton(
                          onPressed: selectedOption != null ? () {
                            Navigator.pop(context);
                            // Submit vote
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Oyunuz kaydedildi!'),
                                backgroundColor: AppleTheme.systemGreen,
                              ),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Oyu Gönder'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
