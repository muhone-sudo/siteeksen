// Usta & Hizmet (FAZ M8, K8): sitenin hizmet alanındaki onaylı işletmeler (vitrin) ve sakinin kendi talepleri.
// Telefon yalnız işletmenin paketi izin veriyorsa gelir; diğerlerine talep açılarak ulaşılır.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../../core/widgets/future_list.dart';

const marketRequestStatus = {
  'OPEN': 'Açık — teklif bekleniyor',
  'FULL': 'Doldu — teklifleri inceleyin',
  'EXPIRED': 'Süresi doldu',
  'CLOSED': 'Teklif seçildi',
  'CANCELLED': 'Kapatıldı',
};

String kurusText(Object? v) => formatTry(toNum(v) / 100);

String distanceText(Object? m) {
  if (m == null) return '';
  final v = toNum(m);
  return v < 1000 ? '${v.round()} m' : '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

String priceText(Map s) {
  final min = s['price_min_kurus'], max = s['price_max_kurus'];
  if (min == null) return 'Teklifle';
  final unit = '${s['unit'] ?? ''}'.isEmpty ? '' : ' / ${s['unit']}';
  return '${kurusText(min)} – ${kurusText(max)}$unit';
}

class UstaScreen extends StatefulWidget {
  const UstaScreen({super.key});

  @override
  State<UstaScreen> createState() => _UstaScreenState();
}

class _UstaScreenState extends State<UstaScreen> {
  String? _category;
  late Future<Map<String, dynamic>> _meta;
  final _showcaseKey = GlobalKey<FutureListState>();
  final _mineKey = GlobalKey<FutureListState>();

  @override
  void initState() {
    super.initState();
    _meta = apiClient.getMarketMeta();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Usta & Hizmet'),
          bottom: const TabBar(tabs: [Tab(text: 'Yakınımdakiler'), Tab(text: 'Taleplerim')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/usta/talep');
            _mineKey.currentState?.reload();
          },
          icon: const Icon(Icons.add),
          label: const Text('Talep aç'),
        ),
        body: TabBarView(children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _meta,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LoadingView();
              if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: () => setState(() { _meta = apiClient.getMarketMeta(); }));
              final cats = (snap.data!['categories'] as List? ?? const [])
                  .whereType<Map>()
                  .where((c) => c['buyer_scope'] != 'MANAGEMENT')
                  .toList();
              return FutureList(
                key: _showcaseKey,
                load: () => apiClient.getShowcase(categoryId: _category),
                empty: 'Bu kategoride sitenize hizmet veren onaylı işletme yok.',
                emptyIcon: Icons.handyman_outlined,
                header: SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tümü'),
                          selected: _category == null,
                          onSelected: (_) {
                            setState(() => _category = null);
                            _showcaseKey.currentState?.reload();
                          },
                        ),
                      ),
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${c['name']}'),
                            selected: _category == '${c['id']}',
                            onSelected: (_) {
                              setState(() => _category = '${c['id']}');
                              _showcaseKey.currentState?.reload();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                itemBuilder: (context, b, reload) => _BusinessCard(b: b),
              );
            },
          ),
          FutureList(
            key: _mineKey,
            load: apiClient.getMyMarketRequests,
            empty: 'Henüz talebiniz yok. Usta, temizlik ya da tamir için talep açın; yakınınızdaki işletmeler teklif versin.',
            emptyIcon: Icons.assignment_outlined,
            itemBuilder: (context, r, reload) => Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ListTile(
                title: Text('${r['category_name']}'),
                subtitle: Text([
                  marketRequestStatus['${r['status']}'] ?? '${r['status']}',
                  '${r['accepted_count']}/${r['max_accepts']} işletme kabul etti',
                  formatDate(r['created_at']),
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/usta/talepler/${r['id']}');
                  reload();
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final Map<String, dynamic> b;
  const _BusinessCard({required this.b});

  @override
  Widget build(BuildContext context) {
    final rating = b['rating_avg'];
    final parts = [
      '${b['district']} / ${b['city']}',
      if (b['distance_m'] != null) distanceText(b['distance_m']),
      if (rating != null) '★ ${toNum(rating).toStringAsFixed(1)} (${b['rating_count']})' else 'Henüz puan yok',
      '${b['completed_jobs']} tamamlanan iş',
    ];
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ListTile(
        title: Row(children: [
          Flexible(child: Text('${b['name']}')),
          if (b['featured'] == true) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 18, color: Colors.blue),
          ],
        ]),
        subtitle: Text([
          parts.join(' · '),
          if (b['min_price_kurus'] != null) '${kurusText(b['min_price_kurus'])}\'den başlayan fiyatlar',
        ].join('\n')),
        isThreeLine: b['min_price_kurus'] != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/usta/isletme/${b['id']}'),
      ),
    );
  }
}

class BusinessScreen extends StatelessWidget {
  final String id;
  const BusinessScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: apiClient.getShowcaseBusiness(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!));
          final b = snap.data!;
          final services = (b['services'] as List? ?? const []).whereType<Map>().toList();
          final reviews = (b['reviews'] as List? ?? const []).whereType<Map>().toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('${b['name']}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text([
                '${b['district']} / ${b['city']}',
                if (b['distance_m'] != null) distanceText(b['distance_m']),
                if (b['rating_avg'] != null) '★ ${toNum(b['rating_avg']).toStringAsFixed(1)} (${b['rating_count']} değerlendirme)',
              ].join(' · ')),
              if ('${b['description'] ?? ''}'.isNotEmpty) ...[const SizedBox(height: 8), Text('${b['description']}')],
              const SizedBox(height: 8),
              if (b['phone'] != null)
                Text('Telefon: ${b['phone']}', style: const TextStyle(fontWeight: FontWeight.w600))
              else
                const Text('Bu işletmeye talep göndererek ulaşabilirsiniz.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push('/usta/talep?isletme=${b['id']}'),
                icon: const Icon(Icons.send),
                label: const Text('Bu işletmeye talep gönder'),
              ),
              const SizedBox(height: 16),
              Text('Hizmetler ve ürünler', style: Theme.of(context).textTheme.titleMedium),
              if (services.isEmpty) const Text('Henüz kalem eklenmemiş.'),
              for (final s in services)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s['name']}'),
                  subtitle: '${s['description'] ?? ''}'.isEmpty ? null : Text('${s['description']}'),
                  trailing: Text(priceText(s)),
                ),
              const SizedBox(height: 16),
              Text('Değerlendirmeler', style: Theme.of(context).textTheme.titleMedium),
              if (reviews.isEmpty) const Text('Henüz değerlendirme yok. Puan yalnız Usta & Hizmet üzerinden tamamlanan işlere verilir.'),
              for (final r in reviews)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${'★' * toNum(r['rating']).toInt()}${'☆' * (5 - toNum(r['rating']).toInt())}  ${formatDate(r['created_at'])}'),
                  subtitle: Text([
                    if ('${r['comment'] ?? ''}'.isNotEmpty) '${r['comment']}',
                    if (r['reply'] != null) 'İşletmenin yanıtı: ${r['reply']}',
                  ].join('\n')),
                ),
            ],
          );
        },
      ),
    );
  }
}
