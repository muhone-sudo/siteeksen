// Belgeler Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// Ekran hiçbir ağ çağrısı yapmıyordu. Üç sekmenin tamamı koda gömülü uydurma
// belgelerle doluydu ("Site Yönetim Planı 2.4 MB", "Kimlik Fotokopisi",
// "Aidat Sözleşmesi" …). Daha kötüsü:
//   - "Yükle" düğmesi hiçbir yere dosya göndermeden listeye satır ekleyip
//     "Belge yönetimle paylaşıldı" diyordu — sunucuda hiçbir kayıt oluşmuyordu.
//   - "İndir" düğmesi "Belge indiriliyor..." diyordu, hiçbir şey indirmiyordu.
//   - Paylaşım anahtarı sadece yerel değişkeni değiştirip "paylaşıldı" diyordu.
// Bunların hepsi kullanıcıya yalan söylüyordu.
//
// GERÇEK DURUM: Belge modülü için sunucuda uç yoktur ve `ApiClient` içinde
// belge metodu bulunmamaktadır (bkz. lib/core/network/api_client.dart).
// Bu nedenle uydurma içerik tamamen kaldırıldı; ekranın iskeleti (başlık, sekme
// yapısı, bilgi bandı) korunarak içerik `NotImplementedNotice` ile değiştirildi.
// Sunucuda belge uçları açıldığında yalnızca `_buildCurrentTabContent` gerçek
// veriye bağlanacaktır.

import 'package:flutter/material.dart';

import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/data_state.dart';

/// Belgelerim Ekranı - Sakin için belge görüntüleme
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppleTheme.systemGray6,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppleTheme.label),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Belgeler',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5)),
                    ),
                    // NOT: "Yükle" düğmesi kaldırıldı — sunucuda belge yükleme
                    // ucu yok; düğmenin tek yaptığı sahte başarı mesajı vermekti.
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4)
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppleTheme.label,
                unselectedLabelColor: AppleTheme.secondaryLabel,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(child: Text('Site', style: TextStyle(fontSize: 13))),
                  Tab(child: Text('Belgelerim', style: TextStyle(fontSize: 13))),
                  Tab(
                      child: Text('Yüklediklerim',
                          style: TextStyle(fontSize: 13))),
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
                color: _bannerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_bannerIcon, color: _bannerColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_bannerText,
                        style: TextStyle(fontSize: 13, color: _bannerColor)),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildCurrentTabContent()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Color get _bannerColor {
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

  IconData get _bannerIcon {
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

  String get _bannerText {
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

  /// Belge modülünün sunucu karşılığı olmadığı için üç sekme de durumu açıkça
  /// bildirir. Uydurma belge listesi göstermek yerine bu tercih edilmiştir.
  Widget _buildCurrentTabContent() {
    switch (_tabController.index) {
      case 0:
        return const NotImplementedNotice(
          title: 'Site belgeleri henüz hazır değil',
          detail: 'Belge modülü için sunucu tarafında bir uç bulunmuyor. '
              'Site yönetim planı, KVKK metni ve site kuralları burada '
              'listelenecektir.',
        );
      case 1:
        return const NotImplementedNotice(
          title: 'Kişisel belgeleriniz henüz hazır değil',
          detail: 'Yönetimin size özel gönderdiği belgeleri listeleyecek uç '
              'sunucuda mevcut değil.',
        );
      case 2:
        return const NotImplementedNotice(
          title: 'Belge yükleme henüz hazır değil',
          detail: 'Sunucuda belge yükleme ve saklama ucu bulunmadığı için bu '
              'ekrandan belge yüklenemez. Önceki sürüm belgeyi hiçbir yere '
              'göndermeden "yüklendi" diyordu; bu davranış kaldırıldı.',
        );
      default:
        return const SizedBox();
    }
  }
}
