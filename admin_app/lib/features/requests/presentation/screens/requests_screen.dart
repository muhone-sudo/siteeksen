import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _requests = [
    _Request(id: '1', title: 'Asansör arızası', type: 'MAINTENANCE', unit: 'A Blok D.5', date: '01.02.2026', status: 'OPEN'),
    _Request(id: '2', title: 'Su kaçağı', type: 'MAINTENANCE', unit: 'B Blok D.12', date: '31.01.2026', status: 'IN_PROGRESS'),
    _Request(id: '3', title: 'Otopark şikayeti', type: 'COMPLAINT', unit: 'C Blok D.3', date: '30.01.2026', status: 'OPEN'),
    _Request(id: '4', title: 'Gürültü şikayeti', type: 'COMPLAINT', unit: 'A Blok D.8', date: '29.01.2026', status: 'RESOLVED'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talepler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Açık (2)'),
            Tab(text: 'İşlemde (1)'),
            Tab(text: 'Çözüldü (1)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('OPEN'),
          _buildList('IN_PROGRESS'),
          _buildList('RESOLVED'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    final filtered = _requests.where((r) => r.status == status).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('Talep bulunamadı'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final request = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => context.go('/requests/${request.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
                    child: Icon(_getTypeIcon(request.type), color: _getStatusColor(request.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${request.unit} • ${request.date}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(request.status),
                      style: TextStyle(fontSize: 11, color: _getStatusColor(request.status)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppTheme.warningColor;
      case 'IN_PROGRESS': return AppTheme.primaryColor;
      case 'RESOLVED': return AppTheme.successColor;
      default: return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'OPEN': return 'Açık';
      case 'IN_PROGRESS': return 'İşlemde';
      case 'RESOLVED': return 'Çözüldü';
      default: return status;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'MAINTENANCE': return Icons.build;
      case 'COMPLAINT': return Icons.report_problem;
      case 'SUGGESTION': return Icons.lightbulb;
      default: return Icons.help;
    }
  }
}

class _Request {
  final String id;
  final String title;
  final String type;
  final String unit;
  final String date;
  final String status;
  _Request({required this.id, required this.title, required this.type, required this.unit, required this.date, required this.status});
}
