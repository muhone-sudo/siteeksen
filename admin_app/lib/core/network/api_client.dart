import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// API taban adresi.
  ///
  /// DÜZELTME (2026-09-13): Önceki değer `https://api.siteeksen.com/v1` idi.
  /// İki ayrı hata vardı:
  ///   1. Bu alan adı yayında değil — uygulama hiçbir ortamda çalışmıyordu.
  ///   2. Yol `/v1`; backend ise `/api/v1` bekliyor → her çağrı 404 dönerdi.
  /// Artık derleme zamanında verilebiliyor:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  /// Varsayılan, Android emülatöründen local gateway'e (8888) işaret eder.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8888/api/v1',
  );


  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final original = error.requestOptions;
        // Yeniden denenmiş istek tekrar 401 alırsa döngüye girmez.
        if (error.response?.statusCode == 401 && original.extra['_retried'] != true) {
          original.extra['_retried'] = true;
          final refreshed = await _refreshToken();
          if (refreshed) {
            try {
              return handler.resolve(await _retry(original));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Aynı anda gelen 401'ler TEK yenileme isteği paylaşır.
  Future<bool>? _refreshing;

  /// Yenileme jetonu TEK KULLANIMLIKTIR (sunucu her yenilemede yenisini verir).
  ///
  /// DÜZELTME (2026-09-26): önceki sürüm yalnızca erişim jetonunu saklıyor,
  /// yeni yenileme jetonunu atıyordu. Sunucu artık kullanılmış yenileme
  /// jetonunun ikinci kullanımını çalınma işareti sayar ve kullanıcının BÜTÜN
  /// oturumlarını kapatır; eski jetonu tekrar sunmak bu yüzden oturumu düşürür.
  /// Yenileme başarısızsa kayıtlı jetonlar silinir (bozuk oturum saklanmaz).
  Future<bool> _refreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final access = response.data['access_token'] as String?;
      final refresh = response.data['refresh_token'] as String?;
      if (response.statusCode == 200 && access != null) {
        await _storage.write(key: 'access_token', value: access);
        if (refresh != null) {
          await _storage.write(key: 'refresh_token', value: refresh);
        }
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      }
    } catch (_) {
      // Ağ hatası: oturum bilgisi korunur, bir sonraki istekte yeniden denenir.
    }
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: 'access_token');
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch(requestOptions);
  }

  // ============ AUTH ============

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    await _storage.write(key: 'access_token', value: response.data['access_token']);
    await _storage.write(key: 'refresh_token', value: response.data['refresh_token']);

    return response.data;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// JWT access token'ın "roles" claim'ini döner (RBAC menü filtreleme için).
  Future<List<String>> getCurrentUserRoles() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];
    try {
      final parts = token.split('.');
      if (parts.length != 3) return [];
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final roles = payload['roles'];
      if (roles is List) return roles.map((r) => r.toString()).toList();
      return [];
    } catch (_) {
      return [];
    }
  }

  /// KVKK açık rıza onayını kaydeder (zorunlu onay ekranı sonrası çağrılır).
  Future<void> acceptKvkkConsent() async {
    await _dio.post('/users/me/kvkk-consent');
  }

  /// Cihazda kayıtlı bir oturum (refresh token) var mı? — biyometrik giriş
  /// butonunun gösterilip gösterilmeyeceğini belirlemek için kullanılır.
  Future<bool> hasStoredSession() async {
    return await _storage.read(key: 'refresh_token') != null;
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: 'biometric_enabled') == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: 'biometric_enabled', value: 'true');
    } else {
      await _storage.delete(key: 'biometric_enabled');
    }
  }

  /// Biyometrik onay sonrası kayıtlı refresh token ile oturumu yeniler.
  Future<bool> loginWithStoredSession() => _refreshToken();

  // ============ OTURUM ============

  /// Sunucudaki oturumu kapatır (erişim + yenileme jetonu iptal), sonra cihazı
  /// temizler. Dönüş: sunucu iptalinin gerçekleşip gerçekleşmediği.
  ///
  /// DÜZELTME (2026-09-26): çıkış yalnızca giriş ekranına gidiyordu; jetonlar
  /// cihazda kalıyor, biyometrik giriş oturumu geri açıyordu.
  Future<bool> serverLogout() async {
    var revoked = false;
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      final response = await _dio.post('/auth/logout', data: {
        if (refresh != null) 'refresh_token': refresh,
      });
      final data = response.data;
      revoked = data is Map &&
          data['access_token_revoked'] == true &&
          (refresh == null || data['refresh_token_revoked'] == true);
    } catch (_) {
      revoked = false;
    }
    await logout();
    return revoked;
  }

  /// Etkinleştirme / şifre sıfırlama kodu ile şifre belirler (oturum gerekmez).
  Future<Map<String, dynamic>> activateAccount({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final response = await Dio(BaseOptions(baseUrl: baseUrl)).post('/auth/activate', data: {
      'phone': phone,
      'code': code.trim().toUpperCase(),
      'new_password': newPassword,
    });
    return _map(response.data);
  }

  /// Şifre değiştirir; sunucu BÜTÜN oturumları kapatır, cihaz da temizlenir.
  Future<Map<String, dynamic>> changePassword(String current, String next) async {
    final response = await _dio.post('/users/me/password', data: {
      'current_password': current,
      'new_password': next,
    });
    await logout();
    return _map(response.data);
  }

  /// Bağlı olunan siteler: `[{property_id, property_name, unit_id, unit_name, role}]`.
  Future<List<dynamic>> getUserProperties() async {
    final response = await _dio.get('/users/me/properties');
    return listOf(response.data);
  }

  // ============ GENEL YARDIMCILAR ============
  //
  // Ekranlar yol ve gövdeyi burada değil, sözleşmeye (tasks/api-sozlesmesi.md)
  // birebir uyan çağrılarla verir. Önceki sürümdeki ~20 yöntem var olmayan
  // yollara gidiyordu (`/bulletin`, `/energy/summary`, `/smart-collection/*`,
  // `/patrol-sessions`, `/meters/bulk-readings`…); tek tek yöntem yazmak bu
  // sapmayı gizliyordu.

  /// GET → `{"data":[...]}` listesini döner.
  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: _clean(query));
    return listOf(response.data);
  }

  /// GET → nesne yanıtı.
  Future<Map<String, dynamic>> getMap(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: _clean(query));
    return _map(response.data);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final response = await _dio.post(path, data: body ?? const {});
    return _map(response.data);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await _dio.put(path, data: body);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await _dio.patch(path, data: body);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) async {
    final response = await _dio.delete(path, data: body);
    return _map(response.data);
  }

  // ============ DASHBOARD ============

  /// `{success, data:{…}, unavailable:[{source,reason}], partial}` — erişilemeyen
  /// alan yazılmaz; nedeni `unavailable` listesindedir.
  Future<Map<String, dynamic>> getDashboard() => getMap('/dashboard/stats');

  // ============ SAKİNLER ============

  Future<List<dynamic>> getResidents({String? search, String? block, String? role}) =>
      getList('/residents', query: {'search': search, 'block': block, 'role': role});

  Future<Map<String, dynamic>> getResident(String id) => getMap('/residents/$id');

  /// 201 sakin; yeni hesap açıldıysa `activation:{activation_code, purpose,
  /// expires_at, note}` BİR KEZ döner (telefon kayıtlıysa yalnızca `note`).
  Future<Map<String, dynamic>> createResident(Map<String, dynamic> data) => post('/residents', data);

  Future<Map<String, dynamic>> updateResident(String id, Map<String, dynamic> data) =>
      patch('/residents/$id', data);

  /// Yeni etkinleştirme / şifre sıfırlama kodu (eski açık kod geçersizleşir).
  Future<Map<String, dynamic>> issueActivationCode(String residentId) =>
      post('/residents/$residentId/activation-code');

  Future<List<dynamic>> getUnits() => getList('/units');

  /// Servislerin liste yanıtı `{"data": [...]}`; eski düz dizi biçimi de kabul edilir.
  static List<dynamic> listOf(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final v = data['data'] ?? data['items'];
      if (v is List) return v;
    }
    return const [];
  }

  static Map<String, dynamic> _map(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  /// Boş sorgu parametreleri gönderilmez (sunucu `status=` boşunu filtre sayabilir).
  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      out[k] = v;
    });
    return out;
  }
}

// Singleton
final apiClient = ApiClient();
