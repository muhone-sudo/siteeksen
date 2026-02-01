import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';

  // Mock data
  final List<_Resident> _residents = [
    _Resident(id: '1', name: 'Ahmet Yılmaz', unit: 'A Blok D.12', phone: '0532 123 4567', balance: 850, status: 'ACTIVE'),
    _Resident(id: '2', name: 'Ayşe Kaya', unit: 'B Blok D.5', phone: '0533 234 5678', balance: -1200, status: 'ACTIVE'),
    _Resident(id: '3', name: 'Mehmet Demir', unit: 'A Blok D.8', phone: '0534 345 6789', balance: 0, status: 'ACTIVE'),
    _Resident(id: '4', name: 'Fatma Çelik', unit: 'C Blok D.3', phone: '0535 456 7890', balance: -2500, status: 'ACTIVE'),
    _Resident(id: '5', name: 'Ali Şahin', unit: 'B Blok D.15', phone: '0536 567 8901', balance: 920, status: 'INACTIVE'),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: Column(
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
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(label: 'Toplam', value: '124', color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                _StatChip(label: 'Aktif', value: '118', color: AppTheme.successColor),
                const SizedBox(width: 8),
                _StatChip(label: 'Borçlu', value: '23', color: AppTheme.errorColor),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _residents.length,
              itemBuilder: (context, index) {
                final resident = _residents[index];
                return _ResidentCard(
                  resident: resident,
                  onTap: () => context.go('/residents/${resident.id}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/residents/add'),
        icon: const Icon(Icons.add),
        label: const Text('Sakin Ekle'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Tümü'), selected: _filterStatus == 'all', onSelected: (_) => setState(() => _filterStatus = 'all')),
                ChoiceChip(label: const Text('Aktif'), selected: _filterStatus == 'active', onSelected: (_) => setState(() => _filterStatus = 'active')),
                ChoiceChip(label: const Text('Borçlu'), selected: _filterStatus == 'debt', onSelected: (_) => setState(() => _filterStatus = 'debt')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Uygula'),
              ),
            ),
          ],
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
  final _Resident resident;
  final VoidCallback onTap;

  const _ResidentCard({required this.resident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDebt = resident.balance < 0;
    
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
                backgroundColor: hasDebt ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  resident.name.substring(0, 1),
                  style: TextStyle(color: hasDebt ? AppTheme.errorColor : AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resident.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(resident.unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    resident.balance >= 0 ? '₺${resident.balance}' : '-₺${resident.balance.abs()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasDebt ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  ),
                  Text(
                    hasDebt ? 'Borçlu' : 'Güncel',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasDebt ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  ),
                ],
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

class _Resident {
  final String id;
  final String name;
  final String unit;
  final String phone;
  final double balance;
  final String status;

  _Resident({
    required this.id,
    required this.name,
    required this.unit,
    required this.phone,
    required this.balance,
    required this.status,
  });
}
