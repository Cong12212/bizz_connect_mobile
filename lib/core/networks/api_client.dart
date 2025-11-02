import 'package:dio/dio.dart';
import '../constants.dart';

class ApiClient {
  ApiClient._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConst.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
          // Allow 204 No Content
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[Dio] $obj'),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // Gom lỗi Laravel: {message}|{errors[field][0]}
          String msg = 'Unexpected error';
          final data = e.response?.data;
          if (data is Map) {
            if (data['message'] is String) msg = data['message'];
            if (data['errors'] is Map && data['errors'].isNotEmpty) {
              final first = (data['errors'] as Map).values.first;
              if (first is List && first.isNotEmpty && first.first is String) {
                msg = first.first;
              }
            }
          }
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              error: msg,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;

  final Dio _dio;
  Dio get dio => _dio;

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
