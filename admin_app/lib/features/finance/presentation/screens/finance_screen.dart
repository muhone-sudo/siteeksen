// Finans özeti: dönem bazlı tahakkuk/tahsilat, borçlular.
//
// DÜZELTME (2026-09-26): özet yanıtı `{data:[{period,total_amount,
// collected_amount,rate,…}]}` biçimindeydi; ekran alanları üst düzeyde aradığı
// için hep "—" gösteriyordu. Borçlu listesi için "uç yok" deniyordu; oysa
// `GET /finance/debtors` var.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

/// "2026-03" → "Mart 2026".
String periodLabel(Object? period) {
  const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  final m = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch('${period ?? ''}');
  if (m == null) return '${period ?? '—'}';
  final month = int.parse(m.group(2)!);
  return month >= 1 && month <= 12 ? '${months[month]} ${m.group(1)}' : '${period ?? ''}';
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _year = DateTime.now().year;
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finans'),
          actions: [
            IconButton(
              tooltip: 'Ödemeler',
              icon: const Icon(Icons.payments_outlined),
              onPressed: () => context.push('/finance/payments'),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Dönemler'), Tab(text: 'Borçlular')]),
        ),
        floatingActionButton: _canWrite
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/finance/assessments/create'),
                icon: const Icon(Icons.add),
                label: const Text('Tahakkuk'),
              )
            : null,
        body: TabBarView(children: [
          Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
              Text('$_year', style: Theme.of(context).textTheme.titleMedium),
              IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
            ]),
            Expanded(
              child: ApiList(
                token: _year,
                load: () => apiClient.getList('/finance/assessments/overview', query: {'year': _year}),
                empty: '$_year yılında tahakkuk yok',
                header: (items) {
                  final total = items.fold<num>(0, (a, i) => a + toNum(i['total_amount']));
                  final collected = items.fold<num>(0, (a, i) => a + toNum(i['collected_amount']));
                  return StatRow([
                    ('Tahakkuk', formatTry(total)),
                    ('Tahsilat', formatTry(collected)),
                    ('Oran', total > 0 ? '%${(collected * 100 / total).toStringAsFixed(0)}' : '—'),
                  ]);
                },
                itemBuilder: (context, p, _) {
                  // Sunucu `rate`'i tam sayı YÜZDE olarak döner (0-100).
                  final rate = toNum(p['rate']).toDouble();
                  return ListTile(
                    title: Text(periodLabel(p['period'])),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Son ödeme: ${formatDate(p['due_date'])} · '
                          '${formatTry(toNum(p['collected_amount']))} / ${formatTry(toNum(p['total_amount']))}'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: (rate / 100).clamp(0, 1).toDouble()),
                    ]),
                    trailing: Text('%${rate.toStringAsFixed(0)}'),
                  );
                },
              ),
            ),
          ]),
          ApiList(
            load: () => apiClient.getList('/finance/debtors'),
            empty: 'Borçlu daire yok',
            header: (items) => StatRow([
              ('Borçlu', '${items.length}'),
              ('Toplam borç', formatTry(items.fold<num>(0, (a, i) => a + toNum(i['amount'])))),
            ]),
            itemBuilder: (context, d, _) => ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text('${d['name'] ?? ''}'),
              subtitle: Text('${d['unit'] ?? ''}'),
              trailing: Text(formatTry(toNum(d['amount'])), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
