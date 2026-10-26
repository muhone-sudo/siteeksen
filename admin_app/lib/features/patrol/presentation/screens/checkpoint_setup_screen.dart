// Devriye noktası kurulumu (075, FAZ H.5): yönetici noktanın YANINDA telefonla konumu kaydeder
// (≤20 m hassasiyet), yarıçapı ve konum muafiyetini (gerekçeli) ayarlar, QR'ı yeniler.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/location.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

class CheckpointSetupScreen extends StatefulWidget {
  const CheckpointSetupScreen({super.key});

  @override
  State<CheckpointSetupScreen> createState() => _CheckpointSetupScreenState();
}

class _CheckpointSetupScreenState extends State<CheckpointSetupScreen> {
  int _token = 0;

  Future<void> _captureLocation(Map<String, dynamic> cp) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Konum ölçülüyor…')));
    try {
      final p = await currentPosition(timeout: const Duration(seconds: 30));
      if (!mounted) return;
      if (p.isMocked) {
        messenger.showSnackBar(const SnackBar(content: Text('Sahte konum algılandı; kaydedilmedi.')));
        return;
      }
      if (!await confirm(context, 'Konumu kaydet',
          '${cp['name']} için ölçülen konum hassasiyeti ${p.accuracy.round()} m.\n'
              '${p.accuracy > 20 ? 'En az 20 m gerekli; açık alanda biraz bekleyip yeniden deneyin.' : 'Noktanın yanında olduğunuzdan emin olun.'}',
          ok: 'Kaydet')) {
        return;
      }
      if (!mounted) return;
      if (await runAction(context, () => apiClient.post('/patrol-checkpoints/${cp['id']}/location', positionBody(p)), success: 'Nokta konumu kaydedildi')) {
        setState(() => _token++);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _radius(Map<String, dynamic> cp) async {
    final v = await askText(context, 'Yarıçap (m)', '5-500 arası', initial: '${cp['radius_m'] ?? 30}');
    if (v == null || !mounted) return;
    final n = int.tryParse(v.trim());
    if (n == null) return;
    if (await runAction(context, () => apiClient.patch('/patrol-checkpoints/${cp['id']}', {'radius_m': n}), success: 'Yarıçap güncellendi')) {
      setState(() => _token++);
    }
  }

  Future<void> _exempt(Map<String, dynamic> cp) async {
    final exempt = cp['location_check'] == 'EXEMPT';
    if (exempt) {
      if (await runAction(context, () => apiClient.patch('/patrol-checkpoints/${cp['id']}', {'location_check': 'REQUIRED'}),
          success: 'Konum denetimi yeniden zorunlu')) {
        setState(() => _token++);
      }
      return;
    }
    final reason = await askText(context, 'Konum muafiyeti', 'Gerekçe (ör. bodrum, GPS çekmiyor)');
    if (reason == null || !mounted) return;
    if (await runAction(context, () => apiClient.patch('/patrol-checkpoints/${cp['id']}', {'location_check': 'EXEMPT', 'exempt_reason': reason}),
        success: 'Nokta konum denetiminden muaf; okutmalar raporda ayrıca gösterilir')) {
      setState(() => _token++);
    }
  }

  Future<void> _rotate(Map<String, dynamic> cp) async {
    if (!await confirm(context, 'QR yenile', 'Eski QR baskısı hemen geçersiz olur; yenisini noktaya asmalısınız.', ok: 'Yenile')) return;
    try {
      final r = await apiClient.post('/patrol-checkpoints/${cp['id']}/rotate-qr');
      if (!mounted) return;
      setState(() => _token++);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Yeni QR değeri'),
          content: SelectableText('${r['qr_value']}\n\nYazdırmak için panelde Devriye → Noktalar → QR yazdır.'),
          actions: [
            TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: '${r['qr_value']}')), child: const Text('Kopyala')),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _addCheckpoint() async {
    if (await formAction(context, 'Kontrol noktası', const [
      FSpec('name', 'Ad', required: true),
      FSpec('location', 'Konum'),
      FSpec('building', 'Blok'),
      FSpec('floor', 'Kat'),
      FSpec('nfc_tag_id', 'NFC etiket kimliği'),
      FSpec('qr_code', 'QR kodu'),
    ], (v) => apiClient.post('/patrol-checkpoints', v), success: 'Kontrol noktası eklendi; konumu sahada "Konumu buradan al" ile kaydedin')) {
      setState(() => _token++);
    }
  }

  Future<void> _addRoute() async {
    final cps = await optionsFrom('/patrol-checkpoints', (c) => '${c['name']}').catchError((_) => <(String, String)>[]);
    if (!mounted) return;
    await formAction(context, 'Tur tanımla', [
      const FSpec('name', 'Ad', required: true),
      const FSpec('expected_duration_minutes', 'Beklenen süre (dk)', type: FType.integer, initial: 30),
      const FSpec('tolerance_minutes', 'Tolerans (dk)', type: FType.integer, initial: 10),
      FSpec('checkpoints', 'Noktalar (seçim sırası tur sırasıdır)', type: FType.multi, options: cps),
    ], (v) {
      final ids = (v['checkpoints'] as List).cast<String>();
      if (ids.isEmpty) throw StateError('En az bir nokta seçin');
      return apiClient.post('/patrol-routes', {
        'name': v['name'],
        'expected_duration_minutes': v['expected_duration_minutes'] ?? 0,
        'tolerance_minutes': v['tolerance_minutes'] ?? 0,
        'checkpoints': [for (var i = 0; i < ids.length; i++) {'checkpoint_id': ids[i], 'order': i + 1, 'optional': false}],
      });
    }, success: 'Tur tanımlandı');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devriye noktaları'), actions: [
        IconButton(tooltip: 'Tur tanımla', icon: const Icon(Icons.route), onPressed: _addRoute),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addCheckpoint, icon: const Icon(Icons.add_location_alt), label: const Text('Nokta')),
      body: ApiList(
        token: _token,
        load: () => apiClient.getList('/patrol-checkpoints'),
        empty: 'Nokta tanımlanmamış',
        itemBuilder: (context, cp, _) {
          final exempt = cp['location_check'] == 'EXEMPT';
          final hasLoc = cp['latitude'] != null;
          return ListTile(
            leading: Icon(exempt ? Icons.location_off : hasLoc ? Icons.location_on : Icons.location_searching,
                color: exempt ? Colors.orange : hasLoc ? Colors.green : Colors.red),
            title: Text('${cp['name']}'),
            subtitle: Text([
              if ((cp['location'] ?? '').toString().isNotEmpty) '${cp['location']}',
              exempt ? 'konum muaf: ${cp['exempt_reason'] ?? ''}' : hasLoc ? 'yarıçap ${cp['radius_m']} m' : 'konum tanımlı değil — okutma reddedilir',
              if (cp['location_set_at'] != null) 'ölçüm ${formatDateTime(cp['location_set_at'])} (±${toNum(cp['location_accuracy_m']).round()} m)',
            ].join('\n')),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'loc') _captureLocation(cp);
                if (v == 'radius') _radius(cp);
                if (v == 'exempt') _exempt(cp);
                if (v == 'qr') _rotate(cp);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'loc', child: Text('Konumu buradan al')),
                const PopupMenuItem(value: 'radius', child: Text('Yarıçap')),
                PopupMenuItem(value: 'exempt', child: Text(exempt ? 'Konum denetimini aç' : 'Konumdan muaf tut')),
                const PopupMenuItem(value: 'qr', child: Text('QR yenile')),
              ],
            ),
          );
        },
      ),
    );
  }
}
