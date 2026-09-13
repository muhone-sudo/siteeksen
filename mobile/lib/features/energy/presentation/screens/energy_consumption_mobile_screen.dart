// Enerji/Tüketim Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// Ekran hiçbir ağ çağrısı yapmıyordu. Tüm rakamlar koda gömülüydü:
//   - `_currentUsage`: "245 kWh / ₺612,50", "78 m³ / ₺312,00", "12 m³ / ₺96,00"
//   - `_monthlyTrend`: 6 aylık sahte grafik verisi
//   - "%12 tasarruf" ve "Geçen aya göre ₺156.50 daha az" rozetleri sabitti
//   - `_tips`: sabit öneri listesi
// Para tutarı içeren bir ekranda bu, kullanıcının faturasını yanlış okumasına
// yol açar. Ayrıca para biçimlendirmesi elle yapılıyordu (`₺612.50`), Türkçe
// biçim `₺612,50` olmalıdır.
//
// Bu sürüm:
//   - Üç sayaç türünün verisini `GET /finance/consumption/summary?meter_type=…`
//     ucundan alır (apiClient.getConsumptionSummary).
//   - Tutar/oran hesapları sunucudan gelen son iki dönemden yapılır; veri yoksa
//     "—" gösterilir, uydurma rakam ÜRETİLMEZ.
//   - Bir sayaç türü 501 dönerse o kart "henüz hazır değil" der; hepsi 501
//     dönerse ekran `NotImplementedNotice` gösterir.
//   - "Hafta / Ay / Yıl" seçicisi kaldırıldı: sunucu yalnızca son 6 AYI
//     döndürüyor, seçici hiçbir şey değiştirmiyordu.
//   - Sabit "tasarruf ipuçları" listesi kaldırıldı (sunucuda karşılığı yok).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Ekranda gösterilecek bir sayaç türünün sunucudan gelen durumu.
class _MeterSection {
  final String title;
  final String meterType;
  final IconData icon;
  final Color color;

  /// Sunucudan gelen dönem listesi (eskiden yeniye ya da tersi olabilir;
  /// `period` alanına göre sıralanır).
  List<Map<String, dynamic>> data = const [];
  String unit = '';
  String? error;
  bool notImplemented = false;

  _MeterSection({
    required this.title,
    required this.meterType,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic>? get latest => data.isEmpty ? null : data.last;
  Map<String, dynamic>? get previous =>
      data.length < 2 ? null : data[data.length - 2];

  double? get latestAmount => (latest?['amount'] as num?)?.toDouble();
  double? get latestConsumption => (latest?['consumption'] as num?)?.toDouble();

  /// Bir önceki döneme göre yüzde değişim. Karşılaştırma yapılamıyorsa null.
  double? get changePercent {
    final current = latestConsumption;
    final prev = (previous?['consumption'] as num?)?.toDouble();
    if (current == null || prev == null || prev == 0) return null;
    return (current - prev) / prev * 100;
  }
}

/// Enerji Tüketimi Mobil Ekranı - Apple Tarzı
class EnergyConsumptionMobileScreen extends StatefulWidget {
  const EnergyConsumptionMobileScreen({super.key});

  @override
  State<EnergyConsumptionMobileScreen> createState() =>
      _EnergyConsumptionMobileScreenState();
}

class _EnergyConsumptionMobileScreenState
    extends State<EnergyConsumptionMobileScreen> {
  bool _loading = true;

  /// Sayaç türleri 001_initial_schema.sql:237'deki değerlerdir.
  late final List<_MeterSection> _sections = [
    _MeterSection(
        title: 'Elektrik',
        meterType: 'ELECTRIC',
        icon: Icons.bolt_rounded,
        color: AppleTheme.systemYellow),
    _MeterSection(
        title: 'Isıtma',
        meterType: 'HEAT',
        icon: Icons.local_fire_department_rounded,
        color: AppleTheme.systemOrange),
    _MeterSection(
        title: 'Su',
        meterType: 'WATER_COLD',
        icon: Icons.water_drop_rounded,
        color: AppleTheme.systemBlue),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    for (final section in _sections) {
      section.error = null;
      section.notImplemented = false;
      try {
        final result =
            await apiClient.getConsumptionSummary(meterType: section.meterType);
        final rows = (result['data'] as List?) ?? const [];
        final parsed = rows
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort((a, b) =>
              ((a['period'] as String?) ?? '').compareTo((b['period'] as String?) ?? ''));
        section.data = parsed;
        section.unit = (result['unit'] as String?) ?? '';
      } catch (e) {
        section.data = const [];
        section.notImplemented = isNotImplemented(e);
        section.error = toUserMessage(e);
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool get _allNotImplemented => _sections.every((s) => s.notImplemented);
  bool get _allFailed => _sections.every((s) => s.error != null);

  /// Yalnızca verisi GELEN sayaçların son dönem tutarları toplanır.
  /// Hiç veri yoksa null döner ve ekranda "—" gösterilir.
  double? get _totalLatestAmount {
    final amounts =
        _sections.map((s) => s.latestAmount).whereType<double>().toList();
    return amounts.isEmpty ? null : amounts.reduce((a, b) => a + b);
  }

  /// Veri gelen ilk sayacın son dönem etiketi (örn. `2026-01`).
  String? get _latestPeriod {
    for (final section in _sections) {
      final period = section.latest?['period'] as String?;
      if (period != null && period.isNotEmpty) return period;
    }
    return null;
  }

  /// Veri gelen ilk sayaç; hiçbirinde veri yoksa null.
  _MeterSection? get _firstSectionWithData {
    for (final section in _sections) {
      if (section.data.isNotEmpty) return section;
    }
    return null;
  }

  double? get _totalPreviousAmount {
    final amounts = _sections
        .map((s) => (s.previous?['amount'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    return amounts.isEmpty ? null : amounts.reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Tüketim verisi alınıyor…')
            : RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    ..._buildContent(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_rounded)),
          const Expanded(
              child: Text('Enerji Tüketimi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_allNotImplemented) {
      return const [
        SliverToBoxAdapter(
          child: NotImplementedNotice(
            title: 'Tüketim takibi henüz hazır değil',
            detail: 'Sayaç okuma ve tüketim verisi sunucu tarafında hazır '
                'olmadığı için tüketiminiz gösterilemiyor.',
          ),
        ),
      ];
    }
    if (_allFailed) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateView(
              message: _sections.first.error!, onRetry: _load),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(child: _buildTotalCard()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              for (final section in _sections) ...[
                _buildUsageCard(section),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildTrendCard()),
    ];
  }

  Widget _buildTotalCard() {
    final total = _totalLatestAmount;
    final previous = _totalPreviousAmount;
    final diff = (total != null && previous != null) ? total - previous : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppleTheme.systemBlue, AppleTheme.systemPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _periodLabel(_latestPeriod) ?? 'Son Dönem',
                  style: const TextStyle(color: Colors.white70),
                ),
                // Rozet yalnızca GERÇEK bir karşılaştırma yapılabiliyorsa gösterilir.
                if (diff != null && previous != 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(
                            diff <= 0
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '%${(diff.abs() / previous! * 100).toStringAsFixed(0)} '
                          '${diff <= 0 ? 'tasarruf' : 'artış'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(total == null ? '—' : formatTry(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              total == null
                  ? 'Tüketim tutarı alınamadı'
                  : (diff == null
                      ? 'Karşılaştırma için önceki dönem verisi yok'
                      : 'Geçen döneme göre ${formatTry(diff.abs())} '
                          '${diff <= 0 ? 'daha az' : 'daha fazla'}'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(_MeterSection section) {
    final change = section.changePercent;
    final consumption = section.latestConsumption;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(section.icon, color: section.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (section.notImplemented)
                  const Text('Bu sayaç türü sunucuda henüz hazır değil',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.secondaryLabel))
                else if (section.error != null)
                  Text(section.error!,
                      style: const TextStyle(
                          fontSize: 13, color: AppleTheme.systemRed))
                else if (consumption == null)
                  const Text('Bu dönem için okuma yok',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.secondaryLabel))
                else
                  Row(
                    children: [
                      Text('${formatNumber(consumption)} ${section.unit}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      if (change != null) ...[
                        const SizedBox(width: 8),
                        _buildChangeBadge(change),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  section.latestAmount == null
                      ? '—'
                      : formatTry(section.latestAmount),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: section.color)),
              Text(
                  (section.latest?['status'] as String?) == 'BILLED'
                      ? 'faturalandı'
                      : 'tahakkuk bekliyor',
                  style: const TextStyle(
                      fontSize: 11, color: AppleTheme.tertiaryLabel)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBadge(double change) {
    final isDecrease = change < 0;
    final color = isDecrease ? AppleTheme.systemGreen : AppleTheme.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isDecrease
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 12,
              color: color),
          Text('${change.abs().toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Trend grafiği yalnızca gerçekten veri gelen ilk sayaç türü için çizilir.
  Widget _buildTrendCard() {
    final section = _firstSectionWithData;
    if (section == null) {
      return const SizedBox.shrink();
    }

    final maxConsumption = section.data
        .map((d) => (d['consumption'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppleTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${section.title} — Son ${section.data.length} Dönem',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final row in section.data)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 24,
                          height: maxConsumption == 0
                              ? 2
                              : 80 *
                                  (((row['consumption'] as num?)?.toDouble() ??
                                          0) /
                                      maxConsumption),
                          decoration: BoxDecoration(
                            color: section.color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            _shortPeriodLabel(row['period'] as String?) ?? '—',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _monthNames = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  /// `2026-01` → `Ocak 2026`
  String? _periodLabel(String? period) {
    if (period == null || !period.contains('-')) return period;
    final parts = period.split('-');
    final month = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return period;
    return '${_monthNames[month]} ${parts[0]}';
  }

  /// `2026-01` → `Oca`
  String? _shortPeriodLabel(String? period) {
    if (period == null || !period.contains('-')) return period;
    final month = int.tryParse(period.split('-')[1]) ?? 0;
    if (month < 1 || month > 12) return period;
    return _monthNames[month].substring(0, 3);
  }
}
