import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/apple_widgets.dart';

/// Sözleşme ve Belge Yönetim Ekranı - Geliştirilmiş
class ContractManagementScreen extends StatefulWidget {
  const ContractManagementScreen({super.key});

  @override
  State<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends State<ContractManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Tab kategorileri
  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Firma Sözleşmeleri', 'icon': Icons.business_rounded},
    {'name': 'Genel Belgeler', 'icon': Icons.folder_shared_rounded},
    {'name': 'Sakin Belgeleri', 'icon': Icons.person_rounded},
  ];

  // Firma sözleşmeleri (mevcut)
  final List<Map<String, dynamic>> _contracts = [
    {
      'id': 'SZL-2024-001',
      'title': 'Güvenlik Hizmeti Sözleşmesi',
      'vendor': 'ABC Güvenlik Ltd.',
      'type': 'service',
      'startDate': '2024-01-01',
      'endDate': '2026-12-31',
      'monthlyValue': 45000,
      'status': 'active',
      'daysRemaining': 334,
    },
    {
      'id': 'SZL-2024-002',
      'title': 'Asansör Bakım Sözleşmesi',
      'vendor': 'Asansör Teknik A.Ş.',
      'type': 'maintenance',
      'startDate': '2024-03-01',
      'endDate': '2026-03-01',
      'monthlyValue': 8500,
      'status': 'active',
      'daysRemaining': 28,
    },
  ];

  // Genel belgeler (tüm sakinler görebilir)
  final List<Map<String, dynamic>> _generalDocuments = [
    {
      'id': 'DOC-001',
      'title': 'Site Yönetim Planı',
      'category': 'resmi',
      'fileType': 'pdf',
      'fileSize': '2.4 MB',
      'uploadDate': '2024-01-15',
      'uploadedBy': 'Site Yöneticisi',
      'viewCount': 145,
    },
    {
      'id': 'DOC-002',
      'title': 'KVKK Aydınlatma Metni',
      'category': 'yasal',
      'fileType': 'pdf',
      'fileSize': '156 KB',
      'uploadDate': '2024-02-01',
      'uploadedBy': 'Site Yöneticisi',
      'viewCount': 89,
    },
    {
      'id': 'DOC-003',
      'title': 'Site Kuralları ve Yönetmelikleri',
      'category': 'kurallar',
      'fileType': 'pdf',
      'fileSize': '890 KB',
      'uploadDate': '2024-01-20',
      'uploadedBy': 'Site Yöneticisi',
      'viewCount': 234,
    },
    {
      'id': 'DOC-004',
      'title': 'Ortak Alan Kullanım Talimatları',
      'category': 'kurallar',
      'fileType': 'pdf',
      'fileSize': '1.2 MB',
      'uploadDate': '2024-03-01',
      'uploadedBy': 'Site Yöneticisi',
      'viewCount': 167,
    },
    {
      'id': 'DOC-005',
      'title': 'Acil Durum Prosedürleri',
      'category': 'guvenlik',
      'fileType': 'pdf',
      'fileSize': '3.1 MB',
      'uploadDate': '2024-02-15',
      'uploadedBy': 'Site Yöneticisi',
      'viewCount': 78,
    },
  ];

  // Sakine özel belgeler
  final List<Map<String, dynamic>> _residentDocuments = [
    {
      'id': 'RDOC-001',
      'title': 'Daire Teslim Tutanağı',
      'residentName': 'Ahmet Yılmaz',
      'residentUnit': 'A-12',
      'category': 'teslim',
      'fileType': 'pdf',
      'fileSize': '1.8 MB',
      'uploadDate': '2023-06-01',
    },
    {
      'id': 'RDOC-002',
      'title': 'Kira Sözleşmesi',
      'residentName': 'Mehmet Demir',
      'residentUnit': 'B-05',
      'category': 'sozlesme',
      'fileType': 'pdf',
      'fileSize': '2.2 MB',
      'uploadDate': '2024-01-01',
    },
    {
      'id': 'RDOC-003',
      'title': 'Muvafakatname',
      'residentName': 'Ayşe Kaya',
      'residentUnit': 'C-08',
      'category': 'yetki',
      'fileType': 'pdf',
      'fileSize': '450 KB',
      'uploadDate': '2024-03-15',
    },
    {
      'id': 'RDOC-004',
      'title': 'Tapu Fotokopisi',
      'residentName': 'Ali Öztürk',
      'residentUnit': 'A-03',
      'category': 'mulkiyet',
      'fileType': 'pdf',
      'fileSize': '1.1 MB',
      'uploadDate': '2023-08-20',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sözleşme & Belgeler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                            SizedBox(height: 4),
                            Text('Tüm belgeleri yönetin', style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showUploadSheet(context),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Yükle'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemBlue),
                        ),
                      ],
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppleTheme.label,
                unselectedLabelColor: AppleTheme.secondaryLabel,
                dividerColor: Colors.transparent,
                tabs: _tabs.map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab['icon'], size: 16),
                      const SizedBox(width: 6),
                      Text(tab['name'], style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Container(
              height: 90,
              margin: const EdgeInsets.only(top: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _buildStatsForTab(),
              ),
            ),
          ),

          // Search
          SliverToBoxAdapter(
            child: AppleSearchBar(
              controller: _searchController,
              placeholder: 'Belge ara...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Content based on tab
          _buildTabContent(),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<Widget> _buildStatsForTab() {
    switch (_tabController.index) {
      case 0: // Firma Sözleşmeleri
        return [
          _buildMiniStat('Aktif', '${_contracts.length}', Icons.description_rounded, AppleTheme.systemBlue),
          _buildMiniStat('Yaklaşan', '1', Icons.warning_rounded, AppleTheme.systemOrange),
          _buildMiniStat('Aylık', '₺85K', Icons.monetization_on_rounded, AppleTheme.systemGreen),
        ];
      case 1: // Genel Belgeler
        return [
          _buildMiniStat('Toplam', '${_generalDocuments.length}', Icons.folder_rounded, AppleTheme.systemBlue),
          _buildMiniStat('Görüntüleme', '713', Icons.visibility_rounded, AppleTheme.systemPurple),
          _buildMiniStat('Boyut', '7.7 MB', Icons.storage_rounded, AppleTheme.systemGreen),
        ];
      case 2: // Sakin Belgeleri
        return [
          _buildMiniStat('Toplam', '${_residentDocuments.length}', Icons.person_rounded, AppleTheme.systemBlue),
          _buildMiniStat('Sakin', '4', Icons.people_rounded, AppleTheme.systemOrange),
          _buildMiniStat('Boyut', '5.5 MB', Icons.storage_rounded, AppleTheme.systemGreen),
        ];
      default:
        return [];
    }
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildContractsList();
      case 1:
        return _buildGeneralDocumentsList();
      case 2:
        return _buildResidentDocumentsList();
      default:
        return const SliverToBoxAdapter(child: SizedBox());
    }
  }

  // =============================================
  // FİRMA SÖZLEŞMELERİ
  // =============================================
  Widget _buildContractsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Yaklaşan uyarı
            if (_contracts.any((c) => c['daysRemaining'] < 60)) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppleTheme.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppleTheme.systemOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppleTheme.systemOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yenileme Uyarısı', style: TextStyle(fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                          Text('1 sözleşmenin bitiş tarihi yaklaşıyor', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          }
          final contract = _contracts[index - 1];
          return _buildContractCard(contract);
        },
        childCount: _contracts.length + 1,
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final isExpiringSoon = contract['daysRemaining'] < 60;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppleTheme.cardDecoration,
      child: InkWell(
        onTap: () => _showContractDetails(context, contract),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(contract['title'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${contract['daysRemaining']} gün', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(contract['vendor'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppleTheme.tertiaryLabel),
                  const SizedBox(width: 4),
                  Text('${contract['startDate']} - ${contract['endDate']}', style: TextStyle(fontSize: 13, color: AppleTheme.tertiaryLabel)),
                  const Spacer(),
                  Text('₺${contract['monthlyValue']}/ay', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // GENEL BELGELER
  // =============================================
  Widget _buildGeneralDocumentsList() {
    final categories = ['Tümü', 'Resmi', 'Yasal', 'Kurallar', 'Güvenlik'];
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Kategori filtreleri
            return Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(categories[i]),
                    selected: i == 0,
                    onSelected: (selected) {},
                    backgroundColor: AppleTheme.systemGray6,
                    selectedColor: AppleTheme.systemBlue.withOpacity(0.2),
                  ),
                ),
              ),
            );
          }
          final doc = _generalDocuments[index - 1];
          return _buildDocumentCard(doc, isGeneral: true);
        },
        childCount: _generalDocuments.length + 1,
      ),
    );
  }

  // =============================================
  // SAKİN BELGELERİ
  // =============================================
  Widget _buildResidentDocumentsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Sakin arama/filtreleme ipucu
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppleTheme.systemBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppleTheme.systemBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Sakine özel belgeler sadece ilgili sakin tarafından görüntülenebilir.', 
                      style: TextStyle(fontSize: 13, color: AppleTheme.systemBlue)),
                  ),
                ],
              ),
            );
          }
          final doc = _residentDocuments[index - 1];
          return _buildDocumentCard(doc, isGeneral: false);
        },
        childCount: _residentDocuments.length + 1,
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, {required bool isGeneral}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppleTheme.cardDecoration,
      child: InkWell(
        onTap: () => _showDocumentDetails(context, doc, isGeneral),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppleTheme.systemRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppleTheme.systemRed, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (!isGeneral)
                      Text('${doc['residentName']} • ${doc['residentUnit']}', 
                        style: TextStyle(fontSize: 13, color: AppleTheme.systemBlue))
                    else
                      Text('${doc['viewCount']} görüntüleme', 
                        style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                    Text('${doc['fileSize']} • ${doc['uploadDate']}', 
                      style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppleTheme.secondaryLabel),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirm(doc);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('Görüntüle')),
                  const PopupMenuItem(value: 'download', child: Text('İndir')),
                  const PopupMenuItem(value: 'share', child: Text('Paylaş')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
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
      width: 110,
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
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
        ],
      ),
    );
  }

  // =============================================
  // UPLOAD SHEET
  // =============================================
  void _showUploadSheet(BuildContext context) {
    String selectedType = 'general';
    String? selectedResident;
    final titleController = TextEditingController();
    String selectedCategory = 'resmi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                    const Text('Belge Yükle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Belge başarıyla yüklendi'), backgroundColor: AppleTheme.systemGreen),
                      );
                    }, child: const Text('Yükle')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Belge Türü
                    const Text('Belge Türü', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'general', label: Text('Genel'), icon: Icon(Icons.public_rounded)),
                        ButtonSegment(value: 'resident', label: Text('Sakine Özel'), icon: Icon(Icons.person_rounded)),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setSheetState(() => selectedType = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Sakin Seçimi (sadece sakine özel için)
                    if (selectedType == 'resident') ...[
                      const Text('Sakin Seçimi', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedResident,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Sakin seçin...',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A-12', child: Text('Ahmet Yılmaz - A-12')),
                          DropdownMenuItem(value: 'B-05', child: Text('Mehmet Demir - B-05')),
                          DropdownMenuItem(value: 'C-08', child: Text('Ayşe Kaya - C-08')),
                          DropdownMenuItem(value: 'A-03', child: Text('Ali Öztürk - A-03')),
                        ],
                        onChanged: (value) => setSheetState(() => selectedResident = value),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Belge Başlığı
                    const Text('Belge Başlığı', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Belge başlığını girin...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(label: const Text('Resmi'), selected: selectedCategory == 'resmi', onSelected: (s) => setSheetState(() => selectedCategory = 'resmi')),
                        ChoiceChip(label: const Text('Yasal'), selected: selectedCategory == 'yasal', onSelected: (s) => setSheetState(() => selectedCategory = 'yasal')),
                        ChoiceChip(label: const Text('Kurallar'), selected: selectedCategory == 'kurallar', onSelected: (s) => setSheetState(() => selectedCategory = 'kurallar')),
                        ChoiceChip(label: const Text('Sözleşme'), selected: selectedCategory == 'sozlesme', onSelected: (s) => setSheetState(() => selectedCategory = 'sozlesme')),
                        ChoiceChip(label: const Text('Mülkiyet'), selected: selectedCategory == 'mulkiyet', onSelected: (s) => setSheetState(() => selectedCategory = 'mulkiyet')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dosya Seçim Alanı
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppleTheme.systemGray4, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // TODO: Dosya seçici aç
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 48, color: AppleTheme.systemBlue),
                            const SizedBox(height: 12),
                            const Text('Dosya seçmek için tıklayın', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('PDF, DOCX, JPG, PNG (Max 10MB)', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContractDetails(BuildContext context, Map<String, dynamic> contract) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contract['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(contract['vendor'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.tag_rounded, 'Sözleşme No', contract['id']),
                  _buildInfoRow(Icons.play_arrow_rounded, 'Başlangıç', contract['startDate']),
                  _buildInfoRow(Icons.stop_rounded, 'Bitiş', contract['endDate']),
                  _buildInfoRow(Icons.monetization_on_rounded, 'Aylık Tutar', '₺${contract['monthlyValue']}'),
                  _buildInfoRow(Icons.schedule_rounded, 'Kalan Süre', '${contract['daysRemaining']} gün'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_rounded), label: const Text('PDF İndir'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh_rounded), label: const Text('Yenile'))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, Map<String, dynamic> doc, bool isGeneral) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: AppleTheme.systemRed.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppleTheme.systemRed, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            Text('${doc['fileSize']} • ${doc['fileType'].toString().toUpperCase()}', style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!isGeneral) ...[
                    _buildInfoRow(Icons.person_rounded, 'Sakin', doc['residentName']),
                    _buildInfoRow(Icons.home_rounded, 'Daire', doc['residentUnit']),
                  ] else
                    _buildInfoRow(Icons.visibility_rounded, 'Görüntüleme', '${doc['viewCount']}'),
                  _buildInfoRow(Icons.calendar_today_rounded, 'Yükleme Tarihi', doc['uploadDate']),
                  _buildInfoRow(Icons.category_rounded, 'Kategori', doc['category']),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_rounded), label: const Text('Görüntüle'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_rounded), label: const Text('İndir'))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${doc['title']} belgesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge silindi')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemRed),
            child: const Text('Sil'),
          ),
        ],
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
          Text(label, style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
