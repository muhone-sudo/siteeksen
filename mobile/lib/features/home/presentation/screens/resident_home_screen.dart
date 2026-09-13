// Sakin Ana Sayfa Ekranı
//
// NEDEN YENİDEN YAZILDI (2026-09-13, todo 0.C.2/0.C.4):
// Önceki sürüm tamamen uydurmaydı ve kullanıcıya yanlış bilgi veriyordu:
//   - Her kullanıcıya "Merhaba, Ahmet!" diyordu (isim koda gömülüydü).
//   - Bakiye sabit ₺1.250,00 ve "Borçlu" rozeti gösteriyordu.
//   - Bildirimler, açık talep sayısı, kargo sayısı, araç sayısı sabitti.
//   - Hızlı işlem ve hizmet kartlarının `onTap`'ları BOŞTU — dokunmak hiçbir şey yapmıyordu.
//
// Bu sürüm gerçek API'yi kullanır; veri alınamazsa uydurma değer göstermek yerine
// durumu açıkça bildirir ve yeniden denemeyi teklif eder.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  bool _loading = true;
  String? _loadError;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _debt;

  /// Duyuru modülü henüz sunucuda kalıcı değil (501). Uydurma duyuru göstermek
  /// yerine durumu ayrı tutuyoruz.
  List<Map<String, dynamic>>? _announcements;
  String? _announcementsError;
  bool _announcementsNotImplemented = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = await apiClient.getCurrentUser();
      Map<String, dynamic>? debt;
      try {
        debt = await apiClient.getDebtStatus();
      } catch (_) {
        // Borç bilgisi alınamazsa ana sayfa yine açılır; kart "—" gösterir.
        debt = null;
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _debt = debt;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = toUserMessage(e);
        _loading = false;
      });
      return;
    }

    // Duyurular ayrı yüklenir; başarısız olması ana sayfayı kapatmaz.
    try {
      final list = await apiClient.getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements =
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcementsNotImplemented = isNotImplemented(e);
        _announcementsError = toUserMessage(e);
      });
    }
  }

  String get _displayName {
    final first = (_user?['first_name'] as String?)?.trim() ?? '';
    final last = (_user?['last_name'] as String?)?.trim() ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    return full.isEmpty ? 'Sakin' : full;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppleTheme.background,
        body: LoadingView(),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppleTheme.background,
        body: ErrorStateView(message: _loadError!, onRetry: _load),
      );
    }

    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildGreeting(),
              _buildBalanceCard(),
              _buildPayButton(),
              const SectionTitle(title: 'Hızlı İşlemler'),
              _buildQuickActions(),
              const SectionTitle(title: 'Hizmetler'),
              _buildServices(),
              const SectionTitle(title: 'Son Duyurular'),
              _buildAnnouncements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final initial = _displayName.characters.first;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppleTheme.systemBlue.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppleTheme.systemBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, ${_displayName.split(' ').first}!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5),
                ),
                Text(
                  (_user?['email'] as String?) ?? (_user?['phone'] as String?) ?? '',
                  style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_rounded, size: 28),
            tooltip: 'Duyurular',
            onPressed: () => context.pushNamed('announcements'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = (_debt?['current_balance'] as num?)?.toDouble();
    final hasDebt = (_debt?['has_debt'] as bool?) ?? false;
    final nextDue = _debt?['next_due_date'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BalanceCard(
        title: 'Bakiyeniz',
        // Veri yoksa uydurma rakam değil, "—" gösterilir.
        amount: balance == null ? '—' : formatTry(balance),
        subtitle: balance == null
            ? 'Borç bilgisi alınamadı'
            : (nextDue == null || formatDate(nextDue) == '—'
                ? 'Yaklaşan ödeme yok'
                : 'Son ödeme tarihi: ${formatDate(nextDue)}'),
        amountColor: balance == null
            ? AppleTheme.secondaryLabel
            : (hasDebt ? AppleTheme.systemRed : AppleTheme.systemGreen),
        action: balance == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (hasDebt ? AppleTheme.systemRed : AppleTheme.systemGreen)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'Borçlu' : 'Güncel',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDebt
                          ? AppleTheme.systemRed
                          : AppleTheme.systemGreen),
                ),
              ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.pushNamed('duesPayment'),
          icon: const Icon(Icons.credit_card_rounded),
          label: const Text('Aidat Öde'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: AppleTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          QuickActionButton(
            icon: Icons.person_add_rounded,
            label: 'Ziyaretçi',
            color: AppleTheme.systemBlue,
            onTap: () => context.pushNamed('visitorPreregister'),
          ),
          QuickActionButton(
            icon: Icons.event_rounded,
            label: 'Rezervasyon',
            color: AppleTheme.systemGreen,
            onTap: () => context.pushNamed('createReservation'),
          ),
          QuickActionButton(
            icon: Icons.report_problem_rounded,
            label: 'Talep',
            color: AppleTheme.systemOrange,
            onTap: () => context.pushNamed('createRequest'),
          ),
          QuickActionButton(
            icon: Icons.poll_rounded,
            label: 'Anket',
            color: AppleTheme.systemPurple,
            onTap: () => context.pushNamed('surveys'),
          ),
        ],
      ),
    );
  }

  Widget _buildServices() {
    // Alt başlıklarda sayı göstermiyoruz: bu sayılar önceden sabitti
    // ("2 açık", "1 bekliyor") ve gerçek veriyle hiç ilgisi yoktu.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ServiceCard(
            icon: Icons.request_page_rounded,
            title: 'Taleplerim',
            subtitle: 'Aç ve takip et',
            color: AppleTheme.systemOrange,
            onTap: () => context.goNamed('requests'),
          ),
          ServiceCard(
            icon: Icons.inventory_2_rounded,
            title: 'Kargolarım',
            subtitle: 'Teslim durumu',
            color: AppleTheme.systemGreen,
            onTap: () => context.pushNamed('packages'),
          ),
          ServiceCard(
            icon: Icons.bolt_rounded,
            title: 'Tüketim',
            subtitle: 'Sayaç ve fatura',
            color: AppleTheme.systemBlue,
            onTap: () => context.pushNamed('energy'),
          ),
          ServiceCard(
            icon: Icons.folder_copy_rounded,
            title: 'Belgeler',
            subtitle: 'Site evrakları',
            color: AppleTheme.systemPurple,
            onTap: () => context.pushNamed('documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements() {
    if (_announcementsNotImplemented) {
      return const NotImplementedNotice(
        title: 'Duyurular henüz hazır değil',
        detail: 'Duyuru modülü sunucu tarafında gerçek veriye bağlanmadı.',
      );
    }
    if (_announcementsError != null) {
      return ErrorStateView(message: _announcementsError!, onRetry: _load);
    }
    if (_announcements == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: LoadingView(),
      );
    }
    if (_announcements!.isEmpty) {
      return const EmptyStateView(
        message: 'Henüz duyuru yok.',
        icon: Icons.campaign_rounded,
      );
    }

    final items = _announcements!.take(3).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppleTheme.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            NotificationCard(
              icon: Icons.campaign_rounded,
              title: (items[i]['title'] as String?) ?? 'Duyuru',
              message: (items[i]['content'] as String?) ?? '',
              time: formatDate(items[i]['created_at']),
              color: AppleTheme.systemOrange,
              onTap: () => context.pushNamed('announcements'),
            ),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 62),
                child:
                    Container(height: 0.5, color: AppleTheme.opaqueSeparator),
              ),
          ],
        ],
      ),
    );
  }
}
