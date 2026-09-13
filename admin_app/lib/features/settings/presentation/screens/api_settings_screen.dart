// API Anahtarları Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13, todo 0.C.5):
//
// Önceki sürüm iki ayrı yalan söylüyordu:
//
//  1. UYDURMA YAPILANDIRMA: Ekranda WhatsApp, Netgsm, Ziraat, Garanti BBVA, iyzico,
//     OpenAI ve Firebase için "aktif", "test başarılı", "2 saat önce güncellendi"
//     yazan 7 kayıt koda gömülüydü. Yönetici bu entegrasyonların kurulu olduğunu
//     sanıyordu; oysa hiçbiri yoktu. Bir yöneticinin "SMS gönderimi çalışıyor"
//     sanıp hatırlatma göndermemesi doğrudan tahsilat kaybıdır.
//
//  2. YANLIŞ GÜVENLİK GÜVENCESİ: "Bu sayfadaki bilgiler şifrelenmiş olarak saklanır.
//     Her değişiklik kayıt altındadır." deniyordu. Denetimde `pkg/encryption`'ın
//     hiçbir yerden import edilmediği tespit edildi; ekranın tamamı da mock'tu.
//     Karşılığı olmayan güvenlik taahhüdü, kullanıcının gereğinden fazla risk
//     almasına yol açar.
//
// Bu sürüm: kayıtlar gerçek API'den gelir; sunucu henüz hazır değilse bunu
// açıkça söyler; güvenlik notu yalnızca gerçekten sağlanan şeyi anlatır.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_state.dart';

class APISettingsScreen extends StatefulWidget {
  const APISettingsScreen({super.key});

  @override
  State<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends State<APISettingsScreen>
    with SingleTickerProviderStateMixin {
  static const _categories = [
    (id: 'messaging', name: 'Mesajlaşma', icon: Icons.chat_bubble_rounded),
    (id: 'banking', name: 'Banka', icon: Icons.account_balance_rounded),
    (id: 'payment', name: 'Ödeme', icon: Icons.payment_rounded),
    (id: 'ai', name: 'Yapay Zeka', icon: Icons.psychology_rounded),
    (id: 'push', name: 'Bildirim', icon: Icons.notifications_rounded),
  ];

  late final TabController _tabController;

  bool _loading = true;
  String? _error;
  bool _notImplemented = false;
  List<Map<String, dynamic>> _credentials = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
      _notImplemented = false;
    });
    try {
      final list = await apiClient.getCredentials();
      if (!mounted) return;
      setState(() {
        _credentials =
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

  List<Map<String, dynamic>> _byCategory(String categoryId) => _credentials
      .where((c) => (c['category'] ?? c['service_category']) == categoryId)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.background,
      appBar: AppBar(
        title: const Text('API Anahtarları'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final c in _categories) Tab(icon: Icon(c.icon), text: c.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSecurityNotice(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Güvenlik notu — YALNIZCA gerçekten sağlanan şeyi anlatır.
  Widget _buildSecurityNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppleTheme.systemOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppleTheme.systemOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppleTheme.systemOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anahtar saklama henüz şifrelenmiş değil',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Bu ekrandan girilen anahtarlar sunucuda saklanır ancak alan bazlı '
                  'şifreleme henüz devrede değildir. Üretim ortamında kullanmadan önce '
                  'anahtarları bir sır yöneticisinde (secret manager) tutmanız önerilir.',
                  style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_notImplemented) {
      return const SingleChildScrollView(
        child: NotImplementedNotice(
          title: 'API anahtarı yönetimi henüz hazır değil',
          detail: 'Bu modül sunucu tarafında gerçek veri katmanına bağlanmadı. '
              'Entegrasyon anahtarları şimdilik ortam değişkenleriyle verilmelidir.',
        ),
      );
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        for (final c in _categories) _buildCategoryList(c.id, c.name),
      ],
    );
  }

  Widget _buildCategoryList(String categoryId, String categoryName) {
    final items = _byCategory(categoryId);
    if (items.isEmpty) {
      return EmptyStateView(
        message: '$categoryName kategorisinde tanımlı bir anahtar yok.',
        icon: Icons.vpn_key_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CredentialCard(
          data: items[i],
          onDelete: () => _delete(items[i]),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is! String) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anahtarı sil'),
        content: Text('${item['display_name'] ?? item['service_name'] ?? 'Bu kayıt'} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemRed),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.deleteCredential(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anahtar silindi')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      // Sunucu silmediyse "silindi" DENMEZ.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: ${toUserMessage(e)}')),
      );
    }
  }
}

class _CredentialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _CredentialCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = data['is_active'] == true;
    final name = (data['display_name'] ?? data['service_name'] ?? 'Bilinmeyen servis').toString();
    final masked = (data['api_key_masked'] ?? '').toString();
    final updated = data['updated_at'] ?? data['last_modified'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppleTheme.systemGreen : AppleTheme.systemGray)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppleTheme.systemGreen : AppleTheme.systemGray,
                  ),
                ),
              ),
            ],
          ),
          if (masked.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(masked, style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  updated == null ? 'Son güncelleme bilinmiyor' : 'Güncellendi: ${formatDateTime(updated)}',
                  style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppleTheme.systemRed),
                tooltip: 'Sil',
                onPressed: onDelete,
              ),
            ],
          ),
          // Anahtarın kendisini gösterme özelliği BİLEREK yok: sunucuda böyle bir uç
          // bulunmuyor ve bulunsa bile anahtarın ekrana basılması güvenlik açığıdır.
        ],
      ),
    );
  }
}
