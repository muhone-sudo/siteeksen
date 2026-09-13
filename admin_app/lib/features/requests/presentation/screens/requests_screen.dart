// Talep listesi ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Ekranda koda gömülü 4 sahte talep vardı ("Asansör arızası / A Blok D.5",
// "Su kaçağı / B Blok D.12" ...) ve sekme başlıkları da sabit sayı gösteriyordu
// ("Açık (2)"). Yönetici gerçekte açık olan talepleri göremediği için bu ekran
// yanıltıcıydı. Artık liste `GET /requests` ucundan gelir (community servisi bu
// ucu gerçekten veritabanından karşılar) ve sekme sayıları gelen veriden sayılır.
//
// Liste tek seferde çekilip sekmelere göre yerelde süzülür: sekme başlıklarındaki
// sayıların doğru olması için üç durumun tamamı aynı anda gereklidir.
//
// Not: Sunucu talebe ait daire ADINI döndürmüyor (yalnızca `unit_id` var), bu
// yüzden uydurma "A Blok D.5" metni yerine talep numarası (`ticket_number`)
// gösterilir.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _requests = const [];

  static const _statuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiClient.getRequests();
      if (!mounted) return;
      setState(() {
        _requests = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _byStatus(String status) =>
      _requests.where((r) => r['status'] == status).toList();

  /// Sekme başlığı: veri yüklenmeden sayı YAZILMAZ (sahte sayı göstermemek için).
  String _tabLabel(String text, String status) {
    if (_loading || _error != null) return text;
    return '$text (${_byStatus(status).length})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talepler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _tabLabel('Açık', 'OPEN')),
            Tab(text: _tabLabel('İşlemde', 'IN_PROGRESS')),
            Tab(text: _tabLabel('Çözüldü', 'RESOLVED')),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Talepler alınıyor...');
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const NotImplementedNotice(
          title: 'Talep listesi henüz hazır değil',
          detail: 'Sunucu bu listeyi henüz üretmiyor (501).',
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }
    return TabBarView(
      controller: _tabController,
      children: _statuses.map(_buildList).toList(),
    );
  }

  Widget _buildList(String status) {
    final filtered = _byStatus(status);
    if (filtered.isEmpty) {
      // "Veri yok" ile "veri alınamadı" farklı şeylerdir; buraya yalnızca
      // sunucu başarıyla yanıt verdiğinde düşülür.
      return EmptyStateView(
        message: '${_statusText(status)} durumunda talep yok.',
        icon: Icons.inbox_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final request = filtered[index];
          final id = (request['id'] ?? '').toString();
          final title = (request['title'] ?? '').toString();
          final ticket = (request['ticket_number'] ?? '').toString();
          final requestStatus = (request['status'] ?? '').toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: id.isEmpty ? null : () => context.go('/requests/$id'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          _statusColor(requestStatus).withValues(alpha: 0.1),
                      child: Icon(
                        _priorityIcon((request['priority'] ?? '').toString()),
                        color: _statusColor(requestStatus),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title.isEmpty ? '(başlıksız talep)' : title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${ticket.isEmpty ? '—' : ticket} • '
                            '${formatDate(request['created_at'])}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _statusColor(requestStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _statusText(requestStatus),
                        style: TextStyle(
                            fontSize: 11, color: _statusColor(requestStatus)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return AppTheme.warningColor;
      case 'IN_PROGRESS':
        return AppTheme.primaryColor;
      case 'RESOLVED':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'OPEN':
        return 'Açık';
      case 'IN_PROGRESS':
        return 'İşlemde';
      case 'RESOLVED':
        return 'Çözüldü';
      case 'CLOSED':
        return 'Kapandı';
      default:
        return status;
    }
  }

  /// Sunucu talep "tipi" döndürmüyor; gerçekten var olan tek sınıflandırma
  /// `priority` alanıdır, ikon ondan türetilir.
  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'URGENT':
      case 'HIGH':
        return Icons.priority_high;
      case 'LOW':
        return Icons.low_priority;
      default:
        return Icons.support_agent;
    }
  }
}
