// Dairemin sakinleri — malikin kendi bölümündeki kiracı/vekil yönetimi (beşinci tur B5).
//
// Önceden kiracıyı yalnızca site yönetimi ekleyip çıkarabiliyordu. Bölümün aktif maliki
// burada sakinleri görür (telefon maskeli), kiracı/vekil ekler ve kiracılığı bitirir.
// Malik değişikliği yönetimce işlenir (sunucu da reddeder).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

const _roleLabels = {'OWNER': 'Kat maliki', 'TENANT': 'Kiracı', 'PROXY': 'Vekil'};

String _err(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return toUserMessage(e);
}

class UnitResidentsScreen extends StatefulWidget {
  final String unitId;
  final String unitName;
  const UnitResidentsScreen({super.key, required this.unitId, required this.unitName});

  @override
  State<UnitResidentsScreen> createState() => _UnitResidentsScreenState();
}

class _UnitResidentsScreenState extends State<UnitResidentsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await apiClient.getUnitResidents(widget.unitId);
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _err(e);
        _loading = false;
      });
    }
  }

  Future<void> _end(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sakinliği bitir'),
        content: Text('${r['first_name']} ${r['last_name']} bu bölümden çıkarılsın mı? '
            'Kişi bu bölüm için bildirim almaz ve yeni borçlar ona yansımaz; geçmiş kayıtlar silinmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bitir')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await apiClient.endUnitResident(widget.unitId, '${r['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'Sakinlik bitirildi.'}')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<void> _add() async {
    final formKey = GlobalKey<FormState>();
    final first = TextEditingController();
    final last = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    String role = 'TENANT';
    String? error;
    bool busy = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Kiracı / vekil ekle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Sıfat'),
                  items: const [
                    DropdownMenuItem(value: 'TENANT', child: Text('Kiracı')),
                    DropdownMenuItem(value: 'PROXY', child: Text('Vekil')),
                  ],
                  onChanged: (v) => role = v ?? 'TENANT',
                ),
                TextFormField(controller: first, decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null),
                TextFormField(controller: last, decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Soyad gerekli' : null),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon', hintText: '0555 123 45 67 · yurt dışı: +49 …'),
                  validator: (v) => v == null || !isValidPhone(v) ? 'Geçerli bir numara girin' : null,
                ),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta (isteğe bağlı)')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        final res = await apiClient.addUnitResident(widget.unitId, {
                          'first_name': first.text.trim(),
                          'last_name': last.text.trim(),
                          'phone': normalizePhone(phone.text),
                          'email': email.text.trim(),
                          'role': role,
                        });
                        if (ctx.mounted) Navigator.pop(ctx, res);
                      } catch (e) {
                        setState(() {
                          busy = false;
                          error = _err(e);
                        });
                      }
                    },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    last.dispose();
    phone.dispose();
    email.dispose();
    if (result == null || !mounted) return;
    final act = result['activation'];
    final inv = result['invitation'];
    final text = act is Map
        ? 'Etkinleştirme kodu: ${act['activation_code']}\n\nBu kod yalnızca bir kez gösterilir. '
            '${act['sms'] is Map && act['sms']['status'] == 'SENT' ? 'Kod kişinin telefonuna SMS ile de gönderildi.' : 'Kodu kişiye siz iletin.'}'
        : inv != null
            ? '${result['note'] ?? 'Kişiye davet gönderildi; kendi uygulamasından kabul edince bölüme bağlanır.'}'
            : '${result['note'] ?? 'Kişi bölüme eklendi.'}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eklendi'),
        content: SelectableText(text),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.unitName} sakinleri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Kiracı / vekil ekle'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyStateView(message: 'Bu bölümde kayıtlı sakin yok')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
                        for (final r in _items)
                          ListTile(
                            leading: Icon(r['is_active'] == true ? Icons.person : Icons.person_off,
                                color: r['is_active'] == true ? null : Colors.grey),
                            title: Text('${r['first_name']} ${r['last_name']}${r['is_self'] == true ? ' (siz)' : ''}'),
                            subtitle: Text([
                              _roleLabels['${r['role']}'] ?? '${r['role']}',
                              '${r['phone_masked'] ?? ''}',
                              if (r['is_active'] != true) 'Ayrıldı${r['end_date'] != null ? ' · ${formatDate(r['end_date'])}' : ''}',
                            ].where((s) => s.isNotEmpty).join(' · ')),
                            trailing: r['is_active'] == true && r['is_self'] != true && r['role'] != 'OWNER'
                                ? TextButton(onPressed: () => _end(r), child: const Text('Bitir'))
                                : null,
                          ),
                      ]),
                    ),
    );
  }
}
