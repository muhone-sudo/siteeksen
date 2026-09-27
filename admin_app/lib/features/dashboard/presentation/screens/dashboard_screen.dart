// Yönetici ana ekranı (dashboard).
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Ekran tamamen koda gömülü sayılarla çalışıyordu: "124 sakin", "₺45,780 tahsilat",
// "₺12,350 borç", "8 açık talep" ve üç uydurma ödeme kaydı ("Ahmet Yılmaz",
// "Ayşe Kaya", "Mehmet Demir"). Site adı da sabit "Mavi Kent Sitesi" yazıyordu.
// Yönetici bu ekrana bakıp para kararı verebileceği için bu, en riskli uydurma
// veriydi. Artık tüm değerler `GET /dashboard/stats` (gateway özet ucu) ve
// `GET /finance/payments` üzerinden gelir.
//
// Gateway özet ucu `{data: {...}, unavailable: [...], partial: bool}` döndürür:
// alt servislerden biri yanıt vermezse bunu gizlemek yerine açıkça bildiririz;
// değeri alınamayan kart "—" gösterir — sıfır ya da uydurma sayı GÖSTERMEZ.
//
// "Bekleyen Borç" kartı kaldırıldı: sunucu bu değeri üretmiyor, dolayısıyla
// gösterilecek gerçek bir veri yok. Yerine sunucunun gerçekten hesapladığı
// "Tahsilat Oranı" kondu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../finance/presentation/screens/payments_screen.dart' show paymentStatus;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  // Özet kartları
  Map<String, dynamic> _stats = const {};
  Object? _statsError;
  List<String> _unavailableSources = const [];

  // Son ödemeler
  List<dynamic> _payments = const [];
  Object? _paymentsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // İki bölüm birbirinden bağımsız: biri hata verse bile diğeri gösterilir.
    // Tek bir try bloğuna almak, çalışan bölümü de gizlerdi.
    Map<String, dynamic> stats = const {};
    Object? statsError;
    List<String> unavailable = const [];
    try {
      final response = await apiClient.getDashboard();
      final data = response['data'];
      stats = data is Map ? Map<String, dynamic>.from(data) : response;
      final missing = response['unavailable'];
      if (missing is List) {
        unavailable = missing
            .map((e) => e is Map ? '${e['source']}' : '$e')
            .toList(growable: false);
      }
    } catch (e) {
      statsError = e;
    }

    List<dynamic> payments = const [];
    Object? paymentsError;
    try {
      payments = await apiClient.getList('/finance/payments');
    } catch (e) {
      paymentsError = e;
    }

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _statsError = statsError;
      _unavailableSources = unavailable;
      _payments = payments;
      _paymentsError = paymentsError;
      _loading = false;
    });
  }

  /// Sunucudan gelen sayıyı biçimlendirir; değer yoksa uydurmak yerine "—" döner.
  String _statValue(String key, String Function(num) format) {
    final value = _stats[key];
    if (value is num) return format(value);
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return format(parsed);
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView(message: 'Özet veriler alınıyor...')
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoş Geldiniz 👋',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // --- Özet kartları ---
                    _buildStats(),
                    const SizedBox(height: 24),

                    // --- Hızlı işlemler (yalnızca gezinme; veri içermez) ---
                    const Text(
                      'Hızlı İşlemler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_circle,
                            label: 'Tahakkuk Oluştur',
                            onTap: () => context.go('/finance/assessments/create'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.campaign,
                            label: 'Duyuru Yayınla',
                            onTap: () => context.go('/announcements/create'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.speed,
                            label: 'Sayaç Oku',
                            onTap: () => context.go('/meters/reading'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.bar_chart,
                            label: 'Rapor Oluştur',
                            onTap: () => context.go('/reports'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Son ödemeler ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Son Ödemeler',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () => context.go('/finance/payments'),
                          child: const Text('Tümünü Gör'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPayments(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStats() {
    if (_statsError != null) {
      final error = _statsError!;
      if (isNotImplemented(error)) {
        return const NotImplementedNotice(
          title: 'Özet veriler henüz hazır değil',
          detail: 'Sunucu bu özeti henüz üretmiyor (501).',
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _StatCard(
              icon: Icons.people,
              label: 'Toplam Sakin',
              value: _statValue('totalResidents', formatNumber),
              color: AppTheme.primaryColor,
              onTap: () => context.go('/residents'),
            ),
            _StatCard(
              icon: Icons.account_balance_wallet,
              label: 'Dönem Tahsilatı',
              value: _statValue('monthlyIncome', formatTry),
              color: AppTheme.successColor,
              onTap: () => context.go('/finance'),
            ),
            _StatCard(
              icon: Icons.percent,
              label: 'Tahsilat Oranı',
              value: _statValue(
                  'collectionRate', (v) => '%${formatNumber(v)}'),
              color: AppTheme.warningColor,
              onTap: () => context.go('/finance'),
            ),
            _StatCard(
              icon: Icons.support_agent,
              label: 'Açık Talep',
              value: _statValue('pendingRequests', formatNumber),
              color: AppTheme.errorColor,
              onTap: () => context.go('/requests'),
            ),
          ],
        ),
        // Kısmi veri uyarısı: eksik kartın neden "—" olduğunu kullanıcı bilmeli.
        if (_unavailableSources.isNotEmpty)
          NotImplementedNotice(
            title: 'Bazı özet verileri alınamadı',
            detail:
                'Yanıt vermeyen kaynaklar: ${_unavailableSources.join(', ')}. '
                'Bu kartlar "—" gösterir.',
          ),
      ],
    );
  }

  Widget _buildPayments() {
    if (_paymentsError != null) {
      final error = _paymentsError!;
      if (isNotImplemented(error)) {
        return const NotImplementedNotice(
          title: 'Ödeme listesi henüz hazır değil',
          detail: 'Sunucu bu listeyi henüz üretmiyor (501).',
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }

    if (_payments.isEmpty) {
      return const EmptyStateView(
        message: 'Kayıtlı ödeme yok.',
        icon: Icons.receipt_long_outlined,
      );
    }

    // Yalnızca en son 5 ödeme; tamamı için "Tümünü Gör".
    final recent = _payments.take(5).toList();
    return Column(
      children: recent
          .map((p) => _PaymentCard(payment: Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  /// Sunucudan gelen ham ödeme kaydı. Tip güvenli model henüz yok (denetim
  /// bulgusu: freezed/json_serializable kullanılmıyor), bu yüzden alanlar
  /// savunmacı biçimde okunur: eksik alan çökmeye değil "—" gösterimine yol açar.
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final name = (payment['name'] ?? '').toString();
    final unit = (payment['unit'] ?? '').toString();
    final amount = payment['amount'];
    // DÜZELTME (2026-09-27): tamamlanmamış ödemede `completed_at` sıfır zaman
    // damgası gelir (null değil); `??` düşmediği için tarih hep "—" çıkıyordu.
    final date = parseApiDate(payment['completed_at']) ?? payment['created_at'];
    // Onay bekleyen/reddedilen ödeme de yeşil tikle gösteriliyordu.
    final (label, color) = paymentStatus(payment['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(payment['status'] == 'COMPLETED' ? Icons.check : Icons.schedule, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? '—' : name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${unit.isEmpty ? '—' : unit} · $label',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount == null ? '—' : formatTry(toNum(amount)),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(formatDateTime(date),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
