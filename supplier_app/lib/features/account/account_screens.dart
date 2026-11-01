// Hesabım (FAZ M3): tedarikçi hesabı (unvan, vergi no), belgeler (vergi levhası/oda kaydı ve kimlik), incelemeye
// gönderme; bildirimler ve puanlar.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/file_opener.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/data_state.dart';
import '../../core/widgets/future_list.dart';

const accountStatus = {'DRAFT': 'Taslak', 'REVIEW': 'İncelemede', 'APPROVED': 'Onaylı', 'SUSPENDED': 'Askıda', 'CLOSED': 'Kapalı'};
const docTypes = {'TAX_PLATE': 'Vergi levhası', 'ID_CARD': 'Kimlik belgesi', 'CHAMBER_RECORD': 'Oda kaydı', 'OTHER': 'Diğer'};
const docStatus = {'PENDING': 'İncelenecek', 'APPROVED': 'Onaylandı', 'REJECTED': 'Reddedildi'};

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<List<Object?>> _future;
  final _trade = TextEditingController(), _tax = TextEditingController(), _office = TextEditingController();
  bool _terms = false;
  String _docType = 'TAX_PLATE';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object?>> _load() async {
    final me = await apiClient.me();
    if (me != null) {
      _trade.text = '${me['trade_name']}';
      _tax.text = '${me['tax_number']}';
      _office.text = '${me['tax_office']}';
    }
    return [me, me == null ? const [] : await apiClient.documents()];
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Map<String, dynamic> get _form => {'trade_name': _trade.text.trim(), 'tax_number': _tax.text.trim(), 'tax_office': _office.text.trim()};

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final f = picked?.files.single;
    if (f == null || f.bytes == null || !mounted) return;
    if (await runSnack(context, () => apiClient.uploadDocument(_docType, f.bytes!, f.name), 'Belge yüklendi')) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım'), actions: [
        IconButton(tooltip: 'Bildirimler', onPressed: () => context.push('/hesap/bildirimler'), icon: const Icon(Icons.notifications_outlined)),
        IconButton(tooltip: 'Puanlar', onPressed: () => context.push('/hesap/puanlar'), icon: const Icon(Icons.star_outline)),
        IconButton(
          tooltip: 'Çıkış',
          onPressed: () async {
            await apiClient.logout();
            if (context.mounted) context.go('/giris');
          },
          icon: const Icon(Icons.logout),
        ),
      ]),
      body: FutureBuilder<List<Object?>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final me = snap.data![0] as Map<String, dynamic>?;
          final docs = (snap.data![1] as List).whereType<Map>().toList();
          final draft = me == null || me['status'] == 'DRAFT';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              if (me == null)
                const Text('Havuzda görünmek için hesap bilgilerinizi girin, vergi levhası (ya da oda kaydı) ve kimlik belgenizi yükleyip incelemeye gönderin.')
              else ...[
                Text('Durum: ${accountStatus['${me['status']}']}', style: Theme.of(context).textTheme.titleMedium),
                if (me['status_reason'] != null) Text('İnceleme notu: ${me['status_reason']}'),
                if (me['status'] == 'REVIEW') const Text('Hesabınız inceleniyor; sonuç size bildirilecek.'),
              ],
              TextField(controller: _trade, enabled: draft, decoration: const InputDecoration(labelText: 'Ticari unvan')),
              TextField(controller: _tax, enabled: draft, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vergi no / T.C. kimlik no')),
              TextField(controller: _office, enabled: draft, decoration: const InputDecoration(labelText: 'Vergi dairesi')),
              if (me == null) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _terms,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                  title: const Text('Usta & Hizmet tedarikçi üyelik koşullarını kabul ediyorum.'),
                ),
                FilledButton(
                  onPressed: _terms ? () async {
                    if (await runSnack(context, () => apiClient.createAccount({..._form, 'terms_accepted': true}), 'Hesabınız oluşturuldu')) await _reload();
                  } : null,
                  child: const Text('Hesabı oluştur'),
                ),
              ] else if (draft) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => runSnack(context, () => apiClient.updateAccount(_form), 'Kaydedildi'), child: const Text('Kaydet'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (await runSnack(context, () async {
                          await apiClient.updateAccount(_form);
                          await apiClient.submitAccount();
                        }, 'Hesabınız incelemeye gönderildi')) {
                          await _reload();
                        }
                      },
                      child: const Text('İncelemeye gönder'),
                    ),
                  ),
                ]),
              ],
              if (me != null) ...[
                const SizedBox(height: 16),
                Text('Belgeler', style: Theme.of(context).textTheme.titleMedium),
                for (final d in docs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${docTypes['${d['doc_type']}']} · ${docStatus['${d['status']}']}'),
                    subtitle: Text('${d['file_name']}${d['review_note'] != null ? '\n${d['review_note']}' : ''}'),
                    trailing: IconButton(
                      tooltip: 'Aç',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final err = await openBytes(await apiClient.documentFile('${d['id']}'), '${d['file_name']}', subdir: 'belgeler');
                          if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text(toUserMessage(e))));
                        }
                      },
                    ),
                  ),
                if (me['status'] == 'DRAFT' || me['status'] == 'REVIEW')
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _docType,
                        decoration: const InputDecoration(labelText: 'Belge türü'),
                        items: [for (final e in docTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                        onChanged: (v) => setState(() => _docType = v ?? 'TAX_PLATE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(onPressed: _upload, child: const Text('Yükle')),
                  ]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler'), actions: [
        TextButton(onPressed: () => runSnack(context, apiClient.readNotifications, 'Hepsi okundu'), child: const Text('Tümünü okundu say')),
      ]),
      body: FutureList(
        load: () async => (await apiClient.notifications())['data'] as List? ?? const [],
        empty: 'Bildirim yok.',
        itemBuilder: (context, n, reload) => ListTile(
          leading: Icon(n['read_at'] == null ? Icons.circle : Icons.circle_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
          title: Text('${n['subject'] ?? n['topic']}'),
          subtitle: Text('${n['body']}\n${formatDateTime(n['created_at'])}'),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puanlar')),
      body: FutureList(
        load: apiClient.reviews,
        empty: 'Henüz değerlendirme yok.',
        itemBuilder: (context, r, reload) => Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ListTile(
            title: Text('${r['business_name']} · ${'★' * toNum(r['rating']).toInt()}${'☆' * (5 - toNum(r['rating']).toInt())}'),
            subtitle: Text([
              if ('${r['comment'] ?? ''}'.isNotEmpty) '“${r['comment']}”',
              if (r['hidden_at'] != null) 'Platform gizledi: ${r['hidden_reason']}',
              if (r['reply'] != null) 'Yanıtınız: ${r['reply']}',
            ].join('\n')),
            trailing: r['reply'] == null
                ? TextButton(
                    onPressed: () async {
                      final t = await askTextDialog(context, 'Yanıt', 'Yanıtınız (bir kez yazılır)');
                      if (t != null && context.mounted && await runSnack(context, () => apiClient.replyReview('${r['id']}', t), 'Yanıt yayımlandı')) reload();
                    },
                    child: const Text('Yanıtla'),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
