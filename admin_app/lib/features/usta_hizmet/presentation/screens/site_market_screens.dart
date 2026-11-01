// Usta & Hizmet — site adına alım (FAZ M10, K12): yönetici talep açar, teklifleri karşılaştırıp seçer ve seçilen teklifi
// onay bekleyen gidere çevirir; kurul üyesi ve denetçi yalnız okur.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../../core/widgets/forms.dart';

const _status = {'OPEN': 'Açık', 'FULL': 'Doldu', 'EXPIRED': 'Süresi doldu', 'CLOSED': 'Teklif seçildi', 'CANCELLED': 'Kapatıldı'};
const _offerStatus = {'ACTIVE': 'Geçerli', 'ACCEPTED': 'Seçildi', 'DECLINED': 'Seçilmedi'};
const _jobStatus = {'ACTIVE': 'Sürüyor', 'DONE_CLAIMED': 'Tamamlandı (onayınızı bekliyor)', 'COMPLETED': 'Tamamlandı', 'DISPUTED': 'İtirazlı'};

String _kurus(Object? v) => formatTry(toNum(v) / 100);

class SiteMarketScreen extends StatefulWidget {
  const SiteMarketScreen({super.key});

  @override
  State<SiteMarketScreen> createState() => _SiteMarketScreenState();
}

class _SiteMarketScreenState extends State<SiteMarketScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _manager = false;

  @override
  void initState() {
    super.initState();
    apiClient.getCurrentUserRoles().then((r) {
      if (mounted) setState(() => _manager = r.contains('MANAGER'));
    });
  }

  Future<void> _create() async {
    final meta = await apiClient.getMap('/market/meta');
    if (!mounted) return;
    final cats = (meta['categories'] as List? ?? const []).whereType<Map>().where((c) => c['buyer_scope'] != 'RESIDENT');
    final ok = await formAction(context, 'Site adına teklif topla', [
      FSpec('category_id', 'Kategori', type: FType.select, required: true, options: [for (final c in cats) ('${c['id']}', '${c['name']}')]),
      const FSpec('description', 'Ne yapılacak?', type: FType.multiline, required: true),
      const FSpec('preferred_time', 'Uygun zaman'),
    ], (v) async {
      final r = await apiClient.post('/market/requests', {...v, 'buyer_type': 'MANAGEMENT'});
      return {'message': 'Talep ${r['dispatched']} işletmeye iletildi'};
    }, submit: 'Talebi gönder', note: 'Talebi kabul eden işletmeler adınızı, telefonunuzu ve site adresini görür.');
    if (ok) _list.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usta & Hizmet')),
      floatingActionButton: _manager ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Teklif topla')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/market/requests', query: {'scope': 'management'}),
        empty: 'Site adına açılmış talep yok.',
        emptyIcon: Icons.handyman_outlined,
        itemBuilder: (context, r, reload) => Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ListTile(
            title: Text('${r['category_name']} · ${_status['${r['status']}'] ?? r['status']}'),
            subtitle: Text('${r['description']}\n${r['accepted_count']}/${r['max_accepts']} işletme kabul etti · ${formatDate(r['created_at'])}'),
            isThreeLine: true,
            onTap: () async {
              await context.push('/usta-hizmet/${r['id']}');
              reload();
            },
          ),
        ),
      ),
    );
  }
}

class SiteMarketRequestScreen extends StatefulWidget {
  final String id;
  const SiteMarketRequestScreen({super.key, required this.id});

  @override
  State<SiteMarketRequestScreen> createState() => _SiteMarketRequestScreenState();
}

class _SiteMarketRequestScreenState extends State<SiteMarketRequestScreen> {
  late Future<List<Object?>> _future;
  bool _manager = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    apiClient.getCurrentUserRoles().then((r) {
      if (mounted) setState(() => _manager = r.contains('MANAGER'));
    });
  }

  Future<List<Object?>> _load() async {
    Map<String, dynamic>? job;
    try {
      job = await apiClient.getMap('/market/requests/${widget.id}/job');
    } catch (_) {}
    return [await apiClient.getMap('/market/requests/${widget.id}'), await apiClient.getList('/market/requests/${widget.id}/offers'), job];
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _expense(Map<String, dynamic> job, String category) async {
    final cats = await apiClient.getList('/expense-categories');
    if (!mounted) return;
    final vendor = job['vendor'] as Map?;
    final name = '${vendor?['trade_name'] ?? job['business_name']}';
    final ok = await formAction(context, 'Onay bekleyen gider', [
      FSpec('category_id', 'Gider kalemi', type: FType.select, required: true, options: [for (final c in cats.whereType<Map>()) ('${c['id']}', '${c['name']}')]),
      FSpec('expense_date', 'Gider tarihi', type: FType.date, required: true, initial: DateTime.now()),
    ], (v) => apiClient.post('/expenses', {
          ...v,
          'description': 'Usta & Hizmet: $category — $name',
          'amount': toNum(job['amount_kurus']) / 100,
          'is_invoiced': false,
          'invoice_reason': 'Usta & Hizmet teklifi seçildi; fatura iş sonunda alınacak',
          'vendor_name': name,
          'vendor_tax_id': '${vendor?['tax_number'] ?? ''}',
          'notes': 'Usta & Hizmet talep ${widget.id}',
        }), submit: 'Gideri oluştur', note: 'Tutar ${_kurus(job['amount_kurus'])} · $name${vendor != null ? ' · VKN ${vendor['tax_number']}' : ''}. Faturasız gider kurul onayı bekler.');
    if (ok) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site talebi')),
      body: FutureBuilder<List<Object?>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: errorText(snap.error!), onRetry: _reload);
          final r = snap.data![0] as Map<String, dynamic>;
          final offers = (snap.data![1] as List).whereType<Map>().toList();
          final job = snap.data![2] as Map<String, dynamic>?;
          final open = r['status'] != 'CLOSED' && r['status'] != 'CANCELLED';
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                Text('${r['category_name']}', style: Theme.of(context).textTheme.titleLarge),
                Text('${_status['${r['status']}']} · ${r['accepted_count']}/${r['max_accepts']} kabul · ${r['dispatch_count']} işletmeye gönderildi'),
                const SizedBox(height: 8),
                Text('${r['description']}'),
                const SizedBox(height: 16),
                Text('Teklifler', style: Theme.of(context).textTheme.titleMedium),
                if (offers.isEmpty) const Text('Henüz teklif yok.'),
                for (final o in offers)
                  Card(
                    child: ListTile(
                      title: Text('${o['business_name']} · ${_kurus(o['amount_kurus'])}'),
                      subtitle: Text([
                        '${o['description']}',
                        [
                          'geçerli ${formatDate(o['valid_until'])}',
                          if (toNum(o['rating_count']) > 0) '★ ${(toNum(o['rating_sum']) / toNum(o['rating_count'])).toStringAsFixed(1)}',
                          '${o['completed_jobs'] ?? 0} iş',
                          if (o['business_phone'] != null) '${o['business_phone']}',
                          _offerStatus['${o['status']}'] ?? '',
                        ].join(' · '),
                      ].join('\n')),
                      isThreeLine: true,
                      trailing: o['status'] == 'ACTIVE' && open && _manager
                          ? TextButton(
                              onPressed: () async {
                                if (await confirmAction(context, 'Teklifi seç', '${o['business_name']} — ${_kurus(o['amount_kurus'])}. Diğer teklifler reddedilir.',
                                    () => apiClient.post('/market/requests/${widget.id}/offers/${o['id']}/select'), ok: 'Seç', success: 'Teklif seçildi')) {
                                  await _reload();
                                }
                              },
                              child: const Text('Seç'),
                            )
                          : null,
                    ),
                  ),
                if (open && _manager)
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirmAction(context, 'Talebi kapat', 'Teklif seçmeden kapatıyorsunuz; yeni teklif gelmez.',
                          () => apiClient.post('/market/requests/${widget.id}/close'), ok: 'Kapat')) {
                        await _reload();
                      }
                    },
                    child: const Text('Teklif seçmeden kapat'),
                  ),
                if (job != null)
                  Card(
                    margin: const EdgeInsets.only(top: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('İş: ${job['business_name']} · ${_kurus(job['amount_kurus'])} · ${_jobStatus['${job['status']}']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (job['vendor'] is Map)
                          Text('Fatura: ${(job['vendor'] as Map)['trade_name']} · VKN ${(job['vendor'] as Map)['tax_number']} · ${(job['vendor'] as Map)['tax_office']}'),
                        if (_manager) ...[
                          const SizedBox(height: 8),
                          FilledButton.tonal(onPressed: () => _expense(job, '${r['category_name']}'), child: const Text('Onay bekleyen gider oluştur')),
                          if (job['status'] == 'DONE_CLAIMED' || job['status'] == 'DISPUTED')
                            FilledButton(
                              onPressed: () async {
                                if (await runAction(context, () => apiClient.post('/market/requests/${widget.id}/job/confirm'), success: 'İş onaylandı')) await _reload();
                              },
                              child: const Text('İş tamamlandı, onayla'),
                            ),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
