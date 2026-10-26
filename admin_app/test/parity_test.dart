// FAZ H.7: panelle eşitlik altyapısı — form çıktısı, toplu bölüm ayrıştırma ve menü-rota tutarlılığı.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siteeksen_admin/core/widgets/forms.dart';
import 'package:siteeksen_admin/features/units/presentation/screens/units_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  test('toplu bölüm satırları ayrıştırılır; hatalı satır bildirilir', () {
    final (units, errors) = parseUnits('A;0;1;120,5;82;95\n# yorum\nB;2;3;1.234,5;90;\n;1;;10;10;\nC;x;1;10;10;\nD;1;2;0;10;');
    expect(units.length, 2);
    expect(units[0], {'block': 'A', 'floor': 0, 'door_number': '1', 'share_ratio': 120.5, 'net_area_m2': 82, 'gross_area_m2': 95});
    expect(units[1]['share_ratio'], 1234.5);
    expect(units[1].containsKey('gross_area_m2'), isFalse);
    expect(errors, ['4. satır: kapı numarası yok', '5. satır: kat tam sayı olmalı', '6. satır: arsa payı sıfırdan büyük olmalı']);
  });

  testWidgets('form değerleri sunucu biçiminde döner; boş isteğe bağlı alan gönderilmez', (tester) async {
    Map<String, dynamic>? out;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => out = await showForm(context, 'Deneme', [
            const FSpec('name', 'Ad', required: true),
            const FSpec('note', 'Not'),
            const FSpec('amount', 'Tutar', type: FType.decimal),
            const FSpec('count', 'Adet', type: FType.integer),
            FSpec('day', 'Gün', type: FType.date, initial: DateTime(2026, 3, 7)),
            const FSpec('on', 'Açık', type: FType.toggle, initial: true),
            const FSpec('hidden', 'Gizli', visible: _never),
          ]),
          child: const Text('aç'),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(out, isNull, reason: 'zorunlu alan boşken form kapanmamalı');
    expect(find.text('Ad gerekli'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Ad *'), '  Ayşe ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tutar'), '12,50');
    await tester.enterText(find.widgetWithText(TextFormField, 'Adet'), '3');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(out, {'name': 'Ayşe', 'amount': 12.5, 'count': 3, 'day': '2026-03-07', 'on': true});
  });

  test('menüdeki her yolun yönlendiricide karşılığı var', () {
    final menu = File('lib/features/main/presentation/screens/main_screen.dart').readAsStringSync();
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final paths = RegExp(r"_NavItem\([^,]+, '[^']+', '([^']+)'").allMatches(menu).map((m) => m.group(1)!).toSet();
    expect(paths.length, greaterThan(30));
    for (final p in paths) {
      expect(router.contains("path: '$p'"), isTrue, reason: '$p yönlendiricide yok');
    }
  });
}

bool _never(Map<String, dynamic> _) => false;
