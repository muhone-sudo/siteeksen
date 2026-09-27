// Sözleşme takibi.
//
// DÜZELTME (2026-09-27): ekran var olmayan alanları tahmin ediyordu
// (`vendor`, `company`, `contract_no`, `startDate`…) ve sözleşme türlerini
// sunucunun kabul etmediği değerlerle gönderiyordu; yenileme ve fesih hiç
// yoktu. Artık sözleşme (tasks/api-sozlesmesi.md): `GET /contracts`
// (`status`, `expiring_days`), `GET /contracts-summary`, `POST /contracts`,
// `POST /contracts/:id/renew`, `POST /contracts/:id/terminate {reason}`.
// Sistem sözleşmeyi KENDİLİĞİNDEN yenilemez; yenileme yönetimin onayıdır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

/// Sunucunun kabul ettiği türler (şemadaki CHECK ile aynı).
const contractTypes = {
  'SERVICE': 'Hizmet',
  'MAINTENANCE': 'Bakım',
  'RENTAL': 'Kira',
  'EMPLOYMENT': 'İş',
  'INSURANCE': 'Sigorta',
  'OTHER': 'Diğer',
};

(String, Color) contractStatus(Object? status) {
  switch ('${status ?? ''}') {
    case 'ACTIVE':
      return ('Yürürlükte', Colors.green);
    case 'EXPIRED':
      return ('Süresi doldu', Colors.orange);
    case 'TERMINATED':
      return ('Feshedildi', Colors.red);
    case 'DRAFT':
      return ('Taslak', Colors.blueGrey);
    default:
      return ('${status ?? '—'}', Colors.blueGrey);
  }
}

class ContractManagementScreen extends StatefulWidget {
  const ContractManagementScreen({super.key});

  @override
  State<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends State<ContractManagementScreen> {
  bool _canWrite = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  void _changed() => setState(() => _token++);

  Future<void> _renew(Map<String, dynamic> c) async {
    final ok = await confirm(context, 'Sözleşmeyi yenile',
        '"${c['title']}" tanımlı yenileme süresi kadar uzatılır. Bu bir mali yükümlülüktür.', ok: 'Yenile');
    if (!ok || !mounted) return;
    if (await runAction(context, () => apiClient.post('/contracts/${c['id']}/renew'))) _changed();
  }

  Future<void> _terminate(Map<String, dynamic> c) async {
    final reason = await askText(context, 'Sözleşmeyi feshet', 'Fesih gerekçesi');
    if (reason == null || !mounted) return;
    if (await runAction(context, () => apiClient.post('/contracts/${c['id']}/terminate', {'reason': reason}),
        success: 'Sözleşme feshedildi')) {
      _changed();
    }
  }

  Future<void> _create() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ContractForm(),
    );
    if (saved == true) _changed();
  }

  Widget _tile(Map<String, dynamic> c) {
    final (label, color) = contractStatus(c['status']);
    final days = c['days_remaining'];
    final amount = c['payment_type'] == 'YEARLY' ? c['yearly_amount'] : c['monthly_amount'] ?? c['total_amount'];
    final active = c['status'] == 'ACTIVE';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${c['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600))),
            StatusChip(label, color: color),
          ]),
          const SizedBox(height: 4),
          Text('${c['party_name'] ?? ''} · ${contractTypes[c['contract_type']] ?? c['contract_type'] ?? ''}'),
          Text('${formatDate(c['start_date'])} – ${c['end_date'] == null ? 'süresiz' : formatDate(c['end_date'])}'
              '${amount != null ? ' · ${formatTry(toNum(amount))}${c['payment_type'] == 'YEARLY' ? '/yıl' : c['payment_type'] == 'MONTHLY' ? '/ay' : ''}' : ''}'),
          if (days is num && active)
            Text(days < 0 ? 'Süresi ${-days} gün önce doldu' : '$days gün kaldı',
                style: TextStyle(color: c['notice_due'] == true ? Colors.orange : null)),
          if (c['notice_due'] == true)
            const Text('İhbar süresi içinde: yenileme ya da fesih kararı verilmeli',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
          if ((c['termination_reason'] ?? '').toString().isNotEmpty) Text('Fesih gerekçesi: ${c['termination_reason']}'),
          if (_canWrite && (active || c['status'] == 'EXPIRED'))
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => _terminate(c), child: const Text('Feshet')),
              if (c['renewal_period_months'] != null)
                TextButton(onPressed: () => _renew(c), child: const Text('Yenile')),
            ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sözleşmeler'),
          bottom: const TabBar(tabs: [Tab(text: 'Yürürlükte'), Tab(text: '60 günde bitenler'), Tab(text: 'Tümü')]),
        ),
        floatingActionButton: _canWrite
            ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Sözleşme'))
            : null,
        body: TabBarView(children: [
          ApiList(
            token: _token,
            load: () => apiClient.getList('/contracts', query: {'status': 'ACTIVE'}),
            empty: 'Yürürlükte sözleşme yok',
            header: (_) => _Summary(key: ValueKey(_token)),
            itemBuilder: (context, c, _) => _tile(c),
          ),
          ApiList(
            token: _token,
            load: () => apiClient.getList('/contracts', query: {'expiring_days': 60}),
            empty: '60 gün içinde biten sözleşme yok',
            itemBuilder: (context, c, _) => _tile(c),
          ),
          ApiList(
            token: _token,
            load: () => apiClient.getList('/contracts'),
            empty: 'Sözleşme yok',
            itemBuilder: (context, c, _) => _tile(c),
          ),
        ]),
      ),
    );
  }
}

class _Summary extends StatefulWidget {
  const _Summary({super.key});

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  late final Future<Map<String, dynamic>> _f = apiClient.getMap('/contracts-summary');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        final s = snap.data?['summary'];
        if (s is! Map) return const SizedBox.shrink();
        return StatRow([
          ('Yürürlükte', '${s['active'] ?? 0}'),
          ('İhbar süresinde', '${s['notice_due'] ?? 0}'),
          ('30 günde biten', '${s['expiring_in_30_days'] ?? 0}'),
          ('Aylık yük', formatTry(toNum(s['monthly_commitment_try']))),
        ]);
      },
    );
  }
}

class _ContractForm extends StatefulWidget {
  const _ContractForm();

  @override
  State<_ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends State<_ContractForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _party = TextEditingController();
  final _amount = TextEditingController();
  final _renewMonths = TextEditingController();
  final _noticeDays = TextEditingController(text: '30');
  String _type = 'SERVICE';
  String _paymentType = 'MONTHLY';
  DateTime _start = DateTime.now();
  DateTime? _end;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _party, _amount, _renewMonths, _noticeDays]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(DateTime.now().year + 20),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end != null && _end!.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitiş tarihi başlangıçtan önce olamaz')));
      return;
    }
    setState(() => _saving = true);
    final amount = _amount.text.trim().isEmpty ? null : toNum(_amount.text.trim());
    final ok = await runAction(context, () => apiClient.post('/contracts', {
          'contract_type': _type,
          'title': _title.text.trim(),
          'party_name': _party.text.trim(),
          'start_date': apiDate(_start),
          if (_end != null) 'end_date': apiDate(_end!),
          'payment_type': _paymentType,
          if (amount != null && _paymentType == 'MONTHLY') 'monthly_amount': amount,
          if (amount != null && _paymentType == 'YEARLY') 'yearly_amount': amount,
          if (amount != null && _paymentType == 'ONE_TIME') 'total_amount': amount,
          if (_renewMonths.text.trim().isNotEmpty) 'renewal_period_months': int.parse(_renewMonths.text.trim()),
          if (_noticeDays.text.trim().isNotEmpty) 'renewal_notice_days': int.parse(_noticeDays.text.trim()),
        }), success: 'Sözleşme kaydedildi');
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  String? _intOrEmpty(String? v) =>
      (v == null || v.trim().isEmpty || int.tryParse(v.trim()) != null && int.parse(v.trim()) >= 0) ? null : 'Tam sayı girin';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Yeni sözleşme', style: Theme.of(context).textTheme.titleLarge),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tür'),
              items: [for (final e in contractTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Başlık *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
            ),
            TextFormField(
              controller: _party,
              decoration: const InputDecoration(labelText: 'Karşı taraf (firma / kişi) *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Karşı taraf gerekli' : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Başlangıç'),
              subtitle: Text(formatDate(_start)),
              onTap: () async {
                final d = await _pick(_start);
                if (d != null) setState(() => _start = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bitiş'),
              subtitle: Text(_end == null ? 'Süresiz' : formatDate(_end)),
              trailing: _end == null ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _end = null)),
              onTap: () async {
                final d = await _pick(_end ?? _start);
                if (d != null) setState(() => _end = d);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              decoration: const InputDecoration(labelText: 'Ödeme'),
              items: const [
                DropdownMenuItem(value: 'MONTHLY', child: Text('Aylık')),
                DropdownMenuItem(value: 'YEARLY', child: Text('Yıllık')),
                DropdownMenuItem(value: 'ONE_TIME', child: Text('Tek seferlik')),
              ],
              onChanged: (v) => setState(() => _paymentType = v ?? _paymentType),
            ),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tutar (₺)'),
              validator: (v) => (v == null || v.trim().isEmpty || toNum(v.trim()) > 0) ? null : 'Geçerli tutar girin',
            ),
            TextFormField(
              controller: _renewMonths,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yenileme süresi (ay)', helperText: 'Boşsa sözleşme yenilenemez'),
              validator: _intOrEmpty,
            ),
            TextFormField(
              controller: _noticeDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'İhbar süresi (gün)'),
              validator: _intOrEmpty,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Kaydet')),
          ]),
        ),
      ),
    );
  }
}
