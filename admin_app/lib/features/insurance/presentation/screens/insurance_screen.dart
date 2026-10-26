// Sigorta (FAZ H.7, panel /dashboard/insurance ile eşit): bağımsız bölüm DASK takibi (yükümlülük
// malikindir — 6305 m.10/3) ve ortak alan hasar/tazminat kaydı.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _state = {'VALID': ('Geçerli', Colors.green), 'EXPIRING': ('Bitiyor', Colors.orange), 'EXPIRED': ('Bitmiş', Colors.red), 'MISSING': ('Kayıt yok', Colors.grey)};
const _claim = {'REPORTED': 'İhbar edildi', 'EXPERT_ASSIGNED': 'Eksper atandı', 'PAID': 'Ödendi', 'REJECTED': 'Reddedildi', 'CLOSED': 'Kapandı'};
const _next = {'REPORTED': ['EXPERT_ASSIGNED', 'PAID', 'REJECTED'], 'EXPERT_ASSIGNED': ['PAID', 'REJECTED'], 'PAID': ['CLOSED'], 'REJECTED': ['CLOSED']};

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  bool _canWrite = false;
  final _claims = GlobalKey<ApiListState>();

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sigorta'), bottom: const TabBar(tabs: [Tab(text: 'DASK'), Tab(text: 'Hasar kayıtları')])),
        body: TabBarView(children: [
          ApiObject(
            load: () => apiClient.getMap('/insurance/dask'),
            builder: (context, d, reload) {
              final s = (d['summary'] as Map?) ?? const {};
              final rows = ((d['data'] as List?) ?? const []).whereType<Map>().toList();
              return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
                StatRow([
                  ('Geçerli DASK', '${s['VALID'] ?? 0}'),
                  ('30 günde bitiyor', '${s['EXPIRING'] ?? 0}'),
                  ('Bitmiş', '${s['EXPIRED'] ?? 0}'),
                  ('Kayıt yok', '${s['MISSING'] ?? 0}'),
                ]),
                for (final r in rows)
                  ListTile(
                    title: Text('${r['unit']}'),
                    subtitle: Text(r['policy_no'] != null
                        ? '${r['policy_no']}${r['insurer'] != null ? ' · ${r['insurer']}' : ''} · bitiş ${formatDate(r['end_date'])}'
                        : 'Poliçe kaydı yok'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      StatusChip(_state[r['state']]?.$1 ?? '${r['state']}', color: _state[r['state']]?.$2 ?? Colors.grey),
                      if (_canWrite)
                        IconButton(
                          tooltip: 'Poliçe gir',
                          icon: const Icon(Icons.edit_document),
                          onPressed: () async {
                            if (await formAction(context, 'DASK poliçesi — ${r['unit']}', [
                              const FSpec('policy_no', 'Poliçe no', required: true),
                              const FSpec('insurer', 'Sigorta şirketi'),
                              FSpec('start_date', 'Başlangıç', type: FType.date, initial: DateTime.now(), required: true),
                              const FSpec('end_date', 'Bitiş', type: FType.date, required: true),
                            ], (v) => apiClient.post('/insurance/dask', {...v, 'unit_id': r['unit_id']}), success: 'Poliçe kaydedildi')) {
                              await reload();
                            }
                          },
                        ),
                    ]),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${d['note'] ?? ''} Bitişine 30 gün kalan ve bitmiş poliçeler için malike hatırlatma gider.', style: Theme.of(context).textTheme.bodySmall),
                ),
              ]);
            },
          ),
          ApiList(
            key: _claims,
            load: () => apiClient.getList('/insurance/claims'),
            empty: 'Hasar kaydı yok',
            header: (_) => _canWrite
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (await formAction(context, 'Hasar kaydı', [
                            FSpec('occurred_on', 'Olay tarihi', type: FType.date, initial: DateTime.now(), required: true),
                            const FSpec('claimed_amount', 'Talep edilen (TL)', type: FType.decimal),
                            const FSpec('insurer_ref', 'Sigortacı dosya no'),
                            const FSpec('description', 'Açıklama', type: FType.multiline, required: true),
                          ], (v) => apiClient.post('/insurance/claims', v), success: 'Hasar kaydedildi')) {
                            await _claims.currentState?.reload();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Hasar kaydet'),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            itemBuilder: (context, x, reload) => ListTile(
              title: Text('${formatDate(x['occurred_on'])} · ${_claim[x['status']] ?? x['status']}'),
              subtitle: Text([
                '${x['description'] ?? ''}',
                if (x['claimed_amount'] != null) 'Talep ${formatTry(toNum(x['claimed_amount']))}',
                if (x['paid_amount'] != null) 'Ödenen ${formatTry(toNum(x['paid_amount']))} · ${formatDate(x['paid_on'])}',
                if ((x['note'] ?? '').toString().isNotEmpty) '${x['note']}',
              ].join('\n')),
              isThreeLine: true,
              trailing: _canWrite && _next[x['status']] != null
                  ? TextButton(
                      onPressed: () async {
                        bool paid(Map<String, dynamic> v) => v['status'] == 'PAID';
                        if (await formAction(context, 'Hasar durumunu ilerlet', [
                          FSpec('status', 'Yeni durum', type: FType.select, options: [for (final s in _next[x['status']]!) (s, _claim[s]!)], initial: _next[x['status']]!.first, required: true),
                          FSpec('paid_amount', 'Ödenen tazminat (TL)', type: FType.decimal, required: true, visible: paid),
                          FSpec('paid_on', 'Ödeme tarihi', type: FType.date, initial: DateTime.now(), required: true, visible: paid),
                          const FSpec('note', 'Not', type: FType.multiline, hint: 'Ret durumunda sigortacının gerekçesini yazın'),
                        ], (v) {
                          if (v['status'] == 'REJECTED' && (v['note'] ?? '').toString().isEmpty) throw StateError('Ret gerekçesi zorunlu');
                          return apiClient.post('/insurance/claims/${x['id']}/status', v);
                        }, success: 'Durum güncellendi')) {
                          await reload();
                        }
                      },
                      child: const Text('İlerlet'),
                    )
                  : null,
            ),
          ),
        ]),
      ),
    );
  }
}
