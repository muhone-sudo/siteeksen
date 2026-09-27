// Rezervasyon oluşturma.
//
// DÜZELTME (2026-09-26): saatler ve dolu durumları koda gömülüydü; istek
// "09:00" biçiminde saat gönderdiği için sunucu HER rezervasyonu 400 ile
// reddediyordu; sonuç da her zaman "Onaylandı" diye gösteriliyordu (tesis onay
// istiyorsa rezervasyon PENDING kalır). Artık doluluk sunucudan gelir, zaman
// RFC3339 gönderilir ve sunucunun verdiği durum gösterilir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';
import '../../domain/reservation_slots.dart';
import 'my_reservations_screen.dart' show reservationStatusLabels;

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() => _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  List<Map<String, dynamic>> _facilities = [];
  int _selectedFacility = 0;
  DateTime _selectedDate = DateTime.now();
  bool _loadingFacilities = true;
  String? _facilitiesError;

  bool _loadingSlots = false;
  String? _slotsError;
  bool _open = true;
  List<TimeSlot> _slots = [];
  int _selectedSlot = -1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _loadingFacilities = true;
      _facilitiesError = null;
    });
    try {
      final list = await apiClient.getFacilities();
      final usable = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((f) => f['is_active'] != false && f['maintenance_mode'] != true)
          .toList();
      if (!mounted) return;
      setState(() {
        _facilities = usable;
        _loadingFacilities = false;
      });
      if (usable.isNotEmpty) await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facilitiesError = toUserMessage(e);
        _loadingFacilities = false;
      });
    }
  }

  Map<String, dynamic> get _facility => _facilities[_selectedFacility];

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _selectedSlot = -1;
    });
    try {
      final res = await apiClient.getFacilitySlots('${_facility['id']}', apiDate(_selectedDate));
      final open = parseHhmm(res['available_from']) ?? 8 * 60;
      final close = parseHhmm(res['available_to']) ?? 22 * 60;
      final minDur = toNum(_facility['min_duration_minutes']).toInt();
      final busy = <(String, String)>[
        for (final b in ApiClient.listOf(res['busy']).whereType<Map>())
          if (b['start_time'] is String && b['end_time'] is String) (b['start_time'] as String, b['end_time'] as String),
      ];
      if (!mounted) return;
      setState(() {
        _open = res['open'] != false;
        _slots = buildSlots(
          day: _selectedDate,
          openMinute: open,
          closeMinute: close,
          stepMinutes: minDur > 0 ? minDur : 60,
          busy: busy,
          bufferMinutes: toNum(res['buffer_minutes']).toInt(),
          now: DateTime.now(),
        );
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = toUserMessage(e);
        _loadingSlots = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('Rezervasyon Yap'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    );
    if (_loadingFacilities) return Scaffold(appBar: appBar, body: const LoadingView());
    if (_facilitiesError != null) {
      return Scaffold(appBar: appBar, body: ErrorStateView(message: _facilitiesError!, onRetry: _loadFacilities));
    }
    if (_facilities.isEmpty) {
      return Scaffold(appBar: appBar, body: const EmptyStateView(message: 'Rezervasyona açık tesis bulunamadı.'));
    }

    final fee = toNum(_facility['hourly_fee']);
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const SectionTitle(title: 'Tesis'),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _facilities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text('${_facilities[i]['name'] ?? 'Tesis'}'),
                selected: i == _selectedFacility,
                onSelected: (_) {
                  setState(() => _selectedFacility = i);
                  _loadSlots();
                },
              ),
            ),
          ),
          if ((_facility['rules'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Kurallar: ${_facility['rules']}', style: TextStyle(color: AppleTheme.secondaryLabel)),
            ),
          const SectionTitle(title: 'Tarih'),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bookingDays,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = DateTime.now().add(Duration(days: i));
                final selected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
                return ChoiceChip(
                  label: Text(formatDate(d).split(' ').take(2).join(' ')),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedDate = d);
                    _loadSlots();
                  },
                );
              },
            ),
          ),
          const SectionTitle(title: 'Saat'),
          if (_loadingSlots)
            const Padding(padding: EdgeInsets.all(24), child: LoadingView())
          else if (_slotsError != null)
            ErrorStateView(message: _slotsError!, onRetry: _loadSlots)
          else if (!_open)
            const EmptyStateView(message: 'Tesis bu gün kapalı.', icon: Icons.event_busy)
          else if (_slots.isEmpty)
            const EmptyStateView(message: 'Bu gün için uygun saat yok.', icon: Icons.event_busy)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _slots.length; i++)
                    ChoiceChip(
                      label: Text(_slots[i].label),
                      selected: i == _selectedSlot,
                      onSelected: _slots[i].available ? (_) => setState(() => _selectedSlot = i) : null,
                    ),
                ],
              ),
            ),
          if (fee > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Ücret: ${formatTry(fee)}/saat. Uygulamada tahsilat yapılmaz; ödeme yönetimle yapılır.',
                  style: TextStyle(color: AppleTheme.secondaryLabel)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedSlot >= 0 && !_submitting ? _submit : null,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Rezervasyon Yap'),
          ),
        ),
      ),
    );
  }

  int get _bookingDays {
    final n = toNum(_facilities.isEmpty ? null : _facility['advance_booking_days']).toInt();
    return n > 0 ? n.clamp(1, 60) : 14;
  }

  Future<void> _submit() async {
    final slot = _slots[_selectedSlot];
    setState(() => _submitting = true);
    try {
      final res = await apiClient.createReservation(
        facilityId: '${_facility['id']}',
        startTime: slot.startRfc3339(_selectedDate),
        endTime: slot.endRfc3339(_selectedDate),
      );
      if (!mounted) return;
      final status = '${res['status'] ?? ''}';
      final notes = [res['note'], res['deposit_note']].whereType<String>().join('\n');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(status == 'APPROVED' ? 'Rezervasyon onaylandı' : 'Rezervasyon alındı'),
          content: Text([
            '${_facility['name']} · ${formatDate(_selectedDate)} · ${slot.label}',
            'Durum: ${reservationStatusLabels[status] ?? status}',
            if (status == 'PENDING') 'Tesis yönetim onayı gerektiriyor; karar bildirim olarak gelecek.',
            if (notes.isNotEmpty) notes,
          ].join('\n\n')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rezervasyon oluşturulamadı: ${toUserMessage(e)}')));
      await _loadSlots();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
