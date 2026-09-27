// Anket yönetimi.
//
// DÜZELTME (2026-09-27): ekran var olmayan uçlara (`/surveys/:id/results`)
// gidiyor, "genel kurul oylaması" türü sunuyordu. Sunucu genel kurul kararı
// ÜRETMEZ (KMK m.29-32: çağrı, nisap ve karar defteri governance'tadır);
// anket TASLAK olarak açılır, yayınlanınca sakinlere bildirim gider.
// Sözleşme: `GET /surveys?status=`, `GET /surveys/:id` (sonuçlar yalnızca
// görünürse), `POST /surveys`, `POST /surveys/:id/publish|close|cancel {reason}`.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

const surveyTypes = {'POLL': 'Kısa oylama', 'SURVEY': 'Anket', 'VOTE': 'Karar öncesi oylama'};

(String, Color) surveyStatus(Object? s) {
  switch ('${s ?? ''}') {
    case 'DRAFT':
      return ('Taslak', Colors.blueGrey);
    case 'ACTIVE':
      return ('Oylamada', Colors.green);
    case 'ENDED':
      return ('Sona erdi', Colors.indigo);
    case 'CANCELLED':
      return ('İptal edildi', Colors.red);
    default:
      return ('${s ?? '—'}', Colors.blueGrey);
  }
}

class SurveyManagementScreen extends StatefulWidget {
  const SurveyManagementScreen({super.key});

  @override
  State<SurveyManagementScreen> createState() => _SurveyManagementScreenState();
}

class _SurveyManagementScreenState extends State<SurveyManagementScreen> {
  bool _canWrite = false;
  int _token = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _create() async {
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const _SurveyForm());
    if (saved == true) setState(() => _token++);
  }

  Future<void> _open(Map<String, dynamic> s) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: _SurveyDetail(id: '${s['id']}', canWrite: _canWrite),
      ),
    );
    if (mounted) setState(() => _token++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anketler')),
      floatingActionButton: _canWrite
          ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Anket'))
          : null,
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            for (final e in const {'': 'Tümü', 'DRAFT': 'Taslak', 'ACTIVE': 'Oylamada', 'ENDED': 'Sona eren', 'CANCELLED': 'İptal'}.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key)),
              ),
          ]),
        ),
        Expanded(
          child: ApiList(
            token: '$_status$_token',
            load: () => apiClient.getList('/surveys', query: {'status': _status}),
            empty: 'Anket yok',
            itemBuilder: (context, s, _) {
              final (label, color) = surveyStatus(s['status']);
              return ListTile(
                onTap: () => _open(s),
                title: Text('${s['title'] ?? ''}'),
                subtitle: Text('${surveyTypes[s['survey_type']] ?? s['survey_type'] ?? ''} · '
                    '${s['total_votes'] ?? 0}/${s['eligible_voters'] ?? 0} oy (%${formatNumber(toNum(s['participation_rate']))})'
                    '${s['ends_at'] != null ? ' · bitiş ${formatDate(s['ends_at'])}' : ''}'),
                trailing: StatusChip(label, color: color),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _SurveyDetail extends StatelessWidget {
  final String id;
  final bool canWrite;
  const _SurveyDetail({required this.id, required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return ApiObject(
      load: () => apiClient.getMap('/surveys/$id'),
      builder: (context, res, reload) {
        final s = res['survey'] is Map ? Map<String, dynamic>.from(res['survey'] as Map) : <String, dynamic>{};
        final options = s['options'] is List ? (s['options'] as List).whereType<Map>().toList() : const <Map>[];
        final status = s['status'];
        final (label, color) = surveyStatus(status);

        Future<void> act(String action, [Map<String, dynamic>? body]) async {
          if (await runAction(context, () => apiClient.post('/surveys/$id/$action', body))) await reload();
        }

        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: Text('${s['title'] ?? ''}', style: Theme.of(context).textTheme.titleLarge)),
            StatusChip(label, color: color),
          ]),
          if ((s['description'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${s['description']}')),
          const SizedBox(height: 8),
          StatRow([
            ('Oy', '${s['total_votes'] ?? 0}'),
            ('Oy hakkı olan', '${s['eligible_voters'] ?? 0}'),
            ('Katılım', '%${formatNumber(toNum(s['participation_rate']))}'),
          ]),
          Text([
            if (s['is_anonymous'] == true) 'Anonim',
            if (s['is_weighted'] == true) 'Arsa payı ağırlıklı',
            'Başlangıç: ${formatDateTime(s['starts_at'])}',
            if (s['ends_at'] != null) 'Bitiş: ${formatDateTime(s['ends_at'])}',
          ].join(' · ')),
          const Divider(height: 24),
          for (final o in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${o['option_text'] ?? ''}'),
              subtitle: o['percentage'] == null
                  ? null
                  : LinearProgressIndicator(value: (toNum(o['percentage']) / 100).clamp(0, 1).toDouble()),
              trailing: o['vote_count'] == null
                  ? null
                  // `percentage`: ağırlıklıysa arsa payı, değilse oy sayısı üzerinden.
                  : Text('${o['vote_count']} oy'
                      '${o['percentage'] != null ? ' · %${formatNumber(toNum(o['percentage']))}' : ''}'),
            ),
          for (final key in const ['results_note', 'anonymity_note', 'legal_notice'])
            if (res[key] is String) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${res[key]}', style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 16),
          if (canWrite)
            Wrap(spacing: 8, alignment: WrapAlignment.end, children: [
              if (status == 'DRAFT' || status == 'ACTIVE')
                OutlinedButton(
                  onPressed: () async {
                    final reason = await askText(context, 'Anketi iptal et', 'İptal gerekçesi');
                    if (reason != null) await act('cancel', {'reason': reason});
                  },
                  child: const Text('İptal et'),
                ),
              if (status == 'ACTIVE')
                FilledButton(
                  onPressed: () async {
                    if (await confirm(context, 'Oylamayı bitir', 'Oylama şimdi kapanır; sonuçlar kesinleşir.', ok: 'Bitir')) await act('close');
                  },
                  child: const Text('Oylamayı bitir'),
                ),
              if (status == 'DRAFT')
                FilledButton(
                  onPressed: () async {
                    if (await confirm(context, 'Yayınla', 'Anket oylamaya açılır ve sakinlere bildirim oluşturulur.', ok: 'Yayınla')) await act('publish');
                  },
                  child: const Text('Yayınla'),
                ),
            ]),
        ]);
      },
    );
  }
}

class _SurveyForm extends StatefulWidget {
  const _SurveyForm();

  @override
  State<_SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<_SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];
  String _type = 'SURVEY';
  bool _anonymous = true;
  bool _weighted = false;
  bool _showResults = false;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _desc, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runAction(context, () => apiClient.post('/surveys', {
          'title': _title.text.trim(),
          if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
          'survey_type': _type,
          'options': [for (final o in _options) o.text.trim()],
          'is_anonymous': _anonymous,
          'is_weighted': _weighted,
          'show_results_before_end': _showResults,
          // Bitiş: seçilen günün sonu, site saatiyle (+03:00).
          if (_endDate != null) 'ends_at': '${apiDate(_endDate!)}T23:59:00+03:00',
        }));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Yeni anket (taslak)', style: Theme.of(context).textTheme.titleLarge),
            const Text('Genel kurul kararı buradan alınamaz; Yönetişim bölümünü kullanın.'),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tür'),
              items: [for (final e in surveyTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Başlık *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
            ),
            TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3, minLines: 1),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++)
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _options[i],
                    decoration: InputDecoration(labelText: 'Seçenek ${i + 1} *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Seçenek boş olamaz' : null,
                  ),
                ),
                if (_options.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() => _options.removeAt(i).dispose()),
                  ),
              ]),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _options.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Seçenek ekle'),
              ),
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Anonim'), value: _anonymous, onChanged: (v) => setState(() => _anonymous = v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Arsa payına göre ağırlıklı'),
              subtitle: const Text('KMK m.20: ölçü arsa payıdır, metrekare değil'),
              value: _weighted,
              onChanged: (v) => setState(() => _weighted = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonuçlar oylama sürerken görünsün'),
              value: _showResults,
              onChanged: (v) => setState(() => _showResults = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bitiş tarihi'),
              subtitle: Text(_endDate == null ? 'Elle bitirilene kadar' : formatDate(_endDate)),
              trailing: _endDate == null ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _endDate = null)),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: _endDate ?? now.add(const Duration(days: 7)), firstDate: now, lastDate: DateTime(now.year + 2));
                if (d != null) setState(() => _endDate = d);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Taslak olarak kaydet')),
          ]),
        ),
      ),
    );
  }
}
