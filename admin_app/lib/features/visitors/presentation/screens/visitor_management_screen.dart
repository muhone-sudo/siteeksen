import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Ziyaretçi Yönetim Ekranı - Apple Tarzı Minimalist Tasarım
class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;

  final List<String> _filters = ['Tümü', 'Beklenen', 'İçeride', 'Çıkış Yaptı'];

  // Mock data
  final List<Map<String, dynamic>> _visitors = [
    {
      'name': 'Ahmet Yılmaz',
      'unit': 'D.101',
      'purpose': 'Misafir',
      'status': 'expected',
      'time': '14:30',
      'phone': '0532 111 2233',
    },
    {
      'name': 'Kargo - Yurtiçi',
      'unit': 'D.205',
      'purpose': 'Kargo Teslimi',
      'status': 'inside',
      'time': '13:45',
      'phone': null,
    },
    {
      'name': 'Zeynep Kaya',
      'unit': 'D.301',
      'purpose': 'Tadilat Ustası',
      'status': 'left',
      'time': '10:20',
      'phone': '0544 222 3344',
    },
    {
      'name': 'Mehmet Demir',
      'unit': 'D.102',
      'purpose': 'Misafir',
      'status': 'inside',
      'time': '12:00',
      'phone': '0533 444 5566',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Ziyaretçiler',
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
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () {},
                tooltip: 'QR Tara',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Container(
              height: 140,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildStatCard(
                    'Bugün',
                    '12',
                    'ziyaretçi',
                    Icons.calendar_today_rounded,
                    AppleTheme.systemBlue,
                  ),
                  _buildStatCard(
                    'Beklenen',
                    '3',
                    'kişi',
                    Icons.schedule_rounded,
                    AppleTheme.systemOrange,
                  ),
                  _buildStatCard(
                    'İçeride',
                    '2',
                    'kişi',
                    Icons.location_on_rounded,
                    AppleTheme.systemGreen,
                  ),
                  _buildStatCard(
                    'Çıkış Yaptı',
                    '7',
                    'kişi',
                    Icons.check_circle_rounded,
                    AppleTheme.systemGray,
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Ziyaretçi ara...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: AppleTheme.fastAnimation,
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(_filters[index]),
                        onSelected: (selected) {
                          setState(() => _selectedFilter = index);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppleTheme.systemBlue.withOpacity(0.15),
                        checkmarkColor: AppleTheme.systemBlue,
                        labelStyle: TextStyle(
                          color: isSelected ? AppleTheme.systemBlue : AppleTheme.label,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppleTheme.systemBlue : AppleTheme.systemGray4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Section Header
          const SliverToBoxAdapter(
            child: AppleSectionHeader(title: 'Bugünkü Ziyaretçiler'),
          ),

          // Visitor List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredVisitors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final visitor = entry.value;
                  return _buildVisitorTile(
                    visitor,
                    isLast: index == _filteredVisitors.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: AppleFAB(
        icon: Icons.add_rounded,
        label: 'Ziyaretçi Ekle',
        onPressed: () => _showAddVisitorSheet(context),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredVisitors {
    final query = _searchController.text.toLowerCase();
    return _visitors.where((v) {
      final matchesSearch = query.isEmpty ||
          v['name'].toString().toLowerCase().contains(query) ||
          v['unit'].toString().toLowerCase().contains(query);

      final matchesFilter = _selectedFilter == 0 ||
          (_selectedFilter == 1 && v['status'] == 'expected') ||
          (_selectedFilter == 2 && v['status'] == 'inside') ||
          (_selectedFilter == 3 && v['status'] == 'left');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '$title $subtitle',
            style: TextStyle(
              fontSize: 13,
              color: AppleTheme.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorTile(Map<String, dynamic> visitor, {bool isLast = false}) {
    final status = visitor['status'] as String;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'expected':
        statusColor = AppleTheme.systemOrange;
        statusText = 'Bekleniyor';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'inside':
        statusColor = AppleTheme.systemGreen;
        statusText = 'İçeride';
        statusIcon = Icons.location_on_rounded;
        break;
      case 'left':
        statusColor = AppleTheme.systemGray;
        statusText = 'Çıkış Yaptı';
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = AppleTheme.systemGray;
        statusText = status;
        statusIcon = Icons.info_rounded;
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _showVisitorDetails(context, visitor),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      visitor['name'].toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppleTheme.label,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            visitor['name'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visitor['unit']} • ${visitor['purpose']}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppleTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      visitor['time'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppleTheme.secondaryLabel,
                      ),
                    ),
                    if (status == 'inside' || status == 'expected')
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppleTheme.systemGray3,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 76),
            child: Container(
              height: 0.5,
              color: AppleTheme.opaqueSeparator,
            ),
          ),
      ],
    );
  }

  void _showVisitorDetails(BuildContext context, Map<String, dynamic> visitor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitorDetailsSheet(visitor: visitor),
    );
  }

  void _showAddVisitorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddVisitorSheet(),
    );
  }
}

/// Visitor Details Bottom Sheet
class _VisitorDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const _VisitorDetailsSheet({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final status = visitor['status'] as String;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppleTheme.systemGray4,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      visitor['name'].toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visitor['unit']} • ${visitor['purpose']}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppleTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Info Items
          if (visitor['phone'] != null)
            AppleListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.phone_rounded, color: AppleTheme.systemGreen, size: 20),
              ),
              title: visitor['phone'],
              subtitle: 'Telefon',
              showChevron: false,
            ),

          AppleListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppleTheme.systemBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.access_time_rounded, color: AppleTheme.systemBlue, size: 20),
            ),
            title: visitor['time'],
            subtitle: 'Giriş Saati',
            showChevron: false,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (status == 'expected')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Giriş Yaptır'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppleTheme.systemGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (status == 'inside') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Çıkış Yaptır'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppleTheme.systemOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_rounded),
                      label: const Text('Sakine Bildir'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Add Visitor Bottom Sheet
class _AddVisitorSheet extends StatefulWidget {
  const _AddVisitorSheet();

  @override
  State<_AddVisitorSheet> createState() => _AddVisitorSheetState();
}

class _AddVisitorSheetState extends State<_AddVisitorSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGray4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const Text(
                    'Yeni Ziyaretçi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'İsim Soyisim',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Daire',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    items: ['D.101', 'D.102', 'D.201', 'D.202', 'D.301', 'D.302']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedUnit = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Ziyaret Amacı',
                      prefixIcon: Icon(Icons.info_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Ziyaretçi Kaydet'),
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
}
