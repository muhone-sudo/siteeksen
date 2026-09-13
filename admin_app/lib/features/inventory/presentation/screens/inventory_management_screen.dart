// Stok Yönetimi Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü stok kalemleri ve "kritik seviye" uyarıları gösteriyordu.
// Uydurma stok bilgisi, yönetimin gereksiz alım yapmasına ya da gerçekten biten
// malzemeyi fark etmemesine yol açar. Artık veri gerçek API'den gelir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/data_state.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  bool _loading = true;
  String? _error;
  bool _notImplemented = false;
  List<Map<String, dynamic>> _items = const [];

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
      final list = await apiClient.getInventory();
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
        title: const Text('Stok'),
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
          title: 'Stok modülü henüz hazır değil',
          detail: 'Malzeme stok takibi ve giriş/çıkış hareketleri sunucu tarafında '
              'gerçek veriye bağlanmadı.',
        ),
      );
    }
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyStateView(message: 'Kayıtlı stok kalemi yok.', icon: Icons.inventory_2_outlined);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _itemCard(_items[i]),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> it) {
    final qty = it['quantity'];
    final min = it['min_quantity'] ?? it['critical_level'];
    // "Kritik" uyarısı YALNIZCA sunucudan gelen eşik varsa gösterilir; uydurulmaz.
    final isCritical = qty is num && min is num && qty <= min;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((it['name'] ?? 'Kalem').toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (it['category'] != null)
                  Text(it['category'].toString(),
                      style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                if (isCritical)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Kritik seviyenin altında',
                        style: TextStyle(fontSize: 12, color: AppleTheme.systemRed)),
                  ),
              ],
            ),
          ),
          Text(
            qty == null ? '—' : '$qty ${it['unit'] ?? ''}'.trim(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isCritical ? AppleTheme.systemRed : AppleTheme.label,
            ),
          ),
        ],
      ),
    );
  }
}
