import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Personel Yönetim Ekranı - Apple Tarzı
class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() => _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _employees = [
    {
      'name': 'Hasan Güvenlik',
      'position': 'Güvenlik Görevlisi',
      'department': 'Güvenlik',
      'status': 'active',
      'phone': '0532 111 2233',
      'hireDate': '2022-03-15',
      'salary': 18000,
    },
    {
      'name': 'Fatma Temizlik',
      'position': 'Temizlik Personeli',
      'department': 'Temizlik',
      'status': 'on_leave',
      'phone': '0533 222 3344',
      'hireDate': '2023-06-01',
      'salary': 14000,
    },
    {
      'name': 'Mehmet Bakım',
      'position': 'Teknik Personel',
      'department': 'Teknik',
      'status': 'active',
      'phone': '0534 333 4455',
      'hireDate': '2021-01-10',
      'salary': 20000,
    },
  ];

  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'name': 'Fatma Temizlik',
      'type': 'Yıllık İzin',
      'startDate': '2026-02-15',
      'endDate': '2026-02-20',
      'days': 5,
      'status': 'pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 60),
              title: Text(
                'Personel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppleTheme.systemBlue,
                  labelColor: AppleTheme.systemBlue,
                  unselectedLabelColor: AppleTheme.systemGray,
                  tabs: const [
                    Tab(text: 'Personeller'),
                    Tab(text: 'İzinler'),
                    Tab(text: 'Bordro'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEmployeesTab(),
            _buildLeavesTab(),
            _buildPayrollTab(),
          ],
        ),
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.person_add_rounded,
        label: 'Personel Ekle',
        onPressed: () {},
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats
        Row(
          children: [
            Expanded(child: _buildMiniStat('Toplam', '8', Icons.people_rounded, AppleTheme.systemBlue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('Aktif', '7', Icons.check_circle_rounded, AppleTheme.systemGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('İzinde', '1', Icons.beach_access_rounded, AppleTheme.systemOrange)),
          ],
        ),
        const SizedBox(height: 16),
        const AppleSectionHeader(title: 'Personel Listesi'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _employees.asMap().entries.map((entry) {
              return _buildEmployeeTile(entry.value, isLast: entry.key == _employees.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppleSectionHeader(title: 'Bekleyen İzin Talepleri'),
        _leaveRequests.isEmpty
            ? const AppleEmptyState(
                icon: Icons.event_available_rounded,
                title: 'Bekleyen talep yok',
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _leaveRequests.map((leave) => _buildLeaveTile(leave)).toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildPayrollTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Şubat 2026 Bordrosu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Hazırlanıyor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Toplam Bordro', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
              const SizedBox(height: 4),
              const Text('₺125.000', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Bordro Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          Text(title, style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> employee, {bool isLast = false}) {
    final isActive = employee['status'] == 'active';

    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppleTheme.systemGray6,
                  child: Text(
                    employee['name'].toString().substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(
                        '${employee['position']} • ${employee['department']}',
                        style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppleTheme.systemGreen.withOpacity(0.12) : AppleTheme.systemOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'İzinde',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? AppleTheme.systemGreen : AppleTheme.systemOrange),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  Widget _buildLeaveTile(Map<String, dynamic> leave) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppleTheme.systemOrange.withOpacity(0.12),
                child: Icon(Icons.beach_access_rounded, color: AppleTheme.systemOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text('${leave['type']} • ${leave['days']} gün', style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
                    Text('${leave['startDate']} - ${leave['endDate']}', style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: AppleTheme.systemRed, side: BorderSide(color: AppleTheme.systemRed)),
                  child: const Text('Reddet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemGreen),
                  child: const Text('Onayla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
