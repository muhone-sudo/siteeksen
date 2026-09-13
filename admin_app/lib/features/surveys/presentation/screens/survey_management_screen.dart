// Anket / oylama yönetim ekranı.
//
// NE DEĞİŞTİ VE NEDEN (2026-09-13):
// Ekran tamamen uydurma veri gösteriyordu: 3 sabit anket ("Otopark Düzenlemesi",
// "Site İçi Hız Limiti", "Memnuniyet Anketi 2026"), sabit katılım sayıları
// (45/120, 78/120, 95/120) ve tamamen sabit üst istatistikler ("Aktif 2",
// "Katılım %62", "Tamamlanan 8"). Yönetici bu sayılara bakarak "oylama
// tamamlandı / yeter sayı sağlandı" kararı verebilir; KMK'ya göre karar
// yeter sayısı hesabı buna dayandığı için bu doğrudan hukuki risk üretir.
//
// Artık liste `GET /surveys`, sonuçlar `GET /surveys/{id}/results` ve oluşturma
// `POST /surveys` uçlarından gelir. Survey servisi bu uçları henüz gerçek veri
// katmanına bağlamadığı için bugün 501 döner; bu durumda satır üretmek yerine
// `NotImplementedNotice` gösterilir.
//
// Kaldırılanlar:
//   * `_surveys` sabit listesi ve sabit istatistik kartları,
//   * "Geçmiş" başlık düğmesi (`onAction` verilmemişti, basınca hiçbir şey olmuyordu),
//   * detay sayfasındaki "Sonuçları Görüntüle" düğmesi (yalnızca sayfayı kapatıyordu)
//     — yerine sonuçlar doğrudan sunucudan çekilip gösteriliyor,
//   * oluşturma formundaki "Oluştur" düğmesi (kaydetmeden kapatıyordu).
//
// Sunucu sözleşmesi (backend/services/survey/main.go): `POST /surveys` en az 2
// seçenek ister (`options` binding:"required,min=2"), bu yüzden form seçenek
// alanlarını zorunlu tutar.

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/apple_widgets.dart';
import '../../../../core/widgets/data_state.dart';

/// Anket/Oylama Yönetim Ekranı - Apple Tarzı
class SurveyManagementScreen extends StatefulWidget {
  const SurveyManagementScreen({super.key});

  @override
  State<SurveyManagementScreen> createState() => _SurveyManagementScreenState();
}

class _SurveyManagementScreenState extends State<SurveyManagementScreen> {
  /// Sunucudaki `survey_type` değerleri. Sekme 0 oylamaları, sekme 1 anketleri
  /// gösterir; sınıflandırma sunucu alanına göre yapılır, isme göre değil.
  static const Set<String> _pollTypes = {'POLL', 'VOTE'};

  int _selectedTab = 0;
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _surveys = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiClient.getSurveys();
      if (!mounted) return;
      setState(() {
        _surveys = data
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

  List<Map<String, dynamic>> get _filteredSurveys {
    return _surveys.where((s) {
      final type = _str(s['survey_type']).toUpperCase();
      final isPoll = _pollTypes.contains(type);
      return _selectedTab == 0 ? isPoll : !isPoll;
    }).toList();
  }

  /// Modül sunucuda hiç hazır değilse yeni kayıt açtırmanın anlamı yok.
  bool get _moduleUnavailable => _error != null && isNotImplemented(_error!);

  @override
  Widget build(BuildContext context) {
    final loaded = !_loading && _error == null;

    return Scaffold(
      backgroundColor: AppleTheme.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Anketler & Oylamalar',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // İstatistikler yalnızca gerçek veri geldiyse gösterilir.
            if (loaded)
              SliverToBoxAdapter(
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMiniStat('Aktif', '$_activeCount',
                          Icons.how_to_vote_rounded, AppleTheme.systemBlue),
                      _buildMiniStat('Katılım', _participationLabel,
                          Icons.groups_rounded, AppleTheme.systemGreen),
                      _buildMiniStat('Tamamlanan', '$_endedCount',
                          Icons.check_circle_rounded, AppleTheme.systemGray),
                    ],
                  ),
                ),
              ),

            // Tab Selector
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppleTheme.systemGray6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTab('Oylamalar', 0, Icons.how_to_vote_rounded),
                    _buildTab('Anketler', 1, Icons.poll_rounded),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: AppleSectionHeader(
                title: _selectedTab == 0 ? 'Oylamalar' : 'Anketler',
              ),
            ),

            SliverToBoxAdapter(child: _buildBody()),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _moduleUnavailable
          ? null
          : AppleFAB(
              icon: Icons.add_rounded,
              label: _selectedTab == 0 ? 'Oylama' : 'Anket',
              onPressed: () => _showCreateSheet(context),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: LoadingView(message: 'Anketler alınıyor...'),
      );
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const NotImplementedNotice(
          title: 'Anket modülü henüz sunucuda hazır değil',
          detail: 'Survey servisi anketleri veritabanından okumuyor (501). '
              'Gerçek oy sayısı gelmeden burada katılım/karar bilgisi '
              'gösterilmez.',
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: ErrorStateView(message: toUserMessage(error), onRetry: _load),
      );
    }

    final items = _filteredSurveys;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: EmptyStateView(
          message: _selectedTab == 0
              ? 'Kayıtlı oylama yok.'
              : 'Kayıtlı anket yok.',
          icon: Icons.how_to_vote_outlined,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          return _buildSurveyTile(entry.value,
              isLast: entry.key == items.length - 1);
        }).toList(),
      ),
    );
  }

  int get _activeCount =>
      _surveys.where((s) => _str(s['status']).toUpperCase() == 'ACTIVE').length;

  int get _endedCount =>
      _surveys.where((s) => _str(s['status']).toUpperCase() == 'ENDED').length;

  /// Ortalama katılım; sunucu katılım verisi vermiyorsa uydurma bir yüzde
  /// yerine "—" gösterilir.
  String get _participationLabel {
    final rates = _surveys
        .map((s) => s['participation_rate'])
        .whereType<num>()
        .toList();
    if (rates.isEmpty) return '—';
    final avg = rates.reduce((a, b) => a + b) / rates.length;
    return '%${avg.round()}';
  }

  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: AppleTheme.normalAnimation,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4)
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? AppleTheme.systemBlue
                      : AppleTheme.secondaryLabel),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppleTheme.label
                      : AppleTheme.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildSurveyTile(Map<String, dynamic> survey, {bool isLast = false}) {
    final status = _str(survey['status']).toUpperCase();
    final isActive = status == 'ACTIVE';
    final votes = _int(survey['total_votes']);
    final eligible = _int(survey['total_eligible_voters']);
    final hasParticipation = eligible > 0;

    return Column(
      children: [
        InkWell(
          onTap: () => _showSurveyDetails(context, survey),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _str(survey['title']).isEmpty
                            ? '(başlıksız)'
                            : _str(survey['title']),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Katılım çubuğu yalnızca sunucu seçmen sayısını verdiyse
                // çizilir; aksi halde oran uydurmak gerekirdi.
                if (hasParticipation)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (votes / eligible).clamp(0.0, 1.0),
                      backgroundColor: AppleTheme.systemGray6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isActive ? AppleTheme.systemBlue : AppleTheme.systemGray,
                      ),
                      minHeight: 6,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_rounded,
                        size: 14, color: AppleTheme.secondaryLabel),
                    const SizedBox(width: 4),
                    Text(
                      hasParticipation
                          ? '$votes/$eligible katılım'
                          : 'Katılım verisi yok',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.secondaryLabel),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppleTheme.tertiaryLabel),
                    const SizedBox(width: 4),
                    Text(
                      'Son: ${formatDate(survey['ends_at'])}',
                      style: TextStyle(
                          fontSize: 13, color: AppleTheme.tertiaryLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(height: 0.5, color: AppleTheme.opaqueSeparator),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppleTheme.systemGreen;
      case 'ENDED':
        return AppleTheme.systemGray;
      case 'CANCELLED':
        return AppleTheme.systemRed;
      default:
        return AppleTheme.systemOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Aktif';
      case 'ENDED':
        return 'Tamamlandı';
      case 'CANCELLED':
        return 'İptal';
      case 'DRAFT':
        return 'Taslak';
      default:
        return status.isEmpty ? 'Durum yok' : status;
    }
  }

  void _showSurveyDetails(BuildContext context, Map<String, dynamic> survey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SurveyResultsSheet(survey: survey),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateSurveySheet(
        surveyType: _selectedTab == 0 ? 'POLL' : 'SURVEY',
        onCreated: _load,
      ),
    );
  }
}

/// Anket sonuçları sayfası — sayılar `GET /surveys/{id}/results` ucundan gelir.
class _SurveyResultsSheet extends StatefulWidget {
  final Map<String, dynamic> survey;
  const _SurveyResultsSheet({required this.survey});

  @override
  State<_SurveyResultsSheet> createState() => _SurveyResultsSheetState();
}

class _SurveyResultsSheetState extends State<_SurveyResultsSheet> {
  bool _loading = true;
  Object? _error;
  List<Map<String, dynamic>> _options = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await apiClient.getSurveyResults(_str(widget.survey['id']));
      if (!mounted) return;
      final raw = results['options'] ?? results['results'] ?? results['data'];
      setState(() {
        _options = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [];
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

  @override
  Widget build(BuildContext context) {
    final votes = _int(widget.survey['total_votes']);
    final eligible = _int(widget.survey['total_eligible_voters']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_str(widget.survey['title']),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppleTheme.systemGray6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn(
                        'Katılım',
                        eligible > 0
                            ? '${((votes / eligible) * 100).round()}%'
                            : '—',
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: AppleTheme.opaqueSeparator),
                      _statColumn('Oy Sayısı', eligible > 0 ? '$votes' : '—'),
                      Container(
                          width: 1,
                          height: 40,
                          color: AppleTheme.opaqueSeparator),
                      _statColumn('Seçmen', eligible > 0 ? '$eligible' : '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const LoadingView(message: 'Sonuçlar alınıyor...');
    }
    if (_error != null) {
      final error = _error!;
      if (isNotImplemented(error)) {
        return const SingleChildScrollView(
          child: NotImplementedNotice(
            title: 'Sonuçlar henüz sunucuda hazır değil',
            detail: 'Survey servisi oy dökümünü döndürmüyor (501).',
          ),
        );
      }
      return ErrorStateView(message: toUserMessage(error), onRetry: _load);
    }
    if (_options.isEmpty) {
      return const EmptyStateView(
        message: 'Bu anket için seçenek/oy kaydı yok.',
        icon: Icons.ballot_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final option = _options[index];
        final percentage = option['percentage'];
        final ratio =
            percentage is num ? (percentage / 100).clamp(0.0, 1.0) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_str(option['option_text']),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Text(
                  percentage is num
                      ? '${_int(option['vote_count'])} oy • %${percentage.round()}'
                      : '${_int(option['vote_count'])} oy',
                  style:
                      TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                ),
              ],
            ),
            if (ratio != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  backgroundColor: AppleTheme.systemGray6,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppleTheme.systemBlue),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
      ],
    );
  }
}

/// Yeni anket/oylama formu. "Oluştur" yalnızca sunucu 2xx döndürdüğünde
/// başarı mesajı gösterir; hata durumunda form açık kalır.
class _CreateSurveySheet extends StatefulWidget {
  final String surveyType;
  final Future<void> Function() onCreated;

  const _CreateSurveySheet({required this.surveyType, required this.onCreated});

  @override
  State<_CreateSurveySheet> createState() => _CreateSurveySheetState();
}

class _CreateSurveySheetState extends State<_CreateSurveySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _endsAt;
  bool _saving = false;
  String? _formError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endsAt = picked);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      setState(() => _formError = 'Başlık zorunludur.');
      return;
    }
    // Sunucu en az 2 seçenek şart koşuyor (survey/main.go: min=2).
    if (options.length < 2) {
      setState(() => _formError = 'En az 2 seçenek girilmelidir.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await apiClient.createSurvey({
        'title': title,
        'description': _descriptionController.text.trim(),
        'survey_type': widget.surveyType,
        'starts_at': DateTime.now().toUtc().toIso8601String(),
        if (_endsAt != null) 'ends_at': _endsAt!.toUtc().toIso8601String(),
        'options': options,
      });
      await widget.onCreated();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt sunucuya işlendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = toUserMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPoll = widget.surveyType == 'POLL';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                Text(isPoll ? 'Yeni Oylama' : 'Yeni Anket',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Oluştur'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_formError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_formError!,
                        style: TextStyle(color: AppleTheme.systemRed)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Başlık',
                      prefixIcon: Icon(Icons.title_rounded)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.description_rounded)),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Son Tarih',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                        _endsAt == null ? 'Seçilmedi' : formatDate(_endsAt)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Seçenekler (en az 2)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppleTheme.secondaryLabel)),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: '${entry.key + 1}. seçenek',
                        prefixIcon: const Icon(Icons.radio_button_unchecked),
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(
                        () => _optionControllers.add(TextEditingController())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Seçenek ekle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _str(Object? value) => value?.toString() ?? '';

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(_str(value)) ?? 0;
}
