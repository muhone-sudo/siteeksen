import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Rezervasyon Yapma Ekranı - Apple Tarzı
class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() => _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  int _selectedFacility = 0;
  DateTime _selectedDate = DateTime.now();
  int _selectedTimeSlot = -1;

  final List<Map<String, dynamic>> _facilities = [
    {'id': '1', 'name': 'Tenis Kortu', 'icon': Icons.sports_tennis_rounded, 'color': AppleTheme.systemGreen, 'price': 150},
    {'id': '2', 'name': 'Havuz', 'icon': Icons.pool_rounded, 'color': AppleTheme.systemBlue, 'price': 0},
    {'id': '3', 'name': 'Spor Salonu', 'icon': Icons.fitness_center_rounded, 'color': AppleTheme.systemOrange, 'price': 0},
    {'id': '4', 'name': 'Toplantı Odası', 'icon': Icons.meeting_room_rounded, 'color': AppleTheme.systemPurple, 'price': 200},
    {'id': '5', 'name': 'Mangal Alanı', 'icon': Icons.outdoor_grill_rounded, 'color': AppleTheme.systemRed, 'price': 100},
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '09:00 - 10:00', 'available': true},
    {'time': '10:00 - 11:00', 'available': true},
    {'time': '11:00 - 12:00', 'available': false},
    {'time': '12:00 - 13:00', 'available': true},
    {'time': '14:00 - 15:00', 'available': true},
    {'time': '15:00 - 16:00', 'available': false},
    {'time': '16:00 - 17:00', 'available': true},
    {'time': '17:00 - 18:00', 'available': true},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedFacilityData = _facilities[_selectedFacility];

    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Rezervasyon Yap'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // Facility Selection
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Tesis Seçin'),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _facilities.length,
                itemBuilder: (context, index) {
                  final facility = _facilities[index];
                  final isSelected = _selectedFacility == index;

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedFacility = index;
                      _selectedTimeSlot = -1;
                    }),
                    child: AnimatedContainer(
                      duration: AppleTheme.fastAnimation,
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? (facility['color'] as Color).withOpacity(0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? facility['color'] as Color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(facility['icon'] as IconData, color: facility['color'] as Color, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            facility['name'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 2,
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
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Tarih'),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 14,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                  final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = date;
                      _selectedTimeSlot = -1;
                    }),
                    child: AnimatedContainer(
                      duration: AppleTheme.fastAnimation,
                      width: 60,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppleTheme.systemBlue : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[date.weekday - 1],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white70 : AppleTheme.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppleTheme.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Time Slots
          const SliverToBoxAdapter(
            child: SectionTitle(title: 'Saat'),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final slot = _timeSlots[index];
                  final isAvailable = slot['available'] as bool;
                  final isSelected = _selectedTimeSlot == index;

                  return GestureDetector(
                    onTap: isAvailable ? () => setState(() => _selectedTimeSlot = index) : null,
                    child: AnimatedContainer(
                      duration: AppleTheme.fastAnimation,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppleTheme.systemBlue 
                            : isAvailable 
                                ? Colors.white 
                                : AppleTheme.systemGray6,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppleTheme.systemBlue : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot['time'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected 
                                ? Colors.white 
                                : isAvailable 
                                    ? AppleTheme.label 
                                    : AppleTheme.systemGray3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _timeSlots.length,
              ),
            ),
          ),

          // Pricing Info
          if ((selectedFacilityData['price'] as int) > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, color: AppleTheme.systemGreen),
                    const SizedBox(width: 12),
                    Text('Ücret: ', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                    Text('₺${selectedFacilityData['price']}/saat', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedTimeSlot >= 0 ? () => _submitReservation(context) : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Rezervasyon Yap'),
          ),
        ),
      ),
    );
  }

  void _submitReservation(BuildContext context) {
    final facility = _facilities[_selectedFacility];
    final slot = _timeSlots[_selectedTimeSlot];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (facility['color'] as Color).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(facility['icon'] as IconData, size: 48, color: facility['color'] as Color),
            ),
            const SizedBox(height: 24),
            const Text('Rezervasyon Onaylandı!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(facility['name'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(_selectedDate)} • ${slot['time']}',
              style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${date.day} ${months[date.month - 1]}';
  }
}
