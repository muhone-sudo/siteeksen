// Personel ve izin yönetimi.
//
// DÜZELTME (2026-09-26): ekran var olmayan `name` alanını okuyordu; ad boş
// gelince `substring(0,1)` ile ÇÖKÜYORDU. Maaş ve durum alanları da yanlıştı
// (`salary`, `status`); izin Onayla/Reddet düğmelerinin işleyicisi boştu.
//
// Kişisel veri: TCKN ve IBAN sunucudan maskeli gelir; görevli (STAFF) maaş
// göremez (`salary_visible`). Maskesiz görüntüleme mobilde bilerek yoktur.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../visitors/presentation/screens/visitor_management_screen.dart' show initialOf;

const leaveTypeLabels = {
  'ANNUAL': 'Yıllık', 'SICK': 'Hastalık', 'UNPAID': 'Ücretsiz', 'MATERNITY': 'Doğum',
  'PATERNITY': 'Babalık', 'MARRIAGE': 'Evlilik', 'BEREAVEMENT': 'Vefat', 'OTHER': 'Diğer',
};
const leaveStatusLabels = {'PENDING': 'Onay bekliyor', 'APPROVED': 'Onaylandı', 'REJECTED': 'Reddedildi'};
const contractTypes = {'FULL_TIME': 'Tam zamanlı', 'PART_TIME': 'Yarı zamanlı', 'CONTRACT': 'Sözleşmeli', 'INTERN': 'Stajyer'};

class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() => _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen> {
  final _employees = GlobalKey<ApiListState>();
  final _leaves = GlobalKey<ApiListState>();
  bool _canWrite = false;

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
        appBar: AppBar(
          title: const Text('Personel'),
          bottom: const TabBar(tabs: [Tab(text: 'Personel'), Tab(text: 'İzinler')]),
        ),
        floatingActionButton: _canWrite
            ? FloatingActionButton.extended(onPressed: _createEmployee, icon: const Icon(Icons.person_add), label: const Text('Personel'))
            : null,
        body: TabBarView(children: [
          ApiList(
            key: _employees,
            load: () => apiClient.getList('/employees'),
            empty: 'Kayıtlı personel yok',
            itemBuilder: (context, e, _) {
              final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
              final salaryVisible = e['salary_visible'] == true;
              return ListTile(
                leading: CircleAvatar(child: Text(initialOf(name))),
                title: Text(name.isEmpty ? 'Adsız kayıt' : name),
                subtitle: Text([
                  '${e['position'] ?? ''}',
                  contractTypes['${e['contract_type']}'] ?? '',
                  'İşe giriş: ${formatDate(e['hire_date'])}',
                  'Kalan izin: ${toNum(e['remaining_leave_days']).toInt()} gün',
                  if (salaryVisible && e['net_salary'] != null) 'Net: ${formatTry(toNum(e['net_salary']))}',
                ].where((s) => s.isNotEmpty).join(' · ')),
                trailing: e['is_active'] == false ? const StatusChip('Ayrıldı', color: Colors.grey) : null,
              );
            },
          ),
          ApiList(
            key: _leaves,
            load: () => apiClient.getList('/leaves'),
            empty: 'İzin talebi yok',
            itemBuilder: (context, l, reload) => ListTile(
              title: Text('${l['employee_name'] ?? ''} · ${leaveTypeLabels['${l['leave_type']}'] ?? l['leave_type']}'),
              subtitle: Text([
                '${formatDate(l['start_date'])} – ${formatDate(l['end_date'])} (${toNum(l['days']).toInt()} gün)',
                leaveStatusLabels['${l['status']}'] ?? '${l['status']}',
                if ((l['reason'] ?? '').toString().isNotEmpty) '${l['reason']}',
              ].join('\n')),
              isThreeLine: true,
              trailing: _canWrite && l['status'] == 'PENDING'
                  ? PopupMenuButton<String>(
                      onSelected: (a) async {
                        Map<String, dynamic> body = {};
                        if (a == 'reject') {
                          final r = await askText(context, 'İzni reddet', 'Gerekçe');
                          if (r == null) return;
                          body = {'reason': r};
                        }
                        if (!context.mounted) return;
                        if (await runAction(context, () => apiClient.post('/leaves/${l['id']}/$a', body))) await reload();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'approve', child: Text('Onayla')),
                        PopupMenuItem(value: 'reject', child: Text('Reddet')),
                      ],
                    )
                  : null,
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _createEmployee() async {
    final formKey = GlobalKey<FormState>();
    final first = TextEditingController();
    final last = TextEditingController();
    final position = TextEditingController();
    var hire = DateTime.now();
    var type = 'FULL_TIME';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Yeni personel'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: first, decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                TextFormField(controller: last, decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                TextFormField(controller: position, decoration: const InputDecoration(labelText: 'Görev'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Sözleşme türü'),
                  items: [for (final e in contractTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                  onChanged: (v) => set(() => type = v ?? type),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('İşe giriş'),
                  subtitle: Text(formatDate(hire)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: hire, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 60)));
                    if (d != null) set(() => hire = d);
                  },
                ),
                const Text('TCKN ve IBAN gibi kişisel veriler web panelinden girilir.', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            }, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final saved = await runAction(context, () => apiClient.post('/employees', {
            'first_name': first.text.trim(),
            'last_name': last.text.trim(),
            'position': position.text.trim(),
            'hire_date': apiDate(hire),
            'contract_type': type,
          }));
      if (saved) await _employees.currentState?.reload();
    }
    for (final c in [first, last, position]) {
      c.dispose();
    }
  }
}
