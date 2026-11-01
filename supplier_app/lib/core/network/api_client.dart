// SiteEksen Tedarikçi API istemcisi (FAZ M9): kimlik (tedarikçi kaydı, giriş, jeton yenileme) ve pazaryeri uçları
// (`tasks/api-sozlesmesi.md` marketplace bölümü). Jeton güvenli depoda tutulur; 401'de bir kez yenilenir.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// Derleme zamanında verilir: `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
  /// Varsayılan, Android emülatöründen yerel gateway'dir.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8888/api/v1');

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;
  Future<bool>? _refreshing;

  ApiClient() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final original = error.requestOptions;
        final hadToken = original.headers['Authorization'] != null;
        if (error.response?.statusCode == 401 && hadToken && original.extra['_retried'] != true) {
          original.extra['_retried'] = true;
          if (await refresh()) {
            original.headers['Authorization'] = 'Bearer ${await _storage.read(key: _accessKey)}';
            try {
              return handler.resolve(await _dio.fetch(original));
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Aynı anda gelen 401'ler tek yenileme isteğini paylaşır (yenileme jetonu tek kullanımlıktır).
  Future<bool> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final rt = await _storage.read(key: _refreshKey);
    if (rt == null) return false;
    try {
      final r = await Dio(BaseOptions(baseUrl: baseUrl)).post('/auth/refresh', data: {'refresh_token': rt});
      await _saveSession(Map<String, dynamic>.from(r.data as Map));
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> s) async {
    await _storage.write(key: _accessKey, value: '${s['access_token']}');
    if (s['refresh_token'] != null) await _storage.write(key: _refreshKey, value: '${s['refresh_token']}');
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> hasSession() async => (await _storage.read(key: _accessKey)) != null;

  Map<String, dynamic> _map(Object? d) => Map<String, dynamic>.from(d as Map);
  List<dynamic> _list(Object? d) => d is List ? d : (d is Map ? (d['data'] as List? ?? const []) : const []);

  // --- Kimlik ---
  Future<void> login(String phone, String password) async =>
      _saveSession(_map((await _dio.post('/auth/login', data: {'phone': phone, 'password': password})).data));

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout', data: {'refresh_token': await _storage.read(key: _refreshKey)});
    } catch (_) {}
    await clearSession();
  }

  Future<Map<String, dynamic>> signupRequest(String phone) async => _map((await _dio.post('/auth/supplier-signup/request', data: {'phone': phone})).data);
  Future<Map<String, dynamic>> signupVerify(String phone, String code) async =>
      _map((await _dio.post('/auth/supplier-signup/verify', data: {'phone': phone, 'code': code})).data);
  Future<void> signupComplete(Map<String, dynamic> body) async =>
      _saveSession(_map((await _dio.post('/auth/supplier-signup/complete', data: body)).data));

  // --- Hesap ve belgeler ---
  Future<Map<String, dynamic>> meta() async => _map((await _dio.get('/market/meta')).data);
  Future<Map<String, dynamic>?> me() async {
    try {
      return _map((await _dio.get('/market/supplier/me')).data);
    } on DioException catch (e) {
      final d = e.response?.data;
      if (e.response?.statusCode == 404 && d is Map && d['code'] == 'NO_ACCOUNT') return null;
      rethrow;
    }
  }

  Future<void> createAccount(Map<String, dynamic> b) async => _dio.post('/market/supplier/account', data: b);
  Future<void> updateAccount(Map<String, dynamic> b) async => _dio.put('/market/supplier/account', data: b);
  Future<void> submitAccount() async => _dio.post('/market/supplier/account/submit');
  Future<List<dynamic>> documents() async => _list((await _dio.get('/market/supplier/documents')).data);
  Future<void> uploadDocument(String type, List<int> bytes, String name) async => _dio.post('/market/supplier/documents',
      data: FormData.fromMap({'doc_type': type, 'file': MultipartFile.fromBytes(bytes, filename: name)}));
  Future<List<int>> documentFile(String id) async =>
      (await _dio.get<List<int>>('/market/supplier/documents/$id/file', options: Options(responseType: ResponseType.bytes))).data ?? const [];

  // --- İşletmeler ve hizmet kalemleri ---
  Future<List<dynamic>> businesses() async => _list((await _dio.get('/market/supplier/businesses')).data);
  Future<Map<String, dynamic>> business(String id) async => _map((await _dio.get('/market/supplier/businesses/$id')).data);
  Future<Map<String, dynamic>> saveBusiness(String? id, Map<String, dynamic> b) async => _map((id == null
          ? await _dio.post('/market/supplier/businesses', data: b)
          : await _dio.put('/market/supplier/businesses/$id', data: b))
      .data);
  Future<void> businessAction(String id, String action) async => _dio.post('/market/supplier/businesses/$id/$action');
  Future<List<dynamic>> services(String businessId) async => _list((await _dio.get('/market/supplier/businesses/$businessId/services')).data);
  Future<Map<String, dynamic>> saveService(String businessId, String? id, Map<String, dynamic> b) async => _map((id == null
          ? await _dio.post('/market/supplier/businesses/$businessId/services', data: b)
          : await _dio.put('/market/supplier/services/$id', data: b))
      .data);
  Future<void> deleteService(String id) async => _dio.delete('/market/supplier/services/$id');
  Future<void> uploadServicePhoto(String id, List<int> bytes, String name) async =>
      _dio.post('/market/supplier/services/$id/photo', data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: name)}));

  // --- Talepler, teklif, yazışma, iş ---
  Future<Map<String, dynamic>> requests() async => _map((await _dio.get('/market/supplier/requests')).data);
  Future<Map<String, dynamic>> request(String id) async => _map((await _dio.get('/market/supplier/requests/$id')).data);
  Future<Map<String, dynamic>> accept(String id) async => _map((await _dio.post('/market/supplier/requests/$id/accept')).data);
  Future<Map<String, dynamic>> deal(String id) async => _map((await _dio.get('/market/supplier/requests/$id/deal')).data);
  Future<void> saveOffer(String id, Map<String, dynamic> b) async => _dio.post('/market/supplier/requests/$id/offers', data: b);
  Future<void> withdrawOffer(String offerId) async => _dio.post('/market/supplier/offers/$offerId/withdraw');
  Future<List<dynamic>> messages(String id) async =>
      _list((await _dio.get('/market/supplier/requests/$id/messages', queryParameters: {'limit': 200})).data);
  Future<void> sendMessage(String id, String body) async => _dio.post('/market/supplier/requests/$id/messages', data: {'body': body});
  Future<void> jobDone(String jobId) async => _dio.post('/market/supplier/jobs/$jobId/done');
  Future<void> dispute(String id, String reason, String note) async =>
      _dio.post('/market/supplier/requests/$id/dispute', data: {'reason_code': reason, 'note': note});
  Future<List<int>> requestPhoto(String id, int n) async =>
      (await _dio.get<List<int>>('/market/supplier/requests/$id/photos/$n', options: Options(responseType: ResponseType.bytes))).data ?? const [];

  // --- Puanlar, bildirimler ---
  Future<List<dynamic>> reviews() async => _list((await _dio.get('/market/supplier/reviews')).data);
  Future<void> replyReview(String id, String reply) async => _dio.post('/market/supplier/reviews/$id/reply', data: {'reply': reply});
  Future<Map<String, dynamic>> notifications() async => _map((await _dio.get('/market/supplier/notifications')).data);
  Future<void> readNotifications() async => _dio.post('/market/supplier/notifications/read', data: {'ids': <String>[]});

  // --- Bakiye ve paket ---
  Future<Map<String, dynamic>> wallet() async => _map((await _dio.get('/market/supplier/wallet', queryParameters: {'limit': 50})).data);
  Future<Map<String, dynamic>> startTopup(int kurus, String idempotencyKey) async => _map((await _dio.post('/market/supplier/topups',
          data: {'amount_kurus': kurus, 'return_to': 'APP'}, options: Options(headers: {'Idempotency-Key': idempotencyKey})))
      .data);
  Future<Map<String, dynamic>> topup(String id) async => _map((await _dio.get('/market/supplier/topups/$id')).data);
  Future<Map<String, dynamic>> balanceTerms() async => _map((await _dio.get('/market/terms/balance')).data);
  Future<void> acceptBalanceTerms(String version) async => _dio.post('/market/supplier/terms/balance/accept', data: {'version': version});
  Future<List<dynamic>> cardRefunds() async => _list((await _dio.get('/market/supplier/card-refunds')).data);
  Future<Map<String, dynamic>> changePackage(String id) async => _map((await _dio.post('/market/supplier/package', data: {'package_id': id})).data);
}

final apiClient = ApiClient();
