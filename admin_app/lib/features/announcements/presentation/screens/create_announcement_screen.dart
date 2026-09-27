// Duyuru yayınlama ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// `_publish()` HİÇBİR ağ çağrısı yapmadan "Duyuru yayınlandı" diyip ekranı
// kapatıyordu. Yönetici duyuruyu yayınladığını sanıyor, sakinlere hiçbir şey
// ulaşmıyordu — bu, uydurma veriden daha tehlikeli bir sahte başarı mesajıydı.
// Ayrıca kategori seçimi `onChanged: (_) {}` ile hiçbir yere yazılmıyordu.
//
// Artık:
//  * Form `POST /announcements` ucuna gerçekten gönderilir (createAnnouncement).
//  * Başarı mesajı ve ekran kapanması YALNIZCA sunucu 2xx döndüğünde olur.
//  * Sunucu 501 döndüğünde (bugünkü durum: community.announcements henüz gerçek
//    veri katmanına bağlı değil) kullanıcıya "henüz hazır değil" bilgisi verilir
//    ve ekran kapanmaz — böylece yayınlandığı sanılmaz.
//  * Kategori seçimi duruma yazılır ve gönderilen veriye dahil edilir.
//
// "Dosya Ekle" düğmesi kaldırıldı: dosya yükleyen bir uç yok ve düğmenin
// `onPressed` gövdesi boştu (basıldığında sessizce hiçbir şey olmuyordu).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/data_state.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'GENERAL';
  bool _isPinned = false;
  bool _isSubmitting = false;

  /// Sunucu 501 döndüğünde ekranda kalıcı bilgi göstermek için tutulur.
  bool _notImplemented = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Yayınla'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _publish,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Yayınla'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_notImplemented)
              const NotImplementedNotice(
                title: 'Duyuru yayınlama henüz sunucuda hazır değil',
                detail: 'Sunucu bu isteği kabul etmiyor (501). Duyuru '
                    'KAYDEDİLMEDİ; sakinlere hiçbir bildirim gitmedi.',
              ),

            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık *'),
              onChanged: (_) => setState(() {}), // önizleme güncellensin
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık zorunlu' : null,
            ),
            const SizedBox(height: 16),

            // İçerik
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'İçerik *',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İçerik zorunlu' : null,
            ),
            const SizedBox(height: 16),

            // Kategori — seçim artık duruma yazılıyor ve sunucuya gönderiliyor.
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kategori'),
              initialValue: _category,
              items: const [
                // Sunucunun kabul ettiği değerler (PAYMENT/MEETING reddediliyordu).
                DropdownMenuItem(value: 'GENERAL', child: Text('Genel')),
                DropdownMenuItem(value: 'FINANCIAL', child: Text('Mali')),
                DropdownMenuItem(value: 'MAINTENANCE', child: Text('Bakım')),
                DropdownMenuItem(value: 'ASSEMBLY', child: Text('Genel Kurul')),
                DropdownMenuItem(value: 'EMERGENCY', child: Text('Acil')),
              ],
              onChanged: (v) =>
                  setState(() => _category = v ?? 'GENERAL'),
            ),
            const SizedBox(height: 24),

            // Seçenekler
            Card(
              child: Column(
                children: [
                  // Sunucu her duyuruda aktif sakinlere uygulama içi bildirim
                  // oluşturur; anlık bildirim (push) sağlayıcısı bağlı değildir.
                  const ListTile(
                    leading: Icon(Icons.notifications_active_outlined),
                    title: Text('Sakinlere uygulama içi bildirim oluşturulur'),
                    subtitle: Text('Anlık bildirim (push) sağlayıcısı bağlı değil; sonuç yayından sonra gösterilir.'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Duyuruyu sabitle'),
                    subtitle: const Text('Liste başında sabit kalır'),
                    value: _isPinned,
                    onChanged: (v) => setState(() => _isPinned = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Önizleme — girilen metinden üretilir, uydurma içerik yoktur.
            const Text('Önizleme',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isPinned)
                          const Icon(Icons.push_pin,
                              size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _titleController.text.isEmpty
                                ? 'Başlık'
                                : _titleController.text,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contentController.text.isEmpty
                          ? 'İçerik buraya gelecek...'
                          : _contentController.text,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _notImplemented = false;
    });

    try {
      final res = await apiClient.post('/announcements', {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _category,
        'is_pinned': _isPinned,
      });
      if (!mounted) return;
      // Yalnızca sunucu isteği kabul ettiyse başarı bildirilir; bildirimin
      // gerçekte ne olduğu (kaç alıcı, gönderildi/kuyrukta) sunucunun notudur.
      final note = res['notification'] is Map ? (res['notification'] as Map)['note'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(note is String ? 'Duyuru yayınlandı. $note' : 'Duyuru yayınlandı'),
            backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _notImplemented = isNotImplemented(e));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duyuru yayınlanamadı: ${toUserMessage(e)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
