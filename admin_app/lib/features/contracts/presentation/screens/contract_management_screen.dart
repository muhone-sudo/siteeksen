// Sözleşme ve belge yönetimi.
//
// NEDEN DEĞİŞTİ (2026-09-13):
// Ekran iki uydurma firma sözleşmesi (ABC Güvenlik ₺45.000/ay, Asansör Teknik
// ₺8.500/ay), beş uydurma genel belge ve dört uydurma sakin belgesi (gerçek kişi
// adı taşıyan "Ahmet Yılmaz – A-12" gibi kayıtlar) gösteriyordu. Üstelik "Yükle" ve
// "Sil" düğmeleri hiçbir istek göndermeden "Belge başarıyla yüklendi" / "Belge silindi"
// diyordu; yönetici var olmayan belgeleri kayıtlı sanabilirdi.
//
// Artık firma sözleşmeleri `apiClient.getContracts()` ile alınıyor, yeni sözleşme
// `apiClient.createContract()` ile gönderiliyor ve başarı mesajı yalnızca sunucu
// isteği kabul ettiğinde gösteriliyor. Belge arşivi (genel/sakin belgeleri) için
// sunucuda bir uç bulunmadığından o sekmeler uydurma kayıt yerine
// `NotImplementedNotice` gösterir.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

/// Sözleşme ve Belge Yönetim Ekranı
class ContractManagementScreen extends StatefulWidget {
  const ContractManagementScreen({super.key});

  @override
  State<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends State<ContractManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Tab kategorileri (görsel tasarım korunuyor).
  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Firma Sözleşmeleri', 'icon': Icons.business_rounded},
    {'name': 'Genel Belgeler', 'icon': Icons.folder_shared_rounded},
    {'name': 'Sakin Belgeleri', 'icon': Icons.person_rounded},
  ];

  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _contracts = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await apiClient.getContracts();
      if (!mounted) return;
      setState(() {
        _contracts =
            rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  /// Arama kutusu artık gerçekten süzüyor (önce hiçbir etkisi yoktu).
  List<Map<String, dynamic>> get _visibleContracts {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _contracts;
    return _contracts.where((c) {
      final title = (_contractTitle(c)).toLowerCase();
      final vendor = (_contractVendor(c) ?? '').toLowerCase();
      return title.contains(q) || vendor.contains(q);
    }).toList();
  }

  bool get _hasContractData => !_loading && _error == null;

  @override
  Widget build(BuildContext context) {
    final onContractsTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sözleşme & Belgeler',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                          SizedBox(height: 4),
                          Text('Firma sözleşmelerini yönetin',
                              style: TextStyle(
                                  fontSize: 15, color: AppleTheme.secondaryLabel)),
                        ],
                      ),
                    ),
                    // Yalnızca gerçek bir uç bulunan sekmede işlem düğmesi gösterilir.
                    if (onContractsTab)
                      ElevatedButton.icon(
                        onPressed: _showCreateContractSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ekle'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppleTheme.systemBlue),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppleTheme.systemGray6,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppleTheme.label,
                unselectedLabelColor: AppleTheme.secondaryLabel,
                dividerColor: Colors.transparent,
                tabs: _tabs
                    .map((tab) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab['icon'] as IconData, size: 16),
                              const SizedBox(width: 6),
                              Text(tab['name'] as String,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          if (onContractsTab) ...[
            // Stats — sabit değil, yüklenen gerçek sözleşmelerden hesaplanır.
            SliverToBoxAdapter(
              child: Container(
                height: 90,
                margin: const EdgeInsets.only(top: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _buildContractStats(),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: AppleSearchBar(
                controller: _searchController,
                placeholder: 'Sözleşme ara...',
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
            ),
          ],

          _buildTabContent(),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<Widget> _buildContractStats() {
    if (!_hasContractData) {
      return [
        _buildMiniStat('Aktif', '—', Icons.description_rounded, AppleTheme.systemBlue),
        _buildMiniStat('Yaklaşan', '—', Icons.warning_rounded, AppleTheme.systemOrange),
        _buildMiniStat(
            'Aylık', '—', Icons.monetization_on_rounded, AppleTheme.systemGreen),
      ];
    }

    final active = _contracts.where((c) {
      final status = (_text(c, const ['status']) ?? 'ACTIVE').toUpperCase();
      return status == 'ACTIVE' || status == 'AKTIF';
    }).length;
    final expiring = _contracts.where((c) {
      final days = _daysRemaining(c);
      return days != null && days >= 0 && days < 60;
    }).length;
    final monthly = _contracts.fold<double>(
        0, (sum, c) => sum + (_monthlyAmount(c) ?? 0));

    return [
      _buildMiniStat(
          'Aktif', '$active', Icons.description_rounded, AppleTheme.systemBlue),
      _buildMiniStat(
          'Yaklaşan', '$expiring', Icons.warning_rounded, AppleTheme.systemOrange),
      _buildMiniStat('Aylık', formatTry(monthly), Icons.monetization_on_rounded,
          AppleTheme.systemGreen),
    ];
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildContractsList();
      case 1:
        // Genel belge arşivi için sunucuda uç yok; uydurma belge listesi kaldırıldı.
        return const SliverToBoxAdapter(
          child: NotImplementedNotice(
            title: 'Genel belge arşivi henüz hazır değil',
            detail:
                'Site belgelerinin (yönetim planı, KVKK metni, site kuralları) yüklenip '
                'listeleneceği sunucu ucu bulunmuyor. Hazır olduğunda belgeler burada listelenecek.',
          ),
        );
      case 2:
        return const SliverToBoxAdapter(
          child: NotImplementedNotice(
            title: 'Sakine özel belgeler henüz hazır değil',
            detail:
                'Sakin bazlı belge arşivi (teslim tutanağı, kira sözleşmesi, tapu) için '
                'sunucu ucu bulunmuyor. Bu sekmede kişisel veri gösterilmeden önce '
                'yetkilendirme de kurulmalıdır.',
          ),
        );
      default:
        return const SliverToBoxAdapter(child: SizedBox());
    }
  }

  // =============================================
  // FİRMA SÖZLEŞMELERİ
  // =============================================
  Widget _buildContractsList() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
            height: 220, child: LoadingView(message: 'Sözleşmeler alınıyor...')),
      );
    }

    if (_error != null && isNotImplemented(_error!)) {
      return const SliverToBoxAdapter(
        child: NotImplementedNotice(
          title: 'Sözleşme listesi henüz hazır değil',
          detail:
              'Sözleşme servisi veri katmanına bağlanmadığı için kayıt döndürmüyor.',
        ),
      );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 260,
          child: ErrorStateView(message: toUserMessage(_error!), onRetry: _load),
        ),
      );
    }

    final items = _visibleContracts;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: EmptyStateView(
            message: _contracts.isEmpty
                ? 'Kayıtlı firma sözleşmesi yok.'
                : 'Aramanıza uyan sözleşme yok.',
            icon: Icons.description_rounded,
          ),
        ),
      );
    }

    final expiringCount = items.where((c) {
      final days = _daysRemaining(c);
      return days != null && days >= 0 && days < 60;
    }).length;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            if (expiringCount == 0) return const SizedBox();
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppleTheme.systemOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppleTheme.systemOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: AppleTheme.systemOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yenileme Uyarısı',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppleTheme.systemOrange)),
                        Text('$expiringCount sözleşmenin bitiş tarihi yaklaşıyor',
                            style: TextStyle(
                                fontSize: 13, color: AppleTheme.secondaryLabel)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildContractCard(items[index - 1]);
        },
        childCount: items.length + 1,
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final days = _daysRemaining(contract);
    final isExpiringSoon = days != null && days >= 0 && days < 60;
    final amount = _monthlyAmount(contract);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppleTheme.cardDecoration,
      child: InkWell(
        onTap: () => _showContractDetails(contract),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_contractTitle(contract),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  if (isExpiringSoon)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$days gün',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppleTheme.systemOrange)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_contractVendor(contract) ?? 'Firma belirtilmemiş',
                  style:
                      TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppleTheme.tertiaryLabel),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${formatDate(contract['start_date'] ?? contract['startDate'])}'
                      ' - '
                      '${formatDate(contract['end_date'] ?? contract['endDate'])}',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.tertiaryLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(amount == null ? '—' : '${formatTry(amount)}/ay',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  // =============================================
  // YENİ SÖZLEŞME
  // =============================================
  void _showCreateContractSheet() {
    final titleController = TextEditingController();
    final vendorController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'service';
    DateTime? startDate;
    DateTime? endDate;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                      color: AppleTheme.systemGray4,
                      borderRadius: BorderRadius.circular(2.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('İptal')),
                      const Text('Yeni Sözleşme',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final vendor = vendorController.text.trim();
                                if (title.isEmpty || vendor.isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Başlık ve firma adı zorunludur.')),
                                  );
                                  return;
                                }
                                setSheetState(() => saving = true);
                                final ok = await _submitContract(
                                  title: title,
                                  vendor: vendor,
                                  type: selectedType,
                                  startDate: startDate,
                                  endDate: endDate,
                                  amountText: amountController.text,
                                );
                                if (!sheetContext.mounted) return;
                                setSheetState(() => saving = false);
                                if (ok) Navigator.pop(sheetContext);
                              },
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const Text('Sözleşme Başlığı',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'Örn. Asansör bakım sözleşmesi',
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Firma',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: vendorController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'Hizmet alınan firmanın unvanı',
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Tür',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final entry in const {
                            'service': 'Hizmet',
                            'maintenance': 'Bakım',
                            'supply': 'Tedarik',
                            'other': 'Diğer',
                          }.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected: selectedType == entry.key,
                              onSelected: (_) =>
                                  setSheetState(() => selectedType = entry.key),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Süre',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await _pickDate(
                                    sheetContext, startDate ?? DateTime.now());
                                if (picked != null) {
                                  setSheetState(() => startDate = picked);
                                }
                              },
                              child: Text(startDate == null
                                  ? 'Başlangıç'
                                  : formatDate(startDate)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await _pickDate(sheetContext,
                                    endDate ?? startDate ?? DateTime.now());
                                if (picked != null) {
                                  setSheetState(() => endDate = picked);
                                }
                              },
                              child: Text(
                                  endDate == null ? 'Bitiş' : formatDate(endDate)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Aylık Tutar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixText: '₺ ',
                          hintText: '0,00',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      vendorController.dispose();
      amountController.dispose();
    });
  }

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime initial) {
    return showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
  }

  /// Sunucu isteği kabul ederse `true` döner. Başarı mesajı yalnızca o zaman
  /// gösterilir — 501/4xx durumunda kullanıcıya gerçek neden söylenir.
  Future<bool> _submitContract({
    required String title,
    required String vendor,
    required String type,
    required DateTime? startDate,
    required DateTime? endDate,
    required String amountText,
  }) async {
    final amount = double.tryParse(amountText.trim().replaceAll(',', '.'));
    try {
      await apiClient.createContract({
        'title': title,
        'vendor': vendor,
        'type': type,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T').first,
        if (amount != null) 'monthly_amount': amount,
      });
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Sözleşme kaydedildi'),
            backgroundColor: AppleTheme.systemGreen),
      );
      await _load();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Kaydedilemedi: ${toUserMessage(e)}'),
            backgroundColor: AppleTheme.systemRed),
      );
      return false;
    }
  }

  void _showContractDetails(Map<String, dynamic> contract) {
    final days = _daysRemaining(contract);
    final amount = _monthlyAmount(contract);
    final contractNo =
        _text(contract, const ['contract_no', 'contract_number', 'code', 'id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                    color: AppleTheme.systemGray4,
                    borderRadius: BorderRadius.circular(2.5))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_contractTitle(contract),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_contractVendor(contract) ?? 'Firma belirtilmemiş',
                      style: TextStyle(
                          fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 24),
                  if (contractNo != null)
                    _buildInfoRow(
                        Icons.tag_rounded, 'Sözleşme No', contractNo),
                  _buildInfoRow(Icons.play_arrow_rounded, 'Başlangıç',
                      formatDate(contract['start_date'] ?? contract['startDate'])),
                  _buildInfoRow(Icons.stop_rounded, 'Bitiş',
                      formatDate(contract['end_date'] ?? contract['endDate'])),
                  _buildInfoRow(Icons.monetization_on_rounded, 'Aylık Tutar',
                      amount == null ? '—' : formatTry(amount)),
                  if (days != null)
                    _buildInfoRow(
                        Icons.schedule_rounded, 'Kalan Süre', '$days gün'),
                  // NOT: "PDF İndir" / "Yenile" düğmeleri kaldırıldı — karşılığı olan
                  // bir sunucu ucu yok, hiçbir şey yapmayan düğme bırakılmaz.
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppleTheme.secondaryLabel),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

String _contractTitle(Map<String, dynamic> c) =>
    _text(c, const ['title', 'name', 'subject']) ?? 'Başlıksız sözleşme';

String? _contractVendor(Map<String, dynamic> c) =>
    _text(c, const ['vendor', 'vendor_name', 'company', 'company_name', 'counterparty']);

double? _monthlyAmount(Map<String, dynamic> c) =>
    _number(c, const ['monthly_amount', 'monthly_value', 'amount', 'monthlyValue']);

/// Kalan gün sunucudan gelen bitiş tarihinden hesaplanır; sabit "334 gün" gibi
/// uydurma değerler kullanılmaz. Bitiş tarihi yoksa `null` döner.
int? _daysRemaining(Map<String, dynamic> c) {
  final raw = c['end_date'] ?? c['endDate'] ?? c['expires_at'];
  if (raw is! String || raw.isEmpty || raw.startsWith('0001-01-01')) return null;
  final end = DateTime.tryParse(raw);
  if (end == null) return null;
  final now = DateTime.now();
  return end.difference(DateTime(now.year, now.month, now.day)).inDays;
}

String? _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

double? _number(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
