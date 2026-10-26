// Site ayarları (FAZ H.7, panel /dashboard/settings ile eşit): işletme ayarları, KVKK saklama ve imha,
// kamera/biyometrik envanteri, değişiklik geçmişi, site durumu (pasifleştirme) ve malik görünürlük politikası.
// Mevzuata bağlı değerler (gecikme tazminatı, ısıtma payları, nisaplar) burada değiştirilemez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _area = [('ENTRANCE', 'Giriş'), ('PERIMETER', 'Çevre'), ('PARKING', 'Otopark'), ('GARDEN', 'Bahçe'), ('LOBBY', 'Lobi'), ('CORRIDOR', 'Koridor'), ('ELEVATOR', 'Asansör'), ('OTHER', 'Diğer')];
const _method = [('FINGERPRINT', 'Parmak izi'), ('FACE', 'Yüz'), ('PALM', 'Avuç içi'), ('IRIS', 'İris'), ('OTHER', 'Diğer')];
const _visStatus = {
  'DEFAULT': 'Varsayılan (en dar)', 'PENDING': 'Onay bekliyor', 'ACTIVE': 'Yürürlükte', 'SUPERSEDED': 'Yerini yenisi aldı', 'REJECTED': 'Reddedildi', 'CANCELLED': 'Geri çekildi',
};

String _l(List<(String, String)> list, Object? v) => list.firstWhere((e) => e.$1 == v, orElse: () => ('', '$v')).$2;

class SiteSettingsScreen extends StatefulWidget {
  const SiteSettingsScreen({super.key});

  @override
  State<SiteSettingsScreen> createState() => _SiteSettingsScreenState();
}

class _SiteSettingsScreenState extends State<SiteSettingsScreen> {
  List<String> _roles = const [];
  String _userId = '';

  @override
  void initState() {
    super.initState();
    apiClient.getCurrentUserRoles().then((r) async {
      final id = await apiClient.getCurrentUserId();
      if (mounted) {
        setState(() {
          _roles = r;
          _userId = id;
        });
      }
    });
  }

  bool get _w => _roles.any(writeRoles.contains);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ayarlar'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Ayarlar'), Tab(text: 'Saklama ve imha'), Tab(text: 'Kamera ve biyometrik'), Tab(text: 'Geçmiş'), Tab(text: 'Site durumu'), Tab(text: 'Malik görünürlüğü'),
          ]),
        ),
        body: TabBarView(children: [
          _SettingsList(canWrite: _w),
          _Retention(canWrite: _w),
          _Privacy(canWrite: _w),
          ApiList(
            load: () => apiClient.getList('/settings-history'),
            empty: 'Değişiklik yok',
            itemBuilder: (context, h, _) => ListTile(
              title: Text('${h['key']}'),
              subtitle: Text('${h['old_value'] ?? '—'} → ${h['new_value']}\n${formatDateTime(h['changed_at'])} · ${h['changed_by_name'] ?? '—'}'),
              isThreeLine: true,
            ),
          ),
          _Lifecycle(isManager: _roles.contains('MANAGER')),
          _Visibility(canWrite: _w, isBoard: _roles.contains('BOARD_MEMBER'), userId: _userId),
        ]),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  final bool canWrite;
  const _SettingsList({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () async => {'list': await apiClient.getMap('/settings'), 'defs': await apiClient.getList('/settings/definitions')},
      builder: (context, d, reload) {
        final list = ApiClient.listOf((d['list'] as Map)['data']).whereType<Map>().toList();
        final defs = {for (final x in (d['defs'] as List).whereType<Map>()) '${x['key']}': x};
        return ListView(children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Mevzuata bağlı değerler (gecikme tazminatı, ısıtma payları, genel kurul nisapları) burada değiştirilemez; kanunla sabittir.', style: TextStyle(fontSize: 12)),
          ),
          for (final s in list)
            Builder(builder: (context) {
              final def = defs['${s['key']}'];
              final options = [for (final o in ((def?['options'] as List?) ?? const []).whereType<Map>()) ('${o['value']}', '${o['label']}')];
              final shown = options.isEmpty ? '${s['value'] ?? ''}' : _l(options, '${s['value']}');
              return ListTile(
                title: Text('${s['description'] ?? s['key']}'),
                subtitle: Text('$shown${s['is_default'] == true ? ' · varsayılan' : ' · değiştirildi'}'
                    '${s['updated_at'] != null ? '\n${formatDateTime(s['updated_at'])} · ${s['updated_by_name'] ?? ''}' : ''}'),
                isThreeLine: s['updated_at'] != null,
                trailing: canWrite
                    ? RowMenu([
                        ('Düzenle', () async {
                          final type = '${s['type']}';
                          final spec = options.isNotEmpty
                              ? FSpec('value', 'Değer', type: FType.select, options: options, initial: '${s['value']}', required: true)
                              : type == 'BOOL'
                                  ? FSpec('value', 'Açık', type: FType.toggle, initial: s['value'] == true)
                                  : FSpec('value', 'Değer', type: type == 'INT' ? FType.integer : FType.text, initial: s['value'], required: true,
                                      hint: def?['min'] != null ? 'Aralık: ${def!['min']}–${def['max']}' : null);
                          if (await formAction(context, '${s['description'] ?? s['key']}', [spec], (v) => apiClient.put('/settings/${s['key']}', {'value': v['value']}),
                              success: 'Ayar kaydedildi')) {
                            await reload();
                          }
                        }),
                        if (s['is_default'] != true)
                          ('Varsayılana döndür', () async {
                            if (await runAction(context, () => apiClient.delete('/settings/${s['key']}'), success: 'Varsayılana döndü')) await reload();
                          }),
                      ])
                    : null,
              );
            }),
        ]);
      },
    );
  }
}

class _Retention extends StatelessWidget {
  final bool canWrite;
  const _Retention({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () async => {'rules': await apiClient.getMap('/retention-rules'), 'log': await apiClient.getList('/retention-rules/log')},
      builder: (context, d, reload) {
        final r = d['rules'] as Map;
        final rules = ApiClient.listOf(r['data']).whereType<Map>().toList();
        final log = (d['log'] as List).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          if (canWrite)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (await confirmAction(context, 'Şimdi imha et', 'Süresi dolan kişisel veriler anonimleştirilir; işlem imha kaydına yazılır.', () => apiClient.post('/retention-rules/run'), ok: 'İmha et')) {
                    await reload();
                  }
                },
                icon: const Icon(Icons.auto_delete),
                label: const Text('Şimdi imha et'),
              ),
            ),
          for (final x in rules)
            ListTile(
              title: Text('${x['title']}'),
              subtitle: Text('${x['fields'] ?? ''}\n${x['retention_months'] != null ? '${x['retention_months']} ay' : 'Tanımlı değil'}'
                  '${x['last_run_at'] != null ? ' · son imha ${formatDateTime(x['last_run_at'])} (${x['last_run_count']} kayıt)' : ''}'
                  '${(x['justification'] ?? '').toString().isNotEmpty ? '\n${x['justification']}' : ''}'),
              isThreeLine: true,
              trailing: canWrite
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        if (await formAction(context, 'Saklama süresi — ${x['title']}', [
                          FSpec('retention_months', 'Saklama süresi (ay, 1-120)', type: FType.integer, initial: x['retention_months'] ?? 12, required: true),
                          FSpec('justification', 'Gerekçe (işleme amacı / hukuki dayanak)', type: FType.multiline, initial: x['justification'], required: true),
                        ], (v) => apiClient.put('/retention-rules/${x['category']}', v), note: 'Koşul: ${x['condition'] ?? ''}.', success: 'Kaydedildi')) {
                          await reload();
                        }
                      },
                    )
                  : null,
            ),
          Padding(padding: const EdgeInsets.all(16), child: Text('${r['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall)),
          const ListTile(title: Text('İmha kaydı', style: TextStyle(fontWeight: FontWeight.w600))),
          if (log.isEmpty) const ListTile(title: Text('Henüz imha yapılmadı')),
          for (final e in log)
            ListTile(
              dense: true,
              title: Text('${e['category']} · ${e['record_count']} kayıt'),
              subtitle: Text('${formatDateTime(e['executed_at'])} · ${e['method'] == 'ANONYMIZE' ? 'Anonimleştirme' : 'Silme'} · kesim ${formatDate(e['cutoff'])} · '
                  '${e['executed_by'] == 'scheduler' ? 'Otomatik' : 'Yönetim'}'),
            ),
        ]);
      },
    );
  }
}

class _Privacy extends StatelessWidget {
  final bool canWrite;
  const _Privacy({required this.canWrite});

  Future<bool> _camera(BuildContext context, [Map? c]) {
    bool intensive(Map<String, dynamic> v) => v['audio_recording'] == true || v['face_recognition'] == true || v['area_type'] == 'ELEVATOR';
    return formAction(context, c == null ? 'Kamera ekle' : 'Kamera kaydını düzenle', [
      FSpec('location', 'Konum', initial: c?['location'], required: true),
      FSpec('area_type', 'Alan türü', type: FType.select, options: _area, initial: c?['area_type'] ?? 'ENTRANCE', required: true),
      FSpec('purpose', 'Amaç', initial: c?['purpose'], required: true),
      FSpec('retention_days', 'Saklama (gün, 1-365)', type: FType.integer, initial: c?['retention_days'] ?? 15, required: true),
      FSpec('decision_ref', 'Genel kurul kararı', initial: c?['decision_ref']),
      FSpec('access_note', 'Kayıtlara kimler erişir', initial: c?['access_note']),
      FSpec('notice_posted', 'Aydınlatma levhası asılı', type: FType.toggle, initial: c?['notice_posted'] ?? false),
      FSpec('masked', 'Gereksiz alanlar maskelendi', type: FType.toggle, initial: c?['masked'] ?? false),
      FSpec('audio_recording', 'Ses kaydı yapıyor', type: FType.toggle, initial: c?['audio_recording'] ?? false),
      FSpec('face_recognition', 'Yüz tanıma var', type: FType.toggle, initial: c?['face_recognition'] ?? false),
      FSpec('intensive_justification', 'Somut gerekçe', type: FType.multiline, initial: c?['intensive_justification'], required: true, visible: intensive),
      if (c != null) FSpec('is_active', 'Kayıt etkin (kamera kullanımda)', type: FType.toggle, initial: c['is_active'] != false),
    ], (v) async {
      final body = {'intensive_justification': '', 'decision_ref': '', 'access_note': '', ...v};
      if (c != null) return apiClient.put('/privacy/cameras/${c['id']}', body);
      final r = await apiClient.post('/privacy/cameras', body);
      final issues = (r['issues'] as List?) ?? const [];
      return {...r, 'message': issues.isEmpty ? 'Kaydedildi' : 'Kaydedildi; ${issues.length} uygunluk notu var'};
    }, note: 'Bağımsız bölüm içini/kapı önünü, tuvalet, soyunma ve ibadet yerlerini gören kamera konulamaz. Ses kaydı, yüz tanıma ve asansör kamerası için somut gerekçe gerekir.',
        success: c == null ? null : 'Kamera kaydı güncellendi');
  }

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () async => {'cams': await apiClient.getMap('/privacy/cameras'), 'bios': await apiClient.getList('/privacy/biometrics')},
      builder: (context, d, reload) {
        final cams = ApiClient.listOf((d['cams'] as Map)['data']).whereType<Map>().toList();
        final bios = (d['bios'] as List).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          ListTile(
            title: const Text('Kamera envanteri', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: canWrite ? IconButton(icon: const Icon(Icons.add), onPressed: () async {
                if (await _camera(context)) await reload();
              }) : null,
          ),
          for (final c in cams)
            ListTile(
              title: Text('${c['location']} · ${_l(_area, c['area_type'])}${c['is_active'] == false ? ' (pasif)' : ''}'),
              subtitle: Text('${c['purpose']} · ${c['retention_days']} gün'
                  '${((c['issues'] as List?) ?? const []).isNotEmpty ? '\n${(c['issues'] as List).join('\n')}' : ''}',
                  style: ((c['issues'] as List?) ?? const []).isNotEmpty ? const TextStyle(color: Colors.orange) : null),
              trailing: canWrite ? IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                if (await _camera(context, c)) await reload();
              }) : null,
            ),
          const Divider(),
          ListTile(
            title: const Text('Biyometrik sistemler', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: canWrite
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      if (await formAction(context, 'Biyometrik sistem', const [
                        FSpec('name', 'Sistem adı', required: true),
                        FSpec('method', 'Yöntem', type: FType.select, options: _method, initial: 'FINGERPRINT', required: true),
                        FSpec('purpose', 'Amaç', required: true),
                        FSpec('alternative_method', 'Alternatif yöntem', required: true, hint: 'Kartlı geçiş, şifre, görevli eşliği'),
                        FSpec('retention_note', 'Saklama notu'),
                      ], (v) => apiClient.post('/privacy/biometrics', {...v, 'consent_based': true}), success: 'Kaydedildi',
                          note: 'Biyometrik veri özel nitelikli kişisel veridir: açık rıza gerekir ve rıza vermeyene alternatif geçiş yöntemi sunulmalıdır (KVKK m.6).')) {
                        await reload();
                      }
                    },
                  )
                : null,
          ),
          for (final b in bios)
            ListTile(title: Text('${b['name']} · ${_l(_method, b['method'])}'), subtitle: Text('${b['purpose']} · alternatif: ${b['alternative_method']}')),
        ]);
      },
    );
  }
}

class _Lifecycle extends StatelessWidget {
  final bool isManager;
  const _Lifecycle({required this.isManager});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () => apiClient.getMap('/property'),
      builder: (context, s, reload) {
        final active = s['is_active'] != false;
        final events = ((s['events'] as List?) ?? const []).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text('${s['name'] ?? ''}: ${active ? 'Etkin' : 'Pasif'}', style: Theme.of(context).textTheme.titleMedium),
          if (!active && s['deactivated_at'] != null) Text('${formatDateTime(s['deactivated_at'])} — ${s['deactivation_reason'] ?? ''}'),
          const SizedBox(height: 8),
          Text(active
              ? 'Yönetim hizmeti sonlandırıldığında siteyi pasife alın: yeni aidat tahakkuku, gecikme tazminatı, zamanlanmış hatırlatma ve bildirim üretilmez. Kayıtlar silinmez.'
              : 'Site pasif: yeni tahakkuk, gecikme tazminatı ve bildirim üretilmiyor. Yeniden etkinleştirmede pasif dönem için geriye dönük tahakkuk yapılmaz.'),
          const SizedBox(height: 12),
          if (isManager)
            FilledButton(
              style: active ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
              onPressed: () async {
                if (await formAction(context, active ? 'Siteyi pasife al' : 'Siteyi yeniden etkinleştir', [
                  const FSpec('reason', 'Gerekçe', required: true),
                  if (active) FSpec('confirm_name', 'Onay için site adını yazın: ${s['name'] ?? ''}', required: true),
                ], (v) => active ? apiClient.post('/property/deactivate', v) : apiClient.post('/property/reactivate', v))) {
                  await reload();
                }
              },
              child: Text(active ? 'Siteyi pasife al' : 'Siteyi yeniden etkinleştir'),
            ),
          const Divider(height: 24),
          for (final e in events)
            ListTile(
              dense: true,
              title: Text(e['action'] == 'DEACTIVATED' ? 'Pasife alındı' : 'Yeniden etkinleştirildi'),
              subtitle: Text('${formatDateTime(e['at'])} · ${e['reason'] ?? ''}'),
            ),
        ]);
      },
    );
  }
}

class _Visibility extends StatelessWidget {
  final bool canWrite;
  final bool isBoard;
  final String userId;
  const _Visibility({required this.canWrite, required this.isBoard, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () => apiClient.getMap('/settings/owner-visibility'),
      builder: (context, d, reload) {
        final active = Map<String, dynamic>.from((d['active'] as Map?) ?? {});
        final pending = d['pending'] is Map ? Map<String, dynamic>.from(d['pending'] as Map) : null;
        final options = ((d['options'] as List?) ?? const []).whereType<Map>().toList();
        final history = ((d['history'] as List?) ?? const []).whereType<Map>().toList();
        String on(Map p) => options.where((o) => p[o['key']] == true).map((o) => '${o['label']}').join(', ');
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text('${d['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('${_visStatus[active['status']] ?? active['status']}${active['decided_at'] != null ? ' · ${formatDateTime(active['decided_at'])} · onaylayan ${active['decided_by_name'] ?? ''}' : ''}'),
          for (final o in options) Text('• ${o['label']}: ${active[o['key']] == true ? 'görür' : 'görmez'}'),
          const SizedBox(height: 8),
          Text('Her zaman görür: ${((d['always_visible'] as List?) ?? const []).join(' · ')}', style: const TextStyle(fontSize: 12)),
          Text('Hiçbir zaman görmez: ${((d['never_visible'] as List?) ?? const []).join(' · ')}', style: const TextStyle(fontSize: 12)),
          if (canWrite && pending == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: () async {
                  if (await formAction(context, 'Görünürlük değişikliği öner', [
                    for (final o in options) FSpec('${o['key']}', '${o['label']}', type: FType.toggle, initial: active[o['key']] == true),
                    const FSpec('note', 'Gerekçe (kiracılar görür, en az 10 karakter)', type: FType.multiline, required: true),
                  ], (v) => apiClient.post('/settings/owner-visibility', v), submit: 'Öner',
                      note: 'Seçenekleri açmak kiracının kişisel verisini malike gösterir (KVKK m.4 ölçülülük). Değişiklik kiracılara bildirilir.')) {
                    await reload();
                  }
                },
                child: const Text('Değişiklik öner'),
              ),
            ),
          if (pending != null) ...[
            const Divider(height: 24),
            const Text('Onay bekleyen öneri', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${pending['proposed_by_name'] ?? ''} · ${formatDateTime(pending['proposed_at'])}: “${pending['note'] ?? ''}”'),
            Text('Açılacak alanlar: ${on(pending).isEmpty ? 'hiçbiri (en dar ayar)' : on(pending)}'),
            Wrap(spacing: 8, children: [
              if (isBoard && pending['proposed_by'] != userId) ...[
                for (final (path, label) in const [('approve', 'Onayla'), ('reject', 'Reddet')])
                  OutlinedButton(
                    onPressed: () async {
                      final note = await askText(context, label, 'Not', required: false);
                      if (note == null || !context.mounted) return;
                      if (await runAction(context, () => path == 'approve'
                          ? apiClient.post('/settings/owner-visibility/${pending['id']}/approve', {'note': note})
                          : apiClient.post('/settings/owner-visibility/${pending['id']}/reject', {'note': note}))) {
                        await reload();
                      }
                    },
                    child: Text(label),
                  ),
              ],
              if (pending['proposed_by'] == userId)
                TextButton(
                  onPressed: () async {
                    if (await runAction(context, () => apiClient.post('/settings/owner-visibility/${pending['id']}/cancel'))) await reload();
                  },
                  child: const Text('Geri çek'),
                ),
            ]),
            if (!isBoard) const Text('Öneriyi öneren dışındaki bir yönetim kurulu üyesi onaylar.', style: TextStyle(fontSize: 12)),
          ],
          if (history.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Geçmiş', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final h in history)
              ListTile(
                dense: true,
                title: Text('${_visStatus[h['status']] ?? h['status']} · ${formatDateTime(h['proposed_at'])} · ${h['proposed_by_name'] ?? ''}'),
                subtitle: Text('Açılan: ${on(h).isEmpty ? 'hiçbiri' : on(h)} · ${h['note'] ?? ''}'),
              ),
          ],
        ]);
      },
    );
  }
}
