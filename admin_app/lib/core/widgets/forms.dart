// Panelle eşitlik için ortak form, dosya ve satır eylemi altyapısı (FAZ H.7).
//
// Her ekran formu alan tanımıyla verir; değerler sunucunun beklediği biçimde
// döner: tarih YYYY-MM-DD, tarih-saat RFC3339 (UTC), sayı num, boş isteğe
// bağlı alan hiç gönderilmez. Dosya alanı (baytlar, dosya adı) döner.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../utils/formatters.dart';
import '../utils/file_opener.dart';
import 'api_views.dart';

enum FType {
  text,
  password,
  multiline,
  integer,
  decimal,
  date,
  dateTime,
  time,
  select,
  multi,
  toggle,
  file
}

class FSpec {
  final String key;
  final String label;
  final FType type;
  final bool required;
  final List<(String, String)> options;
  final Object? initial;
  final String? hint;
  final List<String> extensions;
  final bool Function(Map<String, dynamic> values)? visible;

  const FSpec(this.key, this.label,
      {this.type = FType.text,
      this.required = false,
      this.options = const [],
      this.initial,
      this.hint,
      this.extensions = const [],
      this.visible});
}

/// Alt sayfada form açar; iptalde null, onayda sunucuya gidecek değerler.
Future<Map<String, dynamic>?> showForm(
    BuildContext context, String title, List<FSpec> fields,
    {String submit = 'Kaydet', String? note}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _FormSheet(title: title, fields: fields, submit: submit, note: note),
  );
}

class _FormSheet extends StatefulWidget {
  final String title;
  final List<FSpec> fields;
  final String submit;
  final String? note;
  const _FormSheet(
      {required this.title,
      required this.fields,
      required this.submit,
      this.note});

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _key = GlobalKey<FormState>();
  final Map<String, dynamic> _v = {};
  final Map<String, TextEditingController> _c = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      switch (f.type) {
        case FType.text || FType.password || FType.multiline || FType.integer || FType.decimal:
          _c[f.key] = TextEditingController(
              text: f.initial == null ? '' : '${f.initial}');
        case FType.toggle:
          _v[f.key] = f.initial == true;
        case FType.multi:
          _v[f.key] = <String>{
            ...((f.initial as Iterable?) ?? const []).map((e) => '$e')
          };
        default:
          if (f.initial != null) _v[f.key] = f.initial;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _current() =>
      {..._v, for (final e in _c.entries) e.key: e.value.text};

  Future<void> _pickDate(FSpec f) async {
    final now = DateTime.now();
    final init = _v[f.key] is DateTime ? _v[f.key] as DateTime : now;
    final d = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 10));
    if (d == null || !mounted) return;
    if (f.type == FType.date) {
      setState(() => _v[f.key] = d);
      return;
    }
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (t == null) return;
    setState(
        () => _v[f.key] = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickFile(FSpec f) async {
    final r = await FilePicker.pickFiles(
      type: f.extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: f.extensions.isEmpty ? null : f.extensions,
      withData: true,
    );
    final file = r?.files.single;
    if (file?.bytes == null) return;
    setState(() => _v[f.key] = (file!.bytes!.toList(), file.name));
  }

  Widget _field(FSpec f) {
    final label = f.required ? '${f.label} *' : f.label;
    String? need(Object? v) =>
        f.required && (v == null || (v is String && v.trim().isEmpty))
            ? '${f.label} gerekli'
            : null;
    switch (f.type) {
      case FType.text || FType.password || FType.multiline:
        return TextFormField(
          controller: _c[f.key],
          maxLines: f.type == FType.multiline ? 4 : 1,
          obscureText: f.type == FType.password,
          minLines: 1,
          decoration: InputDecoration(labelText: label, hintText: f.hint),
          validator: need,
        );
      case FType.integer || FType.decimal:
        return TextFormField(
          controller: _c[f.key],
          keyboardType:
              TextInputType.numberWithOptions(decimal: f.type == FType.decimal),
          decoration: InputDecoration(labelText: label, hintText: f.hint),
          validator: (v) {
            final e = need(v);
            if (e != null || (v ?? '').trim().isEmpty) return e;
            final t = v!.trim().replaceAll(',', '.');
            return (f.type == FType.integer
                        ? int.tryParse(t)
                        : num.tryParse(t)) ==
                    null
                ? 'Geçerli bir sayı girin'
                : null;
          },
        );
      case FType.select:
        return DropdownButtonFormField<String>(
          initialValue: _v[f.key] as String?,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final (v, l) in f.options)
              DropdownMenuItem(
                  value: v, child: Text(l, overflow: TextOverflow.ellipsis))
          ],
          onChanged: (v) => setState(() => _v[f.key] = v),
          validator: need,
        );
      case FType.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          subtitle: f.hint == null ? null : Text(f.hint!),
          value: _v[f.key] == true,
          onChanged: (v) => setState(() => _v[f.key] = v),
        );
      case FType.time:
        final t = _v[f.key] as String?;
        return FormField<String>(
          validator: (_) => need(_v[f.key]),
          builder: (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(t ?? (f.hint ?? 'Seçilmedi'),
                style: s.hasError
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final p = t?.split(':');
              final r = await showTimePicker(
                  context: context,
                  initialTime: p == null
                      ? TimeOfDay.now()
                      : TimeOfDay(
                          hour: int.parse(p[0]), minute: int.parse(p[1])));
              if (r != null) {
                setState(() => _v[f.key] =
                    '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}');
              }
            },
          ),
        );
      case FType.multi:
        final sel = _v[f.key] as Set<String>;
        return InputDecorator(
          decoration:
              InputDecoration(labelText: label, border: InputBorder.none),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (v, l) in f.options)
              FilterChip(
                label: Text(l),
                selected: sel.contains(v),
                onSelected: (on) =>
                    setState(() => on ? sel.add(v) : sel.remove(v)),
              ),
          ]),
        );
      case FType.date || FType.dateTime:
        final d = _v[f.key] as DateTime?;
        return FormField<DateTime>(
          validator: (_) => need(_v[f.key]),
          builder: (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(
                d == null
                    ? (f.hint ?? 'Seçilmedi')
                    : (f.type == FType.date
                        ? formatDate(apiDate(d))
                        : formatDateTime(d.toUtc().toIso8601String())),
                style: s.hasError
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(f),
          ),
        );
      case FType.file:
        final picked = _v[f.key] as (List<int>, String)?;
        return FormField<Object>(
          validator: (_) => need(_v[f.key]),
          builder: (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(picked?.$2 ?? (f.hint ?? 'Dosya seçilmedi'),
                style: s.hasError
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null),
            trailing: const Icon(Icons.attach_file),
            onTap: () => _pickFile(f),
          ),
        );
    }
  }

  Map<String, dynamic> _out() {
    final out = <String, dynamic>{};
    final cur = _current();
    for (final f in widget.fields) {
      if (f.visible != null && !f.visible!(cur)) continue;
      final v = cur[f.key];
      switch (f.type) {
        case FType.text || FType.password || FType.multiline:
          final t = (v as String).trim();
          if (t.isNotEmpty) out[f.key] = t;
        case FType.integer:
          final t = (v as String).trim();
          if (t.isNotEmpty) out[f.key] = int.parse(t);
        case FType.decimal:
          final t = (v as String).trim().replaceAll(',', '.');
          if (t.isNotEmpty) out[f.key] = num.parse(t);
        case FType.date:
          if (v is DateTime) out[f.key] = apiDate(v);
        case FType.dateTime:
          if (v is DateTime) out[f.key] = v.toUtc().toIso8601String();
        case FType.toggle:
          out[f.key] = v == true;
        case FType.select || FType.file || FType.time:
          if (v != null) out[f.key] = v;
        case FType.multi:
          out[f.key] = (v as Set<String>).toList();
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge),
                if (widget.note != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(widget.note!,
                          style: Theme.of(context).textTheme.bodySmall)),
                for (final f in widget.fields)
                  if (f.visible == null || f.visible!(cur))
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _field(f)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (_key.currentState!.validate()) {
                      Navigator.pop(context, _out());
                    }
                  },
                  child: Text(widget.submit),
                ),
              ]),
        ),
      ),
    );
  }
}

/// Formu açar, değerleri [send]'e verir; başarıda true.
Future<bool> formAction(BuildContext context, String title, List<FSpec> fields,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> v) send,
    {String submit = 'Kaydet', String? note, String? success}) async {
  final v = await showForm(context, title, fields, submit: submit, note: note);
  if (v == null || !context.mounted) return false;
  return runAction(context, () => send(v), success: success);
}

/// Onay sorar, sonra çalıştırır.
Future<bool> confirmAction(BuildContext context, String title, String message,
    Future<Map<String, dynamic>> Function() send,
    {String ok = 'Onayla', String? success}) async {
  if (!await confirm(context, title, message, ok: ok) || !context.mounted) {
    return false;
  }
  return runAction(context, send, success: success);
}

/// Gerekçe sorar, sonra çalıştırır.
Future<bool> reasonAction(BuildContext context, String title,
    Future<Map<String, dynamic>> Function(String reason) send,
    {String label = 'Gerekçe', String? success}) async {
  final r = await askText(context, title, label);
  if (r == null || !context.mounted) return false;
  return runAction(context, () => send(r), success: success);
}

/// Dosyayı indirir ve cihazdaki görüntüleyiciyle açar.
Future<void> openDownload(
    BuildContext context, String path, String fallback) async {
  await runAction(context, () async {
    final (bytes, name) = await apiClient.downloadBytes(path, fallback);
    final err = await openBytes(bytes, name);
    if (err != null) throw StateError(err);
    return <String, dynamic>{};
  }, success: 'Dosya açıldı');
}

/// Satır eylemleri menüsü: (etiket, işlem). Boşsa hiçbir şey çizilmez.
class RowMenu extends StatelessWidget {
  final List<(String, Future<void> Function())> actions;
  const RowMenu(this.actions, {super.key});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<int>(
      onSelected: (i) => actions[i].$2(),
      itemBuilder: (_) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem(value: i, child: Text(actions[i].$1))
      ],
    );
  }
}

/// Seçenek listesi: sunucu listesinden (değer, etiket) çiftleri.
Future<List<(String, String)>> optionsFrom(
    String path, String Function(Map<String, dynamic> m) label,
    {String id = 'id', Map<String, dynamic>? query}) async {
  final list = await apiClient.getList(path, query: query);
  return [
    for (final m in list.whereType<Map>())
      ('${m[id]}', label(Map<String, dynamic>.from(m)))
  ];
}

/// Yazma rolü (yönetici/kurul) var mı — ekranlar düğmeleri buna göre gösterir.
class RoleGate extends StatelessWidget {
  final List<String> roles;
  final Widget Function(BuildContext context, bool allowed) builder;
  const RoleGate({super.key, this.roles = writeRoles, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: hasAnyRole(roles),
      builder: (context, s) => builder(context, s.data == true),
    );
  }
}

/// Daire seçenekleri: "A-12" biçiminde (paneldeki gibi).
Future<List<(String, String)>> unitOptions() => optionsFrom(
        '/units', (u) => '${u['block'] ?? ''}-${u['door_number'] ?? ''}')
    .catchError((_) => <(String, String)>[]);
