import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_constants.dart';

class ApiResponse {
  final bool status;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    bool isSuccess = _evaluateStatus(json);

    String message = json['message']?.toString() ?? json['msg']?.toString() ?? '';
    if (message.isEmpty && isSuccess) {
      message = 'Transaction completed successfully.';
    }

    return ApiResponse(
      status: isSuccess,
      message: message,
      data: json['data'] ?? json['transaction'] ?? json['details'] ?? json['response'],
      errors: json['errors'] is Map<String, dynamic> ? json['errors'] as Map<String, dynamic> : null,
    );
  }

  static bool _evaluateStatus(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['success'] ?? json['code'] ?? json['status_code'] ?? json['response_code'];
    if (rawStatus != null) {
      if (rawStatus == true || rawStatus == 1 || rawStatus == '1' || rawStatus == 200 || rawStatus == '200') {
        return true;
      }
      final str = rawStatus.toString().toLowerCase().trim();
      if (str == 'true' || str == 'success' || str == 'successful' || str == 'completed' || str == 'approved' || str == '00' || str == 'paid') {
        return true;
      }
    }

    final msg = (json['message'] ?? json['msg'] ?? '').toString().toLowerCase();
    if (msg.contains('success') || msg.contains('successful') || msg.contains('completed') || msg.contains('approved')) {
      return true;
    }

    return false;
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();
  Function()? onUnauthenticated;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clearSession();
            if (onUnauthenticated != null) {
              onUnauthenticated!();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(status: false, message: e.toString());
    }
  }

  Future<ApiResponse> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _parseResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(status: false, message: e.toString());
    }
  }

  Future<ApiResponse> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return _parseResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(status: false, message: e.toString());
    }
  }

  Future<ApiResponse> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return _parseResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse(status: false, message: e.toString());
    }
  }

  ApiResponse _parseResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return ApiResponse.fromJson(response.data);
    }
    return ApiResponse(
      status: response.statusCode == 200 || response.statusCode == 201,
      message: 'Success',
      data: response.data,
    );
  }

  ApiResponse _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final resData = e.response!.data as Map<String, dynamic>;
      final parsed = ApiResponse.fromJson(resData);
      if (parsed.status) {
        return parsed;
      }
      return ApiResponse(
        status: false,
        message: parsed.message.isNotEmpty ? parsed.message : 'An error occurred',
        data: parsed.data,
        errors: parsed.errors,
      );
    }
    String message = 'Network connection error. Please try again.';
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet connection or transaction history.';
    }
    return ApiResponse(status: false, message: message);
  }
}
