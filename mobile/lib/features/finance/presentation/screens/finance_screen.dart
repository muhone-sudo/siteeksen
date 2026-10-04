// Finansal Durum Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// Önceki sürüm hiçbir ağ çağrısı yapmıyordu. Toplam borç koda gömülü "₺1.200,00"
// idi ve altındaki dört aidat satırı ("Ocak 2026 / Aralık 2025 …") tamamen
// uydurmaydı — her kullanıcıya, her sitede aynı rakamlar gösteriliyordu.
// "Öde" düğmesinin `onPressed`'i boştu, satırların `onTap`'i boştu.
// Para ekranında uydurma rakam göstermek kabul edilemez.
//
// Bu sürüm:
//   - Borcu `GET /finance/debt-status`, tahakkukları `GET /finance/assessments`
//     uçlarından alır (apiClient.getDebtStatus / getAssessments).
//   - Veri alınamazsa uydurma rakam göstermez; hatayı ve "yeniden dene"yi gösterir.
//   - Tahakkuk yoksa "veri yok" der; bu "veri alınamadı" ile karıştırılmaz.
//   - "Öde" gerçek ödeme ekranına (duesPayment) götürür.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool _loading = true;
  String? _loadError;
  bool _notImplemented = false;

  Map<String, dynamic>? _debt;
  List<Map<String, dynamic>> _assessments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _notImplemented = false;
    });
    try {
      final debt = await apiClient.getDebtStatus();
      final assessments = await apiClient.getAssessments();
      if (!mounted) return;
      setState(() {
        _debt = debt;
        _assessments = assessments
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notImplemented = isNotImplemented(e);
        _loadError = toUserMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Durumum'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Finansal durumunuz alınıyor…');
    }
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'Finans modülü henüz hazır değil',
          detail: 'Sunucu bu uç için henüz gerçek veri döndürmüyor.',
        ),
      );
    }
    if (_loadError != null) {
      return ErrorStateView(message: _loadError!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          Text(
            'Aidatlarım',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildAssessmentList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final balance = (_debt?['current_balance'] as num?)?.toDouble();
    final hasDebt = (_debt?['has_debt'] as bool?) ?? ((balance ?? 0) > 0);
    final overdueMonths = (_debt?['overdue_months'] as num?)?.toInt() ?? 0;
    final nextDue = _debt?['next_due_date'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Toplam Borç',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              // Sunucudan bakiye gelmediyse uydurma rakam değil "—" gösterilir.
              balance == null ? '—' : formatTry(balance),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: balance == null
                        ? Colors.grey
                        : (hasDebt ? Colors.red : Colors.green),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              overdueMonths > 0
                  ? '$overdueMonths ay gecikmiş ödeme var'
                  : (formatDate(nextDue) == '—'
                      ? 'Yaklaşan ödeme yok'
                      : 'Son ödeme tarihi: ${formatDate(nextDue)}'),
              style: TextStyle(
                fontSize: 13,
                color: overdueMonths > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.pushNamed('duesPayment');
                      // Ödeme ekranından dönüldüğünde bakiye tazelensin.
                      if (mounted) _load();
                    },
                    child: const Text('Öde'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAssessmentList() {
    if (_assessments.isEmpty) {
      return const [
        EmptyStateView(
          message: 'Tahakkuk kaydı bulunamadı.',
          icon: Icons.receipt_long_rounded,
        ),
      ];
    }
    return _assessments.map(_AssessmentItem.new).toList();
  }
}

class _AssessmentItem extends StatelessWidget {
  /// Sunucudan gelen ham tahakkuk kaydı (`AssessmentSummary`).
  final Map<String, dynamic> assessment;

  const _AssessmentItem(this.assessment);

  String get _periodLabel => assessmentLabel(assessment);

  @override
  Widget build(BuildContext context) {
    final status = (assessment['status'] as String?) ?? 'PENDING';
    final isPaid = status == 'PAID';
    final isOverdue = status == 'OVERDUE';
    final color = isPaid
        ? Colors.green
        : isOverdue
            ? Colors.red
            : Colors.orange;
    final total = (assessment['total_amount'] as num?)?.toDouble() ?? 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isPaid
                ? Icons.check
                : isOverdue
                    ? Icons.priority_high
                    : Icons.schedule,
            color: color,
          ),
        ),
        title: Text(_periodLabel),
        subtitle: Text(formatTry(total)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isPaid
                ? 'Ödendi'
                : isOverdue
                    ? 'Gecikmiş'
                    : status == 'PARTIAL'
                        ? 'Kısmi'
                        : 'Bekliyor',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
