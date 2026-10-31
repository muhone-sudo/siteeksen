// Usta & Hizmet talebi (FAZ M8.2–M8.3): açma (KVKK rızası, uygun işletme sayısı, fotoğraf), ayrıntı (teklifler yan yana,
// seçim, kapatma), yazışma, iş onayı/itirazı ve puan.

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import '../../../../core/widgets/future_list.dart';
import 'usta_screen.dart';

String apiError(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['error'] is String) return d['error'] as String;
  }
  return toUserMessage(e);
}

class CreateMarketRequestScreen extends StatefulWidget {
  final String? targetBusinessId;
  const CreateMarketRequestScreen({super.key, this.targetBusinessId});

  @override
  State<CreateMarketRequestScreen> createState() => _CreateMarketRequestScreenState();
}

class _CreateMarketRequestScreenState extends State<CreateMarketRequestScreen> {
  final _desc = TextEditingController();
  final _time = TextEditingController();
  late Future<Map<String, dynamic>> _meta;
  String? _category;
  int? _count;
  bool _phoneHidden = false, _consent = false, _sending = false;
  final List<PlatformFile> _photos = [];

  @override
  void initState() {
    super.initState();
    _meta = apiClient.getMarketMeta();
  }

  @override
  void dispose() {
    _desc.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _pickCategory(String id) async {
    setState(() {
      _category = id;
      _count = null;
    });
    try {
      final n = await apiClient.marketMatchCount(id, targetBusinessId: widget.targetBusinessId);
      if (mounted && _category == id) setState(() => _count = n);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> _addPhoto() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], withData: true);
    final f = picked?.files.single;
    if (f == null || f.bytes == null) return;
    if (f.size > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf 5 MB sınırını aşıyor.')));
      return;
    }
    setState(() => _photos.add(f));
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      final r = await apiClient.createMarketRequest({
        'category_id': _category,
        'buyer_type': 'RESIDENT',
        'description': _desc.text.trim(),
        'preferred_time': _time.text.trim(),
        'phone_hidden': _phoneHidden,
        'consent': _consent,
        if (widget.targetBusinessId != null) 'target_business_id': widget.targetBusinessId,
      });
      final id = '${(r['request'] as Map)['id']}';
      var failed = 0;
      for (final p in _photos) {
        try {
          await apiClient.addMarketRequestPhoto(id, p.bytes!, p.name);
        } catch (_) {
          failed++;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          'Talebiniz ${r['dispatched']} işletmeye iletildi.${failed > 0 ? ' $failed fotoğraf yüklenemedi.' : ''}')));
      context.pushReplacement('/usta/talepler/$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final direct = widget.targetBusinessId != null;
    return Scaffold(
      appBar: AppBar(title: Text(direct ? 'İşletmeye talep gönder' : 'Usta & Hizmet talebi')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _meta,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!));
          final cats = (snap.data!['categories'] as List? ?? const []).whereType<Map>().where((c) => c['buyer_scope'] != 'MANAGEMENT').toList();
          final ready = _category != null && (_count ?? 0) > 0 && _desc.text.trim().isNotEmpty && _consent && !_sending;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [for (final c in cats) DropdownMenuItem(value: '${c['id']}', child: Text('${c['name']}'))],
                onChanged: (v) => v == null ? null : _pickCategory(v),
              ),
              if (_category != null) ...[
                const SizedBox(height: 8),
                Text(
                  _count == null
                      ? 'Uygun işletmeler aranıyor…'
                      : _count == 0
                          ? (direct ? 'Bu işletme seçtiğiniz kategoride ya da bölgenizde hizmet vermiyor.' : 'Yakınınızda bu kategoride onaylı işletme yok; talep açılamaz.')
                          : direct
                              ? 'Talep yalnız bu işletmeye gönderilir.'
                              : 'Yakınınızda bu kategoride $_count onaylı işletme var.',
                  style: TextStyle(color: (_count ?? 1) == 0 ? Theme.of(context).colorScheme.error : null),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                minLines: 3,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Ne yapılmasını istiyorsunuz?', helperText: 'Telefon ya da e-posta yazmayın; otomatik gizlenir.'),
                onChanged: (_) => setState(() {}),
              ),
              TextField(controller: _time, maxLength: 200, decoration: const InputDecoration(labelText: 'Uygun zaman (isteğe bağlı)')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _phoneHidden,
                onChanged: (v) => setState(() => _phoneHidden = v),
                title: const Text('Telefonum gizli kalsın'),
                subtitle: const Text('İşletmeler size yalnız uygulama içinden yazar.'),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in _photos) InputChip(label: Text(p.name), onDeleted: () => setState(() => _photos.remove(p))),
                if (_photos.length < 3) ActionChip(avatar: const Icon(Icons.add_a_photo_outlined, size: 18), label: const Text('Fotoğraf ekle'), onPressed: _addPhoto),
              ]),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                title: const Text('Talebimin ve iletişim bilgimin (ad, telefon, site adresi), talebi kabul eden en fazla birkaç işletmeyle paylaşılmasına açık rıza veriyorum.'),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: ready ? _submit : null, child: Text(_sending ? 'Gönderiliyor…' : 'Talebi gönder')),
            ],
          );
        },
      ),
    );
  }
}

class MarketRequestScreen extends StatefulWidget {
  final String id;
  const MarketRequestScreen({super.key, required this.id});

  @override
  State<MarketRequestScreen> createState() => _MarketRequestScreenState();
}

class _MarketRequestScreenState extends State<MarketRequestScreen> {
  late Future<List<Object?>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object?>> _load() => Future.wait([
        apiClient.getMarketRequest(widget.id),
        apiClient.getMarketOffers(widget.id),
        apiClient.getMarketJob(widget.id),
      ]);

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _act(Future<void> Function() fn, String ok) async {
    if (await runSnack(context, fn, ok)) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talebim')),
      body: FutureBuilder<List<Object?>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final r = snap.data![0] as Map<String, dynamic>;
          final offers = (snap.data![1] as List).whereType<Map>().toList();
          final job = snap.data![2] as Map<String, dynamic>?;
          final accepted = (r['accepted'] as List? ?? const []).whereType<Map>().toList();
          final open = r['status'] != 'CLOSED' && r['status'] != 'CANCELLED';
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                Text('${r['category_name']}', style: Theme.of(context).textTheme.titleLarge),
                Text('${marketRequestStatus['${r['status']}'] ?? r['status']} · ${r['accepted_count']}/${r['max_accepts']} işletme kabul etti · ${formatDate(r['created_at'])}'),
                const SizedBox(height: 8),
                Text('${r['description']}'),
                if (job != null) _JobCard(id: widget.id, job: job, onAct: _act),
                const SizedBox(height: 16),
                Text('Teklifler', style: Theme.of(context).textTheme.titleMedium),
                if (offers.isEmpty)
                  Text(accepted.isEmpty ? 'Talebinizi henüz kabul eden işletme yok.' : 'Kabul eden işletmelerden teklif bekleniyor.'),
                for (final o in offers)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('${o['business_name']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(kurusText(o['amount_kurus']), style: Theme.of(context).textTheme.titleMedium),
                        ]),
                        Text([
                          if (toNum(o['rating_count']) > 0) '★ ${(toNum(o['rating_sum']) / toNum(o['rating_count'])).toStringAsFixed(1)} (${o['rating_count']})',
                          '${o['completed_jobs'] ?? 0} tamamlanan iş',
                          'geçerli ${formatDate(o['valid_until'])}',
                          if (o['business_phone'] != null) 'Tel: ${o['business_phone']}',
                        ].join(' · ')),
                        const SizedBox(height: 4),
                        Text('${o['description']}'),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          if (o['status'] == 'ACCEPTED') const Chip(label: Text('Seçtiniz')),
                          if (o['status'] == 'DECLINED') const Chip(label: Text('Seçilmedi')),
                          if (o['status'] == 'ACTIVE' && open)
                            FilledButton(
                              onPressed: () async {
                                if (await confirmDialog(context, 'Teklifi seç', '${o['business_name']} — ${kurusText(o['amount_kurus'])}. Diğer teklifler reddedilir.', ok: 'Seç')) {
                                  await _act(() => apiClient.selectMarketOffer(widget.id, '${o['id']}'), 'Teklif seçildi; işletmeye bildirildi.');
                                }
                              },
                              child: const Text('Bu teklifi seç'),
                            ),
                          OutlinedButton(
                            onPressed: () => context.push('/usta/talepler/${widget.id}/mesaj/${o['dispatch_id']}?ad=${Uri.encodeComponent('${o['business_name']}')}'),
                            child: const Text('Mesaj'),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                if (accepted.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Kabul eden işletmeler', style: Theme.of(context).textTheme.titleMedium),
                  for (final a in accepted) ListTile(contentPadding: EdgeInsets.zero, title: Text('${a['business_name']}'), subtitle: Text('kabul ${formatDateTime(a['accepted_at'])}')),
                ],
                if (open) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirmDialog(context, 'Talebi kapat', 'Teklif seçmeden talebi kapatırsınız; yeni teklif gelmez.', ok: 'Kapat')) {
                        await _act(() => apiClient.closeMarketRequest(widget.id), 'Talep kapatıldı.');
                      }
                    },
                    child: const Text('Teklif seçmeden talebi kapat'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> job;
  final Future<void> Function(Future<void> Function(), String) onAct;
  const _JobCard({required this.id, required this.job, required this.onAct});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final status = '${j['status']}';
    const labels = {'ACTIVE': 'Sürüyor', 'DONE_CLAIMED': 'İşletme tamamlandı dedi', 'COMPLETED': 'Tamamlandı', 'DISPUTED': 'İtiraz ettiniz'};
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('İş: ${j['business_name']} — ${kurusText(j['amount_kurus'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(labels[status] ?? status),
          if (status == 'DONE_CLAIMED' || status == 'DISPUTED') ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton(onPressed: () => widget.onAct(() => apiClient.confirmMarketJob(widget.id), 'İşi onayladınız; puan verebilirsiniz.'), child: const Text('İş tamamlandı, onaylıyorum')),
              if (status == 'DONE_CLAIMED')
                OutlinedButton(
                  onPressed: () async {
                    final note = await askTextDialog(context, 'İtiraz', 'Ne eksik kaldı?');
                    if (note != null) await widget.onAct(() => apiClient.disputeMarketJob(widget.id, note), 'İtirazınız işletmeye iletildi.');
                  },
                  child: const Text('İtiraz et'),
                ),
            ]),
          ],
          if (status == 'COMPLETED' && j['review'] == null) ...[
            const SizedBox(height: 8),
            const Text('Puanınız'),
            Row(children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i yıldız',
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                ),
            ]),
            TextField(controller: _comment, maxLength: 1000, decoration: const InputDecoration(labelText: 'Yorumunuz (isteğe bağlı)')),
            FilledButton(onPressed: () => widget.onAct(() => apiClient.reviewMarketJob(widget.id, _rating, _comment.text.trim()), 'Teşekkürler; puanınız yayımlandı.'), child: const Text('Puanı gönder')),
          ],
          if (j['review'] is Map) Text('Puanınız: ${(j['review'] as Map)['rating']}/5 ${(j['review'] as Map)['comment'] ?? ''}'),
        ]),
      ),
    );
  }
}

class MarketChatScreen extends StatefulWidget {
  final String id, dispatchId, title;
  const MarketChatScreen({super.key, required this.id, required this.dispatchId, required this.title});

  @override
  State<MarketChatScreen> createState() => _MarketChatScreenState();
}

class _MarketChatScreenState extends State<MarketChatScreen> {
  final _body = TextEditingController();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getMarketMessages(widget.id, widget.dispatchId);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty) return;
    if (await runSnack(context, () => apiClient.sendMarketMessage(widget.id, widget.dispatchId, text), 'Gönderildi')) {
      _body.clear();
      setState(() => _future = apiClient.getMarketMessages(widget.id, widget.dispatchId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LoadingView();
              if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!));
              final msgs = snap.data!.whereType<Map>().toList();
              if (msgs.isEmpty) return const EmptyStateView(message: 'Henüz mesaj yok. Daire numaranızı ve uygun zamanı buradan paylaşın.');
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m['sender_side'] == 'BUYER';
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${m['body']}'),
                        Text(formatDateTime(m['created_at']), style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _body, decoration: const InputDecoration(hintText: 'Mesajınız'))),
              IconButton(tooltip: 'Gönder', onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
