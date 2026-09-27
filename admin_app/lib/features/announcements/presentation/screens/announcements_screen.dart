// Duyuru listesi ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Liste koda gömülü 3 sahte duyurudan ("Aylık Aidat Hatırlatması", "Asansör
// Bakımı", "Otopark Düzenlemesi") oluşuyordu ve her kartın altında sabit
// "85 görüntüleme" yazıyordu. Yönetici, gerçekte yayınlanmış duyuruları göremiyor,
// üstelik var olmayan bir okunma istatistiğine bakıyordu.
//
// Artık liste `GET /announcements` ucundan gelir. Bu uç community servisinde
// henüz gerçek veri katmanına bağlı DEĞİL ve 501 döner; bu durumda sahte kayıt
// göstermek yerine `NotImplementedNotice` ile durum açıkça bildirilir. Uç gerçek
// veriye bağlandığı an ekran hiçbir değişiklik gerektirmeden çalışır.
//
// "Görüntülenme" satırı kaldırıldı: sunucu böyle bir alan üretmiyor.
// "Düzenle" menü öğesi kaldırıldı: uygulamada düzenleme ekranı/rotası yok, menü
// seçildiğinde sessizce hiçbir şey olmuyordu. Kalan iki işlem (sabitle, sil)
// gerçek API çağrılarıdır.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _announcements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiClient.getList('/announcements');
      if (!mounted) return;
      setState(() {
        _announcements = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _togglePin(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty) return;
    final pinned = item['is_pinned'] == true;
    try {
      // DÜZELTME (2026-09-26): `PUT /announcements/:id` diye bir uç yok;
      // sabitleme kendi ucuyla yapılır.
      await apiClient.post('/announcements/$id/pin', {'pinned': !pinned});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pinned ? 'Sabitleme kaldırıldı' : 'Duyuru sabitlendi'),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem yapılamadı: ${toUserMessage(e)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/announcements/create'),
        icon: const Icon(Icons.add),
        label: const Text('Duyuru Yayınla'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Duyurular alınıyor...');
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const SingleChildScrollView(
          child: NotImplementedNotice(
            title: 'Duyurular henüz sunucuda hazır değil',
            detail: 'Duyuru servisi (community.announcements) gerçek veri '
                'katmanına bağlanmadı; sunucu 501 döndürüyor. Gerçek duyuru '
                'listesi hazır olduğunda bu ekran otomatik çalışacaktır.',
          ),
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }
    if (_announcements.isEmpty) {
      return const EmptyStateView(
        message: 'Henüz yayınlanmış duyuru yok.',
        icon: Icons.campaign_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final item = _announcements[index];
          final title = (item['title'] ?? '').toString();
          final content = (item['content'] ?? '').toString();
          final isPinned = item['is_pinned'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        const Icon(Icons.push_pin,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title.isEmpty ? '(başlıksız duyuru)' : title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'pin') _togglePin(item);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(isPinned
                                ? 'Sabitlemeyi kaldır'
                                : 'Sabitle'),
                          ),
                          // Silme ucu sunucuda yok: yayımlanmış duyuru kayıttır;
                          // süresi dolan duyuru `expires_at` ile listeden düşer.
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(content.isEmpty ? '—' : content,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(formatDate(item['created_at']),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const Spacer(),
                      if ((item['category'] ?? '').toString().isNotEmpty)
                        Text(
                          _categoryText(item['category'].toString()),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _categoryText(String category) {
    switch (category) {
      case 'GENERAL':
      case 'INFO':
        return 'Genel';
      case 'FINANCIAL':
        return 'Mali';
      case 'MAINTENANCE':
        return 'Bakım';
      case 'ASSEMBLY':
        return 'Genel Kurul';
      case 'EMERGENCY':
        return 'Acil';
      default:
        return category;
    }
  }
}
