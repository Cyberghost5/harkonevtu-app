import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

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
    return ApiResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'],
      errors: json['errors'] is Map<String, dynamic> ? json['errors'] : null,
    );
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
        baseUrl: 'https://nmilleniumresource.com.ng/api/v1',
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
      return ApiResponse(
        status: false,
        message: resData['message']?.toString() ?? 'An error occurred',
        data: resData['data'],
        errors: resData['errors'] is Map<String, dynamic> ? resData['errors'] : null,
      );
    }
    String message = 'Network connection error. Please try again.';
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet connection.';
    }
    return ApiResponse(status: false, message: message);
  }
}
