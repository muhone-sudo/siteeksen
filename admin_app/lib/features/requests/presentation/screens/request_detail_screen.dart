// Talep detayı ve durum güncelleme.
//
// DÜZELTME (2026-09-26): ekran `GET /requests/:id` (sunucuda YOK) ve
// `POST /requests/:id/comments` (sunucuda YOK) çağırıyordu; yorum her zaman
// başarısız oluyordu. Kayıt liste ucundan bulunur; yorum alanı kaldırıldı.
// Durum yalnızca sunucunun izin verdiği sırayla ilerler:
// AÇIK → İŞLEMDE → ÇÖZÜLDÜ; KAPANDI'yı sakin onaylar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const requestStatusText = {'OPEN': 'Açık', 'IN_PROGRESS': 'İşlemde', 'RESOLVED': 'Çözüldü (sakin onayı bekleniyor)', 'CLOSED': 'Kapandı'};
const requestPriorityText = {'LOW': 'Düşük', 'NORMAL': 'Normal', 'HIGH': 'Yüksek', 'URGENT': 'Acil'};

/// Sunucunun kabul ettiği bir sonraki durum (yoksa null).
String? nextRequestStatus(Object? status) => switch (status) {
      'OPEN' => 'IN_PROGRESS',
      'IN_PROGRESS' => 'RESOLVED',
      _ => null,
    };

class RequestDetailScreen extends StatelessWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  Future<Map<String, dynamic>> _load() async {
    final list = await apiClient.getList('/requests');
    final match = list.whereType<Map>().where((r) => '${r['id']}' == requestId);
    if (match.isEmpty) throw StateError('Talep bulunamadı (silinmiş ya da başka siteye ait olabilir).');
    return Map<String, dynamic>.from(match.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talep Detayı')),
      body: ApiObject(
        load: _load,
        builder: (context, r, reload) {
          final next = nextRequestStatus(r['status']);
          final photos = ApiClient.listOf(r['photo_urls']);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${r['title'] ?? ''}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text([
                '${r['ticket_number'] ?? ''}',
                requestStatusText['${r['status']}'] ?? '${r['status']}',
                requestPriorityText['${r['priority']}'] ?? '',
              ].where((s) => s.isNotEmpty).join(' · ')),
              const SizedBox(height: 12),
              Text('${r['description'] ?? ''}'),
              if ((r['location'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Konum: ${r['location']}'),
              ],
              if (photos.isNotEmpty) Text('${photos.length} fotoğraf eklenmiş (web panelinde görüntülenir)'),
              const Divider(height: 32),
              Text('Oluşturma: ${formatDateTime(r['created_at'])}'),
              if (parseApiDate(r['resolved_at']) != null) Text('Çözüm: ${formatDateTime(r['resolved_at'])}'),
              if (parseApiDate(r['user_confirmed_at']) != null) Text('Sakin onayı: ${formatDateTime(r['user_confirmed_at'])}'),
              const SizedBox(height: 24),
              if (next != null)
                FilledButton(
                  onPressed: () async {
                    final ok = await runAction(
                      context,
                      () => apiClient.patch('/requests/$requestId/status', {'status': next}),
                      success: 'Talep "${requestStatusText[next]}" durumuna alındı',
                    );
                    if (ok && context.mounted) context.pop(true);
                  },
                  child: Text(next == 'IN_PROGRESS' ? 'İşleme al' : 'Çözüldü olarak işaretle'),
                ),
              if (r['status'] == 'RESOLVED')
                const Text('Talebi sakin onaylayınca kapanır; onaylamazsa yeniden işleme düşer.'),
            ],
          );
        },
      ),
    );
  }
}
