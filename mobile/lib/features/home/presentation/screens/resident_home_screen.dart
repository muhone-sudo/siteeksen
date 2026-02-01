import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Sakin Ana Sayfa Ekranı - Apple Tarzı
class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  final Map<String, dynamic> _userData = {
    'name': 'Ahmet Yılmaz',
    'unit': 'D.105',
    'building': 'A Blok',
    'balance': -1250.00,
  };

  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.campaign_rounded,
      'title': 'Yeni Duyuru',
      'message': 'Yarın saat 10:00-14:00 arası su kesintisi yapılacaktır.',
      'time': '1 saat',
      'color': Color(0xFFFF9500),
    },
    {
      'icon': Icons.inventory_2_rounded,
      'title': 'Kargo Geldi',
      'message': 'Aras Kargo ile gönderiniz ulaştı.',
      'time': '3 saat',
      'color': Color(0xFF34C759),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppleTheme.systemBlue.withOpacity(0.12),
                      child: Text(
                        _userData['name'].toString().substring(0, 1),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppleTheme.systemBlue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, ${_userData['name'].toString().split(' ').first}!',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                          ),
                          Text(
                            '${_userData['building']} • ${_userData['unit']}',
                            style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_rounded, size: 28),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppleTheme.systemRed, shape: BoxShape.circle),
                              child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BalanceCard(
                  title: 'Bakiyeniz',
                  amount: '₺${(_userData['balance'] as double).abs().toStringAsFixed(2)}',
                  subtitle: 'Son ödeme tarihi: 15 Şubat 2026',
                  amountColor: (_userData['balance'] as double) < 0 ? AppleTheme.systemRed : AppleTheme.systemGreen,
                  action: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Borçlu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemRed)),
                  ),
                ),
              ),
            ),

            // Pay Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.credit_card_rounded),
                    label: const Text('Aidat Öde'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions
            const SliverToBoxAdapter(
              child: SectionTitle(title: 'Hızlı İşlemler'),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: AppleTheme.cardDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    QuickActionButton(icon: Icons.person_add_rounded, label: 'Ziyaretçi', color: AppleTheme.systemBlue, onTap: () {}),
                    QuickActionButton(icon: Icons.event_rounded, label: 'Rezervasyon', color: AppleTheme.systemGreen, onTap: () {}),
                    QuickActionButton(icon: Icons.report_problem_rounded, label: 'Talep', color: AppleTheme.systemOrange, onTap: () {}),
                    QuickActionButton(icon: Icons.poll_rounded, label: 'Oylama', color: AppleTheme.systemPurple, onTap: () {}),
                  ],
                ),
              ),
            ),

            // Services Grid
            const SliverToBoxAdapter(
              child: SectionTitle(title: 'Hizmetler', action: 'Tümü'),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildListDelegate([
                  ServiceCard(icon: Icons.request_page_rounded, title: 'Talepler', subtitle: '2 açık', color: AppleTheme.systemOrange, onTap: () {}),
                  ServiceCard(icon: Icons.inventory_2_rounded, title: 'Kargolarım', subtitle: '1 bekliyor', color: AppleTheme.systemGreen, onTap: () {}),
                  ServiceCard(icon: Icons.directions_car_rounded, title: 'Araçlarım', subtitle: '2 kayıtlı', color: AppleTheme.systemBlue, onTap: () {}),
                  ServiceCard(icon: Icons.receipt_long_rounded, title: 'Faturalar', subtitle: 'Ocak 2026', color: AppleTheme.systemPurple, onTap: () {}),
                ]),
              ),
            ),

            // Notifications
            const SliverToBoxAdapter(
              child: SectionTitle(title: 'Son Bildirimler', action: 'Tümü'),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppleTheme.cardDecoration,
                child: Column(
                  children: _notifications.asMap().entries.map((entry) {
                    final notif = entry.value;
                    return Column(
                      children: [
                        NotificationCard(
                          icon: notif['icon'] as IconData,
                          title: notif['title'] as String,
                          message: notif['message'] as String,
                          time: notif['time'] as String,
                          color: notif['color'] as Color,
                          onTap: () {},
                        ),
                        if (entry.key < _notifications.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 62),
                            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
