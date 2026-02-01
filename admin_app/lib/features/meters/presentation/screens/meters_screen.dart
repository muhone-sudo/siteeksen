import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaçlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Isı'),
            Tab(text: 'Soğuk Su'),
            Tab(text: 'Sıcak Su'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MeterList(type: 'HEAT'),
          _MeterList(type: 'WATER_COLD'),
          _MeterList(type: 'WATER_HOT'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/meters/reading'),
        icon: const Icon(Icons.edit),
        label: const Text('Okuma Gir'),
      ),
    );
  }
}

class _MeterList extends StatelessWidget {
  final String type;
  const _MeterList({required this.type});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final meters = List.generate(10, (i) => _Meter(
      id: '$i',
      unit: '${['A', 'B', 'C'][i % 3]} Blok D.${i + 1}',
      serialNumber: 'M-2024-${10000 + i}',
      lastReading: 100.0 + i * 12.5,
      lastReadDate: '28.01.2026',
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meters.length,
      itemBuilder: (context, index) {
        final meter = meters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                type == 'HEAT' ? Icons.whatshot : Icons.water_drop,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(meter.unit),
            subtitle: Text('No: ${meter.serialNumber}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${meter.lastReading}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(meter.lastReadDate, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Meter {
  final String id;
  final String unit;
  final String serialNumber;
  final double lastReading;
  final String lastReadDate;
  _Meter({required this.id, required this.unit, required this.serialNumber, required this.lastReading, required this.lastReadDate});
}
