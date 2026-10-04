import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// İndirilen belge: baytlar ve sunucunun bildirdiği bütünlük özeti.
class DownloadedDocument {
  final List<int> bytes;
  final String? sha256;
  final String? contentType;

  const DownloadedDocument({required this.bytes, this.sha256, this.contentType});
}

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
  /// Sunucudaki oturumu kapatır (erişim + yenileme jetonu iptal edilir), sonra
  /// cihazdaki jetonları siler. Sunucu iptali başarısız olsa da cihaz temizlenir;
  /// dönüş değeri sunucu iptalinin gerçekleşip gerçekleşmediğidir.
  Future<bool> logout() async {
    var revoked = false;
    try {
      final refresh = await _storage.read(key: _refreshTokenKey);
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
    await clearToken();
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
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Şifre değiştirir. Başarılıysa sunucu BÜTÜN oturumları kapatır; cihazdaki
  /// jetonlar da silinir ve kullanıcı yeniden giriş yapar.
  Future<Map<String, dynamic>> changePassword(String current, String next) async {
    final response = await _dio.post('/users/me/password', data: {
      'current_password': current,
      'new_password': next,
    });
    await clearToken();
    return Map<String, dynamic>.from(response.data as Map);
  }

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

  // User
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  /// KVKK açık rıza onayını kaydeder (zorunlu onay ekranı sonrası çağrılır).
  Future<void> acceptKvkkConsent() async {
    await _dio.post('/users/me/kvkk-consent');
  }

  /// Kişinin yanıt bekleyen site davetleri (S-20): başka bir sitenin yönetimi
  /// kişiyi sakin olarak eklemek istediğinde bağ, kişi kabul edene kadar kurulmaz.
  Future<List<dynamic>> getMyInvitations() async {
    final response = await _dio.get('/users/me/invitations');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> respondInvitation(String id, {required bool accept}) async {
    final response = await _dio.post('/users/me/invitations/$id/${accept ? 'accept' : 'decline'}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// KVKK ilgili kişi başvuruları (m.11): kişinin kendi başvuruları.
  Future<List<dynamic>> getKvkkRequests() async {
    final response = await _dio.get('/kvkk-requests');
    return _list(response.data);
  }

  Future<Map<String, dynamic>> createKvkkRequest(String type, String description) async {
    final response = await _dio.post('/kvkk-requests', data: {'request_type': type, 'description': description});
    return Map<String, dynamic>.from(response.data as Map);
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

  /// Tesisin seçilen gündeki DOLU aralıkları ve açılış saatleri.
  /// `{date, open, available_from, available_to, buffer_minutes, busy:[…], note}`
  Future<Map<String, dynamic>> getFacilitySlots(String facilityId, String date) async {
    final response = await _dio.get('/facilities/$facilityId/slots', queryParameters: {'date': date});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// `startTime`/`endTime` RFC3339 olmalıdır (ör. `2026-10-01T09:00:00+03:00`).
  Future<Map<String, dynamic>> createReservation({
    required String facilityId,
    required String startTime,
    required String endTime,
    int? guestCount,
    String? purpose,
  }) async {
    final response = await _dio.post('/reservations', data: {
      'facility_id': facilityId,
      'start_time': startTime,
      'end_time': endTime,
      if (guestCount != null) 'guest_count': guestCount,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId, {String? reason}) async {
    final response = await _dio.post('/reservations/$reservationId/cancel', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Announcements
  Future<List<dynamic>> getAnnouncements() async {
    final response = await _dio.get('/announcements');
    return _list(response.data);
  }

  /// Duyurunun okunduğunu kaydeder (yönetim okunma oranını görür).
  Future<void> markAnnouncementRead(String id) async {
    await _dio.post('/announcements/$id/read');
  }

  // Surveys
  Future<List<dynamic>> getSurveys() async {
    final response = await _dio.get('/surveys');
    return _list(response.data);
  }

  /// `{survey:{…, options:[…]}, results_visible, legal_notice, …}`
  Future<Map<String, dynamic>> getSurvey(String surveyId) async {
    final response = await _dio.get('/surveys/$surveyId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> voteSurvey(String surveyId, String optionId, {String? comment}) async {
    final response = await _dio.post('/surveys/$surveyId/vote', data: {
      'option_id': optionId,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Notifications (uygulama içi gelen kutusu)
  Future<List<dynamic>> getNotifications({int limit = 50}) async {
    final response = await _dio.get('/notifications', queryParameters: {'limit': limit});
    return _list(response.data);
  }

  /// `{data:[{channel,category,enabled,consent_at?,consent_source?}], note}`
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _dio.get('/notification-preferences');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> setNotificationPreference({
    required String channel,
    required String category,
    required bool enabled,
  }) async {
    final response = await _dio.put('/notification-preferences', data: {
      'channel': channel,
      'category': category,
      'enabled': enabled,
      'consent_source': 'MOBILE_APP',
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Documents (görünürlüğe göre)
  Future<List<dynamic>> getDocuments() async {
    final response = await _dio.get('/documents');
    return _list(response.data);
  }

  /// Belgenin kendisini indirir (`GET /documents/:id/download`). Sunucu her
  /// indirmeyi erişim kaydına yazar ve bütünlük için `X-Document-SHA256` döner.
  Future<DownloadedDocument> downloadDocument(String id) async {
    final response = await _dio.get<List<int>>(
      '/documents/$id/download',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Accept': '*/*'},
      ),
    );
    return DownloadedDocument(
      bytes: response.data ?? const [],
      sha256: response.headers.value('x-document-sha256'),
      contentType: response.headers.value('content-type'),
    );
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

  /// `{id, status:"PENDING", note}` — ilan yönetim onayına düşer.
  Future<Map<String, dynamic>> createBulletin(Map<String, dynamic> data) async {
    final response = await _dio.post('/bulletins', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> closeBulletin(String id) async {
    await _dio.post('/bulletins/$id/close');
  }

  /// Servisler liste yanıtını iki biçimde döndürebiliyor: düz dizi ya da
  /// `{"data": [...]}` sarmalayıcısı. Sunucu sözleşmesi `{"data": ...}` olarak
  /// tekilleştirildi; bu yardımcı, eski biçimi de kabul ederek istemcinin
  /// sürüm farkında kırılmasını engeller.
  static List<dynamic> _list(dynamic data) => listOf(data);

  /// [_list]'in dışa açık hâli (ekranlar ham yanıt aldığında kullanır).
  static List<dynamic> listOf(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final v = data['data'] ?? data['items'];
      if (v is List) return v;
    }
    return const [];
  }
}

final apiClient = ApiClient();
