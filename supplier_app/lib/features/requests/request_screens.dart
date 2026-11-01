// Gelen talepler (FAZ M6–M7): maskeli önizleme, kabul (ücret bakiyeden ya da paket hakkından), teklif, yazışma,
// işin tamamlandığını bildirme ve geçersiz talep bildirimi. Ekrana dönüldüğünde liste yenilenir.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/data_state.dart';
import '../../core/widgets/future_list.dart';

String kurus(Object? v) => formatTry(toNum(v) / 100);

const requestStatus = {'OPEN': 'Açık', 'FULL': 'Doldu', 'EXPIRED': 'Süresi doldu', 'CLOSED': 'Kapandı', 'CANCELLED': 'İptal'};
const offerStatus = {'ACTIVE': 'Geçerli', 'WITHDRAWN': 'Geri çekildi', 'ACCEPTED': 'Seçildi', 'DECLINED': 'Seçilmedi'};
const jobStatus = {'ACTIVE': 'Sürüyor', 'DONE_CLAIMED': 'Tamamlandı (onay bekliyor)', 'COMPLETED': 'Tamamlandı', 'DISPUTED': 'Alıcı itiraz etti'};
const disputeReasons = {'FAKE': 'Sahte talep', 'WRONG_CATEGORY': 'Yanlış kategori', 'UNREACHABLE': 'Alıcıya ulaşılamıyor', 'OTHER': 'Diğer'};

String feeText(Map r) {
  if (r['accepted_at'] != null) return r['uses_included'] == true ? 'Paket hakkından düştü' : '${kurus(r['fee_kurus'])} ödendi';
  return r['uses_included'] == true ? 'Paketinizdeki talep hakkından düşer' : 'Kabul ücreti ${kurus(r['fee_kurus'])}';
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  Map<String, dynamic>? _summary;

  Future<List<dynamic>> _load() async {
    final r = await apiClient.requests();
    if (mounted) setState(() => _summary = r);
    return r['data'] as List? ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talepler'),
        bottom: _summary == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Bakiye ${kurus(_summary!['balance_kurus'])} · bu dönem kalan dahil talep ${_summary!['period_included_left']}'),
                ),
              ),
      ),
      body: FutureList(
        load: _load,
        empty: 'Henüz talep yok. Yayındaki işletmelerinizin kategorisinde ve hizmet alanında yeni bir talep açıldığında burada görünür.',
        itemBuilder: (context, r, reload) => Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ListTile(
            title: Text('${r['category_name']} · ${requestStatus['${r['status']}'] ?? r['status']}'),
            subtitle: Text([
              '${r['district']} / ${r['city']}${r['distance_m'] != null ? ' · ${r['distance_m']} m' : ''} · ${r['business_name']}',
              '${r['description']}',
              [
                feeText(r),
                if (r['accepted_at'] != null) 'kabul ettiniz',
                if (r['offer_status'] != null) 'teklif: ${offerStatus['${r['offer_status']}']}',
                if (r['job_status'] != null) 'iş: ${jobStatus['${r['job_status']}']}',
              ].join(' · '),
            ].join('\n')),
            isThreeLine: true,
            onTap: () async {
              await context.push('/talepler/${r['id']}');
              reload();
            },
          ),
        ),
      ),
    );
  }
}

class RequestScreen extends StatefulWidget {
  final String id;
  const RequestScreen({super.key, required this.id});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  late Future<List<Object?>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object?>> _load() async {
    final r = await apiClient.request(widget.id);
    if (r['accepted_at'] == null) return [r, null, null];
    return [r, await apiClient.deal(widget.id), await apiClient.messages(widget.id)];
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _act(Future<void> Function() fn, String ok) async {
    if (await runSnack(context, fn, ok)) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talep')),
      body: FutureBuilder<List<Object?>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final r = snap.data![0] as Map<String, dynamic>;
          final deal = snap.data![1] as Map<String, dynamic>?;
          final msgs = (snap.data![2] as List?)?.whereType<Map>().toList() ?? const <Map>[];
          final contact = r['contact'] as Map?;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                Text('${r['category_name']}', style: Theme.of(context).textTheme.titleLarge),
                Text('${r['district']} / ${r['city']} · ${requestStatus['${r['status']}']} · kabul ${r['accepted_count']}/${r['max_accepts']} · son ${formatDateTime(r['expires_at'])}'),
                const SizedBox(height: 8),
                Text('${r['description']}'),
                if ('${r['preferred_time'] ?? ''}'.isNotEmpty) Text('Zaman: ${r['preferred_time']}'),
                Text('Şubeniz: ${r['business_name']}'),
                Text(feeText(r), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (toNum(r['photo_count']) > 0)
                  SizedBox(
                    height: 110,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (var n = 0; n < toNum(r['photo_count']); n++)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 8),
                          child: FutureBuilder<List<int>>(
                            future: apiClient.requestPhoto(widget.id, n),
                            builder: (context, s) => s.hasData
                                ? Image.memory(Uint8List.fromList(s.data!), width: 100, height: 100, fit: BoxFit.cover)
                                : const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())),
                          ),
                        ),
                    ]),
                  ),
                const SizedBox(height: 12),
                if (contact == null) ...[
                  const Text('Alıcının adı, telefonu ve adresi talebi kabul ettiğinizde açılır.'),
                  if (r['status'] == 'OPEN')
                    FilledButton(
                      onPressed: r['can_afford'] == true
                          ? () async {
                              if (await confirmDialog(context, 'Talebi kabul et',
                                  '${feeText(r)}. Kabul ettiğinizde alıcının iletişim bilgisi açılır; ücret anlaşmadan bağımsızdır.', ok: 'Kabul et')) {
                                await _act(() => apiClient.accept(widget.id), 'Talebi kabul ettiniz; iletişim bilgileri açıldı.');
                              }
                            }
                          : null,
                      child: Text(r['can_afford'] == true ? 'Kabul et' : 'Bakiye yetersiz — Bakiye sekmesinden yükleyin'),
                    ),
                ] else
                  Card(
                    child: ListTile(
                      title: Text('${contact['name']}'),
                      subtitle: Text('${contact['phone'] ?? 'Telefon gizli — mesajla ulaşın'}\n${contact['site_name']} · ${contact['site_address']}'),
                      isThreeLine: true,
                    ),
                  ),
                if (deal != null) ...[
                  _OfferSection(id: widget.id, r: r, deal: deal, act: _act),
                  _JobSection(deal: deal, act: _act),
                  const SizedBox(height: 12),
                  Text('Alıcıyla yazışma', style: Theme.of(context).textTheme.titleMedium),
                  if (msgs.isEmpty) const Text('Henüz mesaj yok. Daire numarasını ve uygun zamanı yazışarak netleştirin.'),
                  for (final m in msgs.reversed)
                    Align(
                      alignment: m['sender_side'] == 'SUPPLIER' ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: m['sender_side'] == 'SUPPLIER' ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${m['body']}\n${m['sender_side'] == 'SUPPLIER' ? 'Siz' : 'Alıcı'} · ${formatDateTime(m['created_at'])}'),
                      ),
                    ),
                  _MessageBox(onSend: (t) => _act(() => apiClient.sendMessage(widget.id, t), 'Gönderildi')),
                  _DisputeSection(id: widget.id, deal: deal, act: _act),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

typedef Act = Future<void> Function(Future<void> Function() fn, String ok);

class _OfferSection extends StatefulWidget {
  final String id;
  final Map r, deal;
  final Act act;
  const _OfferSection({required this.id, required this.r, required this.deal, required this.act});

  @override
  State<_OfferSection> createState() => _OfferSectionState();
}

class _OfferSectionState extends State<_OfferSection> {
  final _amount = TextEditingController(), _desc = TextEditingController(), _until = TextEditingController();

  @override
  void initState() {
    super.initState();
    final active = (widget.deal['offers'] as List).whereType<Map>().where((o) => o['status'] == 'ACTIVE').firstOrNull;
    if (active != null) {
      _amount.text = (toNum(active['amount_kurus']) / 100).toStringAsFixed(0);
      _desc.text = '${active['description']}';
      _until.text = '${active['valid_until']}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = (widget.deal['offers'] as List).whereType<Map>().toList();
    final active = offers.where((o) => o['status'] == 'ACTIVE').firstOrNull;
    final open = widget.r['status'] != 'CLOSED' && widget.r['status'] != 'CANCELLED';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      Text('Teklifiniz', style: Theme.of(context).textTheme.titleMedium),
      for (final o in offers)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${kurus(o['amount_kurus'])} · ${offerStatus['${o['status']}']}'),
          subtitle: Text('geçerli ${formatDate(o['valid_until'])} · ${o['description']}'),
          trailing: o['status'] == 'ACTIVE'
              ? TextButton(onPressed: () => widget.act(() => apiClient.withdrawOffer('${o['id']}'), 'Teklif geri çekildi'), child: const Text('Geri çek'))
              : null,
        ),
      if (open) ...[
        TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tutar (TL)')),
        TextField(controller: _until, decoration: const InputDecoration(labelText: 'Geçerlilik (YYYY-AA-GG)')),
        TextField(controller: _desc, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Açıklama (kapsam, malzeme, süre)')),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => widget.act(
              () => apiClient.saveOffer(widget.id, {
                    'amount_kurus': ((double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0) * 100).round(),
                    'description': _desc.text.trim(),
                    'valid_until': _until.text.trim(),
                  }),
              active == null ? 'Teklif gönderildi' : 'Teklif güncellendi'),
          child: Text(active == null ? 'Teklif gönder' : 'Teklifi güncelle'),
        ),
      ] else
        const Text('Talep kapandı; yeni teklif verilemez.'),
    ]);
  }
}

class _JobSection extends StatelessWidget {
  final Map deal;
  final Act act;
  const _JobSection({required this.deal, required this.act});

  @override
  Widget build(BuildContext context) {
    final j = deal['job'] as Map?;
    if (j == null) return const SizedBox.shrink();
    final review = j['review'] as Map?;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('İş: ${jobStatus['${j['status']}']} · ${kurus(j['amount_kurus'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (j['status'] == 'DISPUTED') Text('Alıcının itirazı: ${j['dispute_note']}'),
          if (j['status'] == 'ACTIVE')
            FilledButton(onPressed: () => act(() => apiClient.jobDone('${j['id']}'), 'Alıcıya işin tamamlandığı bildirildi'), child: const Text('İş tamamlandı')),
          if (j['status'] == 'DONE_CLAIMED') const Text('Alıcının onayı bekleniyor; süresinde yanıt vermezse iş tamamlanmış sayılır.'),
          if (review != null) Text('Alıcının puanı: ${review['rating']}/5 ${review['comment'] ?? ''}'),
        ]),
      ),
    );
  }
}

class _MessageBox extends StatefulWidget {
  final Future<void> Function(String) onSend;
  const _MessageBox({required this.onSend});

  @override
  State<_MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<_MessageBox> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: TextField(controller: _c, decoration: const InputDecoration(hintText: 'Mesajınız'))),
        IconButton(
          tooltip: 'Gönder',
          icon: const Icon(Icons.send),
          onPressed: () async {
            final t = _c.text.trim();
            if (t.isEmpty) return;
            _c.clear();
            await widget.onSend(t);
          },
        ),
      ]);
}

class _DisputeSection extends StatelessWidget {
  final String id;
  final Map deal;
  final Act act;
  const _DisputeSection({required this.id, required this.deal, required this.act});

  @override
  Widget build(BuildContext context) {
    final x = deal['dispute'] as Map?;
    if (x != null) {
      const st = {'OPEN': 'İnceleniyor', 'APPROVED': 'Onaylandı (iade)', 'REJECTED': 'Reddedildi'};
      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: ListTile(
          title: Text('Geçersiz talep bildiriminiz: ${st['${x['status']}']}'),
          subtitle: Text('${disputeReasons['${x['reason_code']}']} · ${x['note']}${x['decision_note'] != null ? '\nPlatform: ${x['decision_note']}' : ''}'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton(
        onPressed: () async {
          final reason = await showDialog<String>(
            context: context,
            builder: (ctx) => SimpleDialog(title: const Text('Talep geçersiz mi?'), children: [
              for (final e in disputeReasons.entries) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e.key), child: Text(e.value)),
            ]),
          );
          if (reason == null || !context.mounted) return;
          final note = await askTextDialog(context, 'Açıklama', 'En az 10 karakter');
          if (note != null) await act(() => apiClient.dispute(id, reason, note), 'Bildiriminiz platforma iletildi');
        },
        child: const Text('Talep geçersiz — platforma bildir'),
      ),
    );
  }
}
