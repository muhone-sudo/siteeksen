// Site ilan panosu (sakin).
//
// DÜZELTME (2026-09-26): liste var olmayan alanları okuyor (`description`,
// `author`, `unit`, `date`, `views`), kategori filtreleri küçük harfli
// olduğu için hiçbir ilanla eşleşmiyordu. Yeni ilan zorunlu `content`
// alanını göndermediği ve fiyatı metin olarak yolladığı için HER ZAMAN
// reddediliyor, yine de "İlanınız yayınlandı!" deniyordu — oysa ilan
// yönetim onayına düşer (PENDING).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

/// Sunucunun kabul ettiği kategoriler (bulletin servisi).
const bulletinCategories = <String, String>{
  'SALE': 'Satılık',
  'RENT': 'Kiralık',
  'LOST_FOUND': 'Kayıp/Bulunan',
  'HELP': 'Yardımlaşma',
  'SUGGESTION': 'Öneri',
  'CARPOOL': 'Araç paylaşımı',
  'SERVICE': 'Hizmet',
  'EVENT': 'Etkinlik',
  'OTHER': 'Diğer',
};

const bulletinStatusLabels = <String, String>{
  'PENDING': 'Onay bekliyor',
  'APPROVED': 'Yayında',
  'REJECTED': 'Reddedildi',
  'EXPIRED': 'Süresi doldu',
  'CLOSED': 'Kapatıldı',
};

/// Formdaki fiyat metnini sayıya çevirir ("1.250,50" → 1250.5). Boşsa null.
num? parsePriceInput(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final normalized = t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t;
  return num.tryParse(normalized);
}

class BulletinBoardMobileScreen extends StatefulWidget {
  const BulletinBoardMobileScreen({super.key});

  @override
  State<BulletinBoardMobileScreen> createState() => _BulletinBoardMobileScreenState();
}

class _BulletinBoardMobileScreenState extends State<BulletinBoardMobileScreen> {
  late Future<List<dynamic>> _future;
  String? _category;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getBulletins();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getBulletins());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Panosu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('İlan Ver'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('Tümü'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                ),
                for (final e in bulletinCategories.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(e.value), selected: _category == e.key, onSelected: (_) => setState(() => _category = e.key)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingView();
                if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
                final items = snap.data!
                    .whereType<Map>()
                    .where((b) => _category == null || b['category'] == _category)
                    .toList();
                if (items.isEmpty) return const EmptyStateView(message: 'İlan yok', icon: Icons.campaign_outlined);
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _tile(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map b) {
    final price = b['price'];
    final mine = b['is_mine'] == true;
    final status = '${b['status'] ?? ''}';
    return ListTile(
      title: Text('${b['title'] ?? ''}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${b['content'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text([
            bulletinCategories['${b['category']}'] ?? '${b['category']}',
            if (price != null) '${formatTry(toNum(price))}${b['price_negotiable'] == true ? ' (pazarlık)' : ''}',
            [b['author_name'], b['unit_name']].where((v) => v != null && '$v'.isNotEmpty).join(' '),
            formatDate(b['created_at']),
            if (mine) bulletinStatusLabels[status] ?? status,
            if (status == 'REJECTED' && (b['rejection_reason'] ?? '').toString().isNotEmpty) 'Gerekçe: ${b['rejection_reason']}',
          ].where((s) => s.isNotEmpty).join(' · '), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: mine && (status == 'PENDING' || status == 'APPROVED')
          ? TextButton(onPressed: () => _close(b), child: const Text('Kapat'))
          : null,
    );
  }

  Future<void> _close(Map b) async {
    try {
      await apiClient.closeBulletin('${b['id']}');
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toUserMessage(e))));
    }
  }

  Future<void> _create() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final content = TextEditingController();
    final price = TextEditingController();
    var category = 'SALE';
    var negotiable = false;
    var anonymous = false;
    String? error;
    var busy = false;

    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Yeni İlan', style: Theme.of(ctx).textTheme.titleLarge),
                  if (error != null)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [for (final e in bulletinCategories.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                    onChanged: (v) => setSheet(() => category = v ?? category),
                  ),
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                  ),
                  TextFormField(
                    controller: content,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama gerekli' : null,
                  ),
                  if (category == 'SALE' || category == 'RENT' || category == 'SERVICE')
                    TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fiyat (₺, isteğe bağlı)'),
                      validator: (v) => (v != null && v.trim().isNotEmpty && parsePriceInput(v) == null) ? 'Geçerli bir tutar girin' : null,
                    ),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Pazarlık payı var'), value: negotiable,
                      onChanged: (v) => setSheet(() => negotiable = v)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Adım gösterilmesin'),
                      subtitle: const Text('Yönetim ilan sahibini yine görür'), value: anonymous,
                      onChanged: (v) => setSheet(() => anonymous = v)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() {
                              busy = true;
                              error = null;
                            });
                            try {
                              final res = await apiClient.createBulletin({
                                'category': category,
                                'title': title.text.trim(),
                                'content': content.text.trim(),
                                if (parsePriceInput(price.text) != null) 'price': parsePriceInput(price.text),
                                'price_negotiable': negotiable,
                                'is_anonymous': anonymous,
                              });
                              if (ctx.mounted) Navigator.pop(ctx, '${res['note'] ?? ''}');
                            } catch (e) {
                              setSheet(() {
                                busy = false;
                                error = toUserMessage(e);
                              });
                            }
                          },
                    child: const Text('Gönder'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    title.dispose();
    content.dispose();
    price.dispose();
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(created.isNotEmpty ? created : 'İlanınız alındı; yönetim onayından sonra yayınlanacak.'),
    ));
    await _reload();
  }
}
