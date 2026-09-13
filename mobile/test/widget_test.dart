// Sakin uygulaması — temel duman (smoke) testi.
//
// NEDEN YENİDEN YAZILDI (2026-09-13):
// Bu dosya `flutter create` şablonundan kalan sayaç testiydi; var olmayan `MyApp`
// sınıfını çağırdığı için DERLENMİYORDU. Yani projede "1 test var" denmesine rağmen
// çalıştırılabilir tek bir test yoktu ve `flutter analyze` hata veriyordu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/main.dart';

void main() {
  testWidgets('Uygulama çöküp kapanmadan ilk kareyi çizer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SiteEksenApp()),
    );

    // İlk kare çizildi mi? (router ve tema kurulumu patlarsa burada düşer)
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Uygulama başlığı ve hata ayıklama bandı doğru yapılandırılmış',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SiteEksenApp()),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'SiteEksen');
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.routerConfig, isNotNull);
  });
}
