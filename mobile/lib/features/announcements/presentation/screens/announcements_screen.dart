import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Duyurular Ekranı - Apple Tarzı
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final List<Map<String, dynamic>> _announcements = [
    {
      'id': '1',
      'title': 'Su Kesintisi Duyurusu',
      'content': 'Yarın saat 10:00-14:00 arasında ana boru hattı bakımı nedeniyle su kesintisi yapılacaktır. Lütfen gerekli tedbirleri alınız.',
      'date': '1 Şubat 2026',
      'time': '10:30',
      'type': 'alert',
      'isRead': false,
      'isPinned': true,
    },
    {
      'id': '2',
      'title': 'Genel Kurul Toplantısı',
      'content': 'Yıllık olağan genel kurul toplantısı 15 Şubat 2026 tarihinde saat 14:00\'te site toplantı salonunda gerçekleştirilecektir.',
      'date': '28 Ocak 2026',
      'time': '15:00',
      'type': 'event',
      'isRead': true,
      'isPinned': true,
    },
    {
      'id': '3',
      'title': 'Otopark Düzenlemesi',
      'content': 'Site otopark alanlarının yeniden düzenlenmesi çalışmaları başlamıştır. Detaylı bilgi için yönetimimize başvurabilirsiniz.',
      'date': '25 Ocak 2026',
      'time': '09:00',
      'type': 'info',
      'isRead': true,
      'isPinned': false,
    },
    {
      'id': '4',
      'title': 'Aidat Hatırlatması',
      'content': 'Şubat ayı aidat son ödeme tarihi 15 Şubat 2026\'dır. Geç ödemelerde %2 gecikme faizi uygulanacaktır.',
      'date': '20 Ocak 2026',
      'time': '11:00',
      'type': 'payment',
      'isRead': true,
      'isPinned': false,
    },
  ];

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'alert': return Icons.warning_rounded;
      case 'event': return Icons.event_rounded;
      case 'payment': return Icons.payment_rounded;
      default: return Icons.info_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'alert': return AppleTheme.systemOrange;
      case 'event': return AppleTheme.systemPurple;
      case 'payment': return AppleTheme.systemGreen;
      default: return AppleTheme.systemBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinnedAnnouncements = _announcements.where((a) => a['isPinned'] == true).toList();
    final regularAnnouncements = _announcements.where((a) => a['isPinned'] != true).toList();

    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Duyurular'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Tümünü Oku'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Pinned Announcements
          if (pinnedAnnouncements.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionTitle(title: 'Sabitlenmiş'),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppleTheme.cardDecoration,
                child: Column(
                  children: pinnedAnnouncements.asMap().entries.map((entry) {
                    return _buildAnnouncementTile(entry.value, isLast: entry.key == pinnedAnnouncements.length - 1);
                  }).toList(),
                ),
              ),
            ),
          ],

          // Regular Announcements
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Tüm Duyurular'),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppleTheme.cardDecoration,
              child: Column(
                children: regularAnnouncements.asMap().entries.map((entry) {
                  return _buildAnnouncementTile(entry.value, isLast: entry.key == regularAnnouncements.length - 1);
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementTile(Map<String, dynamic> announcement, {bool isLast = false}) {
    final icon = _getTypeIcon(announcement['type'] as String);
    final color = _getTypeColor(announcement['type'] as String);
    final isUnread = announcement['isRead'] != true;

    return Column(
      children: [
        InkWell(
          onTap: () => _showAnnouncementDetail(context, announcement),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (announcement['isPinned'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.push_pin_rounded, size: 16, color: AppleTheme.systemOrange),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement['content'] as String,
                        style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement['date']} ${announcement['time']}',
                            style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                          ),
                          if (isUnread) ...[
                            const Spacer(),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppleTheme.systemBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
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
            padding: const EdgeInsets.only(left: 72),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  void _showAnnouncementDetail(BuildContext context, Map<String, dynamic> announcement) {
    final icon = _getTypeIcon(announcement['type'] as String);
    final color = _getTypeColor(announcement['type'] as String);

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
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['title'] as String,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${announcement['date']} ${announcement['time']}',
                              style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    announcement['content'] as String,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Paylaş'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Okundu'),
                        ),
                      ),
                    ],
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
