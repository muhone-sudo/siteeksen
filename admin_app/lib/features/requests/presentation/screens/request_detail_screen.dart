import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  String _status = 'OPEN';
  bool _isSubmitting = false;
  final _commentController = TextEditingController();

  Future<void> _updateStatus() async {
    setState(() => _isSubmitting = true);
    try {
      await apiClient.updateRequestStatus(widget.requestId, _status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep güncellendi'), backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talep güncellenemedi, lütfen tekrar deneyin')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep Detayı'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'assign', child: Text('Görevli Ata')),
              const PopupMenuItem(value: 'priority', child: Text('Öncelik Değiştir')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.warningColor,
                        child: Icon(Icons.build, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Asansör Arızası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Talep #${widget.requestId}', style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A Blok asansörü 3. katta durdu ve kapı açılmıyor. Acil müdahale gerekiyor.',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Card(
            child: Column(
              children: [
                _InfoTile(icon: Icons.person, label: 'Talep Eden', value: 'Ahmet Yılmaz - A Blok D.5'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.calendar_today, label: 'Tarih', value: '01.02.2026 14:30'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.category, label: 'Kategori', value: 'Bakım/Onarım'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.flag, label: 'Öncelik', value: 'Yüksek'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status change
          const Text('Durum Güncelle', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'OPEN', label: Text('Açık')),
              ButtonSegment(value: 'IN_PROGRESS', label: Text('İşlemde')),
              ButtonSegment(value: 'RESOLVED', label: Text('Çözüldü')),
            ],
            selected: {_status},
            onSelectionChanged: (v) => setState(() => _status = v.first),
          ),
          if (_status == 'RESOLVED') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: AppTheme.warningColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Talep "Çözüldü" olarak işaretlendi. Talep, sakin onayladıktan sonra otomatik olarak kapatılacaktır.',
                      style: TextStyle(color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Comments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('2 yorum', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          _CommentCard(author: 'Yönetici', content: 'Asansör firması ile iletişime geçildi.', date: '01.02.2026 15:00'),
          _CommentCard(author: 'Ahmet Yılmaz', content: 'Teşekkürler, bekliyorum.', date: '01.02.2026 15:30'),
          const SizedBox(height: 16),

          // Add comment
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(hintText: 'Yorum ekle...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _commentController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum eklendi')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _updateStatus,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Güncelle'),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String author;
  final String content;
  final String date;
  const _CommentCard({required this.author, required this.content, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(content),
          ],
        ),
      ),
    );
  }
}
