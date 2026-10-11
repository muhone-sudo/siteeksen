// Dairemin sakinleri (beşinci tur B5; altıncı tur D3).
//
// Malik ya da kiracı dairenin sakinlerini görür (telefon maskeli) ve DAVET gönderir: malik kiracı, vekil ya da
// (dairede oturuyorsa) hane üyesi; kiracı hane üyesi. Kişiye SMS + e-posta gider; etkinleştirme kodu davet edene
// gösterilmez. Dairede aktif kiracı varken kiracı daveti gönderilemez; kiracılık malikin tek taraflı işlemiyle
// bitmez (sunucu kuralları; yanıt metni gösterilir).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';
import 'tenancy_requests_screen.dart';

const _roleLabels = {'OWNER': 'Kat maliki', 'TENANT': 'Kiracı', 'PROXY': 'Vekil', 'HOUSEHOLD': 'Hane üyesi'};

String _err(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return toUserMessage(e);
}

/// Davetin kişiye iletim sonucu (SMS / e-posta). Hiçbir kanal ulaşmadıysa açıkça söylenir.
String _deliveryText(Object? d) {
  if (d is! Map) return '';
  String one(String label, Object? x) {
    if (x is! Map) return '';
    final status = '${x['status']}';
    return '$label: ${status == 'SENT' ? 'gönderildi' : status == 'NOT_CONFIGURED' ? 'yapılandırılmamış' : 'gönderilemedi'}';
  }
  final lines = [one('SMS', d['sms']), one('E-posta', d['email'])].where((s) => s.isNotEmpty).toList();
  final reached = [d['sms'], d['email']].any((x) => x is Map && x['status'] == 'SENT');
  if (!reached) lines.add('Davet kişiye ulaştırılamadı; kişinin hesabı varsa uygulamasında görür, yoksa site yönetiminden kod istemesi gerekir.');
  return lines.join('\n');
}
class UnitResidentsScreen extends StatefulWidget {
  final String unitId;
  final String unitName;

  /// Kişinin bu dairedeki sıfatı: OWNER ya da TENANT (kiracılık bitişi düğmeleri buna göre).
  final String role;
  const UnitResidentsScreen({super.key, required this.unitId, required this.unitName, this.role = 'OWNER'});

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
        title: const Text('Kaydı bitir'),
        content: Text('${r['first_name']} ${r['last_name']} bu daireden çıkarılsın mı? '
            'Kişi bu daire için bildirim almaz; geçmiş kayıtlar silinmez.'),
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

  /// Malik: kiracılığın bitmesini ister (kiracı onaylamadan bitmez). Kiracı: kendi çıkışını bildirir.
  Future<void> _tenancyAction() async {
    final owner = widget.role == 'OWNER';
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(owner ? 'Kiracılığın bitmesini iste' : 'Çıkışımı bildir'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(owner
              ? 'İstek kiracıya iletilir. Kiracı onaylarsa kiracılık biter; reddederse sürer.'
              : 'Kiracılığınız bugün itibarıyla sona erer; malike bilgi verilir. Bu daire için bildirim almazsınız.'),
          TextField(controller: ctrl, maxLines: 2, decoration: InputDecoration(labelText: owner ? 'Gerekçe (en az 5 karakter)' : 'Not (isteğe bağlı)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              if (owner && ctrl.text.trim().length < 5) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: Text(owner ? 'İste' : 'Bildir'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null || !mounted) return;
    try {
      final res = owner ? await apiClient.requestTenancyEnd(widget.unitId, reason) : await apiClient.tenancyExit(widget.unitId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? 'İşlem tamamlandı.'}')));
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
          title: const Text('Davet gönder'),
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
                    DropdownMenuItem(value: 'HOUSEHOLD', child: Text('Hane üyesi')),
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
                        final res = await apiClient.inviteToUnit(widget.unitId, {
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
              child: const Text('Gönder'),
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
    final text = '${result['note'] ?? 'Davet gönderildi.'}\n\n${_deliveryText(result['delivery'])}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Davet gönderildi'),
        content: SelectableText(text),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.unitName} sakinleri'), actions: [
        IconButton(
          tooltip: 'Kiracılık işlemleri',
          icon: const Icon(Icons.assignment_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TenancyRequestsScreen())),
        ),
        // Dairede aktif kiracı yoksa sunucu açıkça söyler (409); malik devirden sonra kiracıyı göremeyebilir (D6).
        if (widget.role == 'OWNER' || widget.role == 'TENANT')
          PopupMenuButton<String>(
            onSelected: (_) => _tenancyAction(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'end', child: Text(widget.role == 'OWNER' ? 'Kiracılığın bitmesini iste' : 'Çıkışımı bildir')),
            ],
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Davet gönder'),
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
                            trailing: r['is_active'] == true && r['is_self'] != true && (r['role'] == 'PROXY' || r['role'] == 'HOUSEHOLD')
                                ? TextButton(onPressed: () => _end(r), child: const Text('Bitir'))
                                : null,
                          ),
                      ]),
                    ),
    );
  }
}
