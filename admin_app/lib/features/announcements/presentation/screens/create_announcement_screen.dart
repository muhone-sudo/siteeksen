import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _sendNotification = true;
  bool _isPinned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Yayınla'),
        actions: [
          TextButton.icon(
            onPressed: _publish,
            icon: const Icon(Icons.send),
            label: const Text('Yayınla'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık *'),
              validator: (v) => v?.isEmpty ?? true ? 'Başlık zorunlu' : null,
            ),
            const SizedBox(height: 16),
            
            // Content
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'İçerik *',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (v) => v?.isEmpty ?? true ? 'İçerik zorunlu' : null,
            ),
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kategori'),
              value: 'GENERAL',
              items: const [
                DropdownMenuItem(value: 'GENERAL', child: Text('Genel')),
                DropdownMenuItem(value: 'PAYMENT', child: Text('Ödeme')),
                DropdownMenuItem(value: 'MAINTENANCE', child: Text('Bakım')),
                DropdownMenuItem(value: 'MEETING', child: Text('Toplantı')),
                DropdownMenuItem(value: 'EMERGENCY', child: Text('Acil')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            
            // Options
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push bildirim gönder'),
                    subtitle: const Text('Tüm sakinlere bildirim gönderilir'),
                    value: _sendNotification,
                    onChanged: (v) => setState(() => _sendNotification = v),
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
            const SizedBox(height: 16),
            
            // Attachment
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file),
              label: const Text('Dosya Ekle'),
            ),
            const SizedBox(height: 32),
            
            // Preview
            const Text('Önizleme', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          const Icon(Icons.push_pin, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _titleController.text.isEmpty ? 'Başlık' : _titleController.text,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contentController.text.isEmpty ? 'İçerik buraya gelecek...' : _contentController.text,
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

  void _publish() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru yayınlandı'), backgroundColor: Colors.green),
      );
      context.pop();
    }
  }
}
