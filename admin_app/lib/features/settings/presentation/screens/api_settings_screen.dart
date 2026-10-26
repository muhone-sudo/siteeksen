// Entegrasyon durumu — dış sağlayıcıların GERÇEK bağlantı durumu (FAZ H.1.2).
//
// Sağlayıcı anahtarları sunucu ortam değişkeniyle verilir; uygulamadan girilmez
// ve gösterilmez. Durum gateway'in /integrations/status ucundan okunur.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/api_views.dart';

const _channels = {'IN_APP': 'Uygulama içi', 'SMS': 'SMS', 'EMAIL': 'E-posta', 'PUSH': 'Anlık bildirim (push)'};

class APISettingsScreen extends StatelessWidget {
  const APISettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entegrasyon Durumu')),
      body: ApiObject(
        load: () => apiClient.getMap('/integrations/status'),
        builder: (context, res, reload) {
          final data = Map<String, dynamic>.from((res['data'] as Map?) ?? {});
          final delivery = Map<String, dynamic>.from((data['delivery'] as Map?) ?? {});
          final missing = ((delivery['channels_without_provider'] as List?) ?? []).map((e) => '$e').toSet();
          final card = data['card_payment'] as Map?;
          final storage = Map<String, dynamic>.from((data['storage'] as Map?) ?? {});
          final unavailable = (res['unavailable'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Sağlayıcı anahtarları sunucuda ortam değişkeniyle verilir; bu ekranda girilmez ve gösterilmez.',
                style: TextStyle(color: Colors.black54),
              ),
              if (unavailable.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Durum alınamayan: ${unavailable.map((u) => (u as Map)['source']).join(', ')}',
                    style: const TextStyle(color: Colors.orange)),
              ],
              const SizedBox(height: 16),
              const Text('Bildirim kanalları', style: TextStyle(fontWeight: FontWeight.w600)),
              for (final e in _channels.entries)
                ListTile(
                  title: Text(e.value),
                  trailing: missing.contains(e.key)
                      ? const StatusChip('Sağlayıcı yok', color: Colors.orange)
                      : const StatusChip('Bağlı', color: Colors.green),
                ),
              const Divider(),
              ListTile(
                title: const Text('Kartla ödeme'),
                subtitle: Text(card == null ? 'Bilinmiyor' : '${card['provider']}'),
                trailing: card == null
                    ? null
                    : (card['ready'] == true
                        ? const StatusChip('Bağlı', color: Colors.green)
                        : const StatusChip('Kapalı', color: Colors.orange)),
              ),
              const Divider(),
              const Text('Dosya deposu', style: TextStyle(fontWeight: FontWeight.w600)),
              for (final e in storage.entries) ListTile(dense: true, title: Text(e.key), trailing: Text('${e.value}')),
            ],
          );
        },
      ),
    );
  }
}
