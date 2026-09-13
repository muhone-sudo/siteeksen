// Demirbaş Takip Ekranı (sakin)
//
// NEDEN DEĞİŞTİRİLDİ (2026-09-13):
// Ekran hiçbir ağ çağrısı yapmıyordu. Beş demirbaş koda gömülüydü — her
// kullanıcıya aynı "Baymak kombi", "Samsung klima", "Bosch bulaşık makinesi"
// gösteriliyor; garanti tarihleri, son bakım tarihleri ve "Toplam / Garantili /
// Garanti Bitti" sayaçları bu uydurma listeden hesaplanıyordu. Kullanıcı kendi
// dairesinin verisini gördüğünü sanıyordu.
// Ayrıca detay sayfasındaki "Arıza Bildir" düğmesi hiçbir istek göndermeden
// "Arıza bildirimi oluşturuldu" diyordu — sahte başarı mesajı.
//
// GERÇEK DURUM: Demirbaş modülü için sunucuda uç yoktur ve `ApiClient` içinde
// demirbaş metodu bulunmamaktadır (bkz. lib/core/network/api_client.dart).
// Bu nedenle uydurma liste ve ona bağlı tüm kartlar kaldırıldı; ekranın başlığı
// korunarak durum `NotImplementedNotice` ile açıkça bildiriliyor.
// Arıza bildirimi ise GERÇEKTEN çalışan talep akışına yönlendiriliyor
// (`POST /requests` — community servisi kalıcı).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/apple_theme.dart';
import '../../../../core/widgets/data_state.dart';

/// Demirbaş Takip Ekranı - Sakin için daire demirbaşları
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

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
                        const Text('Demirbaşlarım',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Dairenize ait demirbaş ve cihazlar',
                        style: TextStyle(
                            fontSize: 15, color: AppleTheme.secondaryLabel)),
                  ],
                ),
              ),
            ),
          ),

          // NOT: "Toplam / Garantili / Garanti Bitti" sayaçları kaldırıldı;
          // bu sayılar uydurma listeden hesaplanıyordu ve gerçek bir daireye ait
          // değildi. Sunucu demirbaş ucu açtığında buraya geri gelecekler.
          const SliverToBoxAdapter(
            child: NotImplementedNotice(
              title: 'Demirbaş takibi henüz hazır değil',
              detail: 'Dairenize ait demirbaş, garanti ve bakım kayıtlarını '
                  'döndüren bir sunucu ucu bulunmuyor. Hazır olduğunda cihaz '
                  'listesi, garanti durumu ve bakım geçmişi burada görünecek.',
            ),
          ),

          // Arıza bildirimi gerçek talep akışıyla yapılabiliyor; kullanıcıyı
          // çıkmaz sokakta bırakmamak için buradan yönlendiriliyor.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.pushNamed('createRequest'),
                  icon: const Icon(Icons.report_problem_rounded),
                  label: const Text('Arıza için talep oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppleTheme.systemRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
