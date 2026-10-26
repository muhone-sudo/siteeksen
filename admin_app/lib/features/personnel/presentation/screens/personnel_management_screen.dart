// Personel ve izin yönetimi.
//
// DÜZELTME (2026-09-26): ekran var olmayan `name` alanını okuyordu; ad boş
// gelince `substring(0,1)` ile ÇÖKÜYORDU. Maaş ve durum alanları da yanlıştı
// (`salary`, `status`); izin Onayla/Reddet düğmelerinin işleyicisi boştu.
//
// Kişisel veri: TCKN ve IBAN sunucudan maskeli gelir; görevli (STAFF) maaş
// göremez (`salary_visible`). Maskesiz görüntüleme mobilde bilerek yoktur.
// FAZ H.7: ilişik kesme, izin girişi, bordro (gir/öde/iptal, yıllık maliyet)
// ve SGK/MUHSGK yükümlülük takvimi panelle eşit. Sistem bordro HESAPLAMAZ.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';
import '../../../visitors/presentation/screens/visitor_management_screen.dart' show initialOf;

const leaveTypeLabels = {
  'ANNUAL': 'Yıllık', 'SICK': 'Hastalık', 'UNPAID': 'Ücretsiz', 'MATERNITY': 'Doğum',
  'PATERNITY': 'Babalık', 'MARRIAGE': 'Evlilik', 'BEREAVEMENT': 'Vefat', 'OTHER': 'Diğer',
};
const leaveStatusLabels = {'PENDING': 'Onay bekliyor', 'APPROVED': 'Onaylandı', 'REJECTED': 'Reddedildi'};
const contractTypes = {'FULL_TIME': 'Tam zamanlı', 'PART_TIME': 'Yarı zamanlı', 'CONTRACT': 'Sözleşmeli', 'INTERN': 'Stajyer'};
const _payStatus = {'PAID': ('Ödendi', Colors.green), 'PENDING': ('Ödeme bekliyor', Colors.orange), 'CANCELLED': ('İptal', Colors.grey)};

String _month(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() => _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen> {
  final _employees = GlobalKey<ApiListState>();
  final _leaves = GlobalKey<ApiListState>();
  bool _canWrite = false;
  bool _payrollVisible = false;

  @override
  void initState() {
    super.initState();
    apiClient.getCurrentUserRoles().then((r) {
      if (mounted) {
        setState(() {
          _canWrite = r.any(writeRoles.contains);
          _payrollVisible = _canWrite || r.contains('AUDITOR');
        });
      }
    });
  }

  Future<List<(String, String)>> _employeeOptions() => optionsFrom('/employees', (e) => '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim())
      .catchError((_) => <(String, String)>[]);

  Future<void> _createLeave() async {
    final emps = await _employeeOptions();
    if (!mounted) return;
    if (await formAction(context, 'İzin gir', [
      FSpec('employee_id', 'Personel', type: FType.select, options: emps, required: true),
      FSpec('leave_type', 'Tür', type: FType.select, options: [for (final e in leaveTypeLabels.entries) (e.key, e.value)], initial: 'ANNUAL', required: true),
      FSpec('start_date', 'Başlangıç', type: FType.date, initial: DateTime.now(), required: true),
      FSpec('end_date', 'Bitiş', type: FType.date, initial: DateTime.now(), required: true),
      const FSpec('reason', 'Açıklama'),
    ], (v) => apiClient.post('/leaves', v), success: 'İzin talebi oluşturuldu (onay bekliyor)')) {
      await _leaves.currentState?.reload();
      await _employees.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _payrollVisible ? 4 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personel'),
          actions: [if (_canWrite) IconButton(tooltip: 'İzin gir', icon: const Icon(Icons.event_available), onPressed: _createLeave)],
          bottom: TabBar(isScrollable: true, tabs: [
            const Tab(text: 'Personel'),
            const Tab(text: 'İzinler'),
            if (_payrollVisible) const Tab(text: 'Bordro'),
            if (_payrollVisible) const Tab(text: 'Yükümlülükler'),
          ]),
        ),
        floatingActionButton: _canWrite
            ? FloatingActionButton.extended(onPressed: _createEmployee, icon: const Icon(Icons.person_add), label: const Text('Personel'))
            : null,
        body: TabBarView(children: [
          ApiList(
            key: _employees,
            load: () => apiClient.getList('/employees'),
            empty: 'Kayıtlı personel yok',
            header: (_) => FutureBuilder<Map<String, dynamic>>(
              future: apiClient.getMap('/employees/summary'),
              builder: (context, s) {
                final d = s.data;
                if (d == null) return const SizedBox.shrink();
                return StatRow([
                  ('Aktif', '${d['total_active'] ?? 0}'),
                  ('Ayrılan', '${d['total_inactive'] ?? 0}'),
                  ('Bekleyen izin', '${d['pending_leaves'] ?? 0}'),
                  if (d['monthly_salary_cost'] != null) ('Aylık maaş', formatTry(toNum(d['monthly_salary_cost']))),
                ]);
              },
            ),
            itemBuilder: (context, e, reload) {
              final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
              final salaryVisible = e['salary_visible'] == true;
              return ListTile(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _EmployeeDetail(id: '${e['id']}', name: name))),
                leading: CircleAvatar(child: Text(initialOf(name))),
                title: Text(name.isEmpty ? 'Adsız kayıt' : name),
                subtitle: Text([
                  '${e['position'] ?? ''}',
                  contractTypes['${e['contract_type']}'] ?? '',
                  'İşe giriş: ${formatDate(e['hire_date'])}',
                  'Kalan izin: ${toNum(e['remaining_leave_days']).toInt()} gün',
                  if (salaryVisible && e['net_salary'] != null) 'Net: ${formatTry(toNum(e['net_salary']))}',
                ].where((s) => s.isNotEmpty).join(' · ')),
                trailing: e['is_active'] == false
                    ? const StatusChip('Ayrıldı', color: Colors.grey)
                    : (_canWrite
                        ? RowMenu([
                            ('İlişik kes', () async {
                              if (await formAction(context, 'İlişik kes — $name', [
                                const FSpec('reason', 'Gerekçe', type: FType.multiline, required: true),
                                FSpec('end_date', 'Ayrılış tarihi', type: FType.date, initial: DateTime.now()),
                              ], (v) => apiClient.post('/employees/${e['id']}/terminate', v), submit: 'İlişik kes', success: 'Ayrılış işlendi')) {
                                await reload();
                              }
                            }),
                          ])
                        : null),
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
                  ? RowMenu([
                      ('Onayla', () async {
                        if (await runAction(context, () => apiClient.post('/leaves/${l['id']}/approve'))) await reload();
                      }),
                      ('Reddet', () async {
                        if (await reasonAction(context, 'İzni reddet', (r) => apiClient.post('/leaves/${l['id']}/reject', {'reason': r}))) await reload();
                      }),
                    ])
                  : null,
            ),
          ),
          if (_payrollVisible) _PayrollTab(canWrite: _canWrite, employees: _employeeOptions),
          if (_payrollVisible) _ComplianceTab(canWrite: _canWrite),
        ]),
      ),
    );
  }

  Future<void> _createEmployee() async {
    if (await formAction(context, 'Yeni personel', [
      const FSpec('first_name', 'Ad', required: true),
      const FSpec('last_name', 'Soyad', required: true),
      const FSpec('position', 'Görev', required: true),
      const FSpec('department', 'Bölüm'),
      FSpec('hire_date', 'İşe giriş', type: FType.date, initial: DateTime.now(), required: true),
      FSpec('contract_type', 'Sözleşme', type: FType.select, options: [for (final e in contractTypes.entries) (e.key, e.value)], initial: 'FULL_TIME'),
      const FSpec('tc_number', 'TCKN', hint: 'Algoritmik olarak doğrulanır; şifreli saklanır'),
      const FSpec('phone', 'Telefon'),
      const FSpec('email', 'E-posta'),
      const FSpec('gross_salary', 'Brüt maaş (TL)', type: FType.decimal),
      const FSpec('net_salary', 'Net maaş (TL)', type: FType.decimal),
      const FSpec('annual_leave_days', 'Yıllık izin (gün)', type: FType.integer, hint: 'İş K. m.53: 1-5 yıl kıdemde en az 14'),
      const FSpec('bank_name', 'Banka'),
      const FSpec('bank_iban', 'IBAN', hint: 'mod-97 doğrulanır; şifreli saklanır'),
      const FSpec('sgk_number', 'SGK no'),
    ], (v) => apiClient.post('/employees', v), success: 'Personel kaydedildi')) {
      await _employees.currentState?.reload();
    }
  }
}

class _PayrollTab extends StatefulWidget {
  final bool canWrite;
  final Future<List<(String, String)>> Function() employees;
  const _PayrollTab({required this.canWrite, required this.employees});

  @override
  State<_PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<_PayrollTab> {
  DateTime _period = DateTime.now();
  int _token = 0;

  String get _p => _month(_period);

  Future<void> _create() async {
    final emps = await widget.employees();
    if (!mounted) return;
    if (await formAction(context, 'Bordro gir — $_p', [
      FSpec('employee_id', 'Personel', type: FType.select, options: emps, required: true),
      const FSpec('net_salary', 'Net ödenen (TL)', type: FType.decimal, required: true),
      const FSpec('employer_cost', 'İşveren maliyeti (TL)', type: FType.decimal, required: true, hint: 'Brüt + işveren SGK + işsizlik payı'),
      const FSpec('gross_salary', 'Brüt ücret', type: FType.decimal),
      const FSpec('sgk_employee', 'SGK işçi payı', type: FType.decimal),
      const FSpec('sgk_employer', 'SGK işveren payı', type: FType.decimal),
      const FSpec('income_tax', 'Gelir vergisi', type: FType.decimal),
      const FSpec('stamp_tax', 'Damga vergisi', type: FType.decimal),
      const FSpec('source_ref', 'Bordronun kaynağı', required: true, hint: 'Mali müşavir, bordro / tahakkuk no'),
      const FSpec('payment_date', 'Ödeme tarihi', type: FType.date, hint: 'Boşsa ödeme bekliyor'),
      const FSpec('payment_reference', 'Ödeme referansı'),
      const FSpec('notes', 'Not', type: FType.multiline),
    ], (v) async {
      final r = await apiClient.post('/payroll', {...v, 'period': _p});
      return {...r, 'message': r['payment_status'] == 'PAID' ? 'Bordro ve ödeme kaydedildi' : 'Bordro kaydedildi (ödeme bekliyor)'};
    }, note: 'Tutarları mali müşavirin bordrosundan girin; sistem hesaplama ya da doğrulama yapmaz.')) {
      setState(() => _token++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      key: ValueKey('$_p-$_token'),
      load: () => apiClient.getMap('/payroll', query: {'period': _p}),
      builder: (context, d, reload) {
        final rows = ((d['data'] as List?) ?? const []).whereType<Map>().toList();
        final t = (d['totals'] as Map?) ?? const {};
        final missing = ((d['missing'] as List?) ?? const []).map((e) => '$e').toList();
        return ListView(padding: const EdgeInsets.only(bottom: 96), children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _period = DateTime(_period.year, _period.month - 1))),
            Expanded(child: Text(periodLabel(_p), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _month(DateTime.now()) == _p ? null : () => setState(() => _period = DateTime(_period.year, _period.month + 1)),
            ),
          ]),
          StatRow([
            ('Net ödeme', formatTry(toNum(t['net']))),
            ('İşveren maliyeti', formatTry(toNum(t['employer_cost']))),
            ('Ödenmemiş net', formatTry(toNum(t['unpaid_net']))),
          ]),
          if (missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Bu dönemde çalışıp bordrosu girilmemiş: ${missing.join(', ')}', style: const TextStyle(color: Colors.orange)),
            ),
          if (widget.canWrite)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Bordro gir')),
              ),
            ),
          if (rows.isEmpty) const ListTile(title: Text('Bu dönem için bordro kaydı yok.')),
          for (final r in rows)
            ListTile(
              title: Text('${r['employee_name'] ?? ''} · ${formatTry(toNum(r['net_salary']))}'),
              subtitle: Text([
                '${r['position'] ?? ''}',
                'İşveren maliyeti ${formatTry(toNum(r['employer_cost']))}',
                '${r['source_ref'] ?? ''}',
                if (r['payment_date'] != null) 'Ödeme ${formatDate(r['payment_date'])}',
                if ((r['cancel_reason'] ?? '').toString().isNotEmpty) '${r['cancel_reason']}',
              ].where((s) => s.isNotEmpty).join(' · ')),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                StatusChip(_payStatus[r['payment_status']]?.$1 ?? '${r['payment_status']}', color: _payStatus[r['payment_status']]?.$2 ?? Colors.grey),
                if (widget.canWrite && r['payment_status'] == 'PENDING')
                  RowMenu([
                    ('Ödendi', () async {
                      if (await formAction(context, 'Ödeme kaydı', [
                        FSpec('payment_date', 'Ödeme tarihi', type: FType.date, initial: DateTime.now(), required: true),
                        const FSpec('payment_reference', 'Referans'),
                      ], (v) => apiClient.post('/payroll/${r['id']}/pay', v), success: 'Ödeme kaydedildi')) {
                        await reload();
                      }
                    }),
                    ('İptal', () async {
                      if (await reasonAction(context, 'Bordroyu iptal et', (x) => apiClient.post('/payroll/${r['id']}/cancel', {'reason': x}), success: 'Kayıt iptal edildi')) {
                        await reload();
                      }
                    }),
                  ]),
              ]),
            ),
          Padding(padding: const EdgeInsets.all(16), child: Text('${d['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall)),
          const Divider(),
          _YearCosts(token: _token),
        ]);
      },
    );
  }
}

class _YearCosts extends StatefulWidget {
  final int token;
  const _YearCosts({required this.token});

  @override
  State<_YearCosts> createState() => _YearCostsState();
}

class _YearCostsState extends State<_YearCosts> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('$_year-${widget.token}'),
      future: apiClient.getMap('/payroll/costs', query: {'year': '$_year'}),
      builder: (context, s) {
        final d = s.data;
        final months = ((d?['data'] as List?) ?? const []).whereType<Map>().toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
            title: const Text('Yıllık personel maliyeti', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d == null ? (s.hasError ? errorText(s.error!) : 'Yükleniyor…') : 'Toplam işveren maliyeti ${formatTry(toNum(d['employer_cost_total']))}'),
            trailing: DropdownButton<int>(
              value: _year,
              items: [for (var i = 0; i < 6; i++) DropdownMenuItem(value: DateTime.now().year - i, child: Text('${DateTime.now().year - i}'))],
              onChanged: (v) => setState(() => _year = v ?? _year),
            ),
          ),
          for (final m in months)
            ListTile(
              dense: true,
              title: Text(periodLabel(m['period'])),
              subtitle: Text('${m['employees']} personel · net ${formatTry(toNum(m['net']))}'),
              trailing: Text(formatTry(toNum(m['employer_cost']))),
            ),
          if (d != null) Padding(padding: const EdgeInsets.all(16), child: Text('${d['note'] ?? ''}', style: Theme.of(context).textTheme.bodySmall)),
        ]);
      },
    );
  }
}

class _ComplianceTab extends StatelessWidget {
  final bool canWrite;
  const _ComplianceTab({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () => apiClient.getMap('/compliance-calendar'),
      builder: (context, d, reload) {
        final items = ((d['data'] as List?) ?? const []).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.only(bottom: 96), children: [
          if (items.isEmpty) const ListTile(title: Text('Yaklaşan yükümlülük yok')),
          for (final i in items)
            ListTile(
              leading: Icon(toNum(i['days_left']) < 0 ? Icons.error : Icons.event,
                  color: toNum(i['days_left']) < 0 ? Colors.red : (toNum(i['days_left']) <= 5 ? Colors.orange : null)),
              title: Text('${i['title'] ?? ''}'),
              subtitle: Text('Son gün ${formatDate(i['due_date'])} · '
                  '${toNum(i['days_left']) < 0 ? '${-toNum(i['days_left'])} gün geçti' : '${i['days_left']} gün'}\n${i['legal_basis'] ?? ''}'),
              isThreeLine: true,
              trailing: canWrite && (i['kind'] == 'SGK_ENTRY' || i['kind'] == 'SGK_EXIT') && i['employee_id'] != null
                  ? TextButton(
                      onPressed: () async {
                        final key = i['kind'] == 'SGK_ENTRY' ? 'entry_date' : 'exit_date';
                        if (await formAction(context, 'SGK bildirgesi verildi', [
                          FSpec(key, 'Bildirgenin verildiği tarih', type: FType.date, initial: DateTime.now(), required: true),
                        ], (v) => apiClient.post('/employees/${i['employee_id']}/sgk', v), success: 'Bildirge tarihi kaydedildi')) {
                          await reload();
                        }
                      },
                      child: const Text('Verildi'),
                    )
                  : null,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${d['note'] ?? ''}${d['muhsgk_enabled'] == false ? ' Aylık MUHSGK takvimi site ayarlarından kapatılmış.' : ''}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ]);
      },
    );
  }
}

/// Personel kartı. TCKN ve IBAN sunucudan MASKELİ gelir; maskesiz görüntüleme (PII_REVEAL kaydı üretir) mobilde yoktur.
class _EmployeeDetail extends StatelessWidget {
  final String id;
  final String name;
  const _EmployeeDetail({required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ApiObject(
        load: () => apiClient.getMap('/employees/$id'),
        builder: (context, e, _) => ListView(children: [
          for (final (l, v) in [
            ('Sicil no', e['employee_number']),
            ('Görev', e['position']),
            ('Bölüm', e['department']),
            ('Sözleşme', contractTypes['${e['contract_type']}'] ?? e['contract_type']),
            ('İşe giriş', formatDate(e['hire_date'])),
            if (e['end_date'] != null) ('Ayrılış', formatDate(e['end_date'])),
            ('Telefon', e['phone']),
            ('E-posta', e['email']),
            ('TCKN', e['tc_number']),
            ('IBAN', e['bank_iban']),
            if (e['salary_visible'] == true) ('Brüt maaş', e['gross_salary'] == null ? null : formatTry(toNum(e['gross_salary']))),
            if (e['salary_visible'] == true) ('Net maaş', e['net_salary'] == null ? null : formatTry(toNum(e['net_salary']))),
            ('Yıllık izin', '${e['annual_leave_days'] ?? 0} gün (kullanılan ${e['used_leave_days'] ?? 0}, kalan ${e['remaining_leave_days'] ?? 0})'),
          ])
            if (v != null && '$v'.isNotEmpty) ListTile(dense: true, title: Text(l), subtitle: Text('$v')),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('TCKN ve IBAN maskelidir; maskesiz görüntüleme denetim kaydıyla yalnız web panelinden yapılır.', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}
