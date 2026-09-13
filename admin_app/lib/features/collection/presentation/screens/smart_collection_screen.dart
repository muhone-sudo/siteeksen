// Akıllı Tahsilat Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü borçlu listesi ("Ahmet Yılmaz", tutarlar, gecikme günleri),
// uydurma tahsilat oranı ve hiçbir şey yapmayan "hatırlatma gönder" düğmeleri
// içeriyordu. Bir yöneticinin bu ekrana bakıp "hatırlatmalar gitti" sanması
// doğrudan tahsilat kaybıdır. Artık veri gerçek API'den gelir; sunucu hazır
// değilse bu açıkça söylenir ve hiçbir işlem başarılı gibi gösterilmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class SmartCollectionScreen extends StatefulWidget {
  const SmartCollectionScreen({super.key});

  @override
  State<SmartCollectionScreen> createState() => _SmartCollectionScreenState();
}

class _SmartCollectionScreenState extends State<SmartCollectionScreen> {
  bool _loading = true;
  String? _error;
  bool _notImplemented = false;

  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _candidates = const [];

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
      final overview = await apiClient.getCollectionOverview();
      final candidates = await apiClient.getCollectionCandidates();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _candidates = candidates
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
        title: const Text('Akıllı Tahsilat'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Tahsilat verileri alınıyor…');
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'Akıllı tahsilat henüz hazır değil',
          detail: 'Kademeli hatırlatma ve tahsilat önceliklendirme modülü sunucu '
              'tarafında gerçek veriye bağlanmadı. Borçlu listesi için Finans > '
              'Borçlular ekranını kullanabilirsiniz.',
        ),
      );
    }
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(),
          const SizedBox(height: 16),
          Text('Hatırlatma Adayları',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          if (_candidates.isEmpty)
            const EmptyStateView(
              message: 'Hatırlatma gerektiren borçlu yok.',
              icon: Icons.check_circle_outline_rounded,
            )
          else
            for (final c in _candidates) _buildCandidate(c),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    // Değer gelmediyse "0" değil "—" gösterilir: sıfır borç ile bilinmeyen borç
    // birbirinden çok farklı şeylerdir.
    String metric(String key) {
      final v = _overview?[key];
      if (v == null) return '—';
      if (v is num && (key.contains('amount') || key.contains('kurus'))) {
        return formatTry(key.contains('kurus') ? v / 100 : v);
      }
      return v.toString();
    }

    return Row(
      children: [
        Expanded(child: _metricCard('Toplam Borç', metric('total_debt_amount'), AppleTheme.systemRed)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Borçlu Sayısı', metric('debtor_count'), AppleTheme.systemOrange)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Tahsilat Oranı', metric('collection_rate'), AppleTheme.systemGreen)),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildCandidate(Map<String, dynamic> c) {
    final name = (c['resident_name'] ?? c['name'] ?? c['resident_id'] ?? 'Bilinmiyor').toString();
    final unit = (c['unit'] ?? c['unit_name'] ?? '').toString();
    final amount = c['amount'] ?? c['debt_amount'];
    final days = c['overdue_days'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(unit.isEmpty ? name : '$name • $unit',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(amount == null ? '—' : formatTry(amount as num),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppleTheme.systemRed)),
            ],
          ),
          if (days != null) ...[
            const SizedBox(height: 4),
            Text('$days gün gecikme',
                style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _startAction(c),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Hatırlatma başlat'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAction(Map<String, dynamic> c) async {
    final residentID = (c['resident_id'] ?? c['user_id'] ?? '').toString();
    if (residentID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kayıtta sakin bilgisi yok; hatırlatma gönderilemez.')),
      );
      return;
    }
    try {
      await apiClient.startCollectionAction(residentID, 'REMINDER');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatma sunucuya iletildi')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      // Sunucu kabul etmediyse "gönderildi" DENMEZ.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatma gönderilemedi: ${toUserMessage(e)}')),
      );
    }
  }
}
