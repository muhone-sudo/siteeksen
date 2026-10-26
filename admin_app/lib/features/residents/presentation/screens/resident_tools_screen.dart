// Sakin davetleri, toplu sakin ekleme ve kiracılık bitişleri (FAZ H.7, panel /dashboard/residents ile eşit).
// Etkinleştirme kodu yalnız bir kez gösterilir. Kiracılık yalnız bitiş akışıyla biter (069): yönetim yolu belge +
// şifreyle beyan + 7 gün itiraz ister; dairenin maliki ya da vekili olan yönetici başlatamaz (sunucu denetler).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';
import '../widgets/activation_code_dialog.dart';

const residentRoles = [('OWNER', 'Kat maliki'), ('TENANT', 'Kiracı'), ('PROXY', 'Vekil'), ('HOUSEHOLD', 'Hane üyesi')];
const _invStatus = {'PENDING': 'Yanıt bekliyor', 'ACCEPTED': 'Kabul edildi', 'DECLINED': 'Reddedildi', 'CANCELLED': 'İptal edildi', 'EXPIRED': 'Süresi doldu'};
const _bulkStatus = {'created': 'Hesap açıldı', 'linked': 'Var olan hesap bağlandı', 'invited': 'Davet gönderildi', 'error': 'Eklenmedi'};
const _roleAliases = {
  'MALIK': 'OWNER', 'KAT MALIKI': 'OWNER', 'OWNER': 'OWNER', 'KIRACI': 'TENANT', 'TENANT': 'TENANT', 'VEKIL': 'PROXY', 'PROXY': 'PROXY',
  'HANE UYESI': 'HOUSEHOLD', 'HOUSEHOLD': 'HOUSEHOLD',
};
const _tKind = {'OWNER_REQUEST': 'Malik isteği', 'TENANT_EXIT': 'Kiracının çıkışı', 'MANAGEMENT': 'Yönetim yolu'};
const _tStatus = {
  'PENDING_TENANT': 'Kiracı onayı bekliyor', 'OBJECTION_WINDOW': 'İtiraz süresinde', 'SUSPENDED': 'İtiraz edildi — askıda',
  'COMPLETED': 'Bitti', 'REJECTED': 'Kiracı reddetti', 'CANCELLED': 'İptal edildi', 'REVERSED': 'Geri alındı',
};
const _docKinds = [('TAHLIYE_KARARI', 'Tahliye kararı'), ('ICRA_TAHLIYE', 'İcra yoluyla tahliye'), ('TASINMA_TUTANAGI', 'Taşınma tutanağı'), ('DIGER', 'Diğer')];
const _tEvent = {
  'CREATED': 'açıldı', 'APPROVED': 'kiracı onayladı', 'DECLINED': 'kiracı reddetti', 'OBJECTED': 'kiracı itiraz etti',
  'DOCUMENT_ADDED': 'belge eklendi', 'COMPLETED': 'tamamlandı', 'CANCELLED': 'iptal edildi', 'REVERSED': 'geri alındı',
};
const _by = {'TENANT': 'kiracı', 'OWNER': 'malik', 'MANAGEMENT': 'yönetim'};

String _norm(String s) => s.trim().toUpperCase().replaceAll('İ', 'I').replaceAll('Ü', 'U').replaceAll(RegExp(r'\s+'), ' ');

class ResidentToolsScreen extends StatefulWidget {
  const ResidentToolsScreen({super.key});

  @override
  State<ResidentToolsScreen> createState() => _ResidentToolsScreenState();
}

class _ResidentToolsScreenState extends State<ResidentToolsScreen> {
  final _inv = GlobalKey<ApiListState>();
  int _tToken = 0;

  Future<void> _invite() async {
    final units = await unitOptions();
    if (!mounted) return;
    final v = await showForm(context, 'Sakin davet et', [
      const FSpec('first_name', 'Ad'),
      const FSpec('last_name', 'Soyad'),
      const FSpec('phone', 'Telefon', required: true, hint: '05xx… · yurt dışı: +ülke kodu'),
      const FSpec('email', 'E-posta', hint: 'Davet e-postayla da gider'),
      FSpec('unit_id', 'Daire', type: FType.select, options: units, required: true),
      const FSpec('role', 'Sıfat', type: FType.select, options: residentRoles, initial: 'TENANT', required: true),
    ], note: 'Dairede aktif kiracı varken kiracı daveti gönderilemez.', submit: 'Davet et');
    if (v == null || !mounted) return;
    try {
      final r = await apiClient.post('/residents/invitations', v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['note'] ?? 'Davet gönderildi'}')));
      if (r['activation'] is Map) {
        await showActivationCodeDialog(context, who: '${v['first_name'] ?? ''} ${v['last_name'] ?? ''} (${v['phone']})'.trim(), activation: Map<String, dynamic>.from(r['activation'] as Map));
      }
      await _inv.currentState?.reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _bulk() async {
    final units = await apiClient.getList('/units').catchError((_) => <dynamic>[]);
    if (!mounted) return;
    final byLabel = {for (final u in units.whereType<Map>()) _norm('${u['block'] ?? ''}-${u['door_number']}'): '${u['id']}'};
    final v = await showForm(context, 'Toplu sakin ekle', const [
      FSpec('text', 'Satırlar (ad;soyad;telefon;daire;sıfat)', type: FType.multiline, required: true, hint: 'Ayşe;Yılmaz;0555 111 22 33;A-3;malik'),
    ], note: 'Daire "A-3" biçiminde; sıfat malik, kiracı ya da vekil. Satırlar ayrı ayrı işlenir; etkinleştirme kodları bir kez gösterilir.', submit: 'Denetle');
    if (v == null || !mounted) return;
    final rows = <Map<String, dynamic>>[];
    final errors = <String>[];
    final lines = '${v['text']}'.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
      final p = [...line.split(RegExp(r'[;\t]')), '', '', '', '', ''];
      final unitId = byLabel[_norm(p[3]).replaceAll(RegExp(r'\s*-\s*'), '-')];
      final role = _roleAliases[_norm(p[4].trim().isEmpty ? 'malik' : p[4])];
      if (p[0].trim().isEmpty || p[1].trim().isEmpty || p[2].trim().isEmpty) {
        errors.add('${i + 1}. satır: ad, soyad ve telefon gerekli');
      } else if (unitId == null) {
        errors.add('${i + 1}. satır: "${p[3].trim()}" dairesi bulunamadı');
      } else if (role == null) {
        errors.add('${i + 1}. satır: sıfat malik, kiracı ya da vekil olmalı');
      } else {
        rows.add({'first_name': p[0].trim(), 'last_name': p[1].trim(), 'phone': p[2].trim(), 'unit_id': unitId, 'role': role});
      }
    }
    if (errors.isNotEmpty || rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.isEmpty ? 'Satır yok' : errors.take(10).join(' · '))));
      return;
    }
    if (!await confirm(context, 'Toplu ekleme', '${rows.length} satır gönderilecek.', ok: 'Gönder') || !mounted) return;
    try {
      final r = await apiClient.post('/residents/bulk', {'residents': rows});
      final data = ApiClient.listOf(r['data']).whereType<Map>().toList();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('${data.where((d) => d['status'] != 'error').length} / ${data.length} satır işlendi')),
          body: ListView(children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('${r['note'] ?? ''}\nKodlar bu ekrandan çıkınca bir daha gösterilmez.')),
            for (final d in data)
              ListTile(
                title: Text('${d['row']}. satır · ${d['phone']} · ${_bulkStatus[d['status']] ?? d['status']}'),
                subtitle: Text(d['error'] != null ? '${d['error']}' : ((d['activation'] as Map?)?['activation_code'] != null ? 'Kod: ${(d['activation'] as Map)['activation_code']}' : '')),
              ),
          ]),
        ),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _tenancyDoc(String attestation, {Map? request}) async {
    final List<(String, String)> tenanted;
    if (request == null) {
      final units = await apiClient.getList('/units').catchError((_) => <dynamic>[]);
      tenanted = [for (final u in units.whereType<Map>()) if (u['occupancy'] == 'TENANT_OCCUPIED') ('${u['id']}', '${u['block'] ?? ''}-${u['door_number']}')];
    } else {
      tenanted = const [];
    }
    if (!mounted) return;
    final v = await showForm(context, request == null ? 'Yönetim yoluyla kiracılığın bitişi' : 'Yeni belge — yeni 7 günlük itiraz süresi', [
      if (request == null) FSpec('unit_id', 'Daire (aktif kiracılı)', type: FType.select, options: tenanted, required: true),
      FSpec('document_kind', 'Belge türü', type: FType.select, options: _docKinds, initial: request == null ? 'TASINMA_TUTANAGI' : 'TAHLIYE_KARARI', required: true),
      const FSpec('uyap_code', 'UYAP doğrulama kodu', hint: 'Varsa girin'),
      const FSpec('file', 'Belge (PDF ya da görsel, en çok 10 MB)', type: FType.file, extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'], required: true),
      const FSpec('password', 'Şifreniz', type: FType.password, required: true),
      if (request == null) const FSpec('reason', 'Gerekçe (kiracı görür, en az 10 karakter)', type: FType.multiline, required: true),
      const FSpec('attest', 'Beyanı okudum ve onaylıyorum', type: FType.toggle),
    ], note: 'Beyan: $attestation', submit: 'Belgeyi yükle ve onayla');
    if (v == null || !mounted) return;
    final file = v.remove('file') as (List<int>, String);
    final fields = {for (final e in v.entries) e.key: e.value is bool ? '${e.value}' : '${e.value}'};
    if (await runAction(
        context,
        () => request == null
            ? apiClient.postMultipart('/residents/tenancy-requests', fields, {'file': file})
            : apiClient.postMultipart('/residents/tenancy-requests/${request['id']}/documents', fields, {'file': file}))) {
      setState(() => _tToken++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Davet ve kiracılık'),
          actions: [IconButton(tooltip: 'Toplu sakin ekle', icon: const Icon(Icons.group_add), onPressed: _bulk)],
          bottom: const TabBar(tabs: [Tab(text: 'Davetler'), Tab(text: 'Kiracılık bitişleri')]),
        ),
        body: TabBarView(children: [
          ApiList(
            key: _inv,
            load: () => apiClient.getList('/residents/invitations'),
            empty: 'Davet yok',
            header: (_) => Column(children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Kişiye SMS ve e-posta gider. Hesabı olmayan kişi kodu girince daireye bağlanır; hesabı olan uygulamasından kabul eder (14 gün).',
                    style: TextStyle(fontSize: 12)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(onPressed: _invite, icon: const Icon(Icons.person_add_alt), label: const Text('Davet et')),
                ),
              ),
            ]),
            itemBuilder: (context, i, reload) => ListTile(
              title: Text('${i['phone']} · ${i['unit']} · ${residentRoles.firstWhere((r) => r.$1 == i['role'], orElse: () => ('', '${i['role']}')).$2}'),
              subtitle: Text('${_invStatus[i['status']] ?? i['status']} · ${formatDateTime(i['created_at'])}'),
              trailing: i['status'] == 'PENDING'
                  ? RowMenu([
                      ('İptal et', () async {
                        if (await confirmAction(context, 'Daveti iptal et', '${i['phone']} daveti iptal edilsin mi?', () => apiClient.post('/residents/invitations/${i['id']}/cancel'),
                            ok: 'İptal et', success: 'Davet iptal edildi')) {
                          await reload();
                        }
                      }),
                    ])
                  : null,
            ),
          ),
          ApiObject(
            key: ValueKey(_tToken),
            load: () async {
              final r = await apiClient.getMap('/residents/tenancy-requests');
              return r;
            },
            builder: (context, d, reload) {
              final list = ApiClient.listOf(d['data']).whereType<Map>().toList();
              final att = '${d['attestation_text'] ?? ''}';
              return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Malikin isteği kiracı onaylamadan sonuçlanmaz. Yönetim yolunda kiracı belgeyi görür ve 7 gün içinde itiraz edebilir; itirazda işlem askıya alınır.',
                      style: TextStyle(fontSize: 12)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(onPressed: () => _tenancyDoc(att), icon: const Icon(Icons.description), label: const Text('Yönetim yolu başlat')),
                  ),
                ),
                if (list.isEmpty) const ListTile(title: Text('Kiracılık bitiş kaydı yok')),
                for (final r in list)
                  Builder(builder: (context) {
                    final docs = ((r['documents'] as List?) ?? const []).whereType<Map>().toList();
                    final events = ((r['events'] as List?) ?? const []).whereType<Map>().toList();
                    final st = '${r['status']}';
                    final deadline = parseApiDate(r['objection_deadline']);
                    final mgmt = r['kind'] == 'MANAGEMENT';
                    return ExpansionTile(
                      title: Text('${r['unit']} · ${r['tenant_name'] ?? ''}'),
                      subtitle: Text('${_tKind[r['kind']] ?? r['kind']} · ${_tStatus[st] ?? st}'
                          '${r['end_date'] != null ? ' · bitti ${formatDate(r['end_date'])}' : deadline != null ? ' · itiraz sonu ${formatDateTime(r['objection_deadline'])}' : ''}'),
                      children: [
                        for (final x in docs)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.attach_file),
                            title: Text('${_docKinds.firstWhere((k) => k.$1 == x['document_kind'], orElse: () => ('', '${x['document_kind']}')).$2}'
                                '${x['uyap_code'] != null ? ' · UYAP ${x['uyap_code']}' : ''} · ${x['file_name']}'),
                            onTap: () => openDownload(context, '/residents/tenancy-requests/${r['id']}/documents/${x['id']}', '${x['file_name']}'),
                          ),
                        for (final e in events)
                          ListTile(dense: true, title: Text('${formatDateTime(e['created_at'])} ${_by[e['by']] ?? e['by']} ${_tEvent[e['event']] ?? e['event']}${e['note'] != null ? ' (${e['note']})' : ''}')),
                        if (mgmt)
                          Wrap(spacing: 8, children: [
                            if (st == 'OBJECTION_WINDOW')
                              TextButton(
                                onPressed: deadline != null && deadline.isBefore(DateTime.now())
                                    ? () async {
                                        if (await runAction(context, () => apiClient.post('/residents/tenancy-requests/${r['id']}/complete'))) await reload();
                                      }
                                    : null,
                                child: const Text('Tamamla (itiraz süresi dolunca)'),
                              ),
                            if (st == 'SUSPENDED') TextButton(onPressed: () => _tenancyDoc(att, request: r), child: const Text('Yeni belge')),
                            if (st == 'OBJECTION_WINDOW' || st == 'SUSPENDED')
                              TextButton(
                                onPressed: () async {
                                  if (await runAction(context, () => apiClient.post('/residents/tenancy-requests/${r['id']}/cancel', {'note': ''}))) await reload();
                                },
                                child: const Text('İptal'),
                              ),
                            if (st == 'COMPLETED')
                              TextButton(
                                onPressed: () async {
                                  if (await formAction(context, 'Kiracılığı geri aç', const [
                                    FSpec('reason', 'Gerekçe', type: FType.multiline, required: true),
                                    FSpec('password', 'Şifreniz', type: FType.password, required: true),
                                  ], (v) => apiClient.post('/residents/tenancy-requests/${r['id']}/reverse', v),
                                      note: 'Belge sahte ya da hatalı çıktıysa kiracılık geçmişiyle geri açılır. Dairede başka kiracı kaydedildiyse geri alınamaz.', submit: 'Geri al')) {
                                    await reload();
                                  }
                                },
                                child: const Text('Geri al'),
                              ),
                          ]),
                      ],
                    );
                  }),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}
