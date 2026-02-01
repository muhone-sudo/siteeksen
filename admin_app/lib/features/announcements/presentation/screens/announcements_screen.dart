import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = [
      _Announcement(id: '1', title: 'Aylık Aidat Hatırlatması', content: 'Şubat ayı aidatlarının son ödeme tarihi 15 Şubat\'tır.', date: '01.02.2026', isPinned: true),
      _Announcement(id: '2', title: 'Asansör Bakımı', content: 'A ve B blok asansörleri 5 Şubat\'ta bakıma alınacaktır.', date: '30.01.2026', isPinned: false),
      _Announcement(id: '3', title: 'Otopark Düzenlemesi', content: 'Misafir otoparkı yeni düzenleme ile A blok önüne taşınmıştır.', date: '28.01.2026', isPinned: false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final item = announcements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isPinned) ...[
                          const Icon(Icons.push_pin, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                            const PopupMenuItem(value: 'pin', child: Text('Sabitle')),
                            const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.content, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(item.date, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.visibility, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Text('85 görüntüleme', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/announcements/create'),
        icon: const Icon(Icons.add),
        label: const Text('Duyuru Yayınla'),
      ),
    );
  }
}

class _Announcement {
  final String id;
  final String title;
  final String content;
  final String date;
  final bool isPinned;
  _Announcement({required this.id, required this.title, required this.content, required this.date, required this.isPinned});
}
