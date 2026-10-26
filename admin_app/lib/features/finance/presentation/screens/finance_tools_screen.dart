// Tahsilat defteri, alacak dekontları ve banka ekstresi mutabakatı (FAZ H.7, panel /dashboard/accounting ile eşit).
// Defter ekle-yalnızdır, her kayıt bir öncekinin SHA-256 özetine bağlıdır. Alacak dekontu borcu düşürür, silinemez;
// hata gerekçeli ters kayıtla düzeltilir (059). Ekstre satırları yönetici onayıyla ödemeye bağlanır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';
import 'collection_entry_screen.dart';

String _kurus(Object? v) => formatTry(toNum(v) / 100);

const _ledgerKind = {'PAYMENT_CONFIRMED': 'Tahsilat onayı', 'PAYMENT_REVERSED': 'Ters kayıt', 'CREDIT_NOTE': 'Alacak dekontu', 'CREDIT_NOTE_REVERSED': 'Dekont ters kaydı'};
const _lineStatus = {
  'SUGGESTED': ('Önerildi', Colors.blue), 'AMBIGUOUS': ('Birden çok aday', Colors.orange), 'UNMATCHED': ('Eşleşmedi', Colors.orange),
  'OUTGOING': ('Giden', Colors.grey), 'DUPLICATE': ('Mükerrer', Colors.grey), 'CONFIRMED': ('Onaylandı', Colors.green), 'IGNORED': ('Yok sayıldı', Colors.grey),
};

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tahsilat defteri'), actions: [
        IconButton(
          tooltip: 'Zinciri doğrula',
          icon: const Icon(Icons.verified),
          onPressed: () => runAction(context, () async {
            final v = await apiClient.getMap('/finance/ledger/verify');
            return {
              'message': v['valid'] == true
                  ? 'Zincir geçerli: ${v['entries']} kayıt, değiştirilmemiş'
                  : 'UYARI: zincir bozuk (sıra ${v['first_invalid_seq']}): ${v['reason']}',
            };
          }),
        ),
      ]),
      body: ApiList(
        load: () => apiClient.getList('/finance/ledger'),
        empty: 'Defter kaydı yok',
        header: (_) => const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Her onay ve ters kayıt bir öncekinin SHA-256 özetine bağlı yazılır; kayıt silinemez ve değiştirilemez.', style: TextStyle(fontSize: 12)),
        ),
        itemBuilder: (context, x, _) {
          final d = (x['detail'] as Map?) ?? const {};
          return ListTile(
            leading: Text('${x['seq']}'),
            title: Text('${_ledgerKind[x['entry_type']] ?? x['entry_type']} · ${_kurus(x['amount_kurus'])}',
                style: toNum(x['amount_kurus']) < 0 ? const TextStyle(color: Colors.red) : null),
            subtitle: Text('${d['reason'] ?? d['reference'] ?? '—'}\n${x['created_by_name'] ?? '—'} · ${formatDateTime(x['created_at'])} · ${'${x['entry_hash'] ?? ''}'.padRight(12).substring(0, 12)}…'),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

class CreditNotesScreen extends StatefulWidget {
  const CreditNotesScreen({super.key});

  @override
  State<CreditNotesScreen> createState() => _CreditNotesScreenState();
}

class _CreditNotesScreenState extends State<CreditNotesScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _create() async {
    final units = await unitOptions();
    if (!mounted) return;
    final u = await showForm(context, 'Alacak dekontu — daire', [FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true)], submit: 'Devam');
    if (u == null || !mounted) return;
    List<dynamic> open;
    try {
      open = await apiClient.getList('/finance/units/${u['unit_id']}/open-assessments');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
      return;
    }
    if (!mounted) return;
    if (open.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borcu kalan tahakkuk yok')));
      return;
    }
    final opts = [
      for (final a in open.whereType<Map>())
        ('${a['id']}', '${a['period']} · vade ${formatDate(a['due_date'])} · kalan ${_kurus(a['outstanding_kurus'])} · en çok ${_kurus(a['max_credit_kurus'])}'),
    ];
    if (await formAction(context, 'Alacak dekontu kes', [
      FSpec('assessment_id', 'Tahakkuk', type: FType.select, options: opts, required: true),
      const FSpec('amount_try', 'Tutar (TL)', type: FType.decimal, required: true),
      const FSpec('reason', 'Gerekçe', type: FType.multiline, required: true, hint: 'Ör. Ocak ayında daire boştu — yönetim kurulu kararı 2026/4'),
    ], (v) async {
      final r = await apiClient.post('/finance/credit-notes', v);
      return {...r, 'message': 'Dekont ${(r['credit_note'] as Map?)?['document_no'] ?? ''} kesildi'};
    }, note: 'Dekont borcu düşürür, tahsilat sayılmaz ve tahsilat defterine yazılır. Silinemez; hata ancak gerekçeli ters kayıtla düzeltilir.')) {
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alacak dekontları')),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.receipt), label: const Text('Dekont kes')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/finance/credit-notes'),
        empty: 'Dekont yok',
        itemBuilder: (context, x, reload) => ListTile(
          title: Text('${x['document_no']} · ${x['unit']} · ${x['period']} · ${_kurus(x['amount_kurus'])}'),
          subtitle: Text('${x['reason'] ?? ''}\n${x['created_by_name'] ?? ''} · ${formatDateTime(x['created_at'])}'
              '${x['reversed_at'] != null ? '\nTers kayıt: ${x['reversal_reason'] ?? ''}' : ''}',
              style: x['reversed_at'] != null ? const TextStyle(color: Colors.red) : null),
          isThreeLine: true,
          trailing: RowMenu([
            ('PDF', () => openDownload(context, '/finance/credit-notes/${x['id']}/pdf', 'alacak-dekontu-${x['document_no']}.pdf')),
            if (_canWrite && x['reversed_at'] == null)
              ('Ters kayıt', () async {
                if (await reasonAction(context, 'Ters kayıt — ${x['document_no']}', (r) => apiClient.post('/finance/credit-notes/${x['id']}/reverse', {'reason': r}),
                    success: 'Dekontun ters kaydı yapıldı; borç geri yüklendi')) {
                  await reload();
                }
              }),
          ]),
        ),
      ),
    );
  }
}

class BankStatementsScreen extends StatefulWidget {
  const BankStatementsScreen({super.key});

  @override
  State<BankStatementsScreen> createState() => _BankStatementsScreenState();
}

class _BankStatementsScreenState extends State<BankStatementsScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _canWrite = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _open(String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ImportDetail(id: id, canWrite: _canWrite)));

  Future<void> _upload() async {
    final v = await showForm(context, 'Ekstre yükle', const [
      FSpec('file', 'Dosya (CSV / Excel)', type: FType.file, extensions: ['csv', 'xlsx', 'txt'], required: true),
    ], note: 'Bankanın internet şubesinden indirdiğiniz hesap hareketlerini yükleyin. Hiçbir ödeme kendiliğinden onaylanmaz.', submit: 'Yükle');
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.postMultipart('/finance/bank-statements', const {}, {'file': v['file'] as (List<int>, String)});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(['Ekstre yüklendi', r['note']].whereType<String>().join(' — '))));
      await _list.currentState?.reload();
      final id = (r['import'] as Map?)?['id'];
      if (id != null) await _open('$id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banka ekstresi')),
      floatingActionButton: _canWrite ? FloatingActionButton.extended(onPressed: _upload, icon: const Icon(Icons.upload_file), label: const Text('Yükle')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/finance/bank-statements'),
        empty: 'Henüz ekstre yüklenmedi',
        itemBuilder: (context, x, _) => ListTile(
          title: Text('${x['file_name']} · ${x['row_count']} hareket'),
          subtitle: Text('${formatDateTime(x['created_at'])}\n${((x['counts'] as Map?) ?? const {}).entries.map((e) => '${_lineStatus[e.key]?.$1 ?? e.key}: ${e.value}').join(' · ')}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open('${x['id']}'),
        ),
      ),
    );
  }
}

class _ImportDetail extends StatefulWidget {
  final String id;
  final bool canWrite;
  const _ImportDetail({required this.id, required this.canWrite});

  @override
  State<_ImportDetail> createState() => _ImportDetailState();
}

class _ImportDetailState extends State<_ImportDetail> {
  int _token = 0;
  void _changed() => setState(() => _token++);

  Future<void> _pick(Map l) async {
    final pending = await apiClient.getList('/finance/payments/pending').catchError((_) => <dynamic>[]);
    if (!mounted) return;
    final opts = [
      for (final p in pending.whereType<Map>())
        if ((toNum(p['amount']) * 100).round() == toNum(l['amount_kurus']).round())
          ('${p['id']}', '${p['name']} · ${p['unit']} · ${p['value_date'] != null ? formatDate(p['value_date']) : ''} · ${p['payer_reference'] ?? ''}'),
    ];
    if (await formAction(context, 'Ödeme bildirimiyle eşleştir', [FSpec('payment_id', 'Onay bekleyen ödeme', type: FType.select, options: opts, required: true)],
        (v) => apiClient.post('/finance/bank-statements/lines/${l['id']}/confirm', v),
        note: 'Hareket: ${formatDate(l['date'])} · ${_kurus(l['amount_kurus'])} · ${l['description'] ?? ''}. Yalnızca aynı tutardaki ödeme onaylanabilir.',
        success: 'Ödeme onaylandı ve borçtan düşüldü')) {
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hareketler')),
      body: ApiObject(
        key: ValueKey(_token),
        load: () => apiClient.getMap('/finance/bank-statements/${widget.id}'),
        builder: (context, d, _) {
          final lines = ApiClient.listOf(d['lines']).whereType<Map>().toList();
          return ListView(children: [
            for (final l in lines)
              Builder(builder: (context) {
                final st = _lineStatus[l['status']];
                final open = ['SUGGESTED', 'AMBIGUOUS', 'UNMATCHED'].contains(l['status']);
                return ListTile(
                  title: Text('${l['line_no']}. ${formatDate(l['date'])} · ${_kurus(l['amount_kurus'])}',
                      style: toNum(l['amount_kurus']) < 0 ? const TextStyle(color: Colors.red) : null),
                  subtitle: Text([
                    '${l['description'] ?? ''}${l['reference'] != null ? ' · ${l['reference']}' : ''}',
                    '${st?.$1 ?? l['status']}${l['payer'] != null ? ' · ${l['payer']}${l['unit'] != null ? ' · ${l['unit']}' : ''}' : ''}',
                    if (l['note'] != null) '${l['note']}',
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: widget.canWrite && open
                      ? RowMenu([
                          if (l['status'] == 'SUGGESTED')
                            ('Onayla', () async {
                              if (await runAction(context, () => apiClient.post('/finance/bank-statements/lines/${l['id']}/confirm', {}), success: 'Ödeme onaylandı ve borçtan düşüldü')) _changed();
                            })
                          else
                            ('Ödeme seç', () => _pick(l)),
                          if (l['status'] != 'SUGGESTED')
                            ('Daireye işle', () async {
                              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CollectionEntryScreen(bankLine: Map<String, dynamic>.from(l))));
                              if (ok == true) _changed();
                            }),
                          ('Yok say', () async {
                            if (await formAction(context, 'Hareketi yok say', const [FSpec('note', 'Gerekçe', required: true, hint: 'Ör. kira geliri; ayrıca gelir olarak kaydedildi')],
                                (v) => apiClient.post('/finance/bank-statements/lines/${l['id']}/ignore', v), success: 'Satır yok sayıldı')) {
                              _changed();
                            }
                          }),
                        ])
                      : (st == null ? null : StatusChip(st.$1, color: st.$2)),
                );
              }),
          ]);
        },
      ),
    );
  }
}

/// Devir (açılış) bakiyeleri (034): önceki yönetimden devreden borçlar. Otomatik gecikme tazminatı işletilmez.
class OpeningBalancesTab extends StatefulWidget {
  final bool canWrite;
  const OpeningBalancesTab({super.key, required this.canWrite});

  @override
  State<OpeningBalancesTab> createState() => _OpeningBalancesTabState();
}

class _OpeningBalancesTabState extends State<OpeningBalancesTab> {
  final _list = GlobalKey<ApiListState>();

  Future<void> _create() async {
    final units = await apiClient.getList('/units').catchError((_) => <dynamic>[]);
    if (!mounted) return;
    final byLabel = {for (final u in units.whereType<Map>()) '${u['block'] ?? ''}-${u['door_number']}'.toUpperCase(): '${u['id']}'};
    final v = await showForm(context, 'Devir bakiyesi gir', [
      FSpec('due_date', 'Vade tarihi', type: FType.date, initial: DateTime.now(), required: true),
      const FSpec('liability', 'Gider sınıfı', type: FType.select, options: [('USAGE', 'Kullanım — daireyi kullanan öder'), ('OWNER', 'Malik — malik öder')], initial: 'USAGE', required: true),
      const FSpec('text', 'Satırlar (daire;tutar;açıklama)', type: FType.multiline, required: true, hint: 'A-3;1.500,50;Önceki yönetimden devir'),
    ], note: 'Devir tutarına önceki yönetimin işlettiği gecikme tazminatı dahil edilmelidir; sistem devreden borca otomatik tazminat işletmez. '
        'Her daireye sınıf başına bir devir kaydı açılır; hepsi tek seferde kaydedilir.', submit: 'Denetle');
    if (v == null || !mounted) return;
    final items = <Map<String, dynamic>>[];
    final errors = <String>[];
    final lines = '${v['text']}'.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final p = [...lines[i].split(RegExp(r'[;\t]')), '', ''];
      final id = byLabel[p[0].trim().toUpperCase().replaceAll(RegExp(r'\s*-\s*'), '-')];
      final t = p[1].trim();
      final n = num.tryParse(t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t);
      if (id == null) {
        errors.add('${i + 1}. satır: "${p[0].trim()}" dairesi bulunamadı');
      } else if (n == null || n <= 0) {
        errors.add('${i + 1}. satır: tutar sıfırdan büyük olmalı');
      } else {
        items.add({'unit_id': id, 'amount': n, if (p[2].trim().isNotEmpty) 'description': p[2].trim()});
      }
    }
    if (errors.isNotEmpty || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.isEmpty ? 'Satır yok' : errors.take(10).join(' · '))));
      return;
    }
    final total = items.fold<num>(0, (a, x) => a + (x['amount'] as num));
    if (!await confirm(context, 'Devir bakiyesi', '${items.length} daire, toplam ${formatTry(total)}.', ok: 'Kaydet') || !mounted) return;
    if (await runAction(context, () async {
      final r = await apiClient.post('/finance/opening-balances', {'due_date': v['due_date'], 'liability': v['liability'], 'items': items});
      return {...r, 'message': '${r['created']} devir kaydı girildi. Sakin bildirimi: ${(r['notification'] as Map?)?['note'] ?? '—'}', 'note': null};
    })) {
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiList(
      key: _list,
      load: () => apiClient.getList('/finance/opening-balances'),
      empty: 'Devir bakiyesi girilmemiş',
      header: (_) => widget.canWrite
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(onPressed: _create, icon: const Icon(Icons.playlist_add), label: const Text('Devir gir')),
              ),
            )
          : const SizedBox.shrink(),
      itemBuilder: (context, o, reload) => ListTile(
        title: Text('${o['unit']} · ${formatTry(toNum(o['amount']))}'),
        subtitle: Text('Ödenen ${formatTry(toNum(o['paid_amount']))} · vade ${formatDate(o['due_date'])} · ${o['liability'] == 'OWNER' ? 'Malik' : 'Kullanım'}\n${o['description'] ?? ''}'),
        isThreeLine: true,
        trailing: widget.canWrite && toNum(o['paid_amount']) == 0
            ? RowMenu([
                ('İptal', () async {
                  if (await confirmAction(context, 'Devir kaydını iptal et', '${o['unit']} devir kaydı iptal edilsin mi?',
                      () => apiClient.post('/finance/opening-balances/${o['id']}/cancel'), ok: 'İptal et', success: 'Devir kaydı iptal edildi')) {
                    await reload();
                  }
                }),
              ])
            : null,
      ),
    );
  }
}

/// Gecikme tazminatını işletir (KMK m.20/2; oran mevzuat tablosundan). Aynı gün tekrar çalıştırmak tutarı değiştirmez.
Future<void> accrueLateFees(BuildContext context) async {
  await formAction(context, 'Gecikme tazminatı (KMK m.20/2)', [
    FSpec('as_of', 'Hesap tarihi', type: FType.date, initial: DateTime.now(), required: true),
  ], (v) async {
    final r = await apiClient.post('/finance/late-fees/accrue', v);
    return {...r, 'message': '${r['processed_count']} tahakkuka toplam ${r['total_fee_try']} TL tazminat işlendi (oran ${r['monthly_rate']}, ${r['legal_basis']})'};
  }, note: 'Vadesi geçmiş ödenmemiş ASIL borca aylık oran işler. Aynı gün tekrar çalıştırmak tutarı değiştirmez.', submit: 'Tazminatı işlet');
}
