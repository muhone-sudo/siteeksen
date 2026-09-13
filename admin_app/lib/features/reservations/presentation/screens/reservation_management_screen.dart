import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/data_state.dart';

/// Rezervasyon Yönetim Ekranı - Apple Tarzı
class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  int _selectedFacility = 0;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservationsAndFacilities();
  }

  void _loadReservationsAndFacilities() async {
    try {
      final facilities = await apiClient.getFacilities();
      final reservations = await apiClient.getReservations();
      setState(() {
        _facilities = List<Map<String, dynamic>>.from(facilities.map((f) {
          return {
            'id': f['id'] ?? '',
            'name': f['name'] ?? '',
            'icon': _getIconForCategory(f['category']),
            'color': _getColorForCategory(f['category']),
          };
        }));
        _reservations = List<Map<String, dynamic>>.from(reservations.map((r) {
          return {
            'id': r['id'] ?? '',
            'facility': r['facility_name'] ?? r['facility'] ?? '',
            'resident': r['resident_name'] ?? r['resident'] ?? '',
            'unit': r['unit_id'] ?? r['unit'] ?? '',
            'date': r['date'] ?? '',
            'time': r['time_slot'] ?? r['time'] ?? '',
            'status': r['status']?.toString().toLowerCase() ?? 'confirmed',
          };
        }));
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'pool': return Icons.pool_rounded;
      case 'gym': return Icons.fitness_center_rounded;
      case 'meeting': return Icons.meeting_room_rounded;
      case 'tennis': return Icons.sports_tennis_rounded;
      default: return Icons.outdoor_grill_rounded;
    }
  }

  Color _getColorForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'pool': return const Color(0xFF007AFF);
      case 'gym': return const Color(0xFFFF9500);
      case 'meeting': return const Color(0xFF34C759);
      case 'tennis': return const Color(0xFFFF3B30);
      default: return const Color(0xFFAF52DE);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppleTheme.background,
        appBar: AppBar(title: const Text('Rezervasyonlar'), backgroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

  /// Rezervasyon oluşturma formu.
  ///
  /// NEDEN BİLDİRİM (2026-09-13): Önceki form koda gömülü bir sakin listesi
  /// gösteriyor, alanların `onChanged`'i boş bırakılmış ve kaydetme hiçbir yere
  /// yazmıyordu. Rezervasyon çakışma denetimi de yoktu; iki kişi aynı saati
  /// "ayırttığını" sanabilirdi. Form gerçek uçlara bağlanana kadar devre dışıdır.
  void _showNewReservationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Yeni Rezervasyon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const NotImplementedNotice(
              title: 'Rezervasyon formu henüz bağlanmadı',
              detail: 'Rezervasyon modülü sunucu tarafında gerçek veri katmanına '
                  'bağlanmadığı için bu formdan kayıt oluşturulamaz. Çakışma '
                  'denetimi de sunucu tarafında yapılmalıdır.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
