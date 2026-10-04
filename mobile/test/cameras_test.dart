// Ortak alan kameraları (FAZ 7.8).

import 'package:flutter_test/flutter_test.dart';

import 'package:siteeksen_mobile/features/kvkk/presentation/screens/kvkk_requests_screen.dart';

void main() {
  test('kamera satırı amaç ve saklama süresini gösterir', () {
    expect(cameraSubtitle({'purpose': 'Giriş güvenliği', 'retention_days': 15}), 'Giriş güvenliği · kayıtlar 15 gün saklanır');
  });
}