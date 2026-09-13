// Genel Kurul (Toplantı) Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Ekran, koda gömülü sahte toplantı kayıtları ve hiçbir yere kaydetmeyen bir
// "sihirbaz" akışı içeriyordu; son adımda ağ çağrısı yapılmadan "toplantı
// oluşturuldu" deniyordu. Genel kurul, KMK m.29-33 kapsamında hukuki sonuç
// doğuran bir süreçtir; sistemin var olmayan bir toplantıyı varmış gibi
// göstermesi kabul edilemez.
//
// Artık toplantılar gerçek `governance` servisinden okunur. Bu servis çağrı
// süresini (15 gün), nisabı (sayı VE arsa payı) ve vekâlet sınırlarını
// uygulayan tek yerdir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class MeetingWizardScreen extends StatefulWidget {
  const MeetingWizardScreen({super.key});

  @override
  State<MeetingWizardScreen> createState() => _MeetingWizardScreenState();
}

class _MeetingWizardScreenState extends State<MeetingWizardScreen> {
  bool _loading = true;
  String? _error;
  bool _notImplemented = false;
  List<Map<String, dynamic>> _meetings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notImplemented = false;
    });
    try {
      final list = await apiClient.getMeetings();
      if (!mounted) return;
      setState(() {
        _meetings =
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notImplemented = isNotImplemented(e);
        _error = toUserMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('Genel Kurul'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'Toplantı yönetimi bu uygulamada henüz açık değil',
          detail: 'Genel kurul süreçleri (çağrı, hazirun, vekâlet, nisap, oylama, '
              'karar defteri) sunucuda hazır; mobil arayüzü henüz bağlanmadı. '
              'Bu işlemler şimdilik yönetim panelinden yürütülmelidir.',
        ),
      );
    }
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);
    if (_meetings.isEmpty) {
      return const EmptyStateView(
        message: 'Planlanmış genel kurul yok.',
        icon: Icons.groups_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _meetings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _meetingCard(_meetings[i]),
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> m) {
    final status = (m['status'] ?? 'PLANNED').toString();
    final kind = (m['kind'] ?? m['type'] ?? '').toString();
    final quorumMet = m['quorum_met'];

    final (label, color) = switch (status) {
      'HELD' => ('Yapıldı', AppleTheme.systemGreen),
      'NOTIFIED' => ('Çağrı yapıldı', AppleTheme.systemBlue),
      'CANCELLED' => ('İptal', AppleTheme.systemRed),
      _ => ('Planlandı', AppleTheme.systemOrange),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kind == 'EXTRAORDINARY' ? 'Olağanüstü Genel Kurul' : 'Olağan Genel Kurul',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tarih: ${formatDateTime(m['scheduled_at'])}',
              style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
          if ((m['location'] ?? '').toString().isNotEmpty)
            Text('Yer: ${m['location']}',
                style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
          if (m['call_number'] != null)
            Text('${m['call_number']}. toplantı',
                style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
          if (quorumMet != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  quorumMet == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: quorumMet == true ? AppleTheme.systemGreen : AppleTheme.systemRed,
                ),
                const SizedBox(width: 6),
                Text(
                  quorumMet == true
                      ? 'Yeter sayı sağlandı (KMK m.30)'
                      : 'Yeter sayı sağlanmadı (KMK m.30)',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
