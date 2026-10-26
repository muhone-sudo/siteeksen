// Rezervasyon yönetimi.
//
// DÜZELTME (2026-09-26): ekran `date`/`time_slot` ve küçük harfli `confirmed`
// durumunu arıyordu (sunucu start_time/end_time ve PENDING/APPROVED…);
// Onayla/İptal düğmeleri yalnızca pencereyi kapatıyordu; sayılar uydurmaydı.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/api_views.dart';
import '../../../../core/widgets/forms.dart';

const _categories = [
  ('MEETING_ROOM', 'Toplantı salonu'),
  ('POOL', 'Havuz'),
  ('GYM', 'Spor salonu'),
  ('TENNIS', 'Tenis kortu'),
  ('BBQ', 'Barbekü'),
  ('SAUNA', 'Sauna'),
  ('OTHER', 'Diğer')
];
const _days = [
  ('1', 'Pzt'),
  ('2', 'Sal'),
  ('3', 'Çar'),
  ('4', 'Per'),
  ('5', 'Cum'),
  ('6', 'Cmt'),
  ('0', 'Paz')
];

/// Tesis ekleme/düzenleme (paneldeki facility-form ile aynı alanlar ve varsayılanlar).
Future<bool> facilityForm(BuildContext context, [Map<String, dynamic>? f]) {
  bool paid(Map<String, dynamic> v) => v['is_paid'] == true;
  return formAction(
      context, f == null ? 'Yeni tesis' : 'Tesis düzenle — ${f['name']}', [
    FSpec('name', 'Ad', required: true, initial: f?['name']),
    FSpec('category', 'Kategori',
        type: FType.select,
        options: _categories,
        initial: f?['category'] ?? 'MEETING_ROOM'),
    FSpec('capacity', 'Kapasite (kişi)',
        type: FType.integer, initial: f?['capacity'], hint: 'Boş = sınırsız'),
    FSpec('available_from', 'Açılış',
        type: FType.time,
        initial: f?['available_from'] ?? '08:00',
        required: true),
    FSpec('available_to', 'Kapanış',
        type: FType.time,
        initial: f?['available_to'] ?? '22:00',
        required: true),
    FSpec('available_days', 'Açık günler',
        type: FType.multi,
        options: _days,
        initial:
            ((f?['available_days'] as List?) ?? const [0, 1, 2, 3, 4, 5, 6])),
    FSpec('advance_booking_days', 'İleri tarih sınırı (gün)',
        type: FType.integer, initial: f?['advance_booking_days'] ?? 14),
    FSpec('min_duration_minutes', 'En kısa süre (dk)',
        type: FType.integer, initial: f?['min_duration_minutes'] ?? 60),
    FSpec('max_duration_minutes', 'En uzun süre (dk)',
        type: FType.integer, initial: f?['max_duration_minutes'] ?? 240),
    FSpec('buffer_minutes', 'Tampon süre (dk)',
        type: FType.integer,
        initial: f?['buffer_minutes'] ?? 0,
        hint: 'Rezervasyonlar arası hazırlık'),
    FSpec('max_reservations_per_unit', 'Haftalık kota (daire)',
        type: FType.integer,
        initial: f?['max_reservations_per_unit'] ?? 2,
        hint: '0 = sınırsız'),
    FSpec('cancellation_deadline_hours', 'İptal son süresi (saat)',
        type: FType.integer,
        initial: f?['cancellation_deadline_hours'] ?? 0,
        hint: '0 = serbest'),
    FSpec('requires_approval', 'Rezervasyon yönetim onayı gerektirir',
        type: FType.toggle, initial: f?['requires_approval'] ?? false),
    FSpec('is_paid', 'Ücretli tesis',
        type: FType.toggle,
        initial: f?['is_paid'] ?? false,
        hint: 'Ücret hesaplanır, tahsil edilmez'),
    FSpec('hourly_fee', 'Saatlik ücret (TL)',
        type: FType.decimal, initial: f?['hourly_fee'], visible: paid),
    FSpec('daily_fee', 'Günlük ücret (TL)',
        type: FType.decimal, initial: f?['daily_fee'], visible: paid),
    FSpec('deposit_amount', 'Depozito (TL)',
        type: FType.decimal, initial: f?['deposit_amount'], visible: paid),
    if (f != null)
      FSpec('is_active', 'Kullanıma açık',
          type: FType.toggle, initial: f['is_active'] ?? true),
    if (f != null)
      FSpec('maintenance_mode', 'Bakımda',
          type: FType.toggle, initial: f['maintenance_mode'] ?? false),
    if (f != null)
      FSpec('maintenance_note', 'Bakım notu (sakinlere gösterilir)',
          initial: f['maintenance_note'],
          required: true,
          visible: (v) => v['maintenance_mode'] == true),
    FSpec('description', 'Açıklama', initial: f?['description']),
    FSpec('rules', 'Kullanım kuralları',
        type: FType.multiline, initial: f?['rules']),
  ], (v) {
    final body = <String, dynamic>{
      'capacity': 0,
      'hourly_fee': 0,
      'daily_fee': 0,
      'deposit_amount': 0,
      ...v,
      'available_days': [
        for (final d in (v['available_days'] as List)) int.parse('$d')
      ],
      'auto_approve_residents': v['requires_approval'] != true,
    };
    return f == null
        ? apiClient.post('/facilities', body)
        : apiClient.patch('/facilities/${f['id']}', body);
  },
      note: f == null
          ? null
          : 'Değişiklikler yalnızca bundan sonraki rezervasyonlara uygulanır.',
      success:
          f == null ? 'Tesis eklendi; sakinler rezervasyon yapabilir' : null);
}

const reservationStatus = {
  'PENDING': ('Onay bekliyor', Colors.orange),
  'APPROVED': ('Onaylandı', Colors.green),
  'REJECTED': ('Reddedildi', Colors.red),
  'CANCELLED': ('İptal', Colors.grey),
  'COMPLETED': ('Tamamlandı', Colors.blueGrey),
};

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen> {
  String? _status = 'PENDING';
  bool _canWrite = false;
  final _fac = GlobalKey<ApiListState>();

  @override
  void initState() {
    super.initState();
    hasAnyRole(writeRoles).then((v) {
      if (mounted) setState(() => _canWrite = v);
    });
  }

  Future<void> _act(
      Map r, String action, Future<void> Function() reload) async {
    Map<String, dynamic> body = {};
    if (action == 'reject' || action == 'cancel') {
      final reason = await askText(
          context, action == 'reject' ? 'Reddet' : 'İptal et', 'Gerekçe',
          required: action == 'reject');
      if (reason == null) return;
      body = {'reason': reason};
    }
    if (!mounted) return;
    if (await runAction(context,
        () => switch (action) {
              'approve' => apiClient.post('/reservations/${r['id']}/approve', body),
              'reject' => apiClient.post('/reservations/${r['id']}/reject', body),
              _ => apiClient.post('/reservations/${r['id']}/cancel', body),
            })) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rezervasyonlar'),
          bottom: const TabBar(
              tabs: [Tab(text: 'Rezervasyonlar'), Tab(text: 'Tesisler')]),
        ),
        body: TabBarView(children: [
          Column(children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in [null, ...reservationStatus.keys])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label:
                            Text(s == null ? 'Tümü' : reservationStatus[s]!.$1),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ApiList(
                token: _status,
                load: () => apiClient
                    .getList('/reservations', query: {'status': _status}),
                empty: 'Rezervasyon yok',
                itemBuilder: (context, r, reload) {
                  final st = reservationStatus['${r['status']}'];
                  final open =
                      r['status'] == 'PENDING' || r['status'] == 'APPROVED';
                  final fee = toNum(r['total_fee']);
                  return ListTile(
                    title: Text(
                        '${r['facility_name'] ?? 'Tesis'} · ${r['unit_name'] ?? ''}'),
                    subtitle: Text([
                      '${formatDate(r['start_time'])} ${formatTime(r['start_time'])}–${formatTime(r['end_time'])}',
                      '${r['resident_name'] ?? ''}',
                      if (toNum(r['guest_count']) > 0)
                        '${toNum(r['guest_count']).toInt()} kişi',
                      if (fee > 0) '${formatTry(fee)} (tahsil edilmedi)',
                      if ((r['purpose'] ?? '').toString().isNotEmpty)
                        '${r['purpose']}',
                      if ((r['rejection_reason'] ?? '').toString().isNotEmpty)
                        'Gerekçe: ${r['rejection_reason']}',
                    ].where((s) => s.isNotEmpty).join('\n')),
                    isThreeLine: true,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (st != null) StatusChip(st.$1, color: st.$2),
                      if (_canWrite && open)
                        PopupMenuButton<String>(
                          onSelected: (a) => _act(r, a, reload),
                          itemBuilder: (_) => [
                            if (r['status'] == 'PENDING')
                              const PopupMenuItem(
                                  value: 'approve', child: Text('Onayla')),
                            if (r['status'] == 'PENDING')
                              const PopupMenuItem(
                                  value: 'reject', child: Text('Reddet')),
                            const PopupMenuItem(
                                value: 'cancel', child: Text('İptal et')),
                          ],
                        ),
                    ]),
                  );
                },
              ),
            ),
          ]),
          ApiList(
            key: _fac,
            load: () => apiClient.getList('/facilities'),
            empty: 'Tesis tanımlı değil',
            header: (_) => _canWrite
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (await facilityForm(context)) {
                            await _fac.currentState?.reload();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tesis ekle'),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            itemBuilder: (context, f, reload) => ListTile(
              leading: Icon(f['maintenance_mode'] == true
                  ? Icons.construction
                  : (f['is_active'] == false
                      ? Icons.block
                      : Icons.meeting_room)),
              title: Text('${f['name'] ?? ''}'),
              subtitle: Text([
                _categories
                    .firstWhere((c) => c.$1 == f['category'],
                        orElse: () => ('', '${f['category'] ?? ''}'))
                    .$2,
                '${f['available_from']}–${f['available_to']}',
                if (toNum(f['capacity']) > 0) '${f['capacity']} kişi',
                f['requires_approval'] == true ? 'Onaylı' : 'Otomatik onay',
                if (f['is_paid'] == true) 'Ücretli',
                if (f['maintenance_mode'] == true)
                  'Bakımda: ${f['maintenance_note'] ?? ''}',
              ].where((s) => s.isNotEmpty).join(' · ')),
              trailing: _canWrite
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        if (await facilityForm(context, f)) await reload();
                      },
                    )
                  : null,
            ),
          ),
        ]),
      ),
    );
  }
}
