// Uygulama içi bildirim gelen kutusu (`GET /notifications`).
//
// NEDEN VAR (2026-09-26): altı modül ve zamanlayıcı (gecikmiş aidat, kargo,
// rezervasyon kararı, duyuru…) sakine uygulama içi bildirim yazıyordu, ama
// mobilde bunları gösteren bir ekran yoktu — bildirimler hiç okunamıyordu.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiClient.getNotifications();
  }

  Future<void> _reload() async {
    setState(() => _future = apiClient.getNotifications());
    await _future;
  }

  static IconData iconFor(String topic) {
    if (topic.startsWith('dues')) return Icons.account_balance_wallet_outlined;
    if (topic.startsWith('package')) return Icons.local_shipping_outlined;
    if (topic.startsWith('reservation')) return Icons.event_outlined;
    if (topic.startsWith('announcement')) return Icons.campaign_outlined;
    if (topic.startsWith('survey')) return Icons.poll_outlined;
    if (topic.startsWith('visitor')) return Icons.person_outline;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimlerim')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) return ErrorStateView(message: toUserMessage(snap.error!), onRetry: _reload);
          final items = snap.data!.whereType<Map>().toList();
          if (items.isEmpty) {
            return const EmptyStateView(message: 'Henüz bildiriminiz yok', icon: Icons.notifications_none);
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                final subject = (n['subject'] as String?)?.trim();
                return ListTile(
                  leading: Icon(iconFor('${n['topic'] ?? ''}')),
                  title: Text(subject == null || subject.isEmpty ? 'Bildirim' : subject),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${n['body'] ?? ''}'),
                      const SizedBox(height: 4),
                      Text(formatDateTime(n['created_at']), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
