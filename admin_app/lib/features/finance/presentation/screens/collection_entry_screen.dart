// Tahsilat girişi (migration 061, beşinci tur B2).
//
// Sakin uygulamadan bildirim yapmadan havale gönderdiğinde ya da yönetime elden
// ödediğinde yönetici tahsilatı buradan girer: `POST /finance/collections`.
// Ödeme aynı anda onaylanır, borç düşer ve tahsilat defterine yazılır; kayıt
// silinemez (düzeltme gerekçeli ters kayıtla yapılır).
// [bankLine] verilirse (FAZ H.7) eşleşmeyen banka ekstresi satırı seçilen borçlara işlenir:
// `POST /finance/bank-statements/lines/:id/collect`; tarih ve tutar ekstreden gelir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

class CollectionEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? bankLine;
  const CollectionEntryScreen({super.key, this.bankLine});

  @override
  State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _open = [];
  String? _unitId;
  final Set<String> _selected = {};
  String _method = 'BANK_TRANSFER';
  DateTime _day = DateTime.now();
  final _reference = TextEditingController();
  String? _error;
  bool _loadingOpen = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    apiClient.getUnits().then((list) {
      if (!mounted) return;
      setState(() => _units = list.whereType<Map<String, dynamic>>().toList());
    }).catchError((Object e) {
      if (mounted) setState(() => _error = errorText(e));
    });
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _loadOpen(String unitId) async {
    setState(() {
      _unitId = unitId;
      _selected.clear();
      _open = [];
      _loadingOpen = true;
      _error = null;
    });
    try {
      final list = await apiClient.getList('/finance/units/$unitId/open-assessments');
      if (mounted) setState(() => _open = list.whereType<Map<String, dynamic>>().toList());
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loadingOpen = false);
    }
  }

  num get _selectedKurus =>
      _open.where((a) => _selected.contains('${a['id']}')).fold<num>(0, (s, a) => s + toNum(a['outstanding_kurus']));

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(now.year - 3), lastDate: now);
    if (d != null && mounted) setState(() => _day = d);
  }

  Future<void> _save() async {
    if (_unitId == null || _selected.isEmpty) return;
    setState(() => _saving = true);
    final line = widget.bankLine;
    final ok = await runAction(
        context,
        () => line != null
            ? apiClient.post('/finance/bank-statements/lines/${line['id']}/collect', {'unit_id': _unitId, 'assessment_ids': _selected.toList()})
            : apiClient.post('/finance/collections', {
                'unit_id': _unitId,
                'assessment_ids': _selected.toList(),
                'payment_method': _method,
                'value_date': apiDate(_day),
                'reference': _reference.text.trim(),
              }));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bankLine == null ? 'Tahsilat gir' : 'Ekstre satırını daireye işle')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.bankLine == null
            ? 'Sakinin bildirim yapmadığı havale/EFT ya da elden ödeme içindir. Kayıt silinemez; hata gerekçeli ters kayıtla düzeltilir.'
            : 'Hareket: ${formatDate(widget.bankLine!['date'])} · ${formatTry(toNum(widget.bankLine!['amount_kurus']) / 100)} · ${widget.bankLine!['description'] ?? ''}. '
                'Tarih ve tutar ekstreden alınır.'),
        const SizedBox(height: 12),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        DropdownButtonFormField<String>(
          initialValue: _unitId,
          decoration: const InputDecoration(labelText: 'Daire', border: OutlineInputBorder()),
          items: [
            for (final u in _units)
              DropdownMenuItem(value: '${u['id']}', child: Text('${u['block'] ?? ''}-${u['door_number'] ?? ''}')),
          ],
          onChanged: (v) {
            if (v != null) _loadOpen(v);
          },
        ),
        const SizedBox(height: 12),
        if (_loadingOpen) const Center(child: CircularProgressIndicator()),
        if (_unitId != null && !_loadingOpen && _open.isEmpty) const Text('Bu dairenin kalan borcu yok.'),
        for (final a in _open)
          CheckboxListTile(
            value: _selected.contains('${a['id']}'),
            onChanged: (v) => setState(() => v == true ? _selected.add('${a['id']}') : _selected.remove('${a['id']}')),
            title: Text('${a['period'] ?? ''} · vade ${formatDate(a['due_date'])}'),
            secondary: Text(formatTry(toNum(a['outstanding_kurus']) / 100)),
          ),
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Seçilen toplam: ${formatTry(_selectedKurus / 100)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        if (widget.bankLine == null) ...[
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'BANK_TRANSFER', label: Text('Havale/EFT')),
            ButtonSegment(value: 'CASH', label: Text('Elden (nakit)')),
          ],
          selected: {_method},
          onSelectionChanged: (s) => setState(() => _method = s.first),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ödeme günü'),
          subtitle: Text(formatDate(apiDate(_day))),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDay,
        ),
        TextField(
          controller: _reference,
          maxLength: 140,
          decoration: const InputDecoration(labelText: 'Açıklama / makbuz no', border: OutlineInputBorder()),
        ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving || _unitId == null || _selected.isEmpty ? null : _save,
          child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet ve borçtan düş'),
        ),
      ]),
    );
  }
}
