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

  // ============ DASHBOARD ============

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/dashboard/stats');
    return response.data;
  }

  // ============ RESIDENTS ============

  Future<List<dynamic>> getResidents({String? search, String? block, String? role}) async {
    final response = await _dio.get('/residents', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (block != null && block.isNotEmpty) 'block': block,
      if (role != null && role.isNotEmpty) 'role': role,
    });
    return _list(response.data, 'data');
  }

  Future<Map<String, dynamic>> getResident(String id) async {
    final response = await _dio.get('/residents/$id');
    return response.data;
  }

  Future<void> createResident(Map<String, dynamic> data) async {
    await _dio.post('/residents', data: data);
  }

  Future<void> updateResident(String id, Map<String, dynamic> data) async {
    await _dio.patch('/residents/$id', data: data);
  }

  // ============ UNITS ============

  Future<List<dynamic>> getUnits() async {
    final response = await _dio.get('/units');
    return _list(response.data, 'data');
  }

  // ============ FINANCE ============

  Future<Map<String, dynamic>> getFinanceOverview() async {
    // DÜZELTME (2026-09-13): '/finance/overview' diye bir uç YOK; her çağrı 404 dönüyordu.
    // Finance servisindeki gerçek uç dönem bazlı tahakkuk/tahsilat özetidir.
    final response = await _dio.get('/finance/assessments/overview');
    return response.data;
  }

  Future<List<dynamic>> getAssessments({int? year, int? month}) async {
    final response = await _dio.get('/finance/assessments', queryParameters: {
      'year': year,
      'month': month,
    });
    return _list(response.data, 'data');
  }

  Future<void> createAssessment(Map<String, dynamic> data) async {
    await _dio.post('/finance/assessments', data: data);
  }

  Future<List<dynamic>> getPayments({String? status, int page = 1}) async {
    final response = await _dio.get('/finance/payments', queryParameters: {
      'status': status,
      'page': page,
    });
    return _list(response.data, 'data');
  }

  Future<List<dynamic>> getExpenseCategories() async {
    final response = await _dio.get('/finance/expense-categories');
    return _list(response.data, 'data');
  }

  Future<void> sendPaymentReminder(String userId) async {
    await _dio.post('/notifications/send', data: {
      'type': 'PUSH',
      'recipients': [userId],
      'title': 'Ödeme Hatırlatması',
      'body': 'Ödenmemiş aidat borcunuz bulunmaktadır.',
    });
  }

  // ============ METERS ============

  Future<List<dynamic>> getMeters({String? type}) async {
    final response = await _dio.get('/meters', queryParameters: {'type': type});
    return _list(response.data, 'data');
  }

  Future<void> submitMeterReading(String meterId, double value) async {
    await _dio.post('/meters/$meterId/readings', data: {'value': value});
  }

  Future<void> submitBulkReadings(List<Map<String, dynamic>> readings) async {
    await _dio.post('/meters/bulk-readings', data: {'readings': readings});
  }

  // ============ ANNOUNCEMENTS ============

  Future<List<dynamic>> getAnnouncements() async {
    final response = await _dio.get('/announcements');
    return _list(response.data, 'data');
  }

  Future<void> createAnnouncement(Map<String, dynamic> data) async {
    await _dio.post('/announcements', data: data);
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _dio.put('/announcements/$id', data: data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete('/announcements/$id');
  }

  // ============ REQUESTS ============

  Future<List<dynamic>> getRequests({String? status}) async {
    final response = await _dio.get('/requests', queryParameters: {'status': status});
    return _list(response.data, 'data');
  }

  Future<Map<String, dynamic>> getRequest(String id) async {
    final response = await _dio.get('/requests/$id');
    return response.data;
  }

  Future<void> updateRequestStatus(String id, String status, {String? note}) async {
    await _dio.patch('/requests/$id/status', data: {
      'status': status,
      'note': note,
    });
  }

  Future<void> addRequestComment(String id, String comment) async {
    await _dio.post('/requests/$id/comments', data: {'content': comment});
  }

  // ============ REPORTS ============

  Future<String> generateReport(String type, {int? year, int? month}) async {
    final response = await _dio.post('/reports/generate', data: {
      'type': type,
      'year': year,
      'month': month,
    });
    return response.data['download_url'];
  }

  // ============ PARKING ============
  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/vehicles');
    return _list(response.data, 'data');
  }

  Future<void> createVehicle(Map<String, dynamic> data) async {
    await _dio.post('/vehicles', data: data);
  }

  Future<List<dynamic>> getParkingLogs() async {
    final response = await _dio.get('/parking-logs');
    return _list(response.data, 'data');
  }

  Future<Map<String, dynamic>> recognizePlate(String base64Image) async {
    final response = await _dio.post('/plate-recognition', data: {'image': base64Image});
    return response.data;
  }

  // ============ PERSONNEL ============
  Future<List<dynamic>> getEmployees() async {
    final response = await _dio.get('/employees');
    return _list(response.data, 'data');
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    await _dio.post('/employees', data: data);
  }

  Future<List<dynamic>> getLeaves() async {
    final response = await _dio.get('/leaves');
    return _list(response.data, 'data');
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    await _dio.patch('/leaves/$leaveId', data: {'status': status});
  }

  // ============ VISITORS ============
  Future<List<dynamic>> getVisitors() async {
    final response = await _dio.get('/visitors');
    return _list(response.data, 'data');
  }

  Future<void> recordVisitorEntry(String visitorId) async {
    await _dio.post('/visitors/$visitorId/entry');
  }

  Future<void> recordVisitorExit(String visitorId) async {
    await _dio.post('/visitors/$visitorId/exit');
  }

  // ============ PACKAGES ============
  Future<List<dynamic>> getPackages() async {
    final response = await _dio.get('/packages');
    return _list(response.data, 'data');
  }

  Future<List<dynamic>> getCarriers() async {
    final response = await _dio.get('/carriers');
    return _list(response.data, 'data');
  }

  Future<List<dynamic>> getUnitPackages(String unitId) async {
    final response = await _dio.get('/units/$unitId/packages');
    return _list(response.data, 'data');
  }

  Future<void> receivePackage(Map<String, dynamic> data) async {
    await _dio.post('/packages', data: data);
  }

  Future<void> deliverPackage(String packageId) async {
    await _dio.post('/packages/$packageId/deliver');
  }

  // ============ BANKING ============
  Future<List<dynamic>> getBankAccounts() async {
    final response = await _dio.get('/bank-accounts');
    return _list(response.data, 'data');
  }

  Future<List<dynamic>> getBankTransactions() async {
    final response = await _dio.get('/bank-transactions');
    return _list(response.data, 'data');
  }

  Future<void> matchBankTransaction(String transactionId, String assessmentId) async {
    await _dio.post('/bank-transactions/$transactionId/match', data: {'assessment_id': assessmentId});
  }

  // ============ FACILITIES & RESERVATIONS ============
  Future<List<dynamic>> getFacilities() async {
    final response = await _dio.get('/facilities');
    return _list(response.data, 'facilities');
  }

  Future<List<dynamic>> getReservations() async {
    final response = await _dio.get('/reservations');
    return _list(response.data, 'data');
  }

  Future<void> createReservation(Map<String, dynamic> data) async {
    await _dio.post('/reservations', data: data);
  }

  Future<void> cancelReservation(String id) async {
    await _dio.delete('/reservations/$id');
  }

  // ============ GİDERLER ============
  Future<List<dynamic>> getExpenses({int? year, int? month, String? status}) async {
    final response = await _dio.get('/expenses', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (status != null) 'status': status,
    });
    return _list(response.data, 'expenses');
  }

  Future<Map<String, dynamic>> getExpense(String id) async {
    final response = await _dio.get('/expenses/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> createExpense(Map<String, dynamic> data) async {
    await _dio.post('/expenses', data: data);
  }

  // ============ SÖZLEŞMELER ============
  Future<List<dynamic>> getContracts({String? status}) async {
    final response = await _dio.get('/contracts', queryParameters: {
      if (status != null) 'status': status,
    });
    return _list(response.data, 'contracts');
  }

  Future<void> createContract(Map<String, dynamic> data) async {
    await _dio.post('/contracts', data: data);
  }

  // ============ İLAN PANOSU ============
  Future<List<dynamic>> getBulletins() async {
    final response = await _dio.get('/bulletin');
    return _list(response.data, 'bulletins');
  }

  Future<void> createBulletin(Map<String, dynamic> data) async {
    await _dio.post('/bulletin', data: data);
  }

  Future<void> deleteBulletin(String id) async {
    await _dio.delete('/bulletin/$id');
  }

  // ============ ENERJİ / TÜKETİM ANALİTİĞİ ============
  Future<Map<String, dynamic>> getEnergySummary() async {
    final response = await _dio.get('/energy/summary');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getEnergyConsumption({String? period}) async {
    final response = await _dio.get('/energy/consumption', queryParameters: {
      if (period != null) 'period': period,
    });
    return _list(response.data, 'consumption');
  }

  // ============ AKILLI TAHSİLAT ============
  Future<Map<String, dynamic>> getCollectionOverview() async {
    final response = await _dio.get('/smart-collection/overview');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getCollectionCandidates() async {
    final response = await _dio.get('/smart-collection/candidates');
    return _list(response.data, 'candidates');
  }

  Future<void> startCollectionAction(String residentId, String action) async {
    await _dio.post('/smart-collection/actions',
        data: {'resident_id': residentId, 'action': action});
  }

  // ============ GENEL KURUL / TOPLANTI ============
  Future<List<dynamic>> getMeetings() async {
    final response = await _dio.get('/meetings');
    return _list(response.data, 'meetings');
  }

  Future<void> createMeeting(Map<String, dynamic> data) async {
    await _dio.post('/meetings', data: data);
  }

  // ============ ANKETLER ============
  Future<List<dynamic>> getSurveys() async {
    final response = await _dio.get('/surveys');
    return _list(response.data, 'surveys');
  }

  Future<void> createSurvey(Map<String, dynamic> data) async {
    await _dio.post('/surveys', data: data);
  }

  Future<Map<String, dynamic>> getSurveyResults(String id) async {
    final response = await _dio.get('/surveys/$id/results');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ============ DEVRİYE ============
  Future<List<dynamic>> getPatrolRoutes() async {
    final response = await _dio.get('/patrol-routes');
    return _list(response.data, 'routes');
  }

  Future<List<dynamic>> getPatrolSessions() async {
    final response = await _dio.get('/patrol-sessions');
    return _list(response.data, 'sessions');
  }

  // ============ DEMİRBAŞ ============
  Future<List<dynamic>> getAssets() async {
    final response = await _dio.get('/assets');
    return _list(response.data, 'assets');
  }

  Future<void> createAsset(Map<String, dynamic> data) async {
    await _dio.post('/assets', data: data);
  }

  // ============ STOK ============
  Future<List<dynamic>> getInventory() async {
    final response = await _dio.get('/inventory');
    return _list(response.data, 'items');
  }

  Future<void> createStockMovement(Map<String, dynamic> data) async {
    await _dio.post('/stock-movements', data: data);
  }

  // ============ API KİMLİK BİLGİLERİ ============
  Future<List<dynamic>> getCredentials() async {
    final response = await _dio.get('/credentials');
    return _list(response.data, 'credentials');
  }

  Future<void> createCredential(Map<String, dynamic> data) async {
    await _dio.post('/credentials', data: data);
  }

  Future<void> deleteCredential(String id) async {
    await _dio.delete('/credentials/$id');
  }

  /// Servislerin liste yanıtları iki biçimde gelebiliyor:
  /// düz dizi ya da `{"<anahtar>": [...]}` / `{"data": [...]}`.
  static List<dynamic> _list(dynamic data, String key) {
    if (data is List) return data;
    if (data is Map) {
      final v = data[key] ?? data['data'] ?? data['items'];
      if (v is List) return v;
    }
    return const [];
  }
}

// Singleton
final apiClient = ApiClient();
