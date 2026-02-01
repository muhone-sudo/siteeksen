import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  late final Dio _dio;
  String? _accessToken;
  
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
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token yenileme mantığı
          // TODO: Refresh token ile yeni token al
        }
        return handler.next(error);
      },
    ));
  }
  
  void setToken(String token) {
    _accessToken = token;
  }
  
  void clearToken() {
    _accessToken = null;
  }

  // Auth
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
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

  Future<List<dynamic>> getUserProperties() async {
    final response = await _dio.get('/users/me/properties');
    return response.data;
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
    return response.data;
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
    return response.data;
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
}
