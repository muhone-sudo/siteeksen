import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.siteeksen.com/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Local dev
  
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
        if (error.response?.statusCode == 401) {
          // Token refresh dene
          final refreshed = await _refreshToken();
          if (refreshed) {
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await Dio().post(
        '$baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: response.data['access_token']);
        return true;
      }
    } catch (e) {
      // Refresh failed
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
  
  // ============ DASHBOARD ============
  
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/dashboard/stats');
    return response.data;
  }
  
  // ============ RESIDENTS ============
  
  Future<List<dynamic>> getResidents({String? search, int page = 1}) async {
    final response = await _dio.get('/users', queryParameters: {
      'role': 'RESIDENT',
      'search': search,
      'page': page,
      'limit': 20,
    });
    return response.data['data'];
  }
  
  Future<Map<String, dynamic>> getResident(String id) async {
    final response = await _dio.get('/users/$id');
    return response.data;
  }
  
  Future<void> createResident(Map<String, dynamic> data) async {
    await _dio.post('/users', data: data);
  }
  
  Future<void> updateResident(String id, Map<String, dynamic> data) async {
    await _dio.put('/users/$id', data: data);
  }
  
  // ============ UNITS ============
  
  Future<List<dynamic>> getUnits() async {
    final response = await _dio.get('/units');
    return response.data['data'];
  }
  
  // ============ FINANCE ============
  
  Future<Map<String, dynamic>> getFinanceOverview() async {
    final response = await _dio.get('/finance/overview');
    return response.data;
  }
  
  Future<List<dynamic>> getAssessments({int? year, int? month}) async {
    final response = await _dio.get('/finance/assessments', queryParameters: {
      'year': year,
      'month': month,
    });
    return response.data['data'];
  }
  
  Future<void> createAssessment(Map<String, dynamic> data) async {
    await _dio.post('/finance/assessments', data: data);
  }
  
  Future<List<dynamic>> getPayments({String? status, int page = 1}) async {
    final response = await _dio.get('/finance/payments', queryParameters: {
      'status': status,
      'page': page,
    });
    return response.data['data'];
  }
  
  Future<List<dynamic>> getExpenseCategories() async {
    final response = await _dio.get('/finance/expense-categories');
    return response.data['data'];
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
    return response.data['data'];
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
    return response.data['data'];
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
    return response.data['data'];
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
}

// Singleton
final apiClient = ApiClient();
