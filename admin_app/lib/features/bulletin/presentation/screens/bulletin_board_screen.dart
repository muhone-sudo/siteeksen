// İlan panosu denetimi (yönetim).
//
// DÜZELTME (2026-09-27): ekran var olmayan `/bulletin` yoluna gidiyor,
// yönetimin ilan VERMESİNİ ve SİLMESİNİ sağlıyordu; sunucuda ne yönetim
// ilanı (yönetim duyuru yayınlar) ne silme vardır. Sakin ilanları ÖNCE
// yönetim onayından geçer — o onay akışı ekranda hiç yoktu.
// Sözleşme: `GET /bulletins?status=`, `GET /bulletins-summary`,
// `POST /bulletins/:id/approve|reject {reason}|close`,
// `GET /bulletins/:id/comments`, `DELETE /bulletin-comments/:id` (gizler).

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';

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

(String, Color) bulletinStatus(Object? s) {
  switch ('${s ?? ''}') {
    case 'PENDING':
      return ('Onay bekliyor', Colors.orange);
    case 'APPROVED':
      return ('Yayında', Colors.green);
    case 'REJECTED':
      return ('Reddedildi', Colors.red);
    case 'EXPIRED':
      return ('Süresi doldu', Colors.blueGrey);
    case 'CLOSED':
      return ('Kapatıldı', Colors.blueGrey);
    default:
      return ('${s ?? '—'}', Colors.blueGrey);
  }
}

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
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

  Future<void> _approve(Map<String, dynamic> b) async {
    if (await runAction(context, () => apiClient.post('/bulletins/${b['id']}/approve'), success: 'İlan yayına alındı')) {
      _changed();
    }
  }

  Future<void> _reject(Map<String, dynamic> b) async {
    final reason = await askText(context, 'İlanı reddet', 'Red gerekçesi (sakine gösterilir)');
    if (reason == null || !mounted) return;
    if (await runAction(context, () => apiClient.post('/bulletins/${b['id']}/reject', {'reason': reason}),
        success: 'İlan reddedildi')) {
      _changed();
    }
  }

  Future<void> _close(Map<String, dynamic> b) async {
    final ok = await confirm(context, 'İlanı kapat', 'İlan panodan kalkar; kayıt ve yorumlar silinmez.', ok: 'Kapat');
    if (!ok || !mounted) return;
    if (await runAction(context, () => apiClient.post('/bulletins/${b['id']}/close'))) _changed();
  }

  void _comments(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          ListTile(title: Text('${b['title']} — yorumlar', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: ApiList(
              load: () => apiClient.getList('/bulletins/${b['id']}/comments'),
              empty: 'Yorum yok',
              itemBuilder: (context, c, reload) => ListTile(
                title: Text('${c['content'] ?? ''}'),
                subtitle: Text('${c['author_name'] ?? 'Anonim'} · ${formatDateTime(c['created_at'])}'),
                trailing: _canWrite
                    ? IconButton(
                        tooltip: 'Gizle',
                        icon: const Icon(Icons.visibility_off_outlined),
                        onPressed: () async {
                          final ok = await confirm(context, 'Yorumu gizle', 'Yorum panodan kalkar; kayıt denetim için saklanır.', ok: 'Gizle');
                          if (ok && context.mounted && await runAction(context, () => apiClient.delete('/bulletin-comments/${c['id']}'))) {
                            await reload();
                          }
                        },
                      )
                    : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> b) {
    final (label, color) = bulletinStatus(b['status']);
    final status = b['status'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${b['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600))),
            StatusChip(label, color: color),
          ]),
          const SizedBox(height: 4),
          Text('${b['content'] ?? ''}'),
          const SizedBox(height: 4),
          Text(
            [
              bulletinCategories[b['category']] ?? '${b['category'] ?? ''}',
              if (b['price'] != null) '${formatTry(toNum(b['price']))}${b['price_negotiable'] == true ? ' (pazarlıklı)' : ''}',
              b['is_anonymous'] == true ? 'Anonim' : [b['author_name'], b['unit_name']].where((v) => '${v ?? ''}'.isNotEmpty).join(' · '),
              formatDate(b['created_at']),
            ].where((s) => s.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((b['rejection_reason'] ?? '').toString().isNotEmpty) Text('Red gerekçesi: ${b['rejection_reason']}'),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: () => _comments(b),
              icon: const Icon(Icons.comment_outlined, size: 18),
              label: Text('${b['comment_count'] ?? 0}'),
            ),
            if (_canWrite && status == 'PENDING') ...[
              TextButton(onPressed: () => _reject(b), child: const Text('Reddet')),
              FilledButton(onPressed: () => _approve(b), child: const Text('Onayla')),
            ],
            if (_canWrite && status == 'APPROVED') TextButton(onPressed: () => _close(b), child: const Text('Kapat')),
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
          title: const Text('İlan Panosu'),
          bottom: const TabBar(tabs: [Tab(text: 'Onay bekleyen'), Tab(text: 'Yayında'), Tab(text: 'Tümü')]),
        ),
        body: TabBarView(children: [
          for (final status in const ['PENDING', 'APPROVED', ''])
            ApiList(
              token: _token,
              load: () => apiClient.getList('/bulletins', query: {'status': status}),
              empty: status == 'PENDING' ? 'Onay bekleyen ilan yok' : 'İlan yok',
              header: status == 'PENDING' && _canWrite ? (_) => _Summary(key: ValueKey(_token)) : null,
              itemBuilder: (context, b, _) => _tile(b),
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
  late final Future<Map<String, dynamic>> _f = apiClient.getMap('/bulletins-summary');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) return const SizedBox.shrink();
        return StatRow([
          ('Bekleyen', '${s['pending_review'] ?? 0}'),
          ('Yayında', '${s['approved'] ?? 0}'),
          ('Reddedilen', '${s['rejected'] ?? 0}'),
          ('Kapatılan', '${s['closed'] ?? 0}'),
        ]);
      },
    );
  }
}
