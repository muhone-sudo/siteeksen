// Konum yardımcıları (FAZ H.5 devriye). Konum yalnız açık tur boyunca ve nokta kurulumunda istenir.

import 'package:geolocator/geolocator.dart';

class LocationFailure implements Exception {
  final String message;
  LocationFailure(this.message);
  @override
  String toString() => message;
}

/// Konum servisi ve izni hazır mı; değilse kullanıcıya anlatılacak hatayı fırlatır.
Future<void> ensureLocationReady() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw LocationFailure('Telefonun konum servisi (GPS) kapalı. Açıp yeniden deneyin.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied) {
    throw LocationFailure('Konum izni verilmedi. Devriye okutması noktanın yanında olduğunuzu konumla doğrular.');
  }
  if (perm == LocationPermission.deniedForever) {
    throw LocationFailure('Konum izni kalıcı olarak reddedilmiş. Uygulama ayarlarından konum iznini açın.');
  }
}

/// En hassas konumu alır (en çok [timeout] bekler).
Future<Position> currentPosition({Duration timeout = const Duration(seconds: 20)}) async {
  await ensureLocationReady();
  return Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(accuracy: LocationAccuracy.best, timeLimit: timeout),
  );
}

/// Sunucuya gönderilecek konum alanları.
Map<String, dynamic> positionBody(Position p) => {
      'latitude': p.latitude,
      'longitude': p.longitude,
      'accuracy_m': p.accuracy,
      'is_mocked': p.isMocked,
    };

double distanceMeters(double lat1, double lon1, double lat2, double lon2) =>
    Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
