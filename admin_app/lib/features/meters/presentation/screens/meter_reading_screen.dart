// Toplu sayaç okuma giriş ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Okunacak sayaç listesi `List.generate(10, ...)` ile ekranda uyduruluyordu
// ("A/B/C Blok D.x", "M-2024-1000x", son okuma = 100 + i*12.5). Daha kötüsü,
// "Kaydet" düğmesi HİÇBİR ağ çağrısı yapmadan "Okumalar kaydedildi" diyordu:
// görevli sahada tüm sayaçları okuyup kaydettiğini sanıyor, hiçbir değer
// sunucuya ulaşmıyordu. Bu değerler tüketim faturalandırmasının girdisi olduğu
// için bu sessiz kayıp doğrudan maddi zarar üretir.
//
// Artık:
//  * Sayaç listesi seçilen türe göre `GET /meters?type=...` ucundan gelir;
//    tür değiştikçe liste yeniden yüklenir.
//  * Kaydetme `POST /meters/bulk-readings` ucuna gerçekten gider.
//  * "Kaydedildi" mesajı ve ekranın kapanması YALNIZCA sunucu 2xx döndüğünde
//    gerçekleşir; hata halinde girilen değerler ekranda KALIR (kaybolmaz) ve
//    kullanıcıya nedeni gösterilir.
//  * Sunucu 501 döndüğünde durum `NotImplementedNotice` ile açıkça bildirilir.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  String _selectedType = 'HEAT';

  bool _loading = true;
  bool _isSaving = false;
  Object? _error;
  List<Map<String, dynamic>> _meters = const [];

  /// Girilen yeni okumalar: sayaç kimliği -> değer.
  final Map<String, double> _newReadings = {};

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
      final data = await apiClient.getMeters(type: _selectedType);
      if (!mounted) return;
      setState(() {
        _meters = data
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

  void _changeType(String type) {
    if (type == _selectedType) return;
    setState(() {
      _selectedType = type;
      // Tür değişince girilen değerler başka sayaçlara ait olur; temizlenir.
      _newReadings.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filled = _newReadings.length;
    final total = _meters.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaç Okuma'),
        actions: [
          TextButton.icon(
            onPressed: (_isSaving || filled == 0) ? null : _saveReadings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tür seçici
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'HEAT', label: Text('Isı')),
                      ButtonSegment(
                          value: 'WATER_COLD', label: Text('Soğuk Su')),
                      ButtonSegment(value: 'WATER_HOT', label: Text('Sıcak Su')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (v) => _changeType(v.first),
                  ),
                ),
              ],
            ),
          ),

          // İlerleme — yalnızca gerçek sayaç listesi varken anlamlı.
          if (total > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('$filled/$total girildi'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: filled / total,
                      backgroundColor: AppTheme.borderColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const LoadingView(message: 'Okunacak sayaçlar alınıyor...');
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const SingleChildScrollView(
          child: NotImplementedNotice(
            title: 'Sayaç listesi henüz sunucuda hazır değil',
            detail: 'IoT servisi sayaçları henüz veritabanından okumuyor '
                '(501). Okuma girişi, gerçek sayaç listesi gelmeden '
                'yapılamaz.',
          ),
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }
    if (_meters.isEmpty) {
      return const EmptyStateView(
        message: 'Bu türde okunacak sayaç yok.',
        icon: Icons.speed_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _meters.length,
      itemBuilder: (context, index) {
        final meter = _meters[index];
        final id = (meter['id'] ?? '').toString();
        final serial = (meter['serial_number'] ?? '').toString();
        final unitId = (meter['unit_id'] ?? '').toString();
        final lastReading = meter['last_reading'];
        final entered = _newReadings[id];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serial.isEmpty ? '(seri no yok)' : serial,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Daire: ${unitId.isEmpty ? '—' : unitId} • Son: '
                        '${lastReading is num ? formatNumber(lastReading) : '—'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    key: ValueKey('reading-$_selectedType-$id'),
                    decoration: const InputDecoration(
                      hintText: 'Yeni',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isSaving && id.isNotEmpty,
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      setState(() {
                        if (parsed == null) {
                          _newReadings.remove(id);
                        } else {
                          _newReadings[id] = parsed;
                        }
                      });
                    },
                  ),
                ),
                if (entered != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: AppTheme.successColor),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReadings() async {
    final readings = _newReadings.entries
        .map((e) => {'meter_id': e.key, 'value': e.value})
        .toList();
    if (readings.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydet'),
        content:
            Text('${readings.length} okuma kaydedilecek. Onaylıyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await apiClient.submitBulkReadings(readings);
      if (!mounted) return;
      // Başarı mesajı yalnızca sunucu okumaları kabul ettiyse gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Okumalar kaydedildi'),
            backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      // Hata halinde girilen değerler ekranda kalır; kullanıcı yeniden dener.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Okumalar kaydedilemedi: ${toUserMessage(e)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
