import 'package:flutter/material.dart';
import '../../../../core/theme/apple_theme.dart';

/// Belgelerim Ekranı - Sakin için belge görüntüleme ve yükleme
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Genel belgeler (site yönetimi tarafından - tüm sakinler görebilir)
  final List<Map<String, dynamic>> _generalDocuments = [
    {
      'id': 'DOC-001',
      'title': 'Site Yönetim Planı',
      'category': 'resmi',
      'description': 'Site yönetim kurulu tarafından onaylanan yönetim planı',
      'fileType': 'pdf',
      'fileSize': '2.4 MB',
      'uploadDate': '15 Ocak 2024',
      'isNew': false,
    },
    {
      'id': 'DOC-002',
      'title': 'KVKK Aydınlatma Metni',
      'category': 'yasal',
      'description': 'Kişisel verilerin korunması hakkında aydınlatma metni',
      'fileType': 'pdf',
      'fileSize': '156 KB',
      'uploadDate': '1 Şubat 2024',
      'isNew': false,
    },
    {
      'id': 'DOC-003',
      'title': 'Site Kuralları ve Yönetmelikleri',
      'category': 'kurallar',
      'description': 'Site içi davranış kuralları ve yönetmelikler',
      'fileType': 'pdf',
      'fileSize': '890 KB',
      'uploadDate': '20 Ocak 2024',
      'isNew': false,
    },
    {
      'id': 'DOC-004',
      'title': 'Ortak Alan Kullanım Talimatları',
      'category': 'kurallar',
      'description': 'Havuz, spor salonu ve sosyal tesis kullanım kuralları',
      'fileType': 'pdf',
      'fileSize': '1.2 MB',
      'uploadDate': '1 Mart 2024',
      'isNew': true,
    },
  ];

  // Yönetimden gelen kişisel belgelerim
  final List<Map<String, dynamic>> _myDocuments = [
    {
      'id': 'RDOC-001',
      'title': 'Daire Teslim Tutanağı',
      'category': 'teslim',
      'description': 'Daire teslim tutanağı ve ekler',
      'fileType': 'pdf',
      'fileSize': '1.8 MB',
      'uploadDate': '1 Haziran 2023',
      'source': 'yonetim',
    },
    {
      'id': 'RDOC-002',
      'title': 'Aidat Sözleşmesi',
      'category': 'sozlesme',
      'description': 'Aylık aidat ödeme taahhütnamesi',
      'fileType': 'pdf',
      'fileSize': '450 KB',
      'uploadDate': '1 Ocak 2024',
      'source': 'yonetim',
    },
  ];

  // Sakin tarafından yüklenen belgeler
  final List<Map<String, dynamic>> _uploadedDocuments = [
    {
      'id': 'UPDOC-001',
      'title': 'Kimlik Fotokopisi',
      'category': 'kisisel',
      'description': 'Kişisel kimlik belgesi',
      'fileType': 'pdf',
      'fileSize': '320 KB',
      'uploadDate': '10 Ocak 2024',
      'sharedWithManagement': true,
      'status': 'approved',
    },
    {
      'id': 'UPDOC-002',
      'title': 'Araç Ruhsatı',
      'category': 'arac',
      'description': 'Otopark için araç kayıt belgesi',
      'fileType': 'pdf',
      'fileSize': '180 KB',
      'uploadDate': '15 Ocak 2024',
      'sharedWithManagement': true,
      'status': 'approved',
    },
    {
      'id': 'UPDOC-003',
      'title': 'Sigorta Poliçesi',
      'category': 'kisisel',
      'description': 'Daire sigortası',
      'fileType': 'pdf',
      'fileSize': '1.2 MB',
      'uploadDate': '20 Şubat 2024',
      'sharedWithManagement': false,
      'status': 'personal',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppleTheme.systemGray6,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppleTheme.label),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Belgeler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    ),
                    // Yükleme butonu (sadece Yüklediklerim tab'ında)
                    if (_tabController.index == 2)
                      ElevatedButton.icon(
                        onPressed: () => _showUploadSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yükle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppleTheme.systemBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
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
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(child: Text('Site', style: TextStyle(fontSize: 13))),
                  Tab(child: Text('Belgelerim', style: TextStyle(fontSize: 13))),
                  Tab(child: Text('Yüklediklerim', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),

          // Info Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _getBannerColor().withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_getBannerIcon(), color: _getBannerColor(), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_getBannerText(), style: TextStyle(fontSize: 13, color: _getBannerColor())),
                  ),
                ],
              ),
            ),
          ),

          // Documents List based on tab
          _buildCurrentTabContent(),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // FAB for upload (always visible on third tab)
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadSheet(context),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Belge Yükle'),
              backgroundColor: AppleTheme.systemBlue,
            )
          : null,
    );
  }

  Color _getBannerColor() {
    switch (_tabController.index) {
      case 0:
        return AppleTheme.systemBlue;
      case 1:
        return AppleTheme.systemGreen;
      case 2:
        return AppleTheme.systemPurple;
      default:
        return AppleTheme.systemBlue;
    }
  }

  IconData _getBannerIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.public_rounded;
      case 1:
        return Icons.lock_rounded;
      case 2:
        return Icons.cloud_upload_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getBannerText() {
    switch (_tabController.index) {
      case 0:
        return 'Site yönetimi tarafından tüm sakinlerle paylaşılan belgeler';
      case 1:
        return 'Yönetimden size özel gönderilen belgeler';
      case 2:
        return 'Sizin yüklediğiniz belgeler - kişisel veya yönetimle paylaşımlı';
      default:
        return '';
    }
  }

  Widget _buildCurrentTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildDocumentsList(_generalDocuments, showNewBadge: true);
      case 1:
        return _buildDocumentsList(_myDocuments);
      case 2:
        return _buildUploadedDocumentsList();
      default:
        return const SliverToBoxAdapter(child: SizedBox());
    }
  }

  Widget _buildDocumentsList(List<Map<String, dynamic>> documents, {bool showNewBadge = false}) {
    if (documents.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: Icons.folder_off_rounded,
          title: 'Henüz belge yok',
          subtitle: 'Bu kategoride belge bulunmuyor.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final doc = documents[index];
          return _buildDocumentCard(doc, showNewBadge: showNewBadge && doc['isNew'] == true);
        },
        childCount: documents.length,
      ),
    );
  }

  Widget _buildUploadedDocumentsList() {
    if (_uploadedDocuments.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: Icons.cloud_upload_rounded,
          title: 'Henüz belge yüklemediniz',
          subtitle: 'Belgelerinizi yükleyerek güvenle saklayın veya yönetimle paylaşın.',
          showUploadButton: true,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final doc = _uploadedDocuments[index];
          return _buildUploadedDocumentCard(doc);
        },
        childCount: _uploadedDocuments.length,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showUploadButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppleTheme.systemGray3),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
            style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel),
            textAlign: TextAlign.center,
          ),
          if (showUploadButton) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showUploadSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('İlk Belgenizi Yükleyin'),
              style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, {bool showNewBadge = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showDocumentDetails(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppleTheme.systemRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.picture_as_pdf_rounded, color: AppleTheme.systemRed, size: 26)),
                    if (showNewBadge)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: AppleTheme.systemGreen,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(child: Icon(Icons.fiber_new_rounded, size: 10, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(doc['description'], style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildCategoryChip(doc['category']),
                        const SizedBox(width: 8),
                        Text(doc['fileSize'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppleTheme.systemGray3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedDocumentCard(Map<String, dynamic> doc) {
    final isShared = doc['sharedWithManagement'] == true;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showUploadedDocumentDetails(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppleTheme.systemPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.upload_file_rounded, color: AppleTheme.systemPurple, size: 26)),
                    // Paylaşım durumu göstergesi
                    Positioned(
                      bottom: -2, right: -2,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: isShared ? AppleTheme.systemBlue : AppleTheme.systemGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isShared ? Icons.people_rounded : Icons.lock_rounded,
                          size: 10, color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isShared ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          size: 14, color: isShared ? AppleTheme.systemBlue : AppleTheme.secondaryLabel,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isShared ? 'Yönetim görüyor' : 'Sadece siz görüyorsunuz',
                          style: TextStyle(fontSize: 12, color: isShared ? AppleTheme.systemBlue : AppleTheme.secondaryLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildCategoryChip(doc['category']),
                        const SizedBox(width: 8),
                        Text(doc['uploadDate'], style: TextStyle(fontSize: 12, color: AppleTheme.tertiaryLabel)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppleTheme.secondaryLabel),
                onSelected: (value) => _handleDocumentAction(value, doc),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('Görüntüle')),
                  const PopupMenuItem(value: 'download', child: Text('İndir')),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(isShared ? 'Paylaşımı Kaldır' : 'Yönetimle Paylaş'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getCategoryLabel(category),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getCategoryColor(category)),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'resmi': return AppleTheme.systemBlue;
      case 'yasal': return AppleTheme.systemPurple;
      case 'kurallar': return AppleTheme.systemOrange;
      case 'guvenlik': return AppleTheme.systemRed;
      case 'sozlesme': return AppleTheme.systemGreen;
      case 'teslim': return AppleTheme.systemTeal;
      case 'kisisel': return AppleTheme.systemIndigo;
      case 'arac': return AppleTheme.systemPink;
      default: return AppleTheme.systemGray;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'resmi': return 'Resmi';
      case 'yasal': return 'Yasal';
      case 'kurallar': return 'Kurallar';
      case 'guvenlik': return 'Güvenlik';
      case 'sozlesme': return 'Sözleşme';
      case 'teslim': return 'Teslim';
      case 'kisisel': return 'Kişisel';
      case 'arac': return 'Araç';
      default: return category;
    }
  }

  void _handleDocumentAction(String action, Map<String, dynamic> doc) {
    switch (action) {
      case 'view':
        _showUploadedDocumentDetails(doc);
        break;
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belge indiriliyor...')));
        break;
      case 'share':
        final isShared = doc['sharedWithManagement'] == true;
        setState(() {
          doc['sharedWithManagement'] = !isShared;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isShared ? 'Paylaşım kaldırıldı' : 'Yönetimle paylaşıldı')),
        );
        break;
      case 'delete':
        _showDeleteConfirm(doc);
        break;
    }
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
              setState(() {
                _uploadedDocuments.removeWhere((d) => d['id'] == doc['id']);
              });
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

  // =============================================
  // UPLOAD SHEET
  // =============================================
  void _showUploadSheet(BuildContext context) {
    String selectedCategory = 'kisisel';
    bool shareWithManagement = false;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

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
              Container(width: 36, height: 5, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppleTheme.systemGray4, borderRadius: BorderRadius.circular(2.5))),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                    const Text('Belge Yükle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen belge başlığı girin')),
                          );
                          return;
                        }
                        // Yeni belge ekle
                        setState(() {
                          _uploadedDocuments.add({
                            'id': 'UPDOC-${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleController.text,
                            'category': selectedCategory,
                            'description': descriptionController.text.isEmpty ? 'Açıklama yok' : descriptionController.text,
                            'fileType': 'pdf',
                            'fileSize': '1.2 MB',
                            'uploadDate': '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                            'sharedWithManagement': shareWithManagement,
                            'status': shareWithManagement ? 'pending' : 'personal',
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(shareWithManagement ? 'Belge yönetimle paylaşıldı' : 'Belge kişisel olarak kaydedildi'),
                            backgroundColor: AppleTheme.systemGreen,
                          ),
                        );
                      },
                      child: const Text('Yükle'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Dosya Seçim Alanı
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppleTheme.systemGray4, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // TODO: Dosya seçici
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 44, color: AppleTheme.systemBlue),
                            const SizedBox(height: 10),
                            const Text('Dosya seçmek için tıklayın', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('PDF, JPG, PNG (Max 10MB)', style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Belge Başlığı
                    const Text('Belge Başlığı *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Örn: Kimlik Fotokopisi',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Açıklama
                    const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Belge hakkında kısa açıklama...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(label: const Text('Kişisel'), selected: selectedCategory == 'kisisel', onSelected: (s) => setSheetState(() => selectedCategory = 'kisisel')),
                        ChoiceChip(label: const Text('Araç'), selected: selectedCategory == 'arac', onSelected: (s) => setSheetState(() => selectedCategory = 'arac')),
                        ChoiceChip(label: const Text('Sözleşme'), selected: selectedCategory == 'sozlesme', onSelected: (s) => setSheetState(() => selectedCategory = 'sozlesme')),
                        ChoiceChip(label: const Text('Diğer'), selected: selectedCategory == 'diger', onSelected: (s) => setSheetState(() => selectedCategory = 'diger')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Paylaşım Seçeneği
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemGray6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.share_rounded, color: AppleTheme.systemBlue),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Yönetimle Paylaş', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              ),
                              Switch(
                                value: shareWithManagement,
                                onChanged: (value) => setSheetState(() => shareWithManagement = value),
                                activeColor: AppleTheme.systemBlue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shareWithManagement
                                ? 'Bu belge site yönetimi tarafından görüntülenebilecek.'
                                : 'Bu belge sadece sizin tarafınızdan görüntülenebilecek.',
                            style: TextStyle(fontSize: 13, color: AppleTheme.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                    
                    // Güvenlik notu
                    if (shareWithManagement) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security_rounded, color: AppleTheme.systemBlue, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Belgeniz güvenli şekilde saklanacak ve sadece site yönetimi erişebilecek.',
                                style: TextStyle(fontSize: 12, color: AppleTheme.systemBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month];
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
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
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: AppleTheme.systemRed.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppleTheme.systemRed, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${doc['fileSize']} • ${doc['fileType'].toString().toUpperCase()}', style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(doc['description'], style: TextStyle(fontSize: 15, color: AppleTheme.secondaryLabel)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İndiriliyor...'))); },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('İndir'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Görüntüle'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showUploadedDocumentDetails(Map<String, dynamic> doc) {
    final isShared = doc['sharedWithManagement'] == true;
    
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
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: AppleTheme.systemPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.upload_file_rounded, color: AppleTheme.systemPurple, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(isShared ? Icons.people_rounded : Icons.lock_rounded, size: 14, color: isShared ? AppleTheme.systemBlue : AppleTheme.secondaryLabel),
                                const SizedBox(width: 4),
                                Text(isShared ? 'Yönetimle paylaşıldı' : 'Kişisel', style: TextStyle(fontSize: 13, color: isShared ? AppleTheme.systemBlue : AppleTheme.secondaryLabel)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Paylaşım durumu değiştirme
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppleTheme.systemGray6, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, color: AppleTheme.secondaryLabel),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Yönetimle Paylaş')),
                        Switch(
                          value: isShared,
                          onChanged: (value) {
                            setState(() { doc['sharedWithManagement'] = value; });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(value ? 'Yönetimle paylaşıldı' : 'Paylaşım kaldırıldı')),
                            );
                          },
                          activeColor: AppleTheme.systemBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () { Navigator.pop(context); _showDeleteConfirm(doc); },
                          icon: const Icon(Icons.delete_rounded, color: AppleTheme.systemRed),
                          label: const Text('Sil', style: TextStyle(color: AppleTheme.systemRed)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppleTheme.systemRed.withOpacity(0.3))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Görüntüle'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppleTheme.systemBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
