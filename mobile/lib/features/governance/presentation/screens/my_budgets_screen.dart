// İşletme projesi (FAZ H.6 S12, kullanıcı kararı K3): malik/vekil sitenin yıllık gider bütçesini ve kendi
// bölümünün payını görür; site ayarı açıksa görüş/itiraz bildirir (KMK m.37). Görüş genel kurulda görüşülür.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../../core/widgets/future_list.dart';

const _status = {
  'NOTIFIED': 'Geçici proje (genel kurul onayı bekliyor)',
  'APPROVED': 'Genel kurulda onaylandı',
  'FINALIZED': 'Kesinleşti',
};

class MyBudgetsScreen extends StatefulWidget {
  const MyBudgetsScreen({super.key});

  @override
  State<MyBudgetsScreen> createState() => _MyBudgetsScreenState();
}

class _MyBudgetsScreenState extends State<MyBudgetsScreen> {
  bool _enabled = true;

  Future<List<dynamic>> _load() async {
    final r = await apiClient.getMyBudgets();
    final en = r['objections_enabled'] != false;
    if (mounted && en != _enabled) setState(() => _enabled = en);
    return (r['data'] as List?) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme Projesi')),
      body: FutureList(
        load: _load,
        empty: 'Tebliğ edilmiş işletme projesi yok',
        emptyIcon: Icons.account_balance_outlined,
        header: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('İşletme projesi sitenin yıllık gider bütçesi ve her bölümün aylık payıdır; aidatın dayanağıdır. '
              'Genel kurulda onaylanır (KMK m.37).'),
        ),
        itemBuilder: (context, b, _) => ListTile(
          leading: const Icon(Icons.account_balance),
          title: Text('${b['period_year']} işletme projesi'),
          subtitle: Text('${_status['${b['status']}'] ?? b['status']} · toplam ${formatTry(toNum(b['total_amount']))}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BudgetDetail(id: '${b['id']}'))),
        ),
      ),
    );
  }
}

class _BudgetDetail extends StatefulWidget {
  final String id;
  const _BudgetDetail({required this.id});

  @override
  State<_BudgetDetail> createState() => _BudgetDetailState();
}

class _BudgetDetailState extends State<_BudgetDetail> {
  late Future<Map<String, dynamic>> _future = apiClient.getMyBudget(widget.id);

  Future<void> _reload() async {
    setState(() => _future = apiClient.getMyBudget(widget.id));
    await _future;
  }

  Future<void> _object(List units) async {
    String? unitId = units.length == 1 ? '${(units.first as Map)['id']}' : null;
    unitId ??= await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(title: const Text('Hangi bölüm için?'), children: [
        for (final u in units.whereType<Map>())
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '${u['id']}'), child: Text('${u['name']}')),
      ]),
    );
    if (unitId == null || !mounted) return;
    final reason = await askTextDialog(context, 'Görüş / itiraz', 'Gerekçeniz');
    if (reason == null || !mounted) return;
    if (await runSnack(context, () => apiClient.addBudgetObjection(widget.id, unitId!, reason), 'Görüşünüz kaydedildi; genel kurulda görüşülür')) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme projesi')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final r = snap.data!;
          final b = Map<String, dynamic>.from((r['budget'] as Map?) ?? {});
          final items = ((b['items'] as List?) ?? []).whereType<Map>().toList();
          final shares = ((r['my_shares'] as List?) ?? []).whereType<Map>().toList();
          final mine = ((r['my_objections'] as List?) ?? []).whereType<Map>().toList();
          final units = (r['my_units'] as List?) ?? [];
          final enabled = r['objections_enabled'] != false;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
              ListTile(
                title: Text('${b['period_year']} · toplam ${formatTry(toNum(b['total_amount']))}'),
                subtitle: Text('${_status['${b['status']}'] ?? b['status']}'
                    '${b['decision_ref'] != null && '${b['decision_ref']}'.isNotEmpty ? '\nKarar: ${b['decision_ref']}' : ''}'),
              ),
              const Divider(),
              const ListTile(title: Text('Bölümümün payı', style: TextStyle(fontWeight: FontWeight.w600))),
              for (final s in shares)
                ListTile(
                  dense: true,
                  title: Text('${s['unit_name']}'),
                  subtitle: Text('Aylık ${formatTry(toNum(s['monthly_kurus']) / 100)} · yıllık ${formatTry(toNum(s['annual_kurus']) / 100)}'),
                ),
              const Divider(),
              const ListTile(title: Text('Kalemler', style: TextStyle(fontWeight: FontWeight.w600))),
              for (final i in items)
                ListTile(dense: true, title: Text('${i['name']}'), trailing: Text(formatTry(toNum(i['amount'])))),
              const Divider(),
              ListTile(
                title: const Text('Görüş / itirazlarım', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${r['note'] ?? ''}'),
              ),
              for (final o in mine)
                ListTile(
                  dense: true,
                  title: Text('${o['reason']}'),
                  subtitle: Text('${formatDateTime(o['submitted_at'])} · ${o['status']}${(o['resolution'] ?? '').toString().isNotEmpty ? ' · ${o['resolution']}' : ''}'),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: enabled
                    ? FilledButton.icon(onPressed: () => _object(units), icon: const Icon(Icons.rate_review_outlined), label: const Text('Görüş / itiraz bildir'))
                    : const Text('Site yönetimi çevrim içi görüş/itiraz alımını kapattı; görüşünüzü genel kurulda ya da yazılı iletebilirsiniz.'),
              ),
            ]),
          );
        },
      ),
    );
  }
}
