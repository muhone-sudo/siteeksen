// Sayaç listesi ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Liste `List.generate(10, ...)` ile ekranda ÜRETİLİYORDU: "A/B/C Blok D.x",
// "M-2024-1000x" seri numaraları ve 100 + i*12.5 formülüyle uydurulmuş sayaç
// değerleri. Yönetici bu sayılara bakarak tüketim/fatura kararı verebileceği için
// bu veriler doğrudan maddi zarara yol açabilirdi.
//
// Artık her sekme `GET /meters?type=...` ucundan kendi verisini çeker. IoT
// servisi bu ucu henüz gerçek veri katmanına bağlamadığı için bugün 501 döner;
// bu durumda uydurma satır üretmek yerine `NotImplementedNotice` gösterilir.
//
// Başlıktaki "indir" düğmesi kaldırıldı: dışa aktarma ucu yok ve düğmenin
// `onPressed` gövdesi boştu (basıldığında hiçbir şey olmuyordu).
//
// Not: Sunucu daire adını döndürmüyor (yalnızca `unit_id`), bu yüzden kartlarda
// uydurma "A Blok D.5" yerine sayaç seri numarası ve daire kimliği gösterilir.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaçlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Isı'),
            Tab(text: 'Soğuk Su'),
            Tab(text: 'Sıcak Su'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MeterList(type: 'HEAT'),
          _MeterList(type: 'WATER_COLD'),
          _MeterList(type: 'WATER_HOT'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/meters/reading'),
        icon: const Icon(Icons.edit),
        label: const Text('Okuma Gir'),
      ),
    );
  }
}

/// Tek bir sayaç türünün listesi. Her sekme kendi isteğini yapar; birinin
/// hatası diğer sekmeleri etkilemez.
class _MeterList extends StatefulWidget {
  final String type;
  const _MeterList({required this.type});

  @override
  State<_MeterList> createState() => _MeterListState();
}

class _MeterListState extends State<_MeterList>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _meters = const [];

  @override
  bool get wantKeepAlive => true;

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
      final data = await apiClient.getMeters(type: widget.type);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const LoadingView(message: 'Sayaçlar alınıyor...');
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const SingleChildScrollView(
          child: NotImplementedNotice(
            title: 'Sayaç listesi henüz sunucuda hazır değil',
            detail: 'IoT servisi sayaçları henüz veritabanından okumuyor '
                '(501). Gerçek sayaç verisi gelmeden burada değer '
                'gösterilmez.',
          ),
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }
    if (_meters.isEmpty) {
      return const EmptyStateView(
        message: 'Bu türde kayıtlı sayaç yok.',
        icon: Icons.speed_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _meters.length,
        itemBuilder: (context, index) {
          final meter = _meters[index];
          final serial = (meter['serial_number'] ?? '').toString();
          final unitId = (meter['unit_id'] ?? '').toString();
          final lastReading = meter['last_reading'];

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  widget.type == 'HEAT' ? Icons.whatshot : Icons.water_drop,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(serial.isEmpty ? '(seri no yok)' : 'No: $serial'),
              subtitle: Text('Daire: ${unitId.isEmpty ? '—' : unitId}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastReading is num ? formatNumber(lastReading) : '—',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatDate(meter['last_read_at']),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
