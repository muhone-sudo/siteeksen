// Kargo teslim imzası (TEST_RAPORU 2.3).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_admin/core/widgets/signature_pad.dart';

void main() {
  test('boş imza PNG üretmez', () async {
    final c = SignatureController();
    c.start(const Offset(5, 5)); // tek nokta çizgi değildir
    expect(c.isEmpty, isTrue);
    expect(await c.toPng(const Size(100, 50)), isNull);
  });

  testWidgets('çizilen imza geçerli PNG olur, temizlenince boşalır', (tester) async {
    final c = SignatureController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SignaturePad(controller: c))));
    await tester.drag(find.byType(SignaturePad), const Offset(80, 20));
    expect(c.isEmpty, isFalse);
    final png = await tester.runAsync(() => c.toPng(const Size(120, 60)));
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]); // PNG imzası
    c.clear();
    expect(c.isEmpty, isTrue);
  });
}
