// Demirbaş Yönetimi Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü demirbaş listesi (marka/model/garanti tarihleri) ve bunlardan
// hesaplanan sahte "toplam değer / garantisi biten" sayaçları gösteriyordu.
// Demirbaş listesi KMK m.39 kapsamında hesap verme belgelerinin parçasıdır;
// uydurma kayıt, yıllık hesabın yanlış çıkmasına yol açar.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class AssetManagementScreen extends StatefulWidget {
  const AssetManagementScreen({super.key});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  bool _loading = true;
  String? _error;
  bool _notImplemented = false;
  List<Map<String, dynamic>> _assets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notImplemented = false;
    });
    try {
      final list = await apiClient.getAssets();
      if (!mounted) return;
      setState(() {
        _assets = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notImplemented = isNotImplemented(e);
        _error = toUserMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Demirbaşlar'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Yenile'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'Demirbaş modülü henüz hazır değil',
          detail: 'Demirbaş kayıtları, garanti ve amortisman takibi sunucu tarafında '
              'gerçek veriye bağlanmadı.',
        ),
      );
    }
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);
    if (_assets.isEmpty) {
      return const EmptyStateView(
        message: 'Kayıtlı demirbaş yok.',
        icon: Icons.chair_outlined,
      );
    }

    // Özet YALNIZCA sunucudan gelen kayıtlardan hesaplanır.
    num totalValue = 0;
    var valued = 0;
    for (final a in _assets) {
      final v = a['purchase_price'] ?? a['value'];
      if (v is num) {
        totalValue += v;
        valued++;
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _metric('Kayıt', '${_assets.length}', AppleTheme.systemBlue)),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(
                  'Toplam değer',
                  valued == 0 ? '—' : formatTry(totalValue),
                  AppleTheme.systemGreen,
                ),
              ),
            ],
          ),
          if (valued > 0 && valued < _assets.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_assets.length - valued} kaydın değeri girilmemiş; toplam eksik olabilir.',
                style: TextStyle(fontSize: 12, color: AppleTheme.systemOrange),
              ),
            ),
          const SizedBox(height: 16),
          for (final a in _assets) _assetCard(a),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _assetCard(Map<String, dynamic> a) {
    final warranty = a['warranty_end'] ?? a['warranty_until'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((a['name'] ?? 'Demirbaş').toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (a['location'] != null)
            Text(a['location'].toString(),
                style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (a['purchase_price'] is num)
                Text(formatTry(a['purchase_price'] as num),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (warranty != null)
                Text('Garanti: ${formatDate(warranty)}',
                    style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
