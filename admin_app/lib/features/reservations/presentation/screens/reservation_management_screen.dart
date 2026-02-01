import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Rezervasyon Yönetim Ekranı - Apple Tarzı
class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  int _selectedFacility = 0;
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _facilities = [
    {'id': '1', 'name': 'Yüzme Havuzu', 'icon': Icons.pool_rounded, 'color': Color(0xFF007AFF)},
    {'id': '2', 'name': 'Spor Salonu', 'icon': Icons.fitness_center_rounded, 'color': Color(0xFFFF9500)},
    {'id': '3', 'name': 'Toplantı Odası', 'icon': Icons.meeting_room_rounded, 'color': Color(0xFF34C759)},
    {'id': '4', 'name': 'Tenis Kortu', 'icon': Icons.sports_tennis_rounded, 'color': Color(0xFFFF3B30)},
    {'id': '5', 'name': 'Barbekü Alanı', 'icon': Icons.outdoor_grill_rounded, 'color': Color(0xFFAF52DE)},
  ];

  final List<Map<String, dynamic>> _reservations = [
    {
      'id': '1',
      'facility': 'Yüzme Havuzu',
      'resident': 'Ali Veli',
      'unit': 'D.101',
      'date': '2026-02-01',
      'time': '10:00 - 11:00',
      'status': 'confirmed',
    },
    {
      'id': '2',
      'facility': 'Spor Salonu',
      'resident': 'Ayşe Kaya',
      'unit': 'D.205',
      'date': '2026-02-01',
      'time': '14:00 - 15:00',
      'status': 'pending',
    },
    {
      'id': '3',
      'facility': 'Toplantı Odası',
      'resident': 'Mehmet Demir',
      'unit': 'D.301',
      'date': '2026-02-01',
      'time': '16:00 - 18:00',
      'status': 'confirmed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: CustomScrollView(
        slivers: [
          // Large Title AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Rezervasyonlar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_month_rounded, color: AppleTheme.systemBlue),
                onPressed: () => _selectDate(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMiniStat('Bugün', '8', Icons.today_rounded, AppleTheme.systemBlue),
                  _buildMiniStat('Bekleyen', '3', Icons.hourglass_top_rounded, AppleTheme.systemOrange),
                  _buildMiniStat('Onaylı', '5', Icons.check_circle_rounded, AppleTheme.systemGreen),
                ],
              ),
            ),
          ),

          // Facilities Selector
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _facilities.length,
                itemBuilder: (context, index) {
                  final facility = _facilities[index];
                  final isSelected = _selectedFacility == index;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFacility = index),
                    child: AnimatedContainer(
                      duration: AppleTheme.normalAnimation,
                      curve: AppleTheme.defaultCurve,
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (facility['color'] as Color).withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? facility['color'] as Color
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: AppleTheme.fastAnimation,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (facility['color'] as Color).withOpacity(isSelected ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              facility['icon'] as IconData,
                              color: facility['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (facility['name'] as String).split(' ').first,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected 
                                  ? facility['color'] as Color
                                  : AppleTheme.secondaryLabel,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Date Selector
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Column(
                        children: [
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _isToday(_selectedDate) ? 'Bugün' : _getDayName(_selectedDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppleTheme.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Section Header
          const SliverToBoxAdapter(
            child: AppleSectionHeader(
              title: 'Günün Rezervasyonları',
              action: 'Tümünü Gör',
            ),
          ),

          // Reservations List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _reservations.isEmpty
                  ? const AppleEmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Rezervasyon Yok',
                      subtitle: 'Bu tarihte henüz rezervasyon bulunmuyor',
                    )
                  : Column(
                      children: _reservations.asMap().entries.map((entry) {
                        return _buildReservationTile(
                          entry.value,
                          isLast: entry.key == _reservations.length - 1,
                        );
                      }).toList(),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Rezervasyon',
        onPressed: () => _showNewReservationSheet(context),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildReservationTile(Map<String, dynamic> reservation, {bool isLast = false}) {
    final status = reservation['status'] as String;
    final isConfirmed = status == 'confirmed';

    return Column(
      children: [
        InkWell(
          onTap: () => _showReservationDetails(context, reservation),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time
                Container(
                  width: 60,
                  child: Column(
                    children: [
                      Text(
                        (reservation['time'] as String).split(' - ').first,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        (reservation['time'] as String).split(' - ').last,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppleTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isConfirmed ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['facility'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${reservation['resident']} • ${reservation['unit']}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppleTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppleTheme.systemGreen.withOpacity(0.12)
                        : AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfirmed ? 'Onaylı' : 'Bekliyor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isConfirmed ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 92),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showReservationDetails(BuildContext context, Map<String, dynamic> reservation) {
    final status = reservation['status'] as String;
    final isConfirmed = status == 'confirmed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray4,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation['facility'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(_selectedDate)} • ${reservation['time']}',
                    style: TextStyle(fontSize: 17, color: AppleTheme.secondaryLabel),
                  ),
                  const SizedBox(height: 24),
                  AppleListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_rounded),
                    ),
                    title: reservation['resident'],
                    subtitle: reservation['unit'],
                    showChevron: false,
                  ),
                  const SizedBox(height: 24),
                  if (!isConfirmed) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppleTheme.systemGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: AppleTheme.systemRed),
                      label: Text('İptal Et', style: TextStyle(color: AppleTheme.systemRed)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppleTheme.systemRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showNewReservationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray4,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  const Text('Yeni Rezervasyon', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kaydet')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tesis', prefixIcon: Icon(Icons.place_outlined)),
                    items: _facilities.map((f) => DropdownMenuItem(value: f['id'] as String, child: Text(f['name'] as String))).toList(),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Sakin', prefixIcon: Icon(Icons.person_outlined)),
                    items: ['Ali Veli - D.101', 'Ayşe Kaya - D.205', 'Mehmet Demir - D.301'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tarih', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    controller: TextEditingController(text: _formatDate(_selectedDate)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Başlangıç'),
                          items: ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (_) {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Bitiş'),
                          items: ['10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
