import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  String _selectedType = 'HEAT';
  final List<_ReadingEntry> _entries = List.generate(10, (i) => _ReadingEntry(
    unit: '${['A', 'B', 'C'][i % 3]} Blok D.${i + 1}',
    serialNumber: 'M-2024-${10000 + i}',
    lastReading: 100.0 + i * 12.5,
    newReading: null,
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaç Okuma'),
        actions: [
          TextButton.icon(
            onPressed: _saveReadings,
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'HEAT', label: Text('Isı')),
                      ButtonSegment(value: 'WATER_COLD', label: Text('Soğuk Su')),
                      ButtonSegment(value: 'WATER_HOT', label: Text('Sıcak Su')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (v) => setState(() => _selectedType = v.first),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_entries.where((e) => e.newReading != null).length}/${_entries.length} girildi'),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _entries.where((e) => e.newReading != null).length / _entries.length,
                    backgroundColor: AppTheme.borderColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Readings list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.unit, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Son: ${entry.lastReading}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Yeni',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => entry.newReading = double.tryParse(v),
                          ),
                        ),
                        if (entry.newReading != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle, color: AppTheme.successColor),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _saveReadings() {
    final filled = _entries.where((e) => e.newReading != null).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydet'),
        content: Text('$filled okuma kaydedilecek. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Okumalar kaydedildi'), backgroundColor: Colors.green),
              );
              context.pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _ReadingEntry {
  final String unit;
  final String serialNumber;
  final double lastReading;
  double? newReading;
  _ReadingEntry({required this.unit, required this.serialNumber, required this.lastReading, this.newReading});
}
