import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// AI Toplantı Sihirbazı Ekranı - Apple Tarzı
class MeetingWizardScreen extends StatefulWidget {
  const MeetingWizardScreen({super.key});

  @override
  State<MeetingWizardScreen> createState() => _MeetingWizardScreenState();
}

class _MeetingWizardScreenState extends State<MeetingWizardScreen> {
  final List<Map<String, dynamic>> _meetings = [
    {
      'id': '1',
      'title': 'Ocak Ayı Yönetim Kurulu Toplantısı',
      'date': '2026-01-28',
      'duration': '45 dakika',
      'status': 'transcribed',
      'participants': 5,
      'decisions': 3,
      'actionItems': 5,
      'hasRecording': true,
    },
    {
      'id': '2',
      'title': 'Bütçe Değerlendirme Toplantısı',
      'date': '2026-01-25',
      'duration': '30 dakika',
      'status': 'transcribed',
      'participants': 4,
      'decisions': 2,
      'actionItems': 3,
      'hasRecording': true,
    },
    {
      'id': '3',
      'title': 'Güvenlik Değerlendirmesi',
      'date': '2026-01-20',
      'duration': '25 dakika',
      'status': 'pending',
      'participants': 3,
      'decisions': 0,
      'actionItems': 0,
      'hasRecording': true,
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
                'Toplantı Sihirbazı',
                style: TextStyle(
                  fontSize: 26,
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
                  color: AppleTheme.systemPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: AppleTheme.systemPurple),
                    const SizedBox(width: 4),
                    Text('AI Destekli', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.systemPurple)),
                  ],
                ),
              ),
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
                  _buildMiniStat('Toplantı', '${_meetings.length}', Icons.groups_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Karar', '${_meetings.fold<int>(0, (sum, m) => sum + (m['decisions'] as int))}', 
                      Icons.gavel_rounded, AppleTheme.systemGreen),
                  _buildMiniStat('Görev', '${_meetings.fold<int>(0, (sum, m) => sum + (m['actionItems'] as int))}', 
                      Icons.task_rounded, AppleTheme.systemOrange),
                ],
              ),
            ),
          ),

          // AI Features Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppleTheme.systemPurple.withOpacity(0.15), AppleTheme.systemBlue.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: AppleTheme.systemPurple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Özellikleri', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            Text('Toplantılarınızı akıllıca yönetin', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAIFeatureChip(Icons.mic_rounded, 'Transkripsiyon'),
                      const SizedBox(width: 8),
                      _buildAIFeatureChip(Icons.summarize_rounded, 'Özet'),
                      const SizedBox(width: 8),
                      _buildAIFeatureChip(Icons.task_alt_rounded, 'Görevler'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Meetings List
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Son Toplantılar'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _meetings.asMap().entries.map((entry) {
                  return _buildMeetingTile(entry.value, isLast: entry.key == _meetings.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.mic_rounded,
        label: 'Kayıt Başlat',
        onPressed: () => _showRecordingSheet(context),
      ),
    );
  }

  Widget _buildAIFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppleTheme.systemPurple),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

  Widget _buildMeetingTile(Map<String, dynamic> meeting, {bool isLast = false}) {
    final isTranscribed = meeting['status'] == 'transcribed';

    return Column(
      children: [
        InkWell(
          onTap: () => _showMeetingDetails(context, meeting),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isTranscribed 
                        ? AppleTheme.systemGreen.withOpacity(0.12)
                        : AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTranscribed ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: isTranscribed ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${meeting['date']} • ${meeting['duration']}',
                        style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                      ),
                      if (isTranscribed)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.gavel_rounded, size: 12, color: AppleTheme.systemGreen),
                              Text(' ${meeting['decisions']} karar', style: TextStyle(fontSize: 12, color: AppleTheme.systemGreen)),
                              const SizedBox(width: 8),
                              Icon(Icons.task_rounded, size: 12, color: AppleTheme.systemBlue),
                              Text(' ${meeting['actionItems']} görev', style: TextStyle(fontSize: 12, color: AppleTheme.systemBlue)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppleTheme.tertiaryLabel),
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

  void _showMeetingDetails(BuildContext context, Map<String, dynamic> meeting) {
    final isTranscribed = meeting['status'] == 'transcribed';

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
                  Text(meeting['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${meeting['date']} • ${meeting['duration']} • ${meeting['participants']} katılımcı',
                      style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 24),
                  if (isTranscribed) ...[
                    _buildSectionCard('Özet', Icons.summarize_rounded, AppleTheme.systemPurple,
                        'Toplantıda otopark düzenlemesi, güvenlik önlemleri ve bütçe konuları görüşüldü. 3 önemli karar alındı.'),
                    const SizedBox(height: 16),
                    _buildSectionCard('Kararlar', Icons.gavel_rounded, AppleTheme.systemGreen,
                        '• Otopark genişletme projesi onaylandı\n• Güvenlik kameraları yenilenecek\n• Aidat artışı %10 olarak belirlendi'),
                    const SizedBox(height: 16),
                    _buildSectionCard('Görevler', Icons.task_alt_rounded, AppleTheme.systemBlue,
                        '• Otopark projesi teklif toplama (Ahmet Bey)\n• Kamera teklifleri değerlendirme (Mehmet Bey)\n• Aidat bilgilendirmesi (Yönetim)'),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemGray6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.pending_rounded, size: 48, color: AppleTheme.systemOrange),
                          const SizedBox(height: 16),
                          const Text('Transkripsiyon Bekliyor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('AI işlemi tamamlandığında özet ve kararlar görüntülenecek',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('AI ile Analiz Et'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  void _showRecordingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
            const SizedBox(height: 20),
            const Text('Yeni Toplantı Kaydı', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppleTheme.systemRed.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, size: 48, color: AppleTheme.systemRed),
            ),
            const SizedBox(height: 16),
            const Text('00:00', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fiber_manual_record_rounded),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemRed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
