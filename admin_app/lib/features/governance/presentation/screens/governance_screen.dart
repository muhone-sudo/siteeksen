// Yönetişim (KMK) — salt okuma: işletme projesi, genel kurul, karar defteri.
//
// NEDEN VAR (2026-09-26): governance servisi (KMK m.20, 28-32, 36-37) gerçek
// veriyle çalışıyor, web panelinde ekranları var, ama mobil uygulamada hiçbir
// karşılığı yoktu. Mobilde izleme yapılır; karar alma, oy ve kesinleştirme gibi
// hukuki sonuç doğuran işlemler bilerek web paneline bırakıldı (hazirun, vekâlet
// ve imza denetimi büyük ekran ister).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const budgetStatusLabels = {'DRAFT': 'Taslak', 'NOTIFIED': 'Tebliğ edildi (itiraz süresi)', 'FINAL': 'Kesinleşti'};
const assemblyStatusLabels = {'PLANNED': 'Planlandı', 'NOTIFIED': 'Çağrı yapıldı', 'HELD': 'Yapıldı'};
const decisionLabels = {'PENDING': 'Karar bekliyor', 'ACCEPTED': 'Kabul', 'REJECTED': 'Red'};

class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetişim'),
          bottom: const TabBar(tabs: [Tab(text: 'İşletme projesi'), Tab(text: 'Genel kurul'), Tab(text: 'Karar defteri')]),
        ),
        body: const TabBarView(children: [_Budgets(), _Assemblies(), _DecisionBook()]),
      ),
    );
  }
}

class _Budgets extends StatelessWidget {
  const _Budgets();

  @override
  Widget build(BuildContext context) {
    return ApiList(
      load: () => apiClient.getList('/governance/budgets'),
      empty: 'İşletme projesi yok',
      itemBuilder: (context, b, _) => ListTile(
        title: Text('${b['period_year']} işletme projesi'),
        subtitle: Text([
          budgetStatusLabels['${b['status']}'] ?? '${b['status']}',
          formatTry(toNum(b['total_amount'])),
          if (parseApiDate(b['objection_deadline']) != null) 'İtiraz son: ${formatDate(b['objection_deadline'])}',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BudgetDetail(id: '${b['id']}'))),
      ),
    );
  }
}

class _BudgetDetail extends StatelessWidget {
  final String id;
  const _BudgetDetail({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme projesi')),
      body: ApiObject(
        load: () => apiClient.getMap('/governance/budgets/$id'),
        builder: (context, b, _) {
          final items = ApiClient.listOf(b['items']).whereType<Map>().toList();
          final shares = ApiClient.listOf(b['unit_shares']).whereType<Map>().toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${b['period_year']} · ${budgetStatusLabels['${b['status']}'] ?? b['status']}',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('Toplam: ${formatTry(toNum(b['total_amount']))} · Açık itiraz: ${toNum(b['open_objections']).toInt()}'),
              const Divider(height: 24),
              Text('Kalemler', style: Theme.of(context).textTheme.titleSmall),
              for (final i in items)
                ListTile(
                  dense: true,
                  title: Text('${i['name']}'),
                  subtitle: Text('${i['distribution_type']} · ${i['kind'] ?? 'EXPENSE'}'),
                  trailing: Text(formatTry(toNum(i['amount']))),
                ),
              const Divider(height: 24),
              Text('Daire payları (aylık)', style: Theme.of(context).textTheme.titleSmall),
              for (final s in shares)
                ListTile(
                  dense: true,
                  title: Text('${s['unit_name']}'),
                  // Paylar kuruş olarak saklanır (toplamları birebir tutar).
                  trailing: Text(formatTry(toNum(s['monthly_kurus']) / 100)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Assemblies extends StatelessWidget {
  const _Assemblies();

  @override
  Widget build(BuildContext context) {
    return ApiList(
      load: () => apiClient.getList('/governance/assemblies'),
      empty: 'Genel kurul kaydı yok',
      itemBuilder: (context, a, _) => ListTile(
        title: Text('${a['kind'] == 'EXTRAORDINARY' ? 'Olağanüstü' : 'Olağan'} genel kurul · ${a['call_number'] ?? 1}. toplantı'),
        subtitle: Text([
          formatDateTime(a['scheduled_at']),
          assemblyStatusLabels['${a['status']}'] ?? '${a['status']}',
          if (a['quorum_met'] != null) (a['quorum_met'] == true ? 'Nisap var' : 'Nisap yok'),
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _AssemblyDetail(id: '${a['id']}'))),
      ),
    );
  }
}

class _AssemblyDetail extends StatelessWidget {
  final String id;
  const _AssemblyDetail({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genel kurul')),
      body: ApiObject(
        load: () => apiClient.getMap('/governance/assemblies/$id'),
        builder: (context, a, _) {
          final agenda = ApiClient.listOf(a['agenda_items']).whereType<Map>().toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(formatDateTime(a['scheduled_at']), style: Theme.of(context).textTheme.titleMedium),
              if ((a['location'] ?? '').toString().isNotEmpty) Text('${a['location']}'),
              Text(assemblyStatusLabels['${a['status']}'] ?? '${a['status']}'),
              if (a['attended_units'] != null)
                Text('Katılım: ${a['attended_units']}/${a['total_units']} daire · '
                    'arsa payı ${toNum(a['attended_share_ratio']).toStringAsFixed(2)}/${toNum(a['total_share_ratio']).toStringAsFixed(2)}'),
              const Divider(height: 24),
              for (final i in agenda)
                Card(
                  child: ListTile(
                    title: Text('${i['order_no']}. ${i['title']}'),
                    subtitle: Text([
                      decisionLabels['${i['decision_status']}'] ?? '${i['decision_status']}',
                      'Lehte ${i['votes_for']} · aleyhte ${i['votes_against']} · çekimser ${i['votes_abstain']}',
                      if ((i['decision_text'] ?? '').toString().isNotEmpty) '${i['decision_text']}',
                    ].join('\n')),
                  ),
                ),
              const SizedBox(height: 12),
              const Text('Hazirun, oy ve karar işlemleri web panelinden yapılır.', style: TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}

class _DecisionBook extends StatefulWidget {
  const _DecisionBook();

  @override
  State<_DecisionBook> createState() => _DecisionBookState();
}

class _DecisionBookState extends State<_DecisionBook> {
  int _year = DateTime.now().year;

  /// Defter yıla göre açılır (yoksa oluşturulur — yalnız M/B); kayıtlar ve
  /// hash zinciri doğrulaması okunur.
  Future<Map<String, dynamic>> _load() async {
    final book = await apiClient.post('/governance/books?kind=DECISION&year=$_year');
    final id = '${book['id']}';
    final entries = await apiClient.getList('/governance/books/$id/entries');
    final verify = await apiClient.getMap('/governance/books/$id/verify');
    return {'book': book, 'entries': entries, 'verify': verify};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
            Text('$_year', style: Theme.of(context).textTheme.titleMedium),
            IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        Expanded(
          child: ApiObject(
            key: ValueKey(_year),
            load: _load,
            builder: (context, d, _) {
              final book = d['book'] as Map<String, dynamic>;
              final verify = d['verify'] as Map<String, dynamic>;
              final entries = (d['entries'] as List).whereType<Map>().toList();
              final valid = verify['valid'] == true;
              return ListView(
                children: [
                  ListTile(
                    leading: Icon(valid ? Icons.verified : Icons.error, color: valid ? Colors.green : Colors.red),
                    title: Text(valid ? 'Kayıt zinciri doğrulandı' : 'Kayıt zinciri BOZUK'),
                    subtitle: Text('${verify['message'] ?? ''}\nDefter: ${book['status'] == 'CLOSED' ? 'notere kapatıldı' : 'açık'}'),
                  ),
                  if (entries.isEmpty) const ListTile(title: Text('Bu yıl kayıt yok')),
                  for (final e in entries)
                    ListTile(
                      title: Text('${e['entry_no']}. ${e['title']}'),
                      subtitle: Text('${formatDate(e['entry_date'])}\n${e['body']}'),
                      isThreeLine: true,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
