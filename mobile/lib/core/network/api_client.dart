import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// API taban adresi.
  ///
  /// DÜZELTME (2026-09-13): Sabit `http://localhost:8000/api/v1` değeri gerçek bir
  /// cihazda ya da emülatörde çalışmaz (`localhost` cihazın kendisidir) ve 8000
  /// portu Kong'a aitti; geliştirmede kullanılan gateway 8888'dedir.
  /// Artık derleme zamanında verilebiliyor:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  /// Varsayılan, Android emülatöründen local gateway'e işaret eder.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8888/api/v1',
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricEnabledKey = 'biometric_enabled';

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final original = error.requestOptions;
        if (error.response?.statusCode == 401 && original.extra['_retried'] != true) {
          original.extra['_retried'] = true;
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final token = await _storage.read(key: _accessTokenKey);
            original.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(original);
              return handler.resolve(response);
            } catch (_) {
              // düşüp normal hata akışına devam eder
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Aynı anda gelen 401'ler TEK yenileme isteği paylaşır: yenileme jetonu
  /// tek kullanımlıktır ve sunucu, tüketilmiş jetonun sonradan yeniden
  /// sunulmasını çalınma işareti sayıp bütün oturumları kapatır.
  Future<bool>? _refreshing;

  Future<bool> _tryRefreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final refresh = await _storage.read(key: _refreshTokenKey);
      if (refresh == null) return false;
      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final accessToken = response.data['access_token'] as String?;
      final refreshToken = response.data['refresh_token'] as String?;
      if (accessToken == null) return false;
      await _persistTokens(accessToken, refreshToken);
      return true;
    } on DioException catch (e) {
      // Sunucu jetonu reddettiyse oturum bitmiştir: bozuk oturum saklanmaz.
      if (e.response?.statusCode == 401) {
        await clearToken();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  void setToken(String token) {
    _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Cihazda kayıtlı bir oturum (refresh token) var mı? — uygulama açılışı ve
  /// biyometrik giriş kontrolünde kullanılır.
  Future<bool> hasStoredSession() async {
    return await _storage.read(key: _refreshTokenKey) != null;
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _biometricEnabledKey, value: 'true');
    } else {
      await _storage.delete(key: _biometricEnabledKey);
    }
  }

  /// Biyometrik onay sonrası kayıtlı refresh token ile oturumu yeniler.
  Future<bool> loginWithStoredSession() => _tryRefreshToken();

  // Auth
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    final accessToken = response.data['access_token'] as String?;
    final refreshToken = response.data['refresh_token'] as String?;
    if (accessToken != null) {
      await _persistTokens(accessToken, refreshToken);
    }
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return response.data;
  }

  // User
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  /// KVKK açık rıza onayını kaydeder (zorunlu onay ekranı sonrası çağrılır).
  Future<void> acceptKvkkConsent() async {
    await _dio.post('/users/me/kvkk-consent');
  }

  Future<List<dynamic>> getUserProperties() async {
    final response = await _dio.get('/users/me/properties');
    return _list(response.data);
  }

  // Finance
  Future<Map<String, dynamic>> getDebtStatus() async {
    final response = await _dio.get('/finance/debt-status');
    return response.data;
  }

  Future<List<dynamic>> getAssessments({int? year}) async {
    final response = await _dio.get('/finance/assessments', queryParameters: {
      if (year != null) 'year': year,
    });
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createPayment({
    required List<String> assessmentIds,
    required String paymentMethod,
    String? cardToken,
    bool saveCard = false,
  }) async {
    final response = await _dio.post('/finance/payments', data: {
      'assessment_ids': assessmentIds,
      'payment_method': paymentMethod,
      if (cardToken != null) 'card_token': cardToken,
      'save_card': saveCard,
    });
    return response.data;
  }

  // Consumption
  Future<Map<String, dynamic>> getConsumptionSummary({String? meterType}) async {
    final response = await _dio.get('/finance/consumption/summary', queryParameters: {
      if (meterType != null) 'meter_type': meterType,
    });
    return response.data;
  }

  // Requests
  Future<List<dynamic>> getRequests({String? status}) async {
    final response = await _dio.get('/requests', queryParameters: {
      if (status != null) 'status': status,
    });
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createRequest({
    required String categoryId,
    required String title,
    required String description,
    String? location,
    List<String>? photos,
    String priority = 'NORMAL',
  }) async {
    final response = await _dio.post('/requests', data: {
      'category_id': categoryId,
      'title': title,
      'description': description,
      if (location != null) 'location': location,
      if (photos != null) 'photos': photos,
      'priority': priority,
    });
    return response.data;
  }

  /// Sakin, yöneticinin RESOLVED işaretlediği talebi onaylar (CLOSED) ya da
  /// reddeder (talep IN_PROGRESS'e geri döner).
  Future<Map<String, dynamic>> confirmRequestResolution(String requestId, bool approved) async {
    final response = await _dio.post('/requests/$requestId/confirm-resolution', data: {
      'approved': approved,
    });
    return response.data;
  }

  // Reservations
  Future<List<dynamic>> getReservations() async {
    final response = await _dio.get('/reservations');
    return _list(response.data);
  }

  Future<List<dynamic>> getFacilities() async {
    final response = await _dio.get('/facilities');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createReservation({
    required String facilityId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _dio.post('/reservations', data: {
      'facility_id': facilityId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
    });
    return response.data;
  }

  Future<void> cancelReservation(String reservationId) async {
    await _dio.delete('/reservations/$reservationId');
  }

  // Announcements
  Future<List<dynamic>> getAnnouncements() async {
    final response = await _dio.get('/announcements');
    return _list(response.data);
  }

  // Surveys
  Future<List<dynamic>> getSurveys() async {
    final response = await _dio.get('/surveys');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> submitSurveyResponse(String surveyId, Map<String, dynamic> data) async {
    final response = await _dio.post('/surveys/$surveyId/responses', data: data);
    return response.data;
  }

  // Packages
  Future<List<dynamic>> getPackages() async {
    final response = await _dio.get('/packages');
    return _list(response.data);
  }

  // Visitors
  Future<List<dynamic>> getVisitors() async {
    final response = await _dio.get('/visitors');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createVisitorPreRegistration(Map<String, dynamic> data) async {
    final response = await _dio.post('/visitors', data: data);
    return response.data;
  }

  // Bulletins (İlan Panosu)
  Future<List<dynamic>> getBulletins() async {
    final response = await _dio.get('/bulletins');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createBulletin(Map<String, dynamic> data) async {
    final response = await _dio.post('/bulletins', data: data);
    return response.data;
  }

  /// Servisler liste yanıtını iki biçimde döndürebiliyor: düz dizi ya da
  /// `{"data": [...]}` sarmalayıcısı. Sunucu sözleşmesi `{"data": ...}` olarak
  /// tekilleştirildi; bu yardımcı, eski biçimi de kabul ederek istemcinin
  /// sürüm farkında kırılmasını engeller.
  static List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final v = data['data'] ?? data['items'];
      if (v is List) return v;
    }
    return const [];
  }
}

final apiClient = ApiClient();
