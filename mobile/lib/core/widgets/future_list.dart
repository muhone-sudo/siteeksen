// Sunucudan liste yükleyen, aşağı çekince yenilenen liste. Hata ASLA boş liste olarak gösterilmez.

import 'package:flutter/material.dart';

import 'data_state.dart';

class FutureList extends StatefulWidget {
  final Future<List<dynamic>> Function() load;
  final Widget Function(BuildContext context, Map<String, dynamic> item, Future<void> Function() reload) itemBuilder;
  final String empty;
  final IconData emptyIcon;
  final Widget? header;

  const FutureList({
    super.key,
    required this.load,
    required this.itemBuilder,
    this.empty = 'Kayıt yok',
    this.emptyIcon = Icons.inbox_rounded,
    this.header,
  });

  @override
  State<FutureList> createState() => FutureListState();
}

class FutureListState extends State<FutureList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> reload() async {
    setState(() { _future = widget.load(); });
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
        if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: reload);
        final items = snap.data!.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(children: [
                  if (widget.header != null) widget.header!,
                  if (items.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: 48), child: EmptyStateView(message: widget.empty, icon: widget.emptyIcon)),
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

/// İşlemi çalıştırır; başarıda [success], hatada nedeni gösterir.
Future<bool> runSnack(BuildContext context, Future<void> Function() fn, String success) async {
  try {
    await fn();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e)), backgroundColor: Theme.of(context).colorScheme.error));
    }
    return false;
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String ok = 'Onayla'}) async {
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

Future<String?> askTextDialog(BuildContext context, String title, String label, {bool required = true}) async {
  final c = TextEditingController();
  final key = GlobalKey<FormState>();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: c,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v ?? '').trim().isEmpty ? '$label gerekli' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => key.currentState!.validate() ? Navigator.pop(ctx, c.text.trim()) : null, child: const Text('Tamam')),
      ],
    ),
  );
  c.dispose();
  return r;
}
