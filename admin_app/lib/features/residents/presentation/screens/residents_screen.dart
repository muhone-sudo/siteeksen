import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

const Map<String, String> _roleLabels = {
  'OWNER': 'Ev Sahibi',
  'TENANT': 'Kiracı',
  'PROXY': 'Vekil',
};

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  final _searchController = TextEditingController();
  String _filterRole = 'all';
  bool _isLoading = true;
  List<dynamic> _residents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiClient.getResidents(
        search: _searchController.text.trim(),
        role: _filterRole == 'all' ? null : _filterRole,
      );
      if (!mounted) return;
      setState(() {
        _residents = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sakinler yüklenemedi, lütfen tekrar deneyin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _residents.where((r) => r['is_active'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakinler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Sakin ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _load();
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _load(),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatChip(label: 'Toplam', value: '${_residents.length}', color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Aktif', value: '$activeCount', color: AppTheme.successColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _residents.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('Sakin bulunamadı', style: TextStyle(color: AppTheme.textSecondary))),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _residents.length,
                          itemBuilder: (context, index) {
                            final resident = _residents[index] as Map<String, dynamic>;
                            return _ResidentCard(
                              resident: resident,
                              onTap: () => context.push('/residents/${resident['id']}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push('/residents/add');
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Sakin Ekle'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Göre Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Tümü'), selected: _filterRole == 'all', onSelected: (_) => setSheetState(() => _filterRole = 'all')),
                  ..._roleLabels.entries.map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _filterRole == e.key,
                        onSelected: (_) => setSheetState(() => _filterRole = e.key),
                      )),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final Map<String, dynamic> resident;
  final VoidCallback onTap;

  const _ResidentCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = '${resident['first_name'] ?? ''} ${resident['last_name'] ?? ''}'.trim();
    final isActive = resident['is_active'] == true;
    final role = _roleLabels[resident['role']] ?? resident['role']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1) : '?',
                  style: const TextStyle(color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${resident['unit'] ?? ''} • $role', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppTheme.successColor : AppTheme.textSecondary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(fontSize: 11, color: isActive ? AppTheme.successColor : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
