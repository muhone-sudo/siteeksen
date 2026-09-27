// Ekranların ortak veri bileşenleri (2026-09-26).
//
// NEDEN VAR: yönetici uygulamasının ekranlarının çoğu hatayı yutup boş liste
// ya da uydurma sayı gösteriyordu; her ekran yükleme/hata/boş durumunu ayrı ve
// eksik yazıyordu. Bu dosya o davranışı TEK yerde tanımlar: yükleniyor, hata
// (nedeniyle ve yeniden deneme), gerçekten boş, liste; işlemlerde sunucunun
// mesajı ve notu olduğu gibi gösterilir.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import 'data_state.dart';

/// Sunucunun hata metnini (varsa) ya da genel Türkçe mesajı döner.
String errorText(Object e) {
  if (e is StateError) return e.message;
  if (e is DioException) {
    final data = e.response?.data;
    final code = e.response?.statusCode;
    if (data is Map && data['error'] is String && code != null && code >= 400 && code < 500 && code != 401) {
      final note = data['note'] is String ? ' — ${data['note']}' : '';
      return '${data['error']}$note';
    }
  }
  return toUserMessage(e);
}

/// Bir işlemi çalıştırır; başarıda sunucunun `message`/`note` metnini, hatada
/// nedenini gösterir. Dönüş: başarılı mı.
Future<bool> runAction(
  BuildContext context,
  Future<Map<String, dynamic>> Function() fn, {
  String? success,
}) async {
  try {
    final res = await fn();
    if (!context.mounted) return true;
    final parts = [success ?? res['message'], res['note'], res['warning']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(parts.isEmpty ? 'İşlem tamamlandı' : parts.join('\n'))));
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText(e)), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
    return false;
  }
}

/// Tek satırlık metin sorar (ör. red gerekçesi). İptalde null.
Future<String?> askText(BuildContext context, String title, String label, {bool required = true, String? initial}) async {
  final c = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  final res = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: c,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v == null || v.trim().isEmpty) ? '$label gerekli' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, c.text.trim());
          },
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
  c.dispose();
  return res;
}

/// Evet/hayır onayı.
Future<bool> confirm(BuildContext context, String title, String message, {String ok = 'Onayla'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Sunucudan liste yükleyen, yenilenebilir liste. Hata ASLA boş liste olarak
/// gösterilmez.
class ApiList extends StatefulWidget {
  final Future<List<dynamic>> Function() load;
  final Widget Function(BuildContext context, Map<String, dynamic> item, Future<void> Function() reload) itemBuilder;
  final String empty;
  final IconData emptyIcon;
  final bool Function(Map<String, dynamic> item)? filter;

  /// Listenin üstüne konacak özet (yüklenen ham liste verilir).
  final Widget Function(List<Map<String, dynamic>> items)? header;

  /// Değişince liste yeniden yüklenir (süzgeç, tarih seçimi vb.).
  final Object? token;

  const ApiList({
    this.token,
    super.key,
    required this.load,
    required this.itemBuilder,
    this.empty = 'Kayıt yok',
    this.emptyIcon = Icons.inbox_rounded,
    this.filter,
    this.header,
  });

  @override
  State<ApiList> createState() => ApiListState();
}

class ApiListState extends State<ApiList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(covariant ApiList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _future = widget.load();
  }

  Future<void> reload() async {
    setState(() => _future = widget.load());
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          if (isNotImplemented(snap.error!)) {
            return ListView(children: [NotImplementedNotice(detail: errorText(snap.error!))]);
          }
          return ErrorStateView(message: errorText(snap.error!), onRetry: reload);
        }
        final all = snap.data!.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        final items = widget.filter == null ? all : all.where(widget.filter!).toList();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(children: [
                  if (widget.header != null) widget.header!(all),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyStateView(message: widget.empty, icon: widget.emptyIcon),
                    ),
                ]);
              }
              return widget.itemBuilder(context, items[i - 1], reload);
            },
          ),
        );
      },
    );
  }
}

/// Sunucudan tek nesne yükleyen görünüm.
class ApiObject extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() load;
  final Widget Function(BuildContext context, Map<String, dynamic> data, Future<void> Function() reload) builder;
  const ApiObject({super.key, required this.load, required this.builder});

  @override
  State<ApiObject> createState() => _ApiObjectState();
}

class _ApiObjectState extends State<ApiObject> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    setState(() => _future = widget.load());
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          if (isNotImplemented(snap.error!)) {
            return ListView(children: [NotImplementedNotice(detail: errorText(snap.error!))]);
          }
          return ErrorStateView(message: errorText(snap.error!), onRetry: _reload);
        }
        return RefreshIndicator(onRefresh: _reload, child: widget.builder(context, snap.data!, _reload));
      },
    );
  }
}

/// Küçük durum etiketi.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, {super.key, this.color = Colors.blueGrey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Özet kutuları satırı.
class StatRow extends StatelessWidget {
  final List<(String, String)> items;
  const StatRow(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, value) in items)
            Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Oturumdaki kullanıcının jeton rolleri arasında verilenlerden biri var mı?
Future<bool> hasAnyRole(List<String> roles) async {
  final mine = await apiClient.getCurrentUserRoles();
  return mine.any(roles.contains);
}

/// Yazma yetkisi olan yönetim rolleri (sunucudaki RequireRole(M,B) ile aynı).
const writeRoles = ['MANAGER', 'BOARD_MEMBER'];
