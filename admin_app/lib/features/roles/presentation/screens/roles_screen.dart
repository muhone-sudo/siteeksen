// Görevlendirmeler (FAZ H.7, panel /dashboard/roles ile eşit). Yönetici, kurul üyesi ve denetçi
// KMK m.34/m.41 uyarınca kat malikleri kurulu kararıyla atanır; karar bilgisi zorunludur. Atamayı
// yalnız yönetici yapar; görev sonlandırılınca kişinin açık oturumları kapanır, kayıt silinmez.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';
import '../../../residents/presentation/widgets/activation_code_dialog.dart';

const _roles = [('MANAGER', 'Yönetici'), ('BOARD_MEMBER', 'Yönetim kurulu üyesi'), ('AUDITOR', 'Denetçi'), ('STAFF', 'Görevli')];
const _needsDecision = {'MANAGER', 'BOARD_MEMBER', 'AUDITOR'};

String _roleName(Object? r) => _roles.firstWhere((e) => e.$1 == r, orElse: () => ('', '$r')).$2;

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _list = GlobalKey<ApiListState>();
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    hasAnyRole(['MANAGER']).then((v) {
      if (mounted) setState(() => _isManager = v);
    });
  }

  Future<void> _grant() async {
    final v = await showForm(context, 'Görev ver', const [
      FSpec('phone', 'Telefon', required: true, hint: 'Kişi bu sitede kayıtlı değilse yeni hesap açılır'),
      FSpec('role', 'Görev', type: FType.select, options: _roles, initial: 'STAFF', required: true),
      FSpec('decision_ref', 'Kurul kararı (tarih ve sayı)', hint: 'Yönetici/kurul/denetçi için zorunlu (KMK m.34/m.41)'),
      FSpec('valid_to', 'Bitiş tarihi', type: FType.date, hint: 'Boşsa süresiz'),
      FSpec('first_name', 'Ad', hint: 'Yalnızca yeni hesap için'),
      FSpec('last_name', 'Soyad', hint: 'Yalnızca yeni hesap için'),
    ]);
    if (v == null || !mounted) return;
    if (_needsDecision.contains(v['role']) && (v['decision_ref'] ?? '').toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu görev için kurul kararı bilgisi zorunludur')));
      return;
    }
    try {
      final r = await apiClient.post('/property-roles', v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(['Görev verildi', r['note']].whereType<String>().join(' — '))));
      if (r['activation'] is Map) {
        await showActivationCodeDialog(context, who: '${v['phone']}', activation: Map<String, dynamic>.from(r['activation'] as Map));
      }
      await _list.currentState?.reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görevlendirmeler')),
      floatingActionButton: _isManager ? FloatingActionButton.extended(onPressed: _grant, icon: const Icon(Icons.person_add_alt), label: const Text('Görev ver')) : null,
      body: ApiList(
        key: _list,
        load: () => apiClient.getList('/property-roles'),
        empty: 'Görevlendirme yok',
        header: (_) => _isManager
            ? const SizedBox.shrink()
            : const Padding(padding: EdgeInsets.all(16), child: Text('Görev verme ve sonlandırma yalnızca yöneticinin yetkisindedir.')),
        itemBuilder: (context, r, reload) => ListTile(
          title: Text('${r['first_name'] ?? ''} ${r['last_name'] ?? ''} · ${_roleName(r['role'])}'),
          subtitle: Text([
            '${r['phone'] ?? ''}',
            '${formatDate(r['valid_from'])} – ${r['valid_to'] != null ? formatDate(r['valid_to']) : 'süresiz'}',
            if ((r['decision_ref'] ?? '').toString().isNotEmpty) 'Karar: ${r['decision_ref']}',
            'Atayan: ${r['granted_by_name'] ?? '—'} · ${formatDateTime(r['granted_at'])}',
          ].join('\n')),
          isThreeLine: true,
          trailing: r['active'] == true
              ? (_isManager
                  ? RowMenu([
                      ('Sonlandır', () async {
                        if (await confirmAction(context, 'Görevi sonlandır', '${r['first_name']} ${r['last_name']} — ${_roleName(r['role'])} görevi sonlandırılsın mı? Kişinin açık oturumları kapanır.',
                            () => apiClient.post('/property-roles/${r['id']}/end'), ok: 'Sonlandır', success: 'Görev sonlandırıldı')) {
                          await reload();
                        }
                      }),
                    ])
                  : const StatusChip('Etkin', color: Colors.green))
              : const StatusChip('Sona erdi', color: Colors.grey),
        ),
      ),
    );
  }
}
